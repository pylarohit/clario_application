// Supabase Edge Function: YouTube Proxy
// Forwards requests to YouTube Data API, solving CORS issues for Flutter Web.
// Deploy: supabase functions deploy youtube-proxy --no-verify-jwt

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
    const query = url.searchParams.get("q") || "";
    const pageToken = url.searchParams.get("pageToken") || "";
    const maxResults = url.searchParams.get("maxResults") || "20";

    const youtubeApiKey = Deno.env.get("NEXT_PUBLIC_YOUTUBE_API_KEY");
    if (!youtubeApiKey) {
      return new Response(
        JSON.stringify({ error: "NEXT_PUBLIC_YOUTUBE_API_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let youtubeUrl = `https://www.googleapis.com/youtube/v3/search?part=snippet&q=${encodeURIComponent(query)}&type=video&maxResults=${maxResults}&order=relevance&key=${youtubeApiKey}`;
    if (pageToken) {
      youtubeUrl += `&pageToken=${encodeURIComponent(pageToken)}`;
    }

    const response = await fetch(youtubeUrl);
    const data = await response.json();

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
