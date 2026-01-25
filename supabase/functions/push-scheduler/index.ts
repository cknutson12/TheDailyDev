import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0"

const supabaseUrl = Deno.env.get("SUPABASE_URL")!
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!

const morningTitle = "Answer today’s question"
const morningBody = "Keep your streak going with today’s system design prompt."
const eveningTitle = "Don’t forget today’s question"
const eveningBody = "If you haven’t answered yet, take 5 minutes and stay sharp."
const fridayTitle = "Free Friday question is live"
const fridayBody = "Your free question is available today. Jump in and stay sharp."

const windowMinutes = 30

function assertConfigured() {
  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error("Supabase environment variables are missing")
  }
}

function getLocalParts(date: Date, timeZone: string) {
  const formatter = new Intl.DateTimeFormat("en-US", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false
  })
  const parts = formatter.formatToParts(date)
  const lookup = Object.fromEntries(parts.map((p) => [p.type, p.value]))
  return {
    year: lookup.year,
    month: lookup.month,
    day: lookup.day,
    weekday: lookup.weekday,
    hour: Number(lookup.hour),
    minute: Number(lookup.minute)
  }
}

function localDateString(parts: { year: string; month: string; day: string }) {
  return `${parts.year}-${parts.month}-${parts.day}`
}

function withinWindow(hour: number, minute: number, targetHour: number, targetMinute: number) {
  const total = hour * 60 + minute
  const target = targetHour * 60 + targetMinute
  return Math.abs(total - target) <= windowMinutes
}

async function sendPush(userId: string, title: string, body: string) {
  const response = await fetch(`${supabaseUrl}/functions/v1/send-push`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${serviceRoleKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ userId, title, body })
  })
  return response.ok
}

serve(async (req) => {
  try {
    assertConfigured()
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), { status: 500 })
  }

  const url = new URL(req.url)
  const type = url.searchParams.get("type") ?? "morning"
  const targetHour = type === "evening" ? 19 : 7
  const targetMinute = 30

  const supabase = createClient(supabaseUrl, serviceRoleKey)

  const { data: users, error } = await supabase
    .from("user_subscriptions")
    .select("user_id, timezone, status, entitlement_status")
    .not("timezone", "is", null)

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  const now = new Date()
  let sentCount = 0

  for (const user of users ?? []) {
    const timeZone = user.timezone
    if (!timeZone) continue

    const parts = getLocalParts(now, timeZone)
    if (!withinWindow(parts.hour, parts.minute, targetHour, targetMinute)) continue

    const localDate = localDateString(parts)
    const { data: existing } = await supabase
      .from("user_push_delivery_log")
      .select("id")
      .eq("user_id", user.user_id)
      .eq("notification_type", type)
      .eq("local_date", localDate)
      .limit(1)

    if (existing && existing.length > 0) continue

    if (type === "friday") {
      const isFriday = parts.weekday?.toLowerCase().startsWith("fri")
      if (!isFriday) continue

      const status = (user.status ?? "").toLowerCase()
      const entitlement = (user.entitlement_status ?? "").toLowerCase()
      const hasActiveStatus = ["active", "trialing", "past_due", "paused"].includes(status)
      const hasActiveEntitlement = entitlement ? ["active", "billing_issue", "paused"].includes(entitlement) : hasActiveStatus
      if (hasActiveStatus && hasActiveEntitlement) continue
    }

    if (type === "evening") {
      const { data: answered } = await supabase.rpc("has_answered_today", {
        p_user_id: user.user_id,
        p_tz: timeZone
      })
      if (answered === true) continue
    }

    const title = type === "evening" ? eveningTitle : type === "friday" ? fridayTitle : morningTitle
    const body = type === "evening" ? eveningBody : type === "friday" ? fridayBody : morningBody

    const ok = await sendPush(user.user_id, title, body)
    if (!ok) continue

    await supabase.from("user_push_delivery_log").insert({
      user_id: user.user_id,
      notification_type: type,
      local_date: localDate
    })

    sentCount += 1
  }

  return new Response(JSON.stringify({ sent: sentCount, type }), { status: 200 })
})
