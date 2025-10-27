// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "npm:stripe@^14";

import { initializeApp, cert, getApps, App } from "firebase-admin/app";
import { getFirestore, Firestore, Timestamp, Transaction } from "firebase-admin/firestore";
console.log("Attempting Firebase Admin modular imports...");

// --- 1. INITIALIZE STRIPE ---
const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});

// --- 2. INITIALIZE FIREBASE ADMIN ---
let db: Firestore;
let firebaseApp: App;

try {
  console.log("Attempting to parse FIREBASE_SERVICE_ACCOUNT_JSON...");
  const serviceAccountString = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!serviceAccountString) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON secret is not set.");
  }
  const serviceAccount = JSON.parse(serviceAccountString);
  console.log("Service Account JSON parsed successfully.");

  // Check if Firebase Admin SDK needs initialization using getApps()
  if (getApps().length === 0) {
    console.log("Initializing Firebase Admin SDK...");
    firebaseApp = initializeApp({
      credential: cert(serviceAccount),
    });
    console.log("Firebase Admin SDK initialized.");
  } else {
    firebaseApp = getApps()[0]; // Get existing app instance
    console.log(`Firebase Admin SDK already initialized. Using existing app.`);
  }

  // Get Firestore instance from the app
  db = getFirestore(firebaseApp);
  console.log("Firestore instance obtained.");

} catch (initError) {
   console.error("CRITICAL ERROR during Firebase Admin initialization:", initError);
}

async function generateNextPaymentID(
  transaction: Transaction
): Promise<string> {
  if (!db) {
    throw new Error("Firestore instance (db) is not available for generateNextPaymentID");
  }

  const prefix = 'PY';
  const padding = 4;
  const paymentCollection = db.collection('Payment');

  // Query for the last ID, ordered by 'payID'
  const lastPaymentQuery = paymentCollection
    .where('payID', '>=', prefix)
    .where('payID', '<', prefix + 'Z')
    .orderBy('payID', 'desc')
    .limit(1);

  // Get the documents *within the transaction*
  const snapshot = await transaction.get(lastPaymentQuery);

  if (snapshot.empty) {
    return `${prefix}${'1'.padLeft(padding, '0')}`; // PY0001
  }

  const lastID = snapshot.docs[0].data().payID as string;

  try {
    const numericPart = lastID.substring(prefix.length);
    const lastNumber = parseInt(numericPart, 10);
    const nextNumber = lastNumber + 1;
    return `${prefix}${nextNumber.toString().padLeft(padding, '0')}`;
  } catch (e) {
    console.error(`Error parsing last payID '${lastID}':`, e);
    // Fallback in case of parsing error
    return `${prefix}${'1'.padLeft(padding, '0')}`;
  }
}

// --- 3. SERVE THE WEBHOOK FUNCTION ---
serve(async (req: Request) => {
  if (!db) {
    console.error("Firestore instance (db) is not available. Aborting webhook processing.");
    return new Response("Internal Server Error: Firestore not initialized", { status: 500 });
  }

  console.log("Stripe webhook function invoked!");
  const signature = req.headers.get("Stripe-Signature");
  const body = await req.text();
  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;
  let event: Stripe.Event;

  // --- 4. VERIFY THE EVENT CAME FROM STRIPE ---
  try {
    console.log("Attempting to verify webhook signature...");
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature!,
      webhookSecret,
      undefined,
      Stripe.createSubtleCryptoProvider()
    );
    console.log(`Webhook signature verified. Event type: ${event.type}`);
  } catch (err) {
    console.error(`Webhook signature verification failed: ${err.message}`);
    return new Response(err.message, { status: 400 });
  }

  // --- 5. HANDLE THE "payment_intent.succeeded" EVENT ---
  if (event.type === "payment_intent.succeeded") {
    console.log("Handling payment_intent.succeeded...");
    const paymentIntent = event.data.object as Stripe.PaymentIntent;
    const billingID = paymentIntent.metadata.billingID;
    const paymentMethod = paymentIntent.payment_method_types[0];

    if (!billingID) {
      console.error("Webhook Error: billingID was missing from metadata.");
      return new Response("Webhook Error: Missing billingID", { status: 200 });
    }

    try {
      // --- 5. RUN THE DATABASE UPDATE AS A TRANSACTION ---
      await db.runTransaction(async (transaction) => {
        // a. Generate the new custom payment ID
        const newPaymentID = await generateNextPaymentID(transaction);

        // b. Get the providerID from the billing document
        const billingRef = db.collection("Billing").doc(billingID);
        const billingDoc = await transaction.get(billingRef);
        if (!billingDoc.exists) {
          throw new Error(`Billing doc ${billingID} not found.`);
        }
        const providerID = billingDoc.data()?.providerID ?? "";

        // c. Create the new Payment document using the new ID
        const newPaymentRef = db.collection("Payment").doc(newPaymentID);
        const newPayment = {
          payID: newPaymentID,
          payStatus: "paid",
          payAmt: paymentIntent.amount / 100, // Convert from cents
          payMethod: paymentMethod,
          payCreatedAt: Timestamp.now(),
          adminRemark: "Paid via Stripe",
          payMediaProof: "",
          providerID: providerID,
          billingID: billingID,
        };
        
        // d. Add the new payment and update the bill *atomically*
        transaction.set(newPaymentRef, newPayment);
        transaction.update(billingRef, { 'billStatus': 'paid' });
      });
      console.log(`Successfully processed payment for billingID: ${billingID}`);
    } catch (error) {
      console.error("Firestore transaction failed:", error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }
  } else if (event.type === "payment_intent.payment_failed") {
    console.log("Handling payment_intent.payment_failed...");
    const paymentIntent = event.data.object as Stripe.PaymentIntent;
    const billingID = paymentIntent.metadata.billingID;
    const paymentMethod = paymentIntent.payment_method_types[0];

    if (!billingID) {
      console.error("Webhook Error: billingID was missing from metadata.");
      return new Response("Webhook Error: Missing billingID", { status: 200 });
    }

    try {
      await db.runTransaction(async (transaction) => {
        const newPaymentID = await generateNextPaymentID(transaction);
        const billingRef = db.collection("Billing").doc(billingID);
        const billingDoc = await transaction.get(billingRef);

        if (!billingDoc.exists) throw new Error(`Billing doc ${billingID} not found.`);

        const providerID = billingDoc.data()?.providerID ?? "";
        const newPaymentRef = db.collection("Payment").doc(newPaymentID);

        const newPayment = {
          payID: newPaymentID,
          payStatus: "failed", // Set status to "failed"
          payAmt: paymentIntent.amount / 100,
          payMethod: paymentMethod,
          payCreatedAt: Timestamp.now(),
          adminRemark: paymentIntent.last_payment_error?.message ?? "Payment failed",
          payMediaProof: "",
          providerID: providerID,
          billingID: billingID,
        };

        transaction.set(newPaymentRef, newPayment);
      });
      console.log(`Successfully logged failed payment for billingID: ${billingID}`);
    } catch (error) {
      console.error("Firestore transaction failed (for failed payment):", error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }
  } else {
    console.log(`Unhandled event type: ${event.type}`);
  }

  // Return a 200 OK to Stripe
  console.log("Webhook processing complete. Returning 200 OK.");
  return new Response(JSON.stringify({ received: true }), { status: 200 });
});

// console.log("Hello from Functions!")

// Deno.serve(async (req) => {
//   const { name } = await req.json()
//   const data = {
//     message: `Hello ${name}!`,
//   }

//   return new Response(
//     JSON.stringify(data),
//     { headers: { "Content-Type": "application/json" } },
//   )
// })

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/stripe-webhook' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
