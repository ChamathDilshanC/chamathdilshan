# Security Policy

## Personal Portfolio & Publishing Platform

This document defines the security architecture, policies, and operational practices for the **Chamath Dilshan Personal Portfolio & Publishing Platform**.

The platform includes a public portfolio, blog, research/publication system, media management, and a private administration panel.

---

# 1. Security Objectives

The primary security objectives are:

- Protect the private administration system.
- Ensure only the authorized GitHub account can access administrative functions.
- Protect application secrets and credentials.
- Prevent unauthorized content modification.
- Protect user-submitted data.
- Secure API endpoints.
- Prevent common web application attacks.
- Maintain auditability of administrative actions.
- Minimize the impact of compromised credentials or sessions.
- Follow the principle of least privilege.

---

# 2. Security Architecture

The platform follows a defense-in-depth security model.

```text
                    INTERNET
                       │
                       ▼
                HTTPS / TLS
                       │
                       ▼
                 Web Application
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
     Public Routes            Admin Routes
                                    │
                                    ▼
                              GitHub OAuth
                                    │
                                    ▼
                           GitHub Identity Check
                                    │
                                    ▼
                           Owner ID Verification
                                    │
                                    ▼
                            Secure Session
                                    │
                                    ▼
                           Admin API Middleware
                                    │
                                    ▼
                              Authorization
                                    │
                                    ▼
                                Database
```

Security must never depend on a single layer.

---

# 3. Threat Model

The application assumes that attackers may:

- Discover the administrator URL.
- Attempt unauthorized authentication.
- Attempt session theft.
- Manipulate API requests.
- Submit malicious input.
- Attempt privilege escalation.
- Abuse public endpoints.
- Attempt brute-force or automated requests.
- Upload malicious files.
- Attempt SQL injection.
- Attempt Cross-Site Scripting (XSS).
- Attempt Cross-Site Request Forgery (CSRF).
- Attempt Server-Side Request Forgery (SSRF).
- Attempt to access private resources directly.
- Attempt to exploit exposed environment variables.
- Attempt to abuse third-party OAuth flows.

The security architecture is designed with these threats in mind.

---

# 4. Administrator Authentication

## Authentication Provider

Administrative authentication uses **GitHub OAuth**.

The application must not implement a separate administrator username/password authentication system.

Authentication flow:

```text
User
 │
 ▼
/ChamathDilshanC
 │
 ▼
Login Page
 │
 ▼
GitHub OAuth
 │
 ▼
GitHub Authorization
 │
 ▼
OAuth Callback
 │
 ▼
Backend Identity Validation
 │
 ▼
GitHub Owner Verification
 │
 ▼
Secure Session
 │
 ▼
Admin Dashboard
```

---

# 5. GitHub Owner Authorization

The administrator account is:

```text
GitHub Username:
ChamathDilshanC
```

Authorization should primarily use the immutable GitHub numeric user ID.

Recommended environment configuration:

```env
GITHUB_OWNER_ID=<github-user-id>
GITHUB_OWNER_USERNAME=ChamathDilshanC
```

The username may be used for display and secondary validation.

The numeric GitHub user ID should be treated as the primary authorization identifier.

---

# 6. No Public Registration

The platform must not contain:

```text
Admin Registration
User Registration
Admin Password Creation
Admin Password Reset
Public Admin Invitations
```

There is only one authorized administrator unless the authorization model is intentionally expanded in the future.

---

# 7. Admin URL Security

The administration interface is exposed through:

```text
/ChamathDilshanC
```

Example:

```text
https://<domain>/ChamathDilshanC
```

The URL itself is not considered a security mechanism.

An attacker who knows the URL must still be unable to access the dashboard without successful GitHub authentication and owner verification.

Security depends on:

```text
GitHub OAuth
+
Owner ID Verification
+
Secure Session
+
Server-side Authorization
```

---

# 8. Server-Side Authorization

All administrative API endpoints must verify authorization on the server.

Protected namespace:

```text
/api/admin/*
```

Every request must pass:

```text
Request
  │
  ▼
Session Validation
  │
  ├── Failed ──► 401 Unauthorized
  │
  ▼
Owner Verification
  │
  ├── Failed ──► 403 Forbidden
  │
  ▼
Authorization
  │
  ▼
Controller
```

Frontend route protection alone is insufficient.

---

# 9. Session Security

Administrative sessions must use secure server-managed sessions.

Recommended cookie properties:

```text
HttpOnly
Secure
SameSite=Lax or Strict
```

Sessions should have controlled expiration.

Sensitive authentication tokens must never be exposed to client-side JavaScript unnecessarily.

Authentication credentials must never be stored in:

```text
localStorage
sessionStorage
URL query parameters
HTML
public source files
Git repositories
```

---

# 10. OAuth Security

The OAuth implementation must:

- Validate the OAuth `state` parameter.
- Use the correct redirect URI.
- Never expose the GitHub client secret to the browser.
- Keep OAuth credentials on the server.
- Validate the authenticated GitHub identity server-side.
- Reject unexpected OAuth responses.
- Avoid accepting arbitrary redirect destinations.

Recommended flow:

```text
Browser
   │
   ▼
Backend OAuth Endpoint
   │
   ▼
GitHub
   │
   ▼
Callback
   │
   ▼
Backend
   │
   ├── Validate state
   ├── Exchange authorization code
   ├── Retrieve GitHub identity
   ├── Verify owner ID
   └── Create session
```

---

# 11. Secret Management

Secrets must never be committed to Git.

Sensitive values include:

```text
DATABASE_URL
GITHUB_CLIENT_SECRET
SESSION_SECRET
STORAGE_SECRET
API_KEYS
ACCESS_TOKENS
PRIVATE_KEYS
```

Secrets should be provided through the deployment platform's environment-variable or secret-management system.

The repository may contain:

```text
.env.example
```

but must never contain:

```text
.env
.env.local
.env.production
```

or equivalent secret files.

---

# 12. Environment Variables

Example:

```env
DATABASE_URL=

GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
GITHUB_OWNER_ID=
GITHUB_OWNER_USERNAME=

SESSION_SECRET=

MEDIA_STORAGE_URL=
MEDIA_STORAGE_KEY=
MEDIA_STORAGE_SECRET=

PUBLIC_SITE_URL=
```

Public configuration and private secrets must be clearly separated.

Only variables explicitly intended for the browser may be exposed to the frontend.

---

# 13. Database Security

The database must not be directly accessible from the public internet unless explicitly required.

Application architecture:

```text
Browser
   │
   ▼
Backend API
   │
   ▼
Database
```

Not:

```text
Browser
   │
   ▼
Database
```

Database credentials must remain server-side.

---

# 14. SQL Injection Prevention

All database queries must use parameterized queries or a trusted ORM/query builder.

Never construct SQL using raw untrusted input.

Unsafe pattern:

```text
SELECT * FROM users WHERE name = '<user input>'
```

Preferred approach:

```text
Parameterized Query
+
Validated Input
```

Raw SQL should only be used when necessary and must remain parameterized.

---

# 15. Input Validation

All externally supplied data must be validated.

Validation is required for:

```text
Blog posts
Projects
Research
Contact forms
Search queries
Media metadata
Admin settings
URL parameters
Query parameters
Request bodies
```

Validation must happen server-side.

Frontend validation is only an additional usability layer.

---

# 16. Cross-Site Scripting (XSS)

The application must protect against:

- Stored XSS.
- Reflected XSS.
- DOM-based XSS.

User-generated content must be sanitized before rendering as HTML.

Particular attention is required for:

```text
Blog content
Research content
Project descriptions
Comments
Contact data
Markdown/HTML content
```

If Markdown is supported, unsafe HTML should be disabled or sanitized.

---

# 17. Content Security Policy

A Content Security Policy should be implemented where supported.

The policy should restrict:

```text
script sources
style sources
image sources
font sources
frame sources
connect sources
```

The policy should be restrictive by default and expanded only when required.

---

# 18. Cross-Site Request Forgery (CSRF)

State-changing authenticated requests must be protected against CSRF.

Examples:

```text
POST
PUT
PATCH
DELETE
```

Recommended protections include:

```text
SameSite Cookies
+
CSRF Tokens where required
+
Origin/Referer Validation
```

GET requests must not perform destructive actions.

---

# 19. Cross-Origin Resource Sharing (CORS)

CORS must not use unrestricted configuration such as:

```text
Access-Control-Allow-Origin: *
```

for authenticated administrative APIs.

The API should explicitly allow only trusted origins.

Example:

```text
https://<domain>
```

Administrative endpoints should not be accessible from arbitrary origins.

---

# 20. Rate Limiting

Rate limiting should be implemented for:

```text
OAuth endpoints
Authentication endpoints
Contact form
Public APIs
Admin APIs
Media uploads
Search endpoints
```

Authentication and sensitive endpoints should have stricter limits.

Example conceptual policy:

```text
Public API       → Standard limit
Contact Form     → Strict limit
OAuth            → Strict limit
Admin API        → Strict limit
File Upload      → Strict limit
```

---

# 21. File Upload Security

Uploaded files must be treated as untrusted.

The server should validate:

```text
File type
MIME type
File extension
File size
File content
Filename
```

Dangerous executable files must not be accepted.

Examples of files requiring special consideration:

```text
.exe
.sh
.bat
.ps1
.php
.jsp
.js
```

Uploaded files should preferably be stored outside the application executable directory.

---

# 22. File Name Security

Original user-provided filenames must not be trusted.

Instead, generated identifiers should be used.

Example:

```text
original:
my-research-paper.pdf

stored:
a8f1c3d9-research.pdf
```

This reduces risks associated with:

```text
Path Traversal
Filename collisions
Special characters
Unexpected filesystem behavior
```

---

# 23. Path Traversal Protection

User input must never directly determine filesystem paths.

Reject patterns such as:

```text
../
..\
/etc/
C:\
```

File access should use server-generated identifiers and controlled storage paths.

---

# 24. SSRF Protection

If the application fetches external URLs, those URLs must be validated.

This is particularly important for:

```text
Image imports
URL previews
External metadata
Webhook integrations
Research links
```

The server must not blindly fetch arbitrary user-provided URLs.

Private/internal network ranges should be blocked where applicable.

---

# 25. API Security

Public API endpoints:

```text
/api/profile
/api/projects
/api/blog
/api/research
```

may be publicly accessible.

Administrative API endpoints:

```text
/api/admin/*
```

must always require authentication and authorization.

Never rely on obscurity of endpoint names.

---

# 26. HTTP Security Headers

The production application should implement appropriate security headers.

Recommended headers include:

```text
Strict-Transport-Security
Content-Security-Policy
X-Content-Type-Options
Referrer-Policy
Permissions-Policy
```

Legacy headers should only be enabled when supported and useful.

---

# 27. HTTPS

Production traffic must use HTTPS.

HTTP traffic should redirect to HTTPS.

Sensitive authentication and administration operations must never occur over plain HTTP.

---

# 28. Password Policy

The platform does not use administrator passwords.

Therefore, the application should not maintain:

```text
Admin Password Hashes
Password Reset Tokens
Password Recovery Questions
```

GitHub is the identity provider.

---

# 29. Contact Form Security

The public contact form is an attack surface.

It must include:

```text
Input validation
Rate limiting
Spam protection
Length limits
Email validation
XSS protection
CSRF protection where applicable
```

Contact submissions must not be rendered as raw HTML inside the admin dashboard.

---

# 30. Audit Logging

Security-sensitive administrative operations should be logged.

Examples:

```text
LOGIN
LOGOUT

CREATE_PROJECT
UPDATE_PROJECT
DELETE_PROJECT

CREATE_BLOG
UPDATE_BLOG
PUBLISH_BLOG
DELETE_BLOG

CREATE_RESEARCH
UPDATE_RESEARCH
PUBLISH_RESEARCH
DELETE_RESEARCH

UPLOAD_MEDIA
DELETE_MEDIA

UPDATE_SETTINGS
```

Audit logs should contain sufficient information to determine:

```text
Who
What
When
Which resource
```

Sensitive tokens and secrets must never be written to logs.

---

# 31. Error Handling

Production error responses must not expose sensitive implementation details.

Do not expose:

```text
Database connection strings
Stack traces
Environment variables
OAuth secrets
Internal filesystem paths
SQL queries
Access tokens
```

Public response:

```json
{
  "success": false,
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred."
  }
}
```

Detailed errors should be available only in protected server-side logs.

---

# 32. Security Logging

Security-related events should be monitored.

Important events include:

```text
Failed OAuth attempts
Unauthorized admin API access
Forbidden access attempts
Rate-limit violations
Invalid file uploads
Unexpected server errors
Suspicious request patterns
```

Logs should be protected against unauthorized modification.

---

# 33. Dependency Security

Dependencies must be kept reasonably up to date.

The project should regularly check for:

```text
Known vulnerabilities
Outdated dependencies
Abandoned packages
Malicious packages
```

Automated dependency security scanning should be enabled where possible.

---

# 34. GitHub Repository Security

The repository should use:

```text
Branch protection
Pull request checks
Secret scanning
Dependency scanning
Code scanning where available
```

Git history must not contain:

```text
API keys
OAuth secrets
Database credentials
Private keys
Access tokens
```

If a secret is accidentally committed, it must be considered compromised and rotated immediately.

Simply deleting the file in a later commit is not sufficient.

---

# 35. GitHub OAuth Credentials

The following values are sensitive:

```text
GITHUB_CLIENT_SECRET
```

The following may be public depending on the implementation:

```text
GITHUB_CLIENT_ID
```

The client secret must only exist on the server.

If the secret is exposed:

```text
1. Revoke/rotate the GitHub OAuth secret.
2. Update production environment variables.
3. Review repository history.
4. Review authentication logs.
5. Investigate unauthorized access.
```

---

# 36. Admin Privilege Model

The initial system uses a single-owner model.

```text
Role:
OWNER
```

Future roles may include:

```text
OWNER
EDITOR
REVIEWER
```

However, additional roles should not be implemented until required.

The default security principle is:

```text
Deny by default.
Grant only required permissions.
```

---

# 37. Least Privilege

Every component should have only the permissions it requires.

Examples:

```text
Frontend
→ Public API access

Public API
→ Public database reads

Admin API
→ Authenticated owner operations

Media service
→ Required storage operations only

Database user
→ Required database permissions only
```

---

# 38. Data Privacy

The platform should minimize collection of personal information.

Only information necessary for functionality should be stored.

Private information should never be unnecessarily exposed through:

```text
Public API responses
HTML source
Client-side JavaScript
Search indexes
Public GitHub repository
```

---

# 39. Personal Documents

Documents such as:

```text
Resume
Certificates
Research Papers
References
```

must be reviewed before public publication.

Documents should not accidentally expose:

```text
Private phone numbers
Private email addresses
Home addresses
Government identifiers
Private access credentials
Private API keys
```

---

# 40. Backup Security

Backups must be protected with appropriate access controls.

Backups should not be publicly accessible.

Recommended backup targets:

```text
Database
Research documents
Important media
Portfolio content
Configuration metadata
```

Secrets should not be included in backups unless required and appropriately encrypted.

---

# 41. Production Security Checklist

Before production deployment:

```text
[ ] HTTPS enabled
[ ] HTTP redirects to HTTPS
[ ] GitHub OAuth configured
[ ] GitHub owner ID configured
[ ] GitHub client secret stored securely
[ ] SESSION_SECRET configured
[ ] Database credentials secured
[ ] Admin APIs protected
[ ] Server-side authorization implemented
[ ] Secure cookies enabled
[ ] CSRF protection reviewed
[ ] CORS restricted
[ ] Rate limiting enabled
[ ] Input validation enabled
[ ] XSS protection implemented
[ ] File upload restrictions implemented
[ ] Security headers configured
[ ] Error responses sanitized
[ ] Audit logging enabled
[ ] Dependency scanning enabled
[ ] Secret scanning enabled
[ ] Database backups configured
[ ] Production environment reviewed
```

---

# 42. Incident Response

If unauthorized access or a security vulnerability is discovered:

### Step 1 — Contain

Immediately restrict affected functionality if necessary.

### Step 2 — Rotate Credentials

Rotate potentially compromised:

```text
OAuth secrets
Session secrets
Database credentials
Storage credentials
API keys
```

### Step 3 — Investigate

Review:

```text
Audit logs
Authentication logs
Application logs
Git history
Deployment history
```

### Step 4 — Remediate

Fix the vulnerability and deploy the security update.

### Step 5 — Verify

Confirm that:

```text
Unauthorized sessions are invalidated.
Compromised credentials are rotated.
The vulnerability is fixed.
Access controls are functioning.
```

---

# 43. Security Disclosure

Security vulnerabilities should not be publicly disclosed before they are investigated and, where appropriate, fixed.

When reporting a vulnerability, include:

```text
Vulnerability description
Affected component
Steps to reproduce
Potential impact
Suggested mitigation
```

Do not include real credentials, access tokens, or other secrets in vulnerability reports.

---

# 44. Security Principles

The platform follows these principles:

```text
Zero Trust
Least Privilege
Defense in Depth
Secure by Default
Fail Securely
Server-Side Authorization
Secret Isolation
Input Validation
Auditability
Data Minimization
```

---

# 45. Final Security Boundary

The most important security boundary of the administration system is:

```text
                 /ChamathDilshanC
                         │
                         ▼
                  GitHub OAuth
                         │
                         ▼
              GitHub Identity Validation
                         │
                         ▼
                 Owner ID Verification
                         │
                    ┌────┴────┐
                    │         │
                  OWNER     NOT OWNER
                    │         │
                    ▼         ▼
              Create Session  403
                    │
                    ▼
              Admin Dashboard
                    │
                    ▼
              Protected Admin API
                    │
                    ▼
                  Database
```

Knowing the admin URL alone must never grant access.

The application must always enforce authorization server-side.

---

# 46. Security Status

Current security architecture:

```text
Authentication       → GitHub OAuth
Authorization        → GitHub Owner ID
Admin Access         → Owner only
Session              → Secure server-side session
API Protection       → Server-side middleware
Secrets              → Environment variables
Database             → Server-side access
File Uploads         → Validation + restricted storage
Auditability         → Audit logs
Transport            → HTTPS
```

This document should be updated whenever a significant authentication, authorization, infrastructure, or data-handling change is introduced.