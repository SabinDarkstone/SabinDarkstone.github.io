export default {
    async fetch(request, env, ctx) {
        const allowOrigin = env.ALLOWED_ORIGIN || '*';
        if (request.method === 'OPTIONS') {
            return new Response(null, {
                headers: corsHeaders(allowOrigin)
            });
        }

        if (
            new URL(request.url).pathname !== '/ama' ||
            request.method !== 'POST'
        ) {
            return json({ message: 'Not found' }, 404, allowOrigin);
        }

        let body;
        try {
            body = await request.json();
        } catch (ex) {
            return json({ message: 'Invalid JSON' }, 400, allowOrigin);
        }

        const { question, body: website, turnstileToken } = body || {};
        if (website)
            return json({ message: 'Spam detected' }, 400, allowOrigin);
        if (!question)
            return json({ message: 'Question is required' }, 400, allowOrigin);

        if (turnstileToken) {
            const valid = await verifyTurnstile(
                turnstileToken,
                request,
                env.TURNSTILE_SECRET_KEY
            );
            if (!valid)
                return json({ message: 'CAPTCHA failed' }, 400, allowOrigin);
        }

        const issueBody = question.trim();

        const ghRes = await fetch(
            `https://api.github.com/repos/${env.GH_OWNER}/${env.GH_REPO}/issues`,
            {
                method: 'POST',
                headers: {
                    Authorization: `Bearer ${env.GH_TOKEN}`,
                    Accept: 'application.vnd.github+json',
                    'User-Agent': 'question-intake-worker'
                },
                body: JSON.stringify({
                    title: 'New AMA question',
                    body: issueBody,
                    labels: undefined
                })
            }
        );

        if (!ghRes.ok) {
            const errText = await ghRes.text();
            return json(
                { message: `GitHub error: ${errText}` },
                ghRes.status,
                allowOrigin
            );
        }

        const data = await ghRes.json();
        return json({ number: data.number }, 200, allowOrigin);
    }
};

function corsHeaders(origin) {
    return {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Max-Age': '86400'
    };
}

function json(obj, status = 200, origin = '*') {
    return new Response(JSON.stringify(obj), {
        status,
        headers: {
            'Content-Type': 'application/json',
            ...corsHeaders(origin)
        }
    });
}

async function verifyTurnstile(token, request, secret) {
    try {
        const ip = request.headers.get('CF-Connecting-IP');
        const resp = await fetch(
            'https://challenges.cloudflare.com/turnstile/v0/siteverify',
            {
                method: 'POST',
                body: new URLSearchParams({
                    secret,
                    response: token,
                    remoteip: ip || ''
                })
            }
        );
        const data = await resp.json();
        return !!data.success;
    } catch (ex) {
        return false;
    }
}
