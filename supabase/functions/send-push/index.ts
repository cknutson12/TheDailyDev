import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0"

const supabaseUrl = Deno.env.get("SUPABASE_URL")!
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
const apnsKeyId = Deno.env.get("APNS_KEY_ID")!
const apnsTeamId = Deno.env.get("APNS_TEAM_ID")!
const apnsBundleId = Deno.env.get("APNS_BUNDLE_ID")!
const apnsKeyP8 = Deno.env.get("APNS_KEY_P8")!
const useSandbox = Deno.env.get("APNS_USE_SANDBOX") === "true"

let cachedJwt: { token: string; iat: number } | null = null
let cachedKey: CryptoKey | null = null

function assertConfigured() {
  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error("Supabase environment variables are missing")
  }
  if (!apnsKeyId || !apnsTeamId || !apnsBundleId || !apnsKeyP8) {
    throw new Error("APNs environment variables are missing")
  }
}

function base64UrlEncode(input: Uint8Array): string {
  const base64 = btoa(String.fromCharCode(...input))
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "")
}

function base64UrlEncodeString(value: string): string {
  return base64UrlEncode(new TextEncoder().encode(value))
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const cleaned = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "")
  const binary = atob(cleaned)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}

async function getSigningKey(): Promise<CryptoKey> {
  if (cachedKey) return cachedKey
  const keyData = pemToArrayBuffer(apnsKeyP8)
  cachedKey = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  )
  return cachedKey
}

async function getApnsJwt(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  if (cachedJwt && now - cachedJwt.iat < 50 * 60) {
    return cachedJwt.token
  }

  const header = { alg: "ES256", kid: apnsKeyId }
  const payload = { iss: apnsTeamId, iat: now }
  const headerPart = base64UrlEncodeString(JSON.stringify(header))
  const payloadPart = base64UrlEncodeString(JSON.stringify(payload))
  const data = `${headerPart}.${payloadPart}`

  const key = await getSigningKey()
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(data)
  )
  const signaturePart = base64UrlEncode(new Uint8Array(signature))
  const token = `${data}.${signaturePart}`
  cachedJwt = { token, iat: now }
  return token
}

async function sendApns(token: string, title: string, body: string) {
  const jwt = await getApnsJwt()
  const endpoint = useSandbox
    ? `https://api.sandbox.push.apple.com/3/device/${token}`
    : `https://api.push.apple.com/3/device/${token}`

  const payload = {
    aps: {
      alert: { title, body },
      sound: "default"
    }
  }

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      authorization: `bearer ${jwt}`,
      "apns-topic": apnsBundleId,
      "content-type": "application/json"
    },
    body: JSON.stringify(payload)
  })

  if (!response.ok) {
    const errorText = await response.text()
    console.error(`APNs send failed: ${response.status} ${errorText}`)
  }

  return response.ok
}

serve(async (req) => {
  try {
    assertConfigured()
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), { status: 500 })
  }

  const authHeader = req.headers.get("Authorization") || ""
  const expected = `Bearer ${serviceRoleKey}`
  if (authHeader !== expected) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 })
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 })
  }

  const { userId, title, body } = await req.json()
  if (!userId || !title || !body) {
    return new Response(JSON.stringify({ error: "Missing fields" }), { status: 400 })
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey)
  const { data: tokens, error } = await supabase
    .from("user_push_tokens")
    .select("token")
    .eq("user_id", userId)

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }), { status: 200 })
  }

  const results = await Promise.all(tokens.map((t) => sendApns(t.token, title, body)))
  const sent = results.filter(Boolean).length
  return new Response(JSON.stringify({ sent, total: tokens.length }), { status: 200 })
})
