// M Grow AI coach server for Cloudflare Workers (free plan).
// It uses Cloudflare Workers AI, so there is NO separate AI key to keep secret.
// The free plan allows about 10,000 "neurons" a day (roughly 300 short chats).
// When the daily free amount is used up, the coach pauses until the next day
// (the app then shows built-in quick tips instead). Nothing is charged on the
// free plan.
//
// It is deployed automatically by .github/workflows/build.yml when the GitHub
// secrets CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID exist.

const MODEL = '@cf/meta/llama-3.1-8b-instruct';
const MAX_MESSAGES = 10;
const MAX_CHARS = 1000;

const LANGS = {
  en: 'English', hi: 'Hindi', bn: 'Bengali', ta: 'Tamil',
  te: 'Telugu', mr: 'Marathi', es: 'Spanish',
};

const BASE_RULES = `You are the M Grow coach, a friendly assistant inside a healthy-lifestyle app.
You help with everyday food, exercise, sleep, water, steps, posture and habit questions.

Rules:
- You are not a doctor. Never diagnose, never recommend or change medicines or supplements, never interpret lab results.
- For symptoms, injuries, pregnancy, chronic conditions or anything worrying, tell the person to see a doctor or dietitian.
- Never recommend crash diets, fasting for weight loss or for height, skipping meals, purging, laxatives, or eating below safe levels.
- Height is mostly genetic. Never promise that any exercise, food, pill, fasting or program will make someone taller. Good sleep, nutrition, sport and posture help people reach their own best height. Growth plates close after puberty.
- Respect allergies and conditions you are told about. If unsure whether a food is safe for them, say so.
- If someone mentions self-harm, suicide, an eating disorder, abuse, or feeling unsafe, respond with warmth, do not give diet or exercise advice, and encourage them to talk to a trusted adult, a doctor or a local helpline, or emergency services if in danger.
- Keep replies short (under 120 words), practical and encouraging. Use simple words. Plain text only, no markdown.
- Stay on health and fitness topics. Politely decline anything else.
- If you are not confident in the requested language, reply in simple English instead.`;

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
    const list = (a) =>
      Array.isArray(a)
        ? a.filter((x) => typeof x === 'string').slice(0, 20).map((x) => x.slice(0, 30)).join(', ')
        : '';
    s += `\n\nAbout the user (shared by them): age group ${String(p.ageGroup).slice(0, 10)}, goal ${String(p.goal).slice(0, 10)}, diet ${String(p.diet).slice(0, 12)}.`;
    if (list(p.allergies)) s += ` Allergies: ${list(p.allergies)}.`;
    if (list(p.conditions)) s += ` Conditions: ${list(p.conditions)}.`;
  }
  return s;
}

// Keep only well-formed turns, merge same-role neighbours, start and end with "user".
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
    // Opening the address in a browser shows this, so you can check it works.
    if (request.method === 'GET') return json({ ok: true, service: 'M Grow coach' });
    if (request.method !== 'POST') return json({ error: 'method' }, 405);

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

    let result;
    try {
      result = await env.AI.run(MODEL, {
        messages: [{ role: 'system', content: systemPrompt(body) }, ...messages],
        max_tokens: 350,
      });
    } catch {
      // Includes "daily free limit reached".
      return json({ error: 'ai unavailable' }, 503);
    }

    const reply = String((result && result.response) || '').trim();
    if (!reply) return json({ error: 'empty' }, 502);
    return json({ reply });
  },
};
