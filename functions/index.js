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
const stripe = require("stripe");
const crypto = require("crypto");

// Load environment variables from .env file
require('dotenv').config();

if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;
const STRIPE_WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET;
const BILLPLZ_SECRET_KEY = process.env.BILLPLZ_SECRET_KEY;
const BILLPLZ_COLLECTION_ID = process.env.BILLPLZ_COLLECTION_ID;
const BILLPLZ_X_SIGNATURE_KEY = process.env.BILLPLZ_X_SIGNATURE_KEY;

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
      return `${prefix}${"1".padStart(padding, "0")}`;
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

// ==================== STRIPE FUNCTIONS ====================

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
    const { amount, currency = "myr", paymentMethodType, billingID } = data;

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

    const stripeClient = stripe(STRIPE_SECRET_KEY);

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

// Stripe Webhook Handler 
exports.stripeWebhook = onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];

  let event;

  try {
    const stripeClient = stripe(STRIPE_SECRET_KEY);

    event = stripeClient.webhooks.constructEvent(
      req.rawBody,
      sig,
      STRIPE_WEBHOOK_SECRET,
    );
  } catch (err) {
    console.error("Webhook signature verification failed:", err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === "payment_intent.succeeded") {
    const paymentIntent = event.data.object;
    const billingID = paymentIntent.metadata.billingID;
    const paymentMethod = paymentIntent.payment_method_types[0];

    if (!billingID) {
      console.error("Webhook Error: billingID missing from metadata");
      return res.status(200).send("Webhook Error: Missing billingID");
    }

    try {
      const existingPayment = await db.collection("Payment")
        .where("billingID", "==", billingID)
        .where("payStatus", "==", "paid")
        .limit(1)
        .get();

      if (!existingPayment.empty) {
        console.log(`Payment already exists for billingID: ${billingID}`);
        return res.status(200).json({ received: true, note: "Already processed" });
      }

      const billingDoc = await db.collection("Billing").doc(billingID).get();

      if (!billingDoc.exists) {
        throw new Error(`Billing document ${billingID} not found`);
      }

      const newPaymentID = await generateNextPaymentID();

      // Create payment document
      const newPayment = {
        payID: newPaymentID,
        payStatus: "paid",
        payAmt: paymentIntent.amount / 100,
        payMethod: "Credit Card",
        payCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
        adminRemark: "",
        payMediaProof: "",
        providerID: "",
        billingID: billingID,
      };

      const batch = db.batch();

      const paymentRef = db.collection("Payment").doc(newPaymentID);
      batch.set(paymentRef, newPayment);

      const billingRef = db.collection("Billing").doc(billingID);
      batch.update(billingRef, { billStatus: "paid" });

      await batch.commit();

      console.log(`Successfully processed payment for billingID: ${billingID}`);
      return res.status(200).json({ received: true });
    } catch (error) {
      console.error("Payment processing error:", error);
      return res.status(500).json({
        error: "Internal Server Error",
        message: error.message,
      });
    }
  } else if (event.type === "payment_intent.payment_failed") {
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

      const newPayment = {
        payID: newPaymentID,
        payStatus: "failed",
        payAmt: paymentIntent.amount / 100,
        payMethod: "Credit Card",
        payCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
        adminRemark: "",
        payMediaProof: "",
        providerID: "",
        billingID: billingID,
      };

      await db.collection("Payment").doc(newPaymentID).set(newPayment);

      console.log(`Successfully logged failed payment for billingID: ${billingID}`);
      return res.status(200).json({ received: true });
    } catch (error) {
      console.error("Failed payment logging error:", error);
      return res.status(500).json({ error: error.message });
    }
  }

  return res.status(200).json({ received: true });
});

// ==================== BILLPLZ FUNCTIONS ====================

exports.createBillplzBill = onCall(async (request) => {
  try {
    console.log("createBillplzBill called");
    const auth = request.auth;
    const data = request.data;

    if (!auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const userId = auth.uid;
    const { amount, billingID, customerEmail, customerName, description } = data;

    if (!amount || !billingID || !customerEmail || !customerName) {
      throw new HttpsError(
        "invalid-argument",
        "All fields are required",
      );
    }

    console.log("Amount received from Flutter (in cents):", amount);

    const projectId = process.env.GCLOUD_PROJECT || "handymanfyp-51049";
    const region = "us-central1";
    const callbackUrl = `https://${region}-${projectId}.cloudfunctions.net/billplzCallback`;

    console.log("GENERATED CALLBACK URL:", callbackUrl);

    const redirectUrl = `https://billplz-payment-success`;

    const billplzResponse = await fetch("https://www.billplz-sandbox.com/api/v3/bills", {
      method: "POST",
      headers: {
        "Authorization": "Basic " + Buffer.from(BILLPLZ_SECRET_KEY + ":").toString("base64"),
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        collection_id: BILLPLZ_COLLECTION_ID,
        email: customerEmail,
        name: customerName,
        amount: amount,
        callback_url: callbackUrl,
        redirect_url: redirectUrl,
        description: description || `Payment for Bill ${billingID}`,
        reference_1_label: "Billing ID",
        reference_1: billingID,
      }),
    });

    if (!billplzResponse.ok) {
      const errorText = await billplzResponse.text();
      console.error("Billplz API Error:", errorText);
      throw new HttpsError("internal", "Failed to create Billplz bill");
    }

    const billplzData = await billplzResponse.json();
    console.log("Billplz bill created:", billplzData.id);

    return {
      url: billplzData.url,
      billId: billplzData.id,
    };
  } catch (error) {
    console.error("Error creating Billplz bill:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message || "Failed to create Billplz bill");
  }
});

// Manual Payment Processing Function 
exports.processBillplzPayment = onCall(async (request) => {
  try {
    console.log("=== MANUAL BILLPLZ PAYMENT PROCESSING ===");
    const auth = request.auth;
    const data = request.data;

    if (!auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { billId, transactionId, billingID } = data;

    if (!billId || !billingID) {
      throw new HttpsError("invalid-argument", "Missing required fields");
    }

    console.log(`Processing payment for billId: ${billId}, billingID: ${billingID}`);

    // Check if payment already exists
    const existingPayment = await db.collection("Payment")
      .where("billingID", "==", billingID)
      .where("payStatus", "==", "paid")
      .limit(1)
      .get();

    if (!existingPayment.empty) {
      console.log(`Payment already processed for billingID: ${billingID}`);
      return { success: true, message: "Already processed" };
    }

    // Get billing document
    const billingDoc = await db.collection("Billing").doc(billingID).get();

    if (!billingDoc.exists) {
      throw new HttpsError("not-found", `Billing document ${billingID} not found`);
    }

    const billingData = billingDoc.data();
    const amount = billingData.billAmt;

    // Generate payment ID
    const newPaymentID = await generateNextPaymentID();

    // Create payment document
    const newPayment = {
      payID: newPaymentID,
      payStatus: "paid",
      payAmt: amount,
      payMethod: "Online Banking",
      payCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminRemark: "",
      payMediaProof: "",
      providerID: "",
      billingID: billingID,
    };

    const batch = db.batch();

    const paymentRef = db.collection("Payment").doc(newPaymentID);
    batch.set(paymentRef, newPayment);

    const billingRef = db.collection("Billing").doc(billingID);
    batch.update(billingRef, { billStatus: "paid" });

    await batch.commit();

    console.log(`Successfully processed manual payment for billingID: ${billingID}`);
    return { success: true, paymentID: newPaymentID };
  } catch (error) {
    console.error("Manual payment processing error:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message);
  }
});

// ==================== BILLPLZ WEBHOOK ====================

exports.billplzCallback = onRequest(async (req, res) => {
  console.log("=== BILLPLZ WEBHOOK RECEIVED ===");

  try {
    const incomingSignature = req.headers['x-signature'];
    const rawBody = req.rawBody.toString();

    const generatedSignature = crypto
      .createHmac('sha256', BILLPLZ_X_SIGNATURE_KEY)
      .update(rawBody)
      .digest('hex');

    if (process.env.FUNCTIONS_EMULATOR !== "true" && incomingSignature !== generatedSignature) {
      console.error("Security Alert: X-Signature mismatch.");
    }

    const data = req.body;
    const isPaid = data.paid === 'true' || data.paid === true;
    const billingID = data.reference_1;
    const transactionId = data.id;
    const amount = data.amount ? parseFloat(data.amount) / 100 : 0;

    if (!billingID) {
      console.error("Error: No Billing ID returned");
      return res.status(200).send("Missing info");
    }

    const newPaymentID = await generateNextPaymentID();

    if (isPaid) {
      const existingPayment = await db.collection("Payment")
        .where("billingID", "==", billingID)
        .where("payStatus", "==", "paid")
        .limit(1)
        .get();

      if (!existingPayment.empty) {
        console.log("Payment already recorded. Skipping.");
        return res.status(200).send("Already processed");
      }
    }

    const paymentData = {
      payID: newPaymentID,
      payStatus: isPaid ? "paid" : "failed",
      payAmt: amount,
      payMethod: "Online Banking",
      payCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminRemark: "",
      payMediaProof: "",
      providerID: transactionId,
      billingID: billingID,
    };

    const batch = db.batch();
    const paymentRef = db.collection("Payment").doc(newPaymentID);

    if (isPaid) {
      batch.set(paymentRef, paymentData);
      const billingRef = db.collection("Billing").doc(billingID);
      batch.update(billingRef, { billStatus: "paid" });
      console.log(`Processing SUCCESS for ${billingID}`);
    } else {
      batch.set(paymentRef, paymentData);
      console.log(`Processing FAILURE for ${billingID}`);
    }

    await batch.commit();
    return res.status(200).send("Webhook processed");

  } catch (error) {
    console.error("Billplz Webhook Error:", error);

    return res.status(200).send("Error handled");
  }
});

// Fail payment for billplz
exports.logBillplzPaymentFailure = onCall(async (request) => {
  console.log("=== MANUAL BILLPLZ PAYMENT FAILURE LOGGING ===");
  const auth = request.auth;
  const data = request.data;

  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { billId, transactionId, billingID } = data;

  if (!billId || !billingID) {
    throw new HttpsError("invalid-argument", "Missing required fields");
  }

  try {
    // Check if a record (paid or failed) already exists to prevent duplicates
    const existingPayment = await db.collection("Payment")
      .where("billingID", "==", billingID)
      .limit(1)
      .get();

    if (!existingPayment.empty) {
      console.log(`Payment record already processed for billingID: ${billingID}. Skipping failure log.`);
      return { success: true, message: "Already processed" };
    }

    // Get billing amount for logging
    const billingDoc = await db.collection("Billing").doc(billingID).get();

    if (!billingDoc.exists) {
      throw new HttpsError("not-found", `Billing document ${billingID} not found`);
    }

    const billingData = billingDoc.data();
    const amount = billingData.billAmt;

    const newPaymentID = await generateNextPaymentID();

    const newPayment = {
      payID: newPaymentID,
      payStatus: "failed",
      payAmt: amount,
      payMethod: "Online Banking",
      payCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminRemark: "",
      payMediaProof: "",
      providerID: "",
      billingID: billingID,
    };

    await db.collection("Payment").doc(newPaymentID).set(newPayment);

    console.log(`Successfully logged manual payment failure for billingID: ${billingID}`);
    return { success: true, paymentID: newPaymentID };
  } catch (error) {
    console.error("Manual payment failure logging error:", error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error.message);
  }
});