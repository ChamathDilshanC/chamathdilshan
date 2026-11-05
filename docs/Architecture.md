# Personal Portfolio Platform — System Architecture

**Project:** Chamath Dilshan Personal Portfolio
**GitHub:** `ChamathDilshanC`
**Architecture Version:** 1.0
**Status:** Planned

> **Update (Nov 2026):** the admin panel is implemented. Sign-in uses Google
> OpenID Connect plus a one-time code emailed through Resend (not GitHub OAuth),
> and media is stored on Cloudinary (not Supabase Storage). See
> [ADMIN_CMS.md](ADMIN_CMS.md) and [SECURITY.md](SECURITY.md) §4–§5. Sections of
> this document that mention GitHub OAuth describe the original plan.

---

## 1. Overview

This project is a modern, production-ready personal portfolio platform designed to serve as a centralized digital identity for **Chamath Dilshan**.

The platform will not be limited to a traditional portfolio. It will also function as a personal publishing platform for:

* Professional profile
* Projects
* Technical skills
* Experience
* Education
* Certifications
* Achievements
* Blog articles
* Technical research
* Research papers / publications
* Technical notes
* Project case studies
* Media and screenshots
* Contact information

The platform will also contain a **private administration panel** that allows the owner to manage portfolio content without modifying the frontend code manually.

---

# 2. Core Goals

The system should provide:

1. A professional public portfolio.
2. A content management system for personal content.
3. Blog publishing capabilities.
4. Research and publication management.
5. Project management.
6. Media management.
7. Secure owner-only administration.
8. GitHub-only authentication.
9. API-based communication between frontend and backend.
10. SEO-friendly public pages.
11. Scalable architecture for future features.
12. Clean separation between public and private functionality.

---

# 3. High-Level Architecture

```text
                         ┌──────────────────────────┐
                         │        Internet           │
                         └────────────┬─────────────┘
                                      │
                                      ▼
                         ┌──────────────────────────┐
                         │       Custom Domain       │
                         │                          │
                         │  /                       │
                         │  /projects               │
                         │  /blog                   │
                         │  /research                │
                         │  /about                  │
                         │  /contact                │
                         │                          │
                         │  /ChamathDilshanC        │
                         └────────────┬─────────────┘
                                      │
                     ┌────────────────┴────────────────┐
                     │                                 │
                     ▼                                 ▼
          ┌──────────────────────┐          ┌──────────────────────┐
          │    Public Frontend   │          │    Admin Frontend    │
          │                      │          │                      │
          │ Portfolio            │          │ Dashboard            │
          │ Projects             │          │ Blog Management      │
          │ Blog                │          │ Research Management   │
          │ Research             │          │ Project Management    │
          │ Experience           │          │ Media Management      │
          │ Certifications       │          │ Site Settings         │
          └──────────┬───────────┘          └──────────┬───────────┘
                     │                                 │
                     └────────────────┬────────────────┘
                                      │
                                      ▼
                         ┌──────────────────────────┐
                         │        API Layer         │
                         │                          │
                         │ Authentication           │
                         │ Portfolio API             │
                         │ Blog API                  │
                         │ Research API               │
                         │ Project API                │
                         │ Media API                  │
                         └────────────┬─────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
             ┌───────────┐     ┌────────────┐    ┌────────────┐
             │ Database  │     │   Storage  │    │ GitHub     │
             │           │     │            │    │ OAuth      │
             │ PostgreSQL│     │ Images     │    │            │
             │           │     │ Documents  │    │ Owner Only │
             └───────────┘     └────────────┘    └────────────┘
```

---

# 4. Application Areas

The system is divided into two major areas.

## 4.1 Public Application

The public application contains content that visitors can access without authentication.

### Public routes

```text
/
├── /about
├── /projects
├── /projects/:slug
├── /blog
├── /blog/:slug
├── /research
├── /research/:slug
├── /experience
├── /education
├── /certifications
├── /achievements
├── /skills
├── /contact
└── /resume
```

---

# 5. Private Administration Application

The administration system is completely separated from the public content interface.

The administrator route will be:

```text
/ChamathDilshanC
```

Example:

```text
https://your-domain.com/ChamathDilshanC
```

This route must not provide access merely because a visitor knows the URL.

Authentication and authorization are mandatory.

---

# 6. Admin Authentication

## Authentication Provider

The administration panel will use **GitHub OAuth**.

No username/password authentication should be implemented for the administrator.

### Authentication flow

```text
User
 │
 │ Visit /ChamathDilshanC
 ▼
Admin Login Page
 │
 │ "Continue with GitHub"
 ▼
GitHub OAuth
 │
 │ Authorization
 ▼
GitHub Callback
 │
 ▼
Backend
 │
 │ Validate GitHub identity
 ▼
Check GitHub User ID
 │
 ├── Authorized ───────► Create Session
 │
 └── Unauthorized ─────► Access Denied
                              │
                              ▼
                         403 Forbidden
```

---

# 7. GitHub Owner Verification

The system must use an **allowlist-based authorization model**.

The GitHub account allowed to access the administration system is:

```text
GitHub Username:
ChamathDilshanC
```

The backend should preferably validate the **GitHub numeric user ID** rather than relying only on the username.

Example configuration:

```env
GITHUB_OWNER_ID=<github-user-id>
GITHUB_OWNER_USERNAME=ChamathDilshanC
```

The GitHub username is useful for display and secondary validation, while the immutable GitHub user ID should be the primary authorization identifier.

---

# 8. Authorization Rules

Only the configured GitHub owner can access administrative resources.

```text
Authenticated + Owner ID matches
        │
        └──► ADMIN ACCESS

Authenticated + Owner ID does not match
        │
        └──► 403 FORBIDDEN

Not authenticated
        │
        └──► 401 / Redirect to Login
```

There should be no public registration system.

There should be no admin password reset system.

There should be no email/password admin login.

There should be no "create account" functionality.

---

# 9. Admin Route Structure

Recommended admin route structure:

```text
/ChamathDilshanC
│
├── /login
├── /callback
├── /dashboard
│
├── /projects
│   ├── /new
│   ├── /:id
│   └── /:id/edit
│
├── /blog
│   ├── /new
│   ├── /:id
│   └── /:id/edit
│
├── /research
│   ├── /new
│   ├── /:id
│   └── /:id/edit
│
├── /experience
├── /education
├── /certifications
├── /achievements
├── /skills
│
├── /media
│
├── /messages
│
└── /settings
```

---

# 10. Admin Dashboard

The dashboard should provide a centralized overview.

Example:

```text
┌─────────────────────────────────────────────┐
│              ADMIN DASHBOARD                │
├─────────────────────────────────────────────┤
│                                             │
│ Projects             12                     │
│ Published Articles   18                     │
│ Research Papers       5                     │
│ Certifications       21                     │
│                                             │
├─────────────────────────────────────────────┤
│ Recent Activity                             │
│                                             │
│ • Published new article                     │
│ • Updated AegisZero project                 │
│ • Added AWS certification                   │
│                                             │
└─────────────────────────────────────────────┘
```

---

# 11. Content Management

The admin panel should allow the owner to manage all major portfolio entities.

## Projects

Each project can contain:

```text
Project
├── Title
├── Slug
├── Short Description
├── Full Description
├── Problem
├── Solution
├── Features
├── Technologies
├── Architecture
├── Screenshots
├── GitHub Repository
├── Live Demo
├── Start Date
├── End Date
├── Status
├── Featured
└── Published
```

---

# 12. Blog System

The blog system should support technical and professional articles.

### Blog entity

```text
BlogPost
├── Title
├── Slug
├── Excerpt
├── Content
├── Cover Image
├── Author
├── Tags
├── Category
├── Reading Time
├── Published Date
├── Updated Date
├── Draft / Published
├── Featured
└── SEO Metadata
```

Recommended categories:

```text
Technology
Programming
Cloud
DevOps
Cybersecurity
AI
Web Development
Software Engineering
Career
Tutorials
Personal
```

---

# 13. Research System

Research should be treated as a separate content type rather than a normal blog post.

### Research entity

```text
Research
├── Title
├── Slug
├── Abstract
├── Content
├── Authors
├── Keywords
├── Research Area
├── Publication Date
├── Status
├── PDF
├── DOI
├── External Links
├── References
├── Images
└── SEO Metadata
```

Possible research statuses:

```text
Draft
In Progress
Under Review
Published
Archived
```

---

# 14. Research Areas

Research can be categorized by technical domain.

Example:

```text
Artificial Intelligence
Cybersecurity
Cloud Computing
Distributed Systems
Software Engineering
Identity & Access Management
Zero Trust Security
DevOps
Web Technologies
```

---

# 15. Portfolio Content Model

The platform should maintain a structured content hierarchy.

```text
Personal Profile
│
├── About
├── Skills
├── Experience
├── Education
├── Certifications
├── Achievements
│
├── Projects
│
├── Blog
│
├── Research
│
└── Media
```

---

# 16. Database Architecture

A relational database such as PostgreSQL is recommended.

### Core tables

```text
users
admin_sessions

profile
skills
experiences
education
certifications
achievements

projects
project_technologies
project_images

blog_posts
blog_categories
blog_tags
blog_post_tags

research
research_authors
research_references

media
contact_messages

site_settings
audit_logs
```

---

# 17. Database Relationship Overview

```text
                    ┌─────────────┐
                    │   Profile   │
                    └─────────────┘

                          │

        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
   Experiences       Education       Certifications


                    ┌─────────────┐
                    │   Project   │
                    └──────┬──────┘
                           │
               ┌───────────┴───────────┐
               ▼                       ▼
        Technologies               Images


                    ┌─────────────┐
                    │  Blog Post  │
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    ▼             ▼
                  Tags        Categories


                    ┌─────────────┐
                    │  Research   │
                    └──────┬──────┘
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
          Authors      References       PDF
```

---

# 18. API Architecture

The frontend must communicate with the backend through a structured API.

Recommended API namespace:

```text
/api
```

## Public API

```text
GET    /api/profile
GET    /api/projects
GET    /api/projects/:slug

GET    /api/blog
GET    /api/blog/:slug

GET    /api/research
GET    /api/research/:slug

GET    /api/skills
GET    /api/experience
GET    /api/education
GET    /api/certifications
GET    /api/achievements

POST   /api/contact
```

---

# 19. Admin API

All admin API endpoints must require authentication and owner authorization.

```text
/api/admin
```

### Projects

```text
GET      /api/admin/projects
POST     /api/admin/projects
GET      /api/admin/projects/:id
PATCH    /api/admin/projects/:id
DELETE   /api/admin/projects/:id
```

### Blog

```text
GET      /api/admin/blog
POST     /api/admin/blog
GET      /api/admin/blog/:id
PATCH    /api/admin/blog/:id
DELETE   /api/admin/blog/:id
```

### Research

```text
GET      /api/admin/research
POST     /api/admin/research
GET      /api/admin/research/:id
PATCH    /api/admin/research/:id
DELETE   /api/admin/research/:id
```

### Media

```text
GET      /api/admin/media
POST     /api/admin/media
DELETE   /api/admin/media/:id
```

---

# 20. Authentication API

```text
GET  /api/auth/github
GET  /api/auth/github/callback

GET  /api/auth/session

POST /api/auth/logout
```

Authentication flow:

```text
GET /api/auth/github
        │
        ▼
GitHub OAuth
        │
        ▼
GET /api/auth/github/callback
        │
        ▼
Validate GitHub account
        │
        ▼
Check owner ID
        │
        ▼
Create secure session
        │
        ▼
Redirect /ChamathDilshanC/dashboard
```

---

# 21. Session Security

The admin authentication session should use secure server-side authentication.

Recommended cookie configuration:

```text
HttpOnly
Secure
SameSite=Lax or Strict
Short/controlled expiration
```

Never store administrator access tokens in:

```text
localStorage
sessionStorage
URL parameters
public frontend state
```

GitHub OAuth client secrets must exist only on the backend/server environment.

---

# 22. Admin API Protection

Every `/api/admin/*` endpoint must execute an authorization check.

Example middleware:

```text
Request
  │
  ▼
Session Validation
  │
  ├── Invalid ──► 401
  │
  ▼
GitHub Owner Verification
  │
  ├── Not Owner ──► 403
  │
  ▼
Admin Controller
  │
  ▼
Database Operation
```

The frontend hiding an admin button is **not** considered security.

Authorization must always be enforced server-side.

---

# 23. Admin Security Model

Security layers:

```text
Layer 1
HTTPS

Layer 2
GitHub OAuth

Layer 3
GitHub Owner ID verification

Layer 4
Secure session

Layer 5
Admin API middleware

Layer 6
Database authorization

Layer 7
Input validation

Layer 8
Rate limiting

Layer 9
Audit logging
```

---

# 24. Audit Logging

Administrative actions should be recorded.

Example:

```text
AuditLog
├── ID
├── User ID
├── Action
├── Resource Type
├── Resource ID
├── IP Hash / Metadata
├── User Agent
└── Created At
```

Example actions:

```text
LOGIN
LOGOUT
CREATE_PROJECT
UPDATE_PROJECT
DELETE_PROJECT

CREATE_BLOG
PUBLISH_BLOG
UPDATE_BLOG
DELETE_BLOG

CREATE_RESEARCH
PUBLISH_RESEARCH
DELETE_RESEARCH

UPLOAD_MEDIA
DELETE_MEDIA

UPDATE_SETTINGS
```

---

# 25. Media Architecture

Media should not be stored directly inside the application database.

The database should store metadata:

```text
Media
├── ID
├── Filename
├── URL
├── Type
├── Size
├── Alt Text
├── Created At
└── Uploaded By
```

Actual files should be stored in an object/media storage provider.

Possible storage:

```text
Object Storage
    │
    ├── profile/
    ├── projects/
    ├── blog/
    ├── research/
    ├── certificates/
    └── documents/
```

---

# 26. Resume and Documents

Documents should be treated as managed media.

Examples:

```text
/resume
/certifications
/research
/publications
```

The admin panel should allow the owner to upload and replace documents.

---

# 27. Content Publishing Workflow

Content should support draft and published states.

```text
Create
  │
  ▼
Draft
  │
  │ Edit
  ▼
Review
  │
  │ Publish
  ▼
Published
  │
  │ Update
  ▼
Updated
```

For example:

```text
Blog Post
    │
    ├── Draft
    ├── Scheduled
    └── Published
```

---

# 28. SEO Architecture

Every public content page should support:

```text
Title
Description
Canonical URL
Open Graph Image
Twitter/X Card
Keywords
Structured Data
```

For blog and research pages, structured data can include:

```text
Article
ScholarlyArticle
Person
WebSite
BreadcrumbList
```

---

# 29. URL / Slug Strategy

Public content should use human-readable slugs.

Examples:

```text
/projects/aegiszero
/blog/building-a-zero-trust-platform
/research/zero-trust-identity-management
```

Admin routes remain separate:

```text
/ChamathDilshanC
```

This separation keeps public URLs clean while protecting the administration interface.

---

# 30. Frontend Architecture

The frontend should be component-based.

Recommended conceptual structure:

```text
Frontend
│
├── Layout
│   ├── Navbar
│   ├── Footer
│   └── SEO
│
├── Pages
│   ├── Home
│   ├── About
│   ├── Projects
│   ├── Blog
│   ├── Research
│   └── Contact
│
├── Components
│   ├── ProjectCard
│   ├── BlogCard
│   ├── ResearchCard
│   ├── Timeline
│   └── CertificateCard
│
└── Admin
    ├── Dashboard
    ├── Editors
    ├── Tables
    ├── MediaManager
    └── Settings
```

---

# 31. Backend Architecture

Backend responsibilities:

```text
Backend
│
├── Authentication
├── Authorization
├── API
├── Database
├── Content Management
├── Media Management
├── Validation
├── Rate Limiting
├── Audit Logging
└── Error Handling
```

The backend must never trust data supplied by the frontend.

---

# 32. Environment Configuration

Secrets must be stored using environment variables.

Example:

```env
DATABASE_URL=

GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
GITHUB_OWNER_ID=

SESSION_SECRET=

MEDIA_STORAGE_URL=
MEDIA_STORAGE_KEY=
MEDIA_STORAGE_SECRET=

PUBLIC_SITE_URL=
```

`.env` files must never be committed.

The repository should contain:

```text
.env.example
```

but not:

```text
.env
```

---

# 33. Repository Structure

A recommended monorepo structure:

```text
chamathdilshan/
│
├── apps/
│   ├── web/
│   │   ├── public/
│   │   ├── admin/
│   │   └── components/
│   │
│   └── api/
│       ├── auth/
│       ├── routes/
│       ├── middleware/
│       ├── services/
│       └── database/
│
├── packages/
│   ├── types/
│   ├── validation/
│   └── config/
│
├── content/
│   ├── blog/
│   └── research/
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── SECURITY.md
│   └── CONTRIBUTING.md
│
├── public/
│
├── .env.example
├── README.md
├── LICENSE
└── ARCHITECTURE.md
```

The exact directory structure can be changed depending on the selected framework.

---

# 34. Deployment Architecture

Recommended production architecture:

```text
                    Internet
                       │
                       ▼
                 Custom Domain
                       │
                       ▼
                Reverse Proxy / CDN
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
     Web Application           API Server
          │                         │
          │                         ├── PostgreSQL
          │                         │
          │                         ├── GitHub OAuth
          │                         │
          │                         └── Object Storage
          │
          ▼
       Visitors
```

---

# 35. CI/CD

The project should use Git-based deployment.

```text
Developer
    │
    ▼
Git Commit
    │
    ▼
GitHub
    │
    ▼
CI Pipeline
    │
    ├── Lint
    ├── Type Check
    ├── Tests
    ├── Build
    └── Security Checks
    │
    ▼
Production Deployment
```

---

# 36. Backup Strategy

Important data should be backed up.

Backup targets:

```text
Database
Media
Research PDFs
Resume
Important documents
```

Database backups should be automated.

---

# 37. Error Handling

The API should use consistent error responses.

Example:

```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Authentication required"
  }
}
```

Common status codes:

```text
200 OK
201 Created
400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
422 Validation Error
429 Too Many Requests
500 Internal Server Error
```

---

# 38. Rate Limiting

Rate limiting should be implemented for:

```text
Authentication endpoints
Contact form
Public APIs
Admin APIs
Media uploads
```

Stricter limits should be applied to authentication-related endpoints.

---

# 39. Input Validation

All incoming data must be validated server-side.

Validation should apply to:

```text
Blog posts
Projects
Research
Contact forms
Media metadata
Admin settings
```

The frontend validation is only for user experience.

Backend validation is the actual security boundary.

---

# 40. Content Versioning

For important content such as:

```text
Research
Blog posts
Project case studies
```

future versions can be supported.

Example:

```text
Blog Post
│
├── Version 1
├── Version 2
└── Version 3
```

This allows restoration of previous content.

---

# 41. Future Extensions

The architecture should allow future features without major restructuring.

Potential future modules:

```text
Newsletter
Comments
Analytics
Search
RSS
Sitemap
Project changelogs
Research citations
Publications
Speaking engagements
Open-source contributions
Guestbook
Contact management
AI-assisted content drafting
Content scheduling
Multi-language support
Dark/light themes
```

---

# 42. Security Principles

The system follows:

```text
Least Privilege
Zero Trust
Defense in Depth
Secure by Default
Server-side Authorization
Secret Isolation
Input Validation
Auditability
```

The administration system should assume that:

```text
The admin URL can become publicly known.
```

Therefore, hiding `/ChamathDilshanC` is not considered an authentication mechanism.

The actual security boundary is:

```text
GitHub OAuth
        +
GitHub Owner ID Verification
        +
Secure Session
        +
Server-side Authorization
```

---

# 43. Admin Access Requirement

The intended administrator model is:

```text
GitHub Account
      │
      ▼
ChamathDilshanC
      │
      ▼
GitHub OAuth
      │
      ▼
Owner ID Verification
      │
      ▼
Admin Session
      │
      ▼
/ChamathDilshanC/dashboard
```

No other GitHub account should receive administrative privileges.

---

# 44. Recommended Admin URL

Production:

```text
https://<domain>/ChamathDilshanC
```

Login:

```text
https://<domain>/ChamathDilshanC/login
```

Dashboard:

```text
https://<domain>/ChamathDilshanC/dashboard
```

The route name is intentionally based on the GitHub identity, while actual authorization is performed using the GitHub account identity on the server.

---

# 45. Final Architecture Principle

The platform should be treated as a **Personal Digital Identity & Publishing Platform**, rather than simply a portfolio website.

The architecture separates:

```text
PUBLIC CONTENT
      │
      ├── Portfolio
      ├── Projects
      ├── Blog
      ├── Research
      └── Publications

PRIVATE MANAGEMENT
      │
      ├── Dashboard
      ├── Content Management
      ├── Media Management
      ├── Publishing
      └── Settings

SECURITY
      │
      ├── GitHub OAuth
      ├── Owner Verification
      ├── Secure Sessions
      ├── API Authorization
      └── Audit Logs
```

This structure provides a strong foundation for evolving the website from a simple portfolio into a long-term personal technical platform.
