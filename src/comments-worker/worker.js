export default {
    async fetch(request, env) {
        const allowOrigin = env.ALLOWED_ORIGIN || '*';

        console.log(request);

        if (request.method === 'OPTIONS') {
            return new Response(null, { headers: corsHeaders(allowOrigin) });
        }

        const url = new URL(request.url);
        const segments = url.pathname.split("/");

        if (url.pathname !==('/comments')) {
            return json({ message: 'Not found' }, 404, allowOrigin);
        }

        if (request.method === 'GET') {
            const entry = url.searchParams.get('entry');
            if (!entry) {
                return json({ message: 'Entry required' }, 400, allowOrigin);
            }
            const list = await env.COMMENTS.list({ prefix: `${entry}:` });
            const comments = await Promise.all(
                list.keys.map(async (key) => {
                    const data = await env.COMMENTS.get(key.name);
                    return JSON.parse(data);
                })
            );
            comments.sort((a, b) => new Date(a.created) - new Date(b.created));
            return json(comments, 200, allowOrigin);
        }

        if (request.method === 'POST') {
            let body;
            try {
                body = await request.json();
            } catch (ex) {
                return json({ message: 'Invalid JSON' }, 400, allowOrigin);
            }

            const { entryId, comment, name } = body || {};
            if (!entryId || !comment) {
                return json({ message: 'Entry ID and comment are required' }, 400, allowOrigin);
            }

            const data = {
                entryId,
                comment: comment.trim(),
                name: name ? name.trim() : 'Anonymous',
                created: new Date().toISOString()
            };

            const key = `${entryId}:${Date.now()}-${Math.random().toString(36).slice(2)}`;
            await env.COMMENTS.put(key, JSON.stringify(data));
            return json(data, 201, allowOrigin);
        }

        return json({ message: 'Method not allowed' }, 405, allowOrigin);
    }
};

function corsHeaders(origin) {
    return {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
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