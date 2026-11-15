// M Grow AI coach proxy for Cloudflare Workers (free plan is enough to start).
// The AI key lives ONLY here, never inside the app.
//
// Setup:
//   1. npm create cloudflare@latest  (choose "Hello World" Worker), paste this file as src/index.js
//   2. npx wrangler secret put ANTHROPIC_API_KEY
//   3. npx wrangler secret put APP_TOKEN        (same value as Config.appToken in the app)
//   4. Optional rate limit: create a KV namespace, bind it as RATE in wrangler.toml
//   5. npx wrangler deploy, then put the worker URL in lib/config.dart (aiEndpoint)
//
// The AI provider charges per message, so also set a monthly spending limit
// in the provider's dashboard.

const MODEL = 'claude-haiku-5-5';
const MAX_MESSAGES = 12;
const MAX_CHARS = 1000;
const DAILY_LIMIT_PER_IP = 40; // used only if the RATE KV binding exists

const LANGS = {
  en: 'English', hi: 'Hindi', bn: 'Bengali', ta: 'Tamil',
  te: 'Telugu', mr: 'Marathi', es: 'Spanish',
};

const BASE_RULES = `You are the M Grow coach, a friendly assistant inside a healthy-lifestyle app.
You help with everyday food, exercise, sleep, water, steps and habit questions.

Rules:
- You are not a doctor. Never diagnose, never recommend or change medicines or supplements, never interpret lab results.
- For symptoms, injuries, pregnancy, chronic conditions or anything worrying, tell the person to see a doctor or dietitian.
- Never recommend crash diets, fasting for weight loss, skipping meals, purging, laxatives, or eating below safe levels.
- Respect allergies and conditions you are told about. If unsure whether a food is safe for them, say so.
- If someone mentions self-harm, suicide, an eating disorder, abuse, or feeling unsafe, respond with warmth, do not give diet or exercise advice, and encourage them to talk to a trusted adult, a doctor or a local helpline, or emergency services if in danger.
- Keep replies short (under 150 words), practical and encouraging. Use simple words. Plain text, no markdown tables.
- Stay on health and fitness topics. Politely decline anything else.`;

const MINOR_RULES = `The user is a teenager (13 to 17).
- Never give weight-loss advice, calorie targets, calorie counting, or diet restriction advice.
- Focus on balanced meals, sleep, play, sport, hydration and feeling good.
- For body image worries, be kind and suggest talking to a parent, school counselor or doctor.`;

function systemPrompt(body) {
  const lang = LANGS[body.lang] || 'English';
  let s = BASE_RULES + `\n\nReply in ${lang}.`;
  if (body.minor === true) s += '\n\n' + MINOR_RULES;
  const p = body.profile;
  if (p && typeof p === 'object') {
    const clean = (a) => (Array.isArray(a) ? a.filter((x) => typeof x === 'string').slice(0, 20).join(', ') : '');
    s += `\n\nAbout the user (shared by them): age group ${String(p.ageGroup).slice(0, 10)}, goal ${String(p.goal).slice(0, 10)}, diet ${String(p.diet).slice(0, 12)}.`;
    if (clean(p.allergies)) s += ` Allergies: ${clean(p.allergies)}.`;
    if (clean(p.conditions)) s += ` Conditions: ${clean(p.conditions)}.`;
  }
  return s;
}

// Keep only well-formed turns, merge same-role neighbours, start with "user".
function cleanMessages(raw) {
  if (!Array.isArray(raw)) return null;
  const out = [];
  for (const m of raw.slice(-MAX_MESSAGES)) {
    if (!m || (m.role !== 'user' && m.role !== 'assistant')) continue;
    if (typeof m.content !== 'string' || !m.content.trim()) continue;
    const content = m.content.slice(0, MAX_CHARS);
    const last = out[out.length - 1];
    if (last && last.role === m.role) last.content += '\n' + content;
    else out.push({ role: m.role, content });
  }
  while (out.length && out[0].role !== 'user') out.shift();
  if (!out.length || out[out.length - 1].role !== 'user') return null;
  return out;
}

const json = (obj, status = 200) =>
  new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') return json({ error: 'method' }, 405);
    if (request.headers.get('x-app-token') !== env.APP_TOKEN) {
      return json({ error: 'unauthorized' }, 401);
    }

    const len = Number(request.headers.get('content-length') || 0);
    if (len > 20000) return json({ error: 'too large' }, 413);

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'bad json' }, 400);
    }

    const messages = cleanMessages(body.messages);
    if (!messages) return json({ error: 'bad messages' }, 400);

    // Optional per-IP daily limit (needs a KV namespace bound as RATE).
    if (env.RATE) {
      const ip = request.headers.get('cf-connecting-ip') || 'x';
      const key = `r:${ip}:${new Date().toISOString().slice(0, 10)}`;
      const n = Number((await env.RATE.get(key)) || 0);
      if (n >= DAILY_LIMIT_PER_IP) return json({ error: 'rate limit' }, 429);
      await env.RATE.put(key, String(n + 1), { expirationTtl: 90000 });
    }

    let res;
    try {
      res = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-api-key': env.ANTHROPIC_API_KEY,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: MODEL,
          max_tokens: 400,
          system: systemPrompt(body),
          messages,
        }),
      });
    } catch {
      return json({ error: 'upstream' }, 502);
    }
    if (!res.ok) return json({ error: 'upstream' }, 502);

    const data = await res.json();
    const reply = (data.content || [])
      .filter((b) => b.type === 'text')
      .map((b) => b.text)
      .join('')
      .trim();
    if (!reply) return json({ error: 'empty' }, 502);
    return json({ reply });
  },
};
