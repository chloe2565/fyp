// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

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

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Stripe from "npm:stripe@^14";

// Initialize Stripe with the secret key from your env
const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!, {
  apiVersion: "2024-06-20",
  // Use Deno's fetch implementation
  httpClient: Stripe.createFetchHttpClient(),
});

serve(async (req: Request) => {
  try {
    const { amount, currency = 'myr', userId, paymentMethodType, billingID } = await req.json();

    if (!amount || !paymentMethodType) {
      return new Response(JSON.stringify({ error: "Amount and payment method type are required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!billingID) {
       return new Response(JSON.stringify({ error: "Billing ID is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!userId) {
       return new Response(
        JSON.stringify({ error: "User is not authenticated" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    // Create a PaymentIntent with the order amount and currency
    const amountInSen = Math.round(amount * 100);
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // Amount must be in the smallest currency unit (e.g., cents)
      currency: currency,
      payment_method_types: [paymentMethodType],
      metadata: {
        userId: userId, 
        billingID: billingID,
      },
    });

    // Send back the client secret to the app
    return new Response(
      JSON.stringify({ clientSecret: paymentIntent.client_secret }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    const error = e instanceof Error ? e.message : "An unknown error occurred";
    return new Response(JSON.stringify({ error }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/create-payment-intent' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
