# Caching Strategy & System

## Personal Portfolio & Publishing Platform

> Caching architecture, policies, layer responsibilities, TTLs, and invalidation
> rules for the **Chamath Dilshan Personal Portfolio & Publishing Platform**
> (Next.js 16 frontend, FastAPI backend, Supabase PostgreSQL + Storage).

This document should be read together with [Architecture.md](Architecture.md),
[TECH_STACK.md](TECH_STACK.md) and [SECURITY.md](SECURITY.md).

---

# 1. Caching Goals

The caching system exists to:

- Serve public content (portfolio, blog, research, projects) with minimal latency.
- Keep origin load (FastAPI + PostgreSQL) low and predictable under traffic spikes.
- Allow the site to survive a slow or briefly unavailable database.
- Make published content appear "instantly" while keeping stale windows short.
- Never cache private, authenticated, or owner-only data in shared caches.
- Give the admin panel a **predictable, explicit** way to flush content after edits.
- Remain simple: a modular monolith cache, not a distributed cache mesh.

## Non-Goals

- No multi-region cache replication (single primary region is assumed initially).
- No caching of the admin dashboard responses in any shared/CDN layer.
- No premature introduction of a dedicated search cache or edge KV store.

---

# 2. Caching Principles

```text
Cache public data aggressively.
Cache private data never (shared caches).
Prefer stale-while-revalidate over hard expiry.
Every cache entry has an owner, a key, and a TTL.
Every mutation has a matching, explicit invalidation.
A cache miss must always be correct; a cache hit must never be wrong for long.
The database is the single source of truth. Caches are disposable.
```

---

# 3. Cache Layer Overview

```text
                        ┌───────────────────────────┐
                        │          Visitor          │
                        │   Browser HTTP cache      │
                        └─────────────┬─────────────┘
                                      │  Cache-Control / ETag
                                      ▼
                        ┌───────────────────────────┐
                        │        CDN / Edge         │
                        │  (static assets, ISR,     │
                        │   public GET responses)   │
                        └─────────────┬─────────────┘
                                      │
                                      ▼
                        ┌───────────────────────────┐
                        │         Next.js 16        │
                        │                           │
                        │  Full Route Cache         │
                        │  Data Cache (fetch)       │
                        │  Request Memoization      │
                        │  ISR / revalidateTag      │
                        │  next/image optimizer     │
                        └─────────────┬─────────────┘
                                      │  HTTPS / REST
                                      ▼
                        ┌───────────────────────────┐
                        │          FastAPI          │
                        │                           │
                        │  In-process TTL cache     │
                        │  Redis cache-aside        │
                        │  HTTP response headers    │
                        └─────────────┬─────────────┘
                          ┌───────────┴───────────┐
                          ▼                       ▼
                ┌──────────────────┐    ┌──────────────────┐
                │      Redis       │    │  Supabase        │
                │  (shared cache,  │    │  PostgreSQL      │
                │   locks, tags)   │    │  + PgBouncer     │
                └──────────────────┘    │  + materialized  │
                                        │    views         │
                                        └──────────────────┘
```

Each layer is independent. Any layer can be disabled and the system stays correct,
only slower.

---

# 4. Layer Responsibilities

| Layer | Caches | Keyed by | Typical TTL | Invalidation |
|---|---|---|---|---|
| Browser HTTP cache | Static assets, public API GETs | URL + `Vary` | asset: 1y immutable; API: 0–60s + SWR | ETag / hashed filename |
| CDN / Edge | Static assets, ISR HTML, public GET JSON | URL + `Vary` | assets: 1y; pages: see §7 | `revalidateTag`, purge API |
| Next.js Data Cache | `fetch()` results from FastAPI | URL + options + tags | per-request `revalidate` | tag-based (`revalidateTag`) |
| Next.js Full Route Cache | Rendered RSC payload / HTML | route + params | until revalidated | `revalidatePath` / `revalidateTag` |
| Next.js Request Memo | Duplicate fetches in one render | URL + options | single request | automatic |
| FastAPI in-process | Hot small objects (settings, profile) | function + args | 30–120s | TTL only + manual clear |
| Redis (shared) | Serialized API payloads, computed aggregates | namespaced key + tags | 60s–24h (see §7) | tag sets + explicit delete |
| PostgreSQL | Query plans, `shared_buffers`, materialized views | query / view | view: manual/cron refresh | `REFRESH MATERIALIZED VIEW` |
| Cloudinary CDN | Images, videos | public_id + version | 1y immutable (versioned URLs) | new version on replace |

---

# 5. Content Classification

Every response is classified before deciding how it is cached.

```text
PUBLIC + STABLE      → profile, skills, experience, education,
                       certifications, achievements
                       → cache long, SWR, CDN OK

PUBLIC + CONTENT     → published projects, blog posts, research
                       → cache medium, tag-based invalidation, CDN OK

PUBLIC + DYNAMIC     → list endpoints with pagination/filters, search
                       → cache short, per-query key, CDN short TTL

PUBLIC + WRITE       → POST /api/contact
                       → never cached; rate limited (see SECURITY.md §20)

PRIVATE / OWNER      → everything under /api/admin/*, /ChamathDilshanC/*,
                       auth/session endpoints
                       → never cached anywhere shared; Cache-Control: no-store
```

Rule: if a response depends on a session cookie, an `Authorization` header, or
owner identity, it is `PRIVATE` and must send `Cache-Control: private, no-store`.

---

# 6. HTTP Caching Headers (FastAPI → clients & CDN)

## 6.1 Public, cacheable GET responses

```http
Cache-Control: public, s-maxage=300, stale-while-revalidate=86400, stale-if-error=604800
ETag: "sha256-<hash-of-body>"
Vary: Accept-Encoding
```

- `s-maxage` → shared caches (CDN) treat content as fresh for N seconds.
- `max-age` (browser) kept small or `0` so users re-validate via the CDN.
- `stale-while-revalidate` → serve stale instantly, refresh in the background.
- `stale-if-error` → serve stale if the origin errors (DB outage resilience).
- `ETag` → conditional `304 Not Modified` responses, cheap re-validation.

**On Vercel**, public content responses also send the same policy through
`Vercel-CDN-Cache-Control`, so the API response is served from the edge after
the first request instead of waiting for a function cold start on every visit.
The five-minute `s-maxage` is the maximum normal delay before an admin edit
appears in a new edge response; the frontend's tag revalidation still refreshes
its own Data Cache immediately.

## 6.2 Private responses

```http
Cache-Control: private, no-store, max-age=0
Vary: Cookie, Authorization
```

## 6.3 Static & versioned assets

```http
Cache-Control: public, max-age=31536000, immutable
```

Only for content-hashed filenames (Next.js build output, versioned storage paths).

## 6.4 Header helper (FastAPI)

```python
# app/core/http_cache.py
import hashlib
from fastapi import Response

PUBLIC_STABLE  = "public, s-maxage=3600, stale-while-revalidate=86400, stale-if-error=604800"
PUBLIC_CONTENT = "public, s-maxage=300,  stale-while-revalidate=86400, stale-if-error=604800"
PUBLIC_DYNAMIC = "public, s-maxage=30,   stale-while-revalidate=300,   stale-if-error=86400"
PRIVATE        = "private, no-store, max-age=0"

def apply_cache(response: Response, policy: str, body: bytes | None = None) -> None:
    response.headers["Cache-Control"] = policy
    if policy is PRIVATE:
        response.headers["Vary"] = "Cookie, Authorization"
        return
    response.headers["Vary"] = "Accept-Encoding"
    if body is not None:
        response.headers["ETag"] = 'W/"sha256-%s"' % hashlib.sha256(body).hexdigest()[:32]
```

---

# 7. TTL Matrix

Values are starting points. Tune from real hit-ratio and edit-frequency data.

| Content | Next.js `revalidate` | CDN `s-maxage` | Redis TTL | Notes |
|---|---|---|---|---|
| `/` home | 3600 | 3600 | 3600 | + tag invalidation on any featured change |
| `/about`, profile | 86400 | 3600 | 86400 | rarely changes |
| `/skills`, `/experience`, `/education` | 86400 | 3600 | 86400 | tag: `taxonomy` |
| `/certifications`, `/achievements` | 86400 | 3600 | 86400 | tag: `credentials` |
| `/projects` (list) | 3600 | 300 | 600 | tag: `projects` |
| `/projects/[slug]` | 3600 | 300 | 3600 | tag: `project:<slug>` |
| `/blog` (list) | 600 | 120 | 300 | tag: `blog` |
| `/blog/[slug]` | 3600 | 300 | 3600 | tag: `post:<slug>` |
| `/research` (list) | 3600 | 300 | 600 | tag: `research` |
| `/research/[slug]` | 3600 | 300 | 3600 | tag: `research:<slug>` |
| `/search?q=` | 60 | 30 | 120 | key includes normalized query |
| `sitemap.xml`, `rss.xml` | 3600 | 3600 | 3600 | tag: `content` (any publish) |
| OG images | build / 86400 | 31536000 | — | regenerate on slug/title change |
| `GET /api/health` | 0 | 0 | — | never cached |
| `POST /api/contact` | — | — | — | `no-store` |
| `/api/admin/*` | — | — | — | `no-store`, never in Redis-public ns |
| Dashboard stats (`/api/admin/dashboard`) | — | — | 60 (private ns) | short server-only cache, owner-scoped key |

---

# 8. Next.js 16 (App Router) Caching

## 8.1 Data Cache — tagged fetches

All server-side reads from FastAPI go through a single typed client so tags and
revalidation are consistent.

```typescript
// lib/api.ts
const API = process.env.NEXT_PUBLIC_API_URL!;

type CacheOpts = { revalidate?: number; tags?: string[] };

export async function apiGet<T>(path: string, cache: CacheOpts = {}): Promise<T> {
  const res = await fetch(`${API}${path}`, {
    next: { revalidate: cache.revalidate ?? 3600, tags: cache.tags ?? [] },
    headers: { Accept: "application/json" },
  });
  if (!res.ok) throw new Error(`API ${path} -> ${res.status}`);
  return res.json() as Promise<T>;
}
```

```typescript
// app/blog/[slug]/page.tsx
export const revalidate = 3600;

export async function generateStaticParams() {
  const posts = await apiGet<{ slug: string }[]>("/api/blog?fields=slug", {
    revalidate: 3600, tags: ["blog"],
  });
  return posts.map((p) => ({ slug: p.slug }));
}

export default async function Page({ params }: { params: { slug: string } }) {
  const post = await apiGet<Post>(`/api/blog/${params.slug}`, {
    revalidate: 3600,
    tags: ["blog", `post:${params.slug}`],
  });
  return <Article post={post} />;
}
```

## 8.2 Route segment config

```typescript
// Public content: statically render + ISR
export const dynamic = "force-static";
export const revalidate = 3600;

// Admin: never cache, always dynamic
// app/ChamathDilshanC/layout.tsx
export const dynamic = "force-dynamic";
export const fetchCache = "force-no-store";
```

## 8.3 On-demand revalidation endpoint

The FastAPI backend calls this **after every successful admin mutation**. It is
protected by a shared secret (never exposed to the browser).

Production configuration must set the same non-empty
`CACHE_REVALIDATE_SECRET` in both the FastAPI deployment and the Next.js
deployment. A `403` from this endpoint means the values do not match; the
backend logs the rejected status without logging either value. Project listing
reads bypass the Next.js data cache as a safety net, but the shared secret is
still required for immediate invalidation of other tagged content and routes.

```typescript
// app/api/revalidate/route.ts
import { revalidateTag, revalidatePath } from "next/cache";
import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  const secret = req.headers.get("x-revalidate-secret");
  if (secret !== process.env.CACHE_REVALIDATE_SECRET) {
    return NextResponse.json({ error: "forbidden" }, { status: 403 });
  }
  const { tags = [], paths = [] } = await req.json();
  // Next 16 requires a cacheLife profile as the second argument.
  // { expire: 0 } drops the entries immediately, which is what an
  // "content just changed" invalidation means.
  for (const t of tags) revalidateTag(t, { expire: 0 });
  for (const p of paths) revalidatePath(p);
  return NextResponse.json({ revalidated: true, tags, paths });
}
```

## 8.4 Client-side (admin panel) data cache

The admin UI uses **SWR** (or TanStack Query) for owner-only data. This cache is
per-browser, in-memory, never shared:

```typescript
useSWR(`/api/admin/projects`, fetcher, {
  revalidateOnFocus: true,
  dedupingInterval: 5000,
});
// After a mutation: mutate("/api/admin/projects") to refetch immediately.
```

---

# 9. FastAPI Backend Caching

## 9.1 Two tiers

```text
Tier 1  In-process TTL cache (per worker)
        - tiny, hot, rarely-changing objects: site_settings, profile
        - 30–120s TTL, lost on restart, not shared between workers
        - guards against request bursts hitting Redis/DB for the same key

Tier 2  Redis cache-aside (shared across workers / instances)
        - serialized JSON payloads for public endpoints
        - computed aggregates (dashboard counts, tag clouds, archives)
        - also hosts: stampede locks, tag → key sets, rate-limit counters
```

## 9.2 Cache-aside pattern

```python
# app/core/cache.py
import json, asyncio
from redis.asyncio import Redis

redis = Redis.from_url(settings.REDIS_URL, decode_responses=True)
NS = "pf:v1"                       # bump v1 -> v2 to invalidate everything

def key(*parts: str) -> str:
    return ":".join([NS, *parts])

async def get_or_set(cache_key: str, ttl: int, tags: list[str], loader):
    hit = await redis.get(cache_key)
    if hit is not None:
        return json.loads(hit)

    lock = key("lock", cache_key)
    got_lock = await redis.set(lock, "1", nx=True, ex=10)
    if not got_lock:                       # someone else is loading it
        for _ in range(50):
            await asyncio.sleep(0.1)
            hit = await redis.get(cache_key)
            if hit is not None:
                return json.loads(hit)

    try:
        value = await loader()
        payload = json.dumps(value, default=str)
        pipe = redis.pipeline()
        pipe.set(cache_key, payload, ex=_jitter(ttl))
        for t in tags:                     # register key under each tag
            pipe.sadd(key("tag", t), cache_key)
            pipe.expire(key("tag", t), _jitter(ttl) + 3600)
        await pipe.execute()
        return value
    finally:
        await redis.delete(lock)

def _jitter(ttl: int) -> int:
    import random
    return ttl + random.randint(0, max(1, ttl // 10))   # avoid synchronized expiry
```

## 9.3 Endpoint usage

```python
@router.get("/api/blog/{slug}")
async def get_post(slug: str, response: Response):
    data = await get_or_set(
        cache_key=key("blog", "post", slug),
        ttl=3600,
        tags=["blog", f"post:{slug}"],
        loader=lambda: blog_service.get_published_by_slug(slug),
    )
    if data is None:
        raise HTTPException(404)
    apply_cache(response, PUBLIC_CONTENT, json.dumps(data, default=str).encode())
    return data
```

## 9.4 Tag-based invalidation

```python
# app/core/cache.py
async def invalidate_tags(*tags: str) -> None:
    pipe = redis.pipeline()
    all_keys: set[str] = set()
    for t in tags:
        members = await redis.smembers(key("tag", t))
        all_keys.update(members)
        pipe.delete(key("tag", t))
    for k in all_keys:
        pipe.delete(k)
    await pipe.execute()
```

---

# 10. Invalidation Flow (the important part)

Every admin write triggers the same three-step flush. This is wired once into a
service-layer hook so no endpoint can forget it.

```text
Admin edits "building-zero-trust" blog post and clicks Publish
        │
        ▼
FastAPI: blog_service.update(id) succeeds, DB committed
        │
        ├── 1. invalidate_tags("blog", "post:building-zero-trust", "content")
        │        → deletes Redis payloads + aggregates (archives, tag cloud, rss)
        │
        ├── 2. POST {NEXT_APP_URL}/api/revalidate
        │        headers: x-revalidate-secret
        │        body: { tags: ["blog", "post:building-zero-trust", "content"],
        │                paths: ["/blog", "/blog/building-zero-trust", "/"] }
        │        → Next.js drops Data Cache + Full Route Cache entries
        │
        └── 3. (optional) CDN purge for those exact paths if not covered by ISR
                 → purge_cdn(["/blog", "/blog/building-zero-trust", "/sitemap.xml"])
        │
        ▼
Next public request → cache miss → fresh render → re-cached
```

## 10.1 Invalidation map

| Mutation | Redis tags | Next tags | Next paths |
|---|---|---|---|
| Project create/update/publish | `projects`, `project:<slug>`, `content` | same | `/projects`, `/projects/<slug>`, `/` |
| Project delete | `projects`, `project:<slug>`, `content` | same | `/projects`, `/`, `/sitemap.xml` |
| Blog publish/update | `blog`, `post:<slug>`, `content` | same | `/blog`, `/blog/<slug>`, `/`, `/rss.xml` |
| Research publish/update | `research`, `research:<slug>`, `content` | same | `/research`, `/research/<slug>` |
| Profile / about update | `profile` | `profile` | `/`, `/about` |
| Skills | `skills` | `skills` | `/`, `/about` |
| Experience (companies and roles) | `experience` | `experience` | `/about` |
| Education | `taxonomy` | `taxonomy` | `/education` |
| Certifications/achievements | `credentials` | `credentials` | `/certifications`, `/achievements` |
| Media replace | `media`, plus owning entity tag | entity tag | entity path |
| Site settings | `settings` | `settings` | `/` (and layout-wide) |

## 10.2 Rules

- Invalidation runs **only after** the DB transaction commits.
- If step 2 or 3 fails, log it and enqueue a retry — do not fail the admin request.
- Deleting content also invalidates `sitemap.xml` / `rss.xml` aggregates.
- Never invalidate by "flush all" except deliberate `NS` version bump (§13).

---

# 11. Database-Level Caching

```text
Supabase PostgreSQL
    │
    ├── Connection pooling (PgBouncer, transaction mode)
    │      → avoids connection storms behind the cache on a mass invalidation
    │
    ├── shared_buffers / OS page cache
    │      → hot rows and indexes stay in memory (managed by Supabase)
    │
    ├── Materialized views for expensive aggregates:
    │      mv_dashboard_counts        (projects, posts, research, certs totals)
    │      mv_blog_archive            (year/month post counts)
    │      mv_tag_cloud               (tag → usage count)
    │      → REFRESH CONCURRENTLY on content mutation OR every 10 min via cron
    │
    └── Indexes on every slug, status, published_at, featured column
           → keeps the cache-miss path fast enough to serve directly
```

Refresh trigger:

```python
# after a content mutation, in the same background task as invalidation
await db.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY mv_dashboard_counts")
```

A slow materialized-view refresh must never block the admin response — run it in a
background task / queue.

---

# 12. Media & Image Caching

- Files are stored in Supabase Storage under **version-pathed** keys, e.g.
  `blog/2026/zero-trust/cover-a8f1c3d9.webp`. Replacing an image writes a **new
  path** and updates the DB row — the old URL stays immutable and cacheable.
- All storage objects served with `Cache-Control: public, max-age=31536000, immutable`.
- `next/image` optimizes and caches derivatives; set
  `images.minimumCacheTTL = 2592000` and restrict `images.remotePatterns` to the
  Supabase project domain.
- Private documents (unpublished research PDFs) are served via **short-lived signed
  URLs** and must be sent with `Cache-Control: private, no-store` — never through
  the CDN.

---

# 13. Global Invalidation / Cache Versioning

For schema changes, serialization changes, or a corrupted cache:

```text
Redis:   bump namespace   NS = "pf:v1"  →  "pf:v2"     (old keys expire out)
Next.js: change deploy / build id                       (Full Route Cache reset)
CDN:     purge everything (rare, manual)
```

Namespace bump is instant, safe, and needs no key enumeration.

---

# 14. Cache Stampede & Failure Handling

| Risk | Mitigation |
|---|---|
| Thundering herd on popular key expiry | per-key Redis lock + short wait-and-retry (§9.2) |
| Synchronized expiry of many keys | TTL jitter (`_jitter()`) |
| Redis down | `get_or_set` catches connection errors → serve directly from DB, log, continue |
| Next.js revalidate endpoint down | retry queue; CDN `stale-if-error` keeps site up |
| Database down | CDN + browser `stale-if-error` (up to 7 days) serves last-known-good |
| Mass invalidation → DB spike | PgBouncer pooling + locks collapse duplicate loads |
| Cache poisoning | strict `Vary`, never cache when `Cookie`/`Authorization` present, no user input in cache keys except normalized/whitelisted params |

Fallback contract: **a cache backend being unavailable degrades performance, never
correctness or availability.**

---

# 15. What Is Never Cached

```text
Any /api/admin/* response
Any response with a Set-Cookie for a session
/api/auth/*  (github, callback, session, logout)
POST /api/contact
GET  /api/health
OAuth state / CSRF tokens
Signed URLs for private documents
Error responses (4xx/5xx) beyond stale-if-error windows
```

CDN configuration must include an explicit bypass rule for `/ChamathDilshanC/*`
and `/api/admin/*`, and must forward (not strip) the session cookie there.

---

# 16. Observability

Track and alert on:

```text
Redis hit ratio            (target > 85% for public content endpoints)
CDN hit ratio              (target > 90% for public pages/assets)
Origin request rate        (should stay flat during traffic spikes)
p95 latency: cache hit vs miss
Invalidation events        (count, tags, success/failure)
Revalidate endpoint errors
Materialized view refresh duration
Stale-if-error activations  (signals origin trouble)
```

Expose a minimal internal endpoint (owner-only) for cache stats:

```text
GET /api/admin/cache/stats   → { hit_ratio, keys, memory, top_keys }
POST /api/admin/cache/purge  → { tags: [...] }  (manual emergency flush, audit-logged)
```

Manual purges are written to `audit_logs` (see [SECURITY.md](SECURITY.md) §30).

---

# 17. Environment Variables

```env
# Redis (shared cache, locks, tag sets)
REDIS_URL=

# Cache behaviour
CACHE_NAMESPACE=pf:v1
CACHE_DEFAULT_TTL=3600
CACHE_ENABLED=true                 # set false locally to debug cache-miss paths

# Next.js on-demand revalidation (server-to-server secret)
CACHE_REVALIDATE_SECRET=
NEXT_APP_URL=https://<domain>

# CDN purge (optional, only if ISR coverage is insufficient)
CDN_PURGE_URL=
CDN_PURGE_TOKEN=
```

`CACHE_REVALIDATE_SECRET` and `CDN_PURGE_TOKEN` are secrets — server-only, never
`NEXT_PUBLIC_*`, never committed (see [GITPUSH.md](../GITPUSH.md) §14).
Configure `CACHE_REVALIDATE_SECRET` in the hosting provider's production
environment for both projects; do not copy it into source files or expose it
through build-time public variables.

---

# 18. Local Development

```text
CACHE_ENABLED=false        → bypass Redis, always hit DB (verify miss path)
Next.js dev                → Data Cache / Full Route Cache disabled by default
CDN                        → not present locally
next/image                 → optimizer still runs; clear .next/cache to reset
```

Run integration tests with `CACHE_ENABLED=true` against a disposable Redis so
invalidation wiring is actually exercised.

---

# 19. Implementation Checklist

```text
[ ] Single typed API client in Next.js with tags on every fetch
[ ] Route segment config: public = static + ISR, admin = force-dynamic + no-store
[ ] /api/revalidate route implemented and secret-protected
[ ] FastAPI http_cache helper applied to every public GET
[ ] FastAPI in-process TTL cache for settings + profile
[ ] Redis cache-aside (get_or_set) with locks + TTL jitter
[ ] Tag registry (tag -> key set) + invalidate_tags
[ ] Service-layer post-commit hook: Redis flush + Next revalidate (+ CDN purge)
[ ] Invalidation map covers every admin mutation
[ ] Materialized views for dashboard/archive/tag-cloud + background refresh
[ ] PgBouncer / Supabase pooler enabled
[ ] Supabase Storage objects version-pathed + immutable Cache-Control
[ ] next/image remotePatterns locked to Supabase domain, minimumCacheTTL set
[ ] CDN bypass rules for /ChamathDilshanC/* and /api/admin/*
[ ] no-store on auth, contact, health, admin, signed URLs
[ ] stale-while-revalidate + stale-if-error on all public responses
[ ] Redis-down fallback path tested (serve from DB)
[ ] Cache hit-ratio + invalidation metrics wired to observability
[ ] Owner-only cache stats + manual purge endpoint (audit-logged)
[ ] CACHE_* env vars in .env.example with placeholder values
```

---

# 20. Summary

```text
Browser      → short max-age + ETag, long immutable assets
CDN / Edge   → public GETs & ISR HTML, s-maxage + SWR + stale-if-error
Next.js      → tagged Data Cache + Full Route Cache, on-demand revalidateTag
FastAPI      → in-process hot cache + Redis cache-aside with stampede locks
Redis        → shared payloads, computed aggregates, tag sets, locks
PostgreSQL   → pooling + materialized views for expensive aggregates
Storage      → immutable version-pathed media via CDN

Source of truth : Supabase PostgreSQL
Cache posture   : aggressive for public, none for private, always explicit invalidation
Failure posture : cache down = slower, never wrong, never offline
```
