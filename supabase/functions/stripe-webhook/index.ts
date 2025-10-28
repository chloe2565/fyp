// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "npm:stripe@^14";

// --- 1. INITIALIZE STRIPE ---
const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
  httpClient: Stripe.createFetchHttpClient(),
});

// --- 2. FIREBASE CONFIGURATION ---
const serviceAccountString = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
if (!serviceAccountString) {
  throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is required");
}
const serviceAccount = JSON.parse(serviceAccountString);
const FIREBASE_PROJECT_ID = serviceAccount.project_id;

// Cache for access token
let cachedAccessToken: string | null = null;
let tokenExpiry: number = 0;

// Get Firebase access token using service account
async function getAccessToken(): Promise<string> {
  // Return cached token if still valid
  if (cachedAccessToken && Date.now() < tokenExpiry) {
    return cachedAccessToken;
  }

  // Create JWT
  const header = { alg: "RS256", typ: "JWT" };
  const now = Math.floor(Date.now() / 1000);
  const expiry = now + 3600; // 1 hour
  
  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: expiry,
    scope: "https://www.googleapis.com/auth/datastore"
  };

  // Encode header and payload
  const encoder = new TextEncoder();
  const headerBase64 = btoa(String.fromCharCode(...encoder.encode(JSON.stringify(header))))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
  const payloadBase64 = btoa(String.fromCharCode(...encoder.encode(JSON.stringify(payload))))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
  
  const unsignedToken = `${headerBase64}.${payloadBase64}`;
  
  // Sign with private key
  const privateKey = serviceAccount.private_key;
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  
  // Extract the base64 content between header and footer
  const pemContents = privateKey
    .replace(pemHeader, '')
    .replace(pemFooter, '')
    .replace(/\n/g, '')
    .replace(/\r/g, '')
    .replace(/\s/g, '')
    .trim();
  
  // Decode base64 to binary
  const binaryDerString = atob(pemContents);
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }
  
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );
  
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(unsignedToken)
  );
  
  const signatureArray = new Uint8Array(signature);
  let signatureBinary = '';
  for (let i = 0; i < signatureArray.length; i++) {
    signatureBinary += String.fromCharCode(signatureArray[i]);
  }
  const signatureBase64 = btoa(signatureBinary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
  
  const jwt = `${unsignedToken}.${signatureBase64}`;
  
  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`
  });
  
  const tokenData = await tokenResponse.json();
  
  if (!tokenData.access_token) {
    console.error("Token error:", tokenData);
    throw new Error("Failed to get access token: " + JSON.stringify(tokenData));
  }
  
  cachedAccessToken = tokenData.access_token;
  tokenExpiry = Date.now() + (tokenData.expires_in * 1000) - 60000; // Refresh 1 min before expiry
  
  return cachedAccessToken;
}

interface FirestoreDocument {
  fields: {
    [key: string]: {
      stringValue?: string;
      integerValue?: string;
      doubleValue?: number;
      timestampValue?: string;
      booleanValue?: boolean;
    };
  };
}

// Helper function to convert Firestore REST API response to readable object
function firestoreDocToObject(doc: FirestoreDocument): any {
  const obj: any = {};
  for (const [key, value] of Object.entries(doc.fields)) {
    if (value.stringValue !== undefined) obj[key] = value.stringValue;
    else if (value.integerValue !== undefined) obj[key] = parseInt(value.integerValue);
    else if (value.doubleValue !== undefined) obj[key] = value.doubleValue;
    else if (value.timestampValue !== undefined) obj[key] = value.timestampValue;
    else if (value.booleanValue !== undefined) obj[key] = value.booleanValue;
  }
  return obj;
}

// Helper function to convert object to Firestore REST API format
function objectToFirestoreDoc(obj: any): FirestoreDocument {
  const fields: any = {};
  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === "string") {
      fields[key] = { stringValue: value };
    } else if (typeof value === "number") {
      if (Number.isInteger(value)) {
        fields[key] = { integerValue: value.toString() };
      } else {
        fields[key] = { doubleValue: value };
      }
    } else if (typeof value === "boolean") {
      fields[key] = { booleanValue: value };
    } else if (value instanceof Date) {
      fields[key] = { timestampValue: value.toISOString() };
    }
  }
  return { fields };
}

async function generateNextPaymentID(): Promise<string> {
  const prefix = 'PY';
  const padding = 4;

  try {
    const token = await getAccessToken();
    const queryUrl = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents:runQuery`;
    
    const response = await fetch(queryUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        structuredQuery: {
          from: [{ collectionId: 'Payment' }],
          where: {
            compositeFilter: {
              op: 'AND',
              filters: [
                {
                  fieldFilter: {
                    field: { fieldPath: 'payID' },
                    op: 'GREATER_THAN_OR_EQUAL',
                    value: { stringValue: prefix }
                  }
                },
                {
                  fieldFilter: {
                    field: { fieldPath: 'payID' },
                    op: 'LESS_THAN',
                    value: { stringValue: prefix + 'Z' }
                  }
                }
              ]
            }
          },
          orderBy: [{ field: { fieldPath: 'payID' }, direction: 'DESCENDING' }],
          limit: 1
        }
      })
    });

    const data = await response.json();
    
    if (!data[0]?.document) {
      return `${prefix}${'1'.padStart(padding, '0')}`; // PY0001
    }

    const lastDoc = firestoreDocToObject(data[0].document);
    const lastID = lastDoc.payID;
    const numericPart = lastID.substring(prefix.length);
    const lastNumber = parseInt(numericPart, 10);
    const nextNumber = lastNumber + 1;
    return `${prefix}${nextNumber.toString().padStart(padding, '0')}`;
    
  } catch (e) {
    console.error(`Error generating payment ID:`, e);
    return `${prefix}${'1'.padStart(padding, '0')}`;
  }
}

// Store processed webhook IDs to prevent duplicate processing
const processedWebhooks = new Set<string>();

// --- 3. SERVE THE WEBHOOK FUNCTION ---
serve(async (req: Request) => {
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
    console.log(`Webhook signature verified. Event type: ${event.type}, Event ID: ${event.id}`);
  } catch (err) {
    console.error(`Webhook signature verification failed: ${err.message}`);
    return new Response(err.message, { status: 400 });
  }

  // --- IDEMPOTENCY CHECK: Prevent duplicate processing ---
  if (processedWebhooks.has(event.id)) {
    console.log(`Event ${event.id} already processed. Returning 200 OK.`);
    return new Response(JSON.stringify({ received: true, note: "Already processed" }), { status: 200 });
  }

  // --- 5. HANDLE THE "payment_intent.succeeded" EVENT ---
  if (event.type === "payment_intent.succeeded") {
    console.log("Handling payment_intent.succeeded...");
    const paymentIntent = event.data.object as Stripe.PaymentIntent;
    const billingID = paymentIntent.metadata.billingID;
    const paymentMethod = paymentIntent.payment_method_types[0];

    if (!billingID) {
      console.error("Webhook Error: billingID was missing from metadata.");
      processedWebhooks.add(event.id);
      return new Response("Webhook Error: Missing billingID", { status: 200 });
    }

    try {
      console.log(`Processing payment for billingID: ${billingID}`);
      const token = await getAccessToken();
      
      // Check if payment already exists for this billing ID
      const checkUrl = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents:runQuery`;
      const checkResponse = await fetch(checkUrl, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          structuredQuery: {
            from: [{ collectionId: 'Payment' }],
            where: {
              compositeFilter: {
                op: 'AND',
                filters: [
                  {
                    fieldFilter: {
                      field: { fieldPath: 'billingID' },
                      op: 'EQUAL',
                      value: { stringValue: billingID }
                    }
                  },
                  {
                    fieldFilter: {
                      field: { fieldPath: 'payStatus' },
                      op: 'EQUAL',
                      value: { stringValue: 'paid' }
                    }
                  }
                ]
              }
            },
            limit: 1
          }
        })
      });

      const checkData = await checkResponse.json();
      if (checkData[0]?.document) {
        console.log(`Payment already exists for billingID: ${billingID}. Skipping.`);
        processedWebhooks.add(event.id);
        return new Response(JSON.stringify({ received: true, note: "Payment already recorded" }), { status: 200 });
      }

      // Generate new payment ID
      const newPaymentID = await generateNextPaymentID();
      console.log(`Generated Payment ID: ${newPaymentID}`);

      // Get billing document
      const billingUrl = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/Billing/${billingID}`;
      const billingResponse = await fetch(billingUrl, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      if (!billingResponse.ok) {
        const errorText = await billingResponse.text();
        console.error(`Billing fetch error: ${errorText}`);
        throw new Error(`Billing document ${billingID} not found`);
      }

      const billingDoc = await billingResponse.json();
      const billingData = firestoreDocToObject(billingDoc);
      const providerID = billingData.providerID || "";
      console.log(`Retrieved providerID: ${providerID}`);

      // Create new payment document
      const newPayment = {
        payID: newPaymentID,
        payStatus: "paid",
        payAmt: paymentIntent.amount / 100,
        payMethod: paymentMethod,
        payCreatedAt: new Date(),
        adminRemark: "Paid via Stripe",
        payMediaProof: "",
        providerID: providerID,
        billingID: billingID,
      };

      const paymentUrl = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/Payment?documentId=${newPaymentID}`;
      const createPaymentResponse = await fetch(paymentUrl, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(objectToFirestoreDoc(newPayment))
      });

      if (!createPaymentResponse.ok) {
        const errorText = await createPaymentResponse.text();
        console.error(`Payment creation error: ${errorText}`);
        throw new Error(`Failed to create payment document`);
      }

      console.log(`Payment document created: ${newPaymentID}`);

      // Update billing status
      const updateBillingUrl = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/Billing/${billingID}?updateMask.fieldPaths=billStatus`;
      const updateResponse = await fetch(updateBillingUrl, {
        method: 'PATCH',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          fields: {
            billStatus: { stringValue: 'paid' }
          }
        })
      });

      if (!updateResponse.ok) {
        const errorText = await updateResponse.text();
        console.error(`Billing update error: ${errorText}`);
        throw new Error(`Failed to update billing status`);
      }

      console.log(`Successfully processed payment for billingID: ${billingID}`);
      processedWebhooks.add(event.id);
      
    } catch (error) {
      console.error("Payment processing failed:", error);
      return new Response(JSON.stringify({
          message: "Internal Server Error during payment processing.",
          error: error instanceof Error ? error.message : String(error), 
      }), { status: 500 });
    }
  } else if (event.type === "payment_intent.payment_failed") {
    console.log("Handling payment_intent.payment_failed...");
    const paymentIntent = event.data.object as Stripe.PaymentIntent;
    const billingID = paymentIntent.metadata.billingID;
    const paymentMethod = paymentIntent.payment_method_types[0];

    if (!billingID) {
      console.error("Webhook Error: billingID was missing from metadata.");
      processedWebhooks.add(event.id);
      return new Response("Webhook Error: Missing billingID", { status: 200 });
    }

    try {
      const token = await getAccessToken();
      
      // Generate new payment ID
      const newPaymentID = await generateNextPaymentID();

      // Get billing document for providerID
      const billingUrl = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/Billing/${billingID}`;
      const billingResponse = await fetch(billingUrl, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      
      const billingDoc = await billingResponse.json();
      const billingData = firestoreDocToObject(billingDoc);
      const providerID = billingData.providerID || "";

      // Create failed payment record
      const newPayment = {
        payID: newPaymentID,
        payStatus: "failed",
        payAmt: paymentIntent.amount / 100,
        payMethod: paymentMethod,
        payCreatedAt: new Date(),
        adminRemark: paymentIntent.last_payment_error?.message ?? "Payment failed",
        payMediaProof: "",
        providerID: providerID,
        billingID: billingID,
      };

      const paymentUrl = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents/Payment?documentId=${newPaymentID}`;
      await fetch(paymentUrl, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(objectToFirestoreDoc(newPayment))
      });

      console.log(`Successfully logged failed payment for billingID: ${billingID}`);
      processedWebhooks.add(event.id);
      
    } catch (error) {
      console.error("Failed payment logging error:", error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }
  } else {
    console.log(`Unhandled event type: ${event.type}`);
    processedWebhooks.add(event.id);
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
