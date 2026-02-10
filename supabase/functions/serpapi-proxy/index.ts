// Supabase Edge Function: SerpAPI Proxy
// Forwards requests to SerpAPI, solving CORS issues for Flutter Web.
// Deploy: supabase functions deploy serpapi-proxy --no-verify-jwt

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const engine = url.searchParams.get("engine") || "google_jobs";
    const query = url.searchParams.get("q") || "";
    const location = url.searchParams.get("location") || "India";
    const num = url.searchParams.get("num");
    const nextPageToken = url.searchParams.get("next_page_token");
    const start = url.searchParams.get("start");

    const serpApiKey = Deno.env.get("SERPAPI_KEY");
    if (!serpApiKey) {
      return new Response(
        JSON.stringify({ error: "SERPAPI_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let serpUrl = `https://serpapi.com/search.json?engine=${engine}&q=${encodeURIComponent(query)}&location=${encodeURIComponent(location)}&api_key=${serpApiKey}`;
    if (num) {
      serpUrl += `&num=${num}`;
    }
    if (nextPageToken) {
      serpUrl += `&next_page_token=${encodeURIComponent(nextPageToken)}`;
    }
    if (start) {
      serpUrl += `&start=${start}`;
    }

    const serpResponse = await fetch(serpUrl);
    const data = await serpResponse.json();

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
