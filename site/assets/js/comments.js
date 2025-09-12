(function() {
    const api = window.COMMENTS_API;
    const entry = window.COMMENTS_ENTRY;
    const listEl = document.getElementById('comments-list');
    const form = document.getElementById('comment-form');
    const nameEl = document.getElementById('comment-name');
    const textEl = document.getElementById('comment-text');

    async function load() {
        if (!api || !entry) return;

        try {
            const res = await fetch(`${api}?entry=${encodeURIComponent(entry)}`);
            const data = await res.json();
            listEl.innerHTML = '';
            if (!data.length) {
                listEl.innerHTML = '<p class="text-muted">No comments yet.</p>';
                return;
            }

            data.forEach((c) => {
                const div = document.createElement('div');
                div.className = 'mb-3';
                const name = c.name || 'Anonymous';
                div.innerHTML = `<strong>${name}</strong><br>${escapeHtml(c.comment)}<div class="text-muted small">${new Date(c.created).toLocaleString()}</div>`;
                listEl.appendChild(div);
            });
        } catch (ex) {
            console.error(ex);
        }
    }

    form?.addEventListener('submit', async (e) => {
        e.preventDefault();
        const payload = {
            entryId: entry,
            name: nameEl.value.trim(),
            comment: textEl.value.trim()
        };
        if (!payload.comment) return;

        try {
            await fetch(api, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            textEl.value = '';
            setTimeout(() => {
                load();
                console.log('Test');
            }, 10000);
        } catch (ex) {
            console.error(ex);
        }
    });

    function escapeHtml(str) {
        return str
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    load();
})();