const params = new URLSearchParams(location.search);
const qEl = document.getElementById('q');
if (params.get('q')) {
    qEl.value = params.get('q');
}

function go(evt) {
    if (evt) {
        evt.preventDefault();
    }
    runSearch(qEl.value.trim());
}

qEl.addEventListener('input', debounce(() => runSearch(qEl.value.trim()), 100));

let idx, documents = [];

async function init() {
    const res = await fetch('/assets/search.json', { cache: 'no-cache'});
    documents = await res.json();

    idx = lunr(function() {
        this.ref('id');
        this.field('title', { boost: 5 });
        this.field('tags', { boost: 3 });
        this.field('summary', { boost: 2 });
        this.field('body');

        this.metadataWhitelist = ['position'];

        documents.forEach(doc => {
            this.add(doc);
        });
    });

    if (qEl.value.trim()) {
        runSearch(qEl.value.trim());
    }
    qEl.focus();
}

function runSearch(query) {
    const list = document.getElementById('results');
    const meta = document.getElementById('meta');
    list.innerHTML = '';
    if (!query) {
        meta.textContent = '';
        return;
    }


    const results = idx.search(sanitize(query));
    meta.textContent = results.length + ' result' + (results.length === 1 ? '' : 's');

    results.slice(0, 50).forEach(r => {
        const doc = documents.find(d => d.id === r.ref);
        list.appendChild(renderItem(doc, r, query));
    });
}

function renderItem(doc, result, query) {
    const a = document.createElement('a');
    a.href = doc.url;
    a.className = 'list-group-item list-group-item-action py-3';

    const snippetHtml = safeHighlight(makeSnippet(doc, result), query);

    a.innerHTML = `
        <div class="d-flex w-100 justify-content-between">
        <h5 class="mb-1">${escapeHTML(doc.title)}</h5>
        ${doc.date ? `<small class="text-muted">${new Date(doc.date).toLocaleDateString()}</small>` : ''}
        </div>
        ${doc.tags.length ? `<div class="mb-1">${doc.tags.map(t => `<span class="badge text-bg-light me-1">${escapeHTML(t)}</span>`).join('')}</div>` : ''}
        <p class="mb-1">${snippetHtml}</p>
    `;
    return a;
}

function makeSnippet(doc, result) {
    const body = (doc.body || '').trim();
    if (!result || !result.matchData) {
        return fallbackSummary(doc);
    }

    const md = result.matchData;
    let bodyPositions = [];
    Object.values(md.metadata).forEach(fieldMap => {
        if (fieldMap.body && Array.isArray(fieldMap.body.position)) {
            bodyPositions = bodyPositions.concat(fieldMap.body.position);
        }
    });

    if (body && bodyPositions.length) {
        bodyPositions.sort((a, b) => a[0] - b[0]);
        const [start, len] = bodyPositions[0];

        const WINDOW_BEFORE = 120;
        const WINDOW_AFTER = 120;

        const from = Math.max(0, start - WINDOW_BEFORE);
        const to = Math.min(body.length, start + len + WINDOW_AFTER);

        let snip = body.slice(from, to).replace(/\s+/g, ' ').trim();
        if (from > 0) {
            snip = '... ' + snip;
        }
        if (to < body.length) {
            snip = snip + ' ...';
        }
        
        return snip;
    }

    return fallbackSummary(doc);
}

function fallbackSummary(doc) {
    const s = (doc.summary || doc.description || '').trim();
    if (!s) return '';
    return s.length > 240 ? s.slice(0, 240) + '...' : s;
}

function safeHighlight(text, query) {
    try {
        return highlight(text, query);
    } catch (err) {
        return escapeHTML(text);
    }
}

function highlight(text, query) {
    const terms = query.split(/\s+/).filter(Boolean).map(t => escapeRegExp(t));
    if (!terms.length) {
        return escapeHTML(text);
    }

    const re = new RegExp('(' + terms.join('|') + ')', 'ig');
    return escapeHTML(text).replace(re, '<mark>$1</mark>');
}

function sanitize(q){ return q.replace(/[^\p{L}\p{N}\s\-_'"]/gu, ''); }
function escapeHTML(s){ return s.replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m])); }
function escapeRegExp(s){ return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

function debounce(fn, ms) {
    let t;
    return (...a) => {
        clearTimeout(t);
        t = setTimeout(() => fn(...a), ms);
    }
}

window.addEventListener('keydown', e => {
    if (e.key === '/' && document.activeElement !== qEl) {
        e.preventDefault();
        qEl.focus();
    }
    if (e.key === 'Escape') {
        qEl.blur();
    }
});

init();