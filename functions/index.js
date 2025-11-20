/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onRequest } = require("firebase-functions/v2/https"); 
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe");;

// Load environment variables from .env file
require('dotenv').config();

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

// Get Stripe keys from environment
const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;
const STRIPE_WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET;

// Helper function to generate next payment ID
async function generateNextPaymentID() {
  const prefix = "PY";
  const padding = 4;

  try {
    const query = await db.collection("Payment")
        .where("payID", ">=", prefix)
        .where("payID", "<", prefix + "Z")
        .orderBy("payID", "desc")
        .limit(1)
        .get();

    if (query.empty) {
      return `${prefix}${"1".padStart(padding, "0")}`; // PY0001
    }

    const lastDoc = query.docs[0];
    const lastID = lastDoc.data().payID;
    const numericPart = lastID.substring(prefix.length);
    const lastNumber = parseInt(numericPart, 10);
    const nextNumber = lastNumber + 1;
    return `${prefix}${nextNumber.toString().padStart(padding, "0")}`;
  } catch (error) {
    console.error("Error generating payment ID:", error);
    return `${prefix}${"1".padStart(padding, "0")}`;
  }
}

// Create Payment Intent - Callable Function
exports.createPaymentIntent = onCall(async (request) => {
  try {
    console.log("createPaymentIntent called (v2)");
    const auth = request.auth;
    const data = request.data;
    console.log("context.auth:", auth);

    if (!auth) {
      throw new HttpsError(
          "unauthenticated",
          "User must be authenticated",
      );
    }
    
    const userId = auth.uid;
    console.log("Authenticated userId:", userId);
    const {amount, currency = "myr", paymentMethodType, billingID} = data;

    // Validate required fields
    if (!amount || !paymentMethodType) {
      throw new functions.https.HttpsError(
          "invalid-argument",
          "Amount and payment method type are required",
      );
    }

    if (!billingID) {
      throw new functions.https.HttpsError(
          "invalid-argument",
          "Billing ID is required",
      );
    }

    // Initialize Stripe with secret key
    const stripeClient = stripe(STRIPE_SECRET_KEY);

    // Create PaymentIntent
    const paymentIntent = await stripeClient.paymentIntents.create({
      amount: amount,
      currency: currency,
      payment_method_types: [paymentMethodType],
      metadata: {
        userId: userId,
        billingID: billingID,
      },
    });

    console.log("PaymentIntent created successfully:", paymentIntent.id);

    return {
      clientSecret: paymentIntent.client_secret,
    };
  } catch (error) {
    console.error("Error creating payment intent:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError(
        "internal",
        error.message || "Failed to create payment intent",
    );
  }
});

// Stripe Webhook Handler - HTTP Function
exports.stripeWebhook = onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];

  let event;

  try {
    // Initialize Stripe with secret key
    const stripeClient = stripe(STRIPE_SECRET_KEY);

    // Construct event from webhook
    event = stripeClient.webhooks.constructEvent(
        req.rawBody,
        sig,
        STRIPE_WEBHOOK_SECRET,
    );
  } catch (err) {
    console.error("Webhook signature verification failed:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle payment_intent.succeeded
  if (event.type === "payment_intent.succeeded") {
    const paymentIntent = event.data.object;
    const billingID = paymentIntent.metadata.billingID;
    const paymentMethod = paymentIntent.payment_method_types[0];

    if (!billingID) {
      console.error("Webhook Error: billingID missing from metadata");
      return res.status(200).send("Webhook Error: Missing billingID");
    }

    try {
      // Check if payment already exists for this billing
      const existingPayment = await db.collection("Payment")
          .where("billingID", "==", billingID)
          .where("payStatus", "==", "paid")
          .limit(1)
          .get();

      if (!existingPayment.empty) {
        console.log(`Payment already exists for billingID: ${billingID}`);
        return res.status(200).json({received: true, note: "Already processed"});
      }

      // Get billing document
      const billingDoc = await db.collection("Billing").doc(billingID).get();

      if (!billingDoc.exists) {
        throw new Error(`Billing document ${billingID} not found`);
      }

      // Generate payment ID
      const newPaymentID = await generateNextPaymentID();

      // Create payment document
      const newPayment = {
        payID: newPaymentID,
        payStatus: "paid",
        payAmt: paymentIntent.amount / 100,
        payMethod: paymentMethod,
        payCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
        adminRemark: "",
        payMediaProof: "",
        providerID: "",
        billingID: billingID,
      };

      // Use batch write for atomicity
      const batch = db.batch();

      // Add payment document
      const paymentRef = db.collection("Payment").doc(newPaymentID);
      batch.set(paymentRef, newPayment);

      // Update billing status
      const billingRef = db.collection("Billing").doc(billingID);
      batch.update(billingRef, {billStatus: "paid"});

      await batch.commit();

      console.log(`Successfully processed payment for billingID: ${billingID}`);
      return res.status(200).json({received: true});
    } catch (error) {
      console.error("Payment processing error:", error);
      return res.status(500).json({
        error: "Internal Server Error",
        message: error.message,
      });
    }
  } else if (event.type === "payment_intent.payment_failed") {
    // Handle payment_intent.payment_failed
    const paymentIntent = event.data.object;
    const billingID = paymentIntent.metadata.billingID;
    const paymentMethod = paymentIntent.payment_method_types[0];

    if (!billingID) {
      console.error("Webhook Error: billingID missing from metadata");
      return res.status(200).send("Webhook Error: Missing billingID");
    }

    try {
      // Generate payment ID
      const newPaymentID = await generateNextPaymentID();

      // Create failed payment record
      const newPayment = {
        payID: newPaymentID,
        payStatus: "failed",
        payAmt: paymentIntent.amount / 100,
        payMethod: paymentMethod,
        payCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
        adminRemark: paymentIntent.last_payment_error?.message || "Payment failed",
        payMediaProof: "",
        providerID: "",
        billingID: billingID,
      };

      await db.collection("Payment").doc(newPaymentID).set(newPayment);

      console.log(`Successfully logged failed payment for billingID: ${billingID}`);
      return res.status(200).json({received: true});
    } catch (error) {
      console.error("Failed payment logging error:", error);
      return res.status(500).json({error: error.message});
    }
  }

  // Return 200 for other events
  return res.status(200).json({received: true});
});