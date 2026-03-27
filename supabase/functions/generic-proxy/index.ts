import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { url, method = 'GET', headers = {}, body } = await req.json()
    
    if (!url) {
      return new Response(JSON.stringify({ error: 'Missing target URL' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    console.log(`Proxying ${method} request to: ${url}`)

    const response = await fetch(url, {
      method,
      headers: {
        ...headers,
        // Optional: override or add specific headers
      },
      body: method !== 'GET' ? JSON.stringify(body) : undefined,
    })

    const responseData = await response.text()
    
    return new Response(responseData, {
      status: response.status,
      headers: { 
        ...corsHeaders, 
        'Content-Type': response.headers.get('Content-Type') || 'application/json' 
      },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
