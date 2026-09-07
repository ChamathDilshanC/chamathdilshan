# ChamathDilshanC — Technology Stack

> Production technology stack and system architecture for the ChamathDilshanC personal professional platform.

---

# 1. Architecture Overview

```text
                         ┌──────────────────────┐
                         │       Visitors       │
                         └──────────┬───────────┘
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │      Next.js         │
                         │      Frontend        │
                         │      App Router      │
                         └──────────┬───────────┘
                                    │
                               HTTPS / REST
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │       FastAPI        │
                         │       Backend       │
                         └──────────┬───────────┘
                                    │
                         ┌──────────┴──────────┐
                         │                     │
                         ▼                     ▼
                 ┌──────────────┐      ┌──────────────┐
                 │   Supabase   │      │   External   │
                 │  PostgreSQL  │      │   Services   │
                 └──────────────┘      └──────────────┘
                         │
                         ▼
                 ┌──────────────┐
                 │   Supabase   │
                 │    Storage   │
                 └──────────────┘
```

---

# 2. Core Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| Frontend | Next.js 16+ | Public website + Admin UI |
| UI | React | Component-based interface |
| Language | TypeScript | Frontend type safety |
| Styling | Tailwind CSS | UI styling |
| Backend | FastAPI | REST API + business logic |
| Backend Language | Python | Backend development |
| Validation | Pydantic | Request/response validation |
| Database | Supabase PostgreSQL | Primary application database |
| Storage | Supabase Storage | Images, PDFs, documents |
| Authentication | GitHub OAuth | Admin authentication |
| API Documentation | OpenAPI / Swagger | API documentation |
| Version Control | Git + GitHub | Source control |
| CI/CD | GitHub Actions | Automated testing and deployment |
| Containerization | Docker | Runtime consistency |

---

# 3. Frontend

## Technology

The frontend will use:

- Next.js 16+
- React
- TypeScript
- App Router
- Tailwind CSS
- ESLint
- Prettier

## Responsibilities

The frontend handles:

- Public professional profile
- Projects
- Blog
- Research
- Experience
- Education
- Certifications
- Achievements
- Skills
- Contact
- Resume
- Search
- Admin dashboard
- Content management interface

---

# 4. Public Website Routes

```text
/
├── /about
├── /projects
│   └── /projects/[slug]
├── /blog
│   └── /blog/[slug]
├── /research
│   └── /research/[slug]
├── /experience
├── /education
├── /certifications
├── /achievements
├── /skills
├── /contact
├── /resume
└── /search
```

---

# 5. Admin Panel

The administrative interface will be available under:

```text
/ChamathDilshanC
```

## Admin Routes

```text
/ChamathDilshanC
├── /login
├── /callback
├── /dashboard
├── /projects
├── /blog
├── /research
├── /experience
├── /education
├── /certifications
├── /achievements
├── /skills
├── /media
├── /messages
├── /audit-logs
└── /settings
```

The admin panel is not a separate application unless future scaling requires it.

It should initially remain part of the main Next.js application.

---

# 6. Backend

## Technology

```text
FastAPI
Python
Pydantic
SQLAlchemy
HTTPX
Supabase Client
```

## Responsibilities

The FastAPI backend is responsible for:

- REST API
- Business logic
- Authentication verification
- Authorization
- Database operations
- Content management
- File management
- Input validation
- Rate limiting
- Security
- Audit logging
- External service integrations

---

# 7. API Architecture

## Public API

```text
/api
├── /health
├── /auth
├── /projects
├── /blog
├── /research
├── /experience
├── /education
├── /certifications
├── /achievements
├── /skills
├── /search
├── /contact
└── /resume
```

## Protected Admin API

```text
/api/admin
├── /dashboard
├── /projects
├── /blog
├── /research
├── /experience
├── /education
├── /certifications
├── /achievements
├── /skills
├── /media
├── /messages
├── /audit-logs
└── /settings
```

All `/api/admin/*` endpoints must perform server-side authorization.

---

# 8. Primary Database — Supabase

Supabase PostgreSQL is the **primary source of truth** for the entire application.

All important structured application data should be stored in PostgreSQL.

## Main Tables

```text
PostgreSQL
│
├── users
├── admin_users
├── profiles
├── projects
├── project_tags
├── blog_posts
├── blog_categories
├── research
├── research_tags
├── experience
├── education
├── certifications
├── achievements
├── skills
├── skill_categories
├── media
├── contact_messages
├── audit_logs
└── site_settings
```

## Source of Truth

```text
Supabase PostgreSQL
        │
        └── PRIMARY SOURCE OF TRUTH
```

The application must not depend on an external search database for core data storage.

---

# 9. Supabase Storage

Supabase Storage will be used for portfolio media and documents.

```text
Storage
│
├── profile/
├── projects/
├── blog/
├── research/
├── certifications/
├── achievements/
├── resume/
└── documents/
```

## Supported Content

Examples:

- Profile images
- Project screenshots
- Project thumbnails
- Blog images
- Research PDFs
- Certificates
- Resume PDF
- Portfolio documents

Private files must not be exposed through unrestricted public URLs.

---

# 10. Backup Strategy

Supabase PostgreSQL remains the primary database.

The backup strategy should be based on the database itself rather than treating an external service as a database backup.

```text
                  Supabase PostgreSQL
                          │
             ┌────────────┼────────────┐
             │            │            │
             ▼            ▼            ▼
        Managed       Point-in-Time   Manual
        Backups        Recovery       Export
```

## Backup Principles

- Database backups must be enabled.
- Important production data must be recoverable.
- Database migrations must be version controlled.
- Production database changes must be traceable.
- Critical data should have an independent recovery strategy.
- Backups must never be stored inside the Git repository.
- Recovery procedures should be documented and tested.

---

# 11. Database Design Principle

The application follows:

> **PostgreSQL is the single source of truth.**

Therefore:

```text
Next.js
   │
   ▼
FastAPI
   │
   ▼
Supabase PostgreSQL
   │
   ├── Projects
   ├── Blog
   ├── Research
   ├── Experience
   ├── Education
   ├── Certifications
   ├── Achievements
   ├── Skills
   └── Settings
```

This keeps the architecture simple and reliable.

---

# 12. Authentication

Admin authentication will use GitHub OAuth.

```text
User
 │
 ▼
/ChamathDilshanC/login
 │
 ▼
GitHub OAuth
 │
 ▼
GitHub Identity
 │
 ▼
FastAPI OAuth Callback
 │
 ▼
Verify GitHub Account
 │
 ▼
Create Secure Session
 │
 ▼
Admin Dashboard
```

Only the authorized GitHub account should be able to access the administration system.

---

# 13. GitHub Owner Verification

Authorization should use the GitHub account's immutable numeric user ID.

Example environment variables:

```env
GITHUB_OWNER_ID=
GITHUB_OWNER_USERNAME=ChamathDilshanC
```

The GitHub numeric user ID is preferred over username-only authorization because usernames can potentially change.

---

# 14. Security Architecture

```text
Internet
   │
   ▼
HTTPS
   │
   ▼
Next.js
   │
   ▼
FastAPI
   │
   ├── Authentication
   ├── Authorization
   ├── Input Validation
   ├── Rate Limiting
   ├── CORS
   ├── CSRF Protection
   ├── Security Headers
   ├── Audit Logging
   └── Error Handling
          │
          ▼
     Supabase
          │
          ▼
      PostgreSQL
```

---

# 15. Security Requirements

The system must implement:

- HTTPS
- Secure cookies
- HttpOnly cookies
- SameSite protection
- OAuth state validation
- Server-side authorization
- Input validation
- Output validation
- SQL injection protection
- XSS protection
- CSRF protection
- CORS restrictions
- Rate limiting
- Security headers
- File upload validation
- Path traversal protection
- Secret management
- Audit logging

---

# 16. Environment Variables

Example:

```env
# Frontend
NEXT_PUBLIC_SITE_URL=
NEXT_PUBLIC_API_URL=

# GitHub OAuth
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
GITHUB_OWNER_ID=
GITHUB_OWNER_USERNAME=ChamathDilshanC

# Supabase
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
SUPABASE_DB_URL=

# Security
SESSION_SECRET=
```

Never commit:

```text
.env
.env.local
.env.production
```

or any credentials/API keys.

---

# 17. Repository Structure

Recommended monorepo:

```text
ChamathDilshanC/
│
├── apps/
│   │
│   ├── web/
│   │   ├── app/
│   │   ├── components/
│   │   ├── features/
│   │   ├── lib/
│   │   ├── hooks/
│   │   ├── public/
│   │   └── styles/
│   │
│   └── api/
│       ├── app/
│       │   ├── api/
│       │   ├── core/
│       │   ├── models/
│       │   ├── schemas/
│       │   ├── services/
│       │   ├── repositories/
│       │   ├── integrations/
│       │   ├── security/
│       │   └── main.py
│       │
│       └── tests/
│
├── packages/
│   ├── shared-types/
│   ├── ui/
│   └── config/
│
├── database/
│   ├── migrations/
│   ├── seed/
│   └── schema/
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── SECURITY.md
│   ├── API.md
│   ├── DATABASE.md
│   ├── CMS.md
│   └── DEPLOYMENT.md
│
├── scripts/
│
├── .github/
│   └── workflows/
│
├── .gitignore
├── README.md
├── CHANGELOG.md
├── LICENSE
└── TECH_STACK.md
```

---

# 18. CMS / Content Management

The admin panel functions as the project's CMS.

## Content Modules

```text
CMS
│
├── Projects
├── Blog
├── Research
├── Experience
├── Education
├── Certifications
├── Achievements
├── Skills
├── Media
└── Site Settings
```

Each module should support appropriate operations such as:

```text
Create
Read
Update
Delete
Publish
Unpublish
Draft
Archive
```

---

# 19. Content Workflow

Recommended publishing workflow:

```text
Admin
  │
  ▼
Create Content
  │
  ▼
Draft
  │
  ▼
Edit / Review
  │
  ▼
Publish
  │
  ▼
Public Website
```

For sensitive or important content, the system can later support:

```text
Draft
  ↓
Review
  ↓
Approved
  ↓
Published
```

---

# 20. Search

Search should initially be implemented using PostgreSQL capabilities.

Potential search targets:

```text
Projects
Blog Posts
Research
Experience
Skills
Education
Certifications
Achievements
```

The search architecture should remain modular so that a dedicated search engine can be introduced later if the platform grows.

---

# 21. SEO

Next.js will handle the primary SEO layer.

The system should support:

- Dynamic metadata
- Open Graph metadata
- Twitter/X metadata
- Canonical URLs
- Sitemap
- Robots.txt
- Structured data
- Article metadata
- Project metadata
- Research metadata

Important public content should be server-rendered or statically generated where appropriate.

---

# 22. Performance

Performance priorities:

```text
Fast Initial Load
        │
        ▼
Server Rendering
        │
        ▼
Optimized Images
        │
        ▼
Caching
        │
        ▼
Minimal Client JavaScript
```

The frontend should avoid unnecessary client-side rendering.

Client Components should only be used when interactive browser-side behavior is required.

---

# 23. CI/CD

GitHub Actions will be responsible for automated validation.

```text
Git Push
   │
   ▼
GitHub Actions
   │
   ├── Install Dependencies
   ├── Lint
   ├── Type Check
   ├── Unit Tests
   ├── Integration Tests
   ├── Security Checks
   └── Build
          │
          ▼
       Deploy
```

Production deployments must only occur after required checks pass.

---

# 24. Docker

Docker may be used for the FastAPI backend.

Example:

```text
Docker
│
└── FastAPI
    ├── Python
    ├── Dependencies
    └── Application
```

The Next.js application may also be containerized when the deployment environment benefits from it.

---

# 25. Observability

The platform should maintain basic observability.

Recommended areas:

- Application logs
- API errors
- Authentication failures
- Admin activity
- Database errors
- Deployment status
- Health checks

Health endpoint:

```text
GET /api/health
```

Example response:

```json
{
  "status": "ok"
}
```

---

# 26. Audit Logging

Administrative actions should be logged.

Example:

```text
audit_logs
├── id
├── admin_user_id
├── action
├── resource_type
├── resource_id
├── metadata
├── ip_address
├── user_agent
└── created_at
```

Examples:

```text
CREATE_PROJECT
UPDATE_PROJECT
DELETE_PROJECT
PUBLISH_BLOG
DELETE_RESEARCH
UPDATE_PROFILE
LOGIN
LOGOUT
```

---

# 27. Development Philosophy

The platform should be:

- Modular
- Secure
- Scalable
- Type-safe
- API-first
- SEO-friendly
- Accessible
- Testable
- Maintainable
- Production-ready

The initial architecture should remain a **modular monolith** rather than unnecessarily introducing microservices.

```text
Next.js
   +
FastAPI
   +
Supabase
```

This provides a clean separation between presentation, application logic, and data.

---

# 28. Final Architecture

```text
                    ┌───────────────────────┐
                    │       Visitors        │
                    └───────────┬───────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │       Next.js         │
                    │                       │
                    │ Public Website        │
                    │ Admin Panel           │
                    │ SEO                   │
                    │ UI                    │
                    └───────────┬───────────┘
                                │
                              HTTPS
                                │
                                ▼
                    ┌───────────────────────┐
                    │       FastAPI         │
                    │                       │
                    │ REST API              │
                    │ Business Logic        │
                    │ Authentication        │
                    │ Authorization         │
                    │ Validation            │
                    │ Security              │
                    └───────────┬───────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ▼                       ▼
          ┌──────────────────┐    ┌──────────────────┐
          │     Supabase     │    │     Supabase     │
          │   PostgreSQL     │    │     Storage      │
          │                  │    │                  │
          │ Primary Data     │    │ Media/Documents  │
          └──────────────────┘    └──────────────────┘
```

---

# 29. Technology Summary

```text
Frontend
└── Next.js 16+
    ├── React
    ├── TypeScript
    ├── App Router
    └── Tailwind CSS

Backend
└── FastAPI
    ├── Python
    ├── Pydantic
    ├── REST API
    └── Business Logic

Database
└── Supabase
    └── PostgreSQL

Storage
└── Supabase Storage

Authentication
└── GitHub OAuth

DevOps
├── Git
├── GitHub
├── GitHub Actions
└── Docker

Security
├── OAuth
├── Secure Sessions
├── Authorization
├── Rate Limiting
├── Validation
├── Security Headers
└── Audit Logs
```

---

# 30. Core Architecture Rule

The system follows three primary responsibilities:

**Next.js → Presentation**

**FastAPI → Application & Business Logic**

**Supabase → Data & Storage**

The architecture should remain simple, secure, and maintainable while allowing future expansion without requiring a complete rewrite.