# Admin panel & content API

Everything on the public site — every section's text and images, projects,
journal articles, work experience, skills and media — is edited in the owner-only admin panel at
`/ChamathDilshanC`. Nothing needs a code change or a redeploy.

```text
 Browser (admin)                      api.chamathdilshan.dev                    chamathdilshan.dev
 ───────────────                      ──────────────────────                    ──────────────────
 /ChamathDilshanC  ── fetch + cookie ─► /api/admin/*  ── validate ─► Postgres
        │                                    │
        │  file upload (signed) ───────────► Cloudinary ◄── verify signed response
        │                                    │
        │                                    └── POST /api/revalidate ─────────► Next.js drops cached pages
 Visitors ─────────────────────────────────────────────────────────────────────► pages read /api/content,
                                                                                 /api/projects, … (cached)
```

---

## 1. What you can edit

| Admin page | Controls |
|---|---|
| **Sections** | 23 blocks: site settings, navigation, FAQ, footer, every home section (hero, about, selected-work heading, services, engagements/pricing, testimonials, CTA band, numbers, journal heading), **home layout** (order and visibility of home sections), and the projects / journal / about / contact pages |
| **Projects** | Case studies: thumbnail (cards), hero **image or video**, a gallery of **multiple images and videos** (drag to reorder, alt text each), story, results, tech stack, live/source links, featured + published, order |
| **Journal** | Articles: cover, date, category, sections of paragraphs with up to two images each, published |
| **Experience** | The work timeline on /about: one entry per company (name, location, website, optional logo) with every role held there (title, employment type, start and end month, summary, highlights, skills). A promotion is a new role at the same company; leave the end month empty for the current role. Companies and roles are ordered by date, newest first; hide a company with its switch |
| **Skills** | Name, category and an icon: search [theSVG](https://thesvg.org) by name (it starts from the skill's name), pick one and choose Colour, Mono, Dark or Light, or paste any image URL. The icon shows centred under the name. Toggle the home strip and the about-page grid; order |
| **Media** | Upload (drag & drop, many at once, with progress), browse, copy URL, alt text, delete (warns if the file is still used) |
| **Activity** | Every sign-in, blocked attempt and change |

Forms are generated from the API's schemas (`app/schemas/sections.py`,
`app/schemas/entities.py`). Adding a field there adds it to the editor.

---

## 2. Sign-in

1. **Continue with Google** — only `ADMIN_EMAIL` is accepted (verified email, and the
   Google `sub` too when `ADMIN_GOOGLE_SUB` is set). Any other account is refused before
   a code is sent.
2. **6-digit code** emailed through **Resend** — 10 minutes, single use, 5 attempts,
   limited resends.
3. A server-side session (HttpOnly, Secure, SameSite=Lax cookie) for 24 hours.

Details and threat model: [SECURITY.md](SECURITY.md) §4, §5, §10.

---

## 2a. Ownership — one Core Author

The project has exactly **one Core Author: `chamathdilshanc`** (the GitHub
account written `ChamathDilshanC` elsewhere in the repos — GitHub handles are
case-insensitive). There is no second Core Author, and none may be added.

- The CMS stores **no author records**. Projects, articles, sections, experience,
  skills and media have no author field, so no API call, admin form, seed run or migration
  can create another Core Author. `tests/unit/test_ownership.py` in the API
  fails if a table, write schema or seed entry ever gains an author field, and
  checks that the API rejects one with 422.
- **Signing in is a separate concept.** `chamathdilshan.dev@gmail.com` is the only
  account allowed to sign in; it is recorded only as the actor in the activity
  log and never becomes an author.
- If bylines are added later (the planned research papers list co-authors),
  they must be plain display text — never a Core Author role or account.

---

## 3. One-time setup

### Google OAuth client
1. Google Cloud Console → *APIs & Services* → *OAuth consent screen*: External, add
   your email as a test user (or publish the app).
2. *Credentials* → *Create credentials* → *OAuth client ID* → **Web application**.
3. Authorised redirect URIs:
   - `https://api.chamathdilshan.dev/api/auth/google/callback`
   - `http://localhost:8000/api/auth/google/callback` (local)
4. Copy the client ID and secret into `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`.

### Resend
1. Add and verify the sending domain (DNS records) in Resend.
2. Create an API key → `RESEND_API_KEY`.
3. `RESEND_FROM="chamathdilshan.dev <auth@chamathdilshan.dev>"` (must be on the verified domain).
4. Locally, leave `RESEND_API_KEY` empty: with `APP_ENV=development` the code is printed in the API log.

### Cloudinary
1. Dashboard → *API Keys*: copy cloud name, API key and API secret into
   `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`.
2. `CLOUDINARY_SIGNATURE_ALGORITHM` must match *Settings → Security → Signature algorithm*
   (default `sha1`).
3. Free plan limits: images 10 MB, videos 100 MB per file (enforced in the uploader).

### Database
`DATABASE_URL` — Supabase Postgres through the **session** pooler (port 5432):

```text
postgresql+asyncpg://postgres.<ref>:<password>@aws-0-<region>.pooler.supabase.com:5432/postgres
```

Then, from `api.chamathdilshan.dev/`:

```bash
alembic upgrade head          # create tables (the Docker image runs this on start)
python -m app.seed --sections # optional: load the current site content as a starting point
```

The seed file `app/seed/content.json` is generated from the frontend's
`content/*.ts` with `npm run export:seed` (run in `chamathdilshan.dev/`).

### Frontend ↔ API
| Variable | Where | Value |
|---|---|---|
| `NEXT_PUBLIC_API_URL` | frontend | `https://api.chamathdilshan.dev` |
| `CACHE_REVALIDATE_SECRET` | **both** | the same random string |
| `NEXT_APP_URL`, `ALLOWED_ORIGINS` | API | `https://chamathdilshan.dev` |
| `SESSION_SECRET` | API | `python -c "import secrets; print(secrets.token_urlsafe(48))"` |

The site and the API must share a registrable domain (`chamathdilshan.dev` /
`api.chamathdilshan.dev`) so the SameSite=Lax session cookie is sent.

---

## 4. Run locally

```bash
# API — http://localhost:8000  (SQLite, no Redis needed)
cd api.chamathdilshan.dev
cp .env.example .env            # set ADMIN_EMAIL, GOOGLE_*, CLOUDINARY_*; CACHE_ENABLED=false
alembic upgrade head && python -m app.seed --sections
uvicorn app.main:app --reload

# Site — http://localhost:3000
cd chamathdilshan.dev
echo "NEXT_PUBLIC_API_URL=http://localhost:8000" > .env.local
npm run dev
```

Open `http://localhost:3000/ChamathDilshanC`.

---

## 5. How changes reach the site

- Public pages read the API through `lib/content.ts` with Next.js cache tags
  (`content`, `projects`, `project:<slug>`, `blog`, `post:<slug>`, `skills`, `experience`).
- Every admin save invalidates Redis and calls the site's `/api/revalidate` with those
  tags, so the next visit renders fresh content. New projects and articles render on
  first visit (`dynamicParams = true`).
- If the API is unreachable **during a build or in development**, the bundled defaults
  in `content/*.ts` are used so the build never fails. **In production** the error
  propagates and Next.js keeps serving the last good page instead of placeholder content.

---

## 6. Media pipeline

1. Admin asks `POST /api/admin/media/sign` for a short-lived Cloudinary signature.
2. The browser uploads straight to Cloudinary (`/auto/upload`, with progress) — videos
   never pass through the API.
3. The browser forwards Cloudinary's response to `POST /api/admin/media`; the API checks
   Cloudinary's response signature and that the URL is this account's before saving it.
4. On the site, images go through a Cloudinary `next/image` loader
   (`f_auto,q_auto,c_limit,w_<width>` — AVIF/WebP at the exact width); videos stream with
   `q_auto,vc_auto`, play muted and looped, and pause on a first-frame poster for visitors
   who prefer reduced motion.

---

## 7. API reference

Public (cacheable, ETag):

| Method | Path | |
|---|---|---|
| GET | `/api/content` | every section, keyed by section name |
| GET | `/api/projects`, `/api/projects/{slug}` | published projects |
| GET | `/api/posts`, `/api/posts/{slug}` | published articles |
| GET | `/api/skills` | skills in order |
| GET | `/api/experience` | visible companies with their roles, most recent first |

Auth: `GET /api/auth/google/login`, `GET /api/auth/google/callback`,
`GET /api/auth/challenge`, `POST /api/auth/verify`, `POST /api/auth/resend`,
`GET /api/auth/me`, `POST /api/auth/logout`, `GET /api/auth/status`.

Admin (session + trusted Origin, never cached): `/api/admin/overview`,
`/api/admin/sections[/{key}]`, `/api/admin/projects[/{id}|/reorder]`,
`/api/admin/posts[/{id}]`, `/api/admin/skills[/{id}|/reorder]`, `/api/admin/experience[/{id}]`,
`/api/admin/media[/sign|/{id}|/{id}/usages]`, `/api/admin/schemas/{project|post|skill|experience}`,
`/api/admin/audit-logs`. Interactive docs at `/docs` outside production.
