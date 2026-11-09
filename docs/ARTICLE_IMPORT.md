# Importing journal articles

In **Admin → Journal**, select **Import article** beside **New article**.
The import page includes **Copy AI instructions**, **Download sample HTML**,
and the full format guide. Give those instructions to Claude or another AI
tool, replace `[YOUR TOPIC]`, and save the response as a UTF-8 `.html` file.

Select the file (up to 1 MB), then select **Import and review**. Review the
extracted fields, content and any conversion warnings in the existing article
editor. **Create article** saves a draft. Publishing uses the existing
visibility control. Importing a file alone does not create or publish a record.

The importer reads content into the existing journal model. Imported fonts,
CSS and scripts never become part of the public page. The existing journal
heading, paragraph, numbered section and image styles are retained. Body
videos use native playback controls and do not autoplay.

## HTML contract

- Exactly one `<h1>` for the article title (up to 200 characters).
- Use `<meta name="article-category" content="...">`,
  `<meta name="article-date" content="YYYY-MM-DD">`, optional
  `<meta name="article-slug" content="lowercase-hyphenated-slug">`,
  and `<meta name="description" content="...">` in the document head.
- Mark one cover image or video with `data-cover`. Without a cover, the
  import is still editable, but a cover must be added before publication.
- Use up to 40 sections, each containing an `<h2>` (up to 120 characters),
  then up to 50 `<p>` paragraphs (up to 5000 characters each), then up to two
  images, then up to two videos. Start another section if text follows media.
- Use `<img src="..." alt="...">` and
  `<video src="..." poster="..." aria-label="..." controls></video>`.
  A video can also contain `<source src="...">`.
- Use existing site paths starting with `/` or HTTPS URLs. Upload local media
  through the Media library first and use the returned URL. Importing HTML
  does not upload accompanying files. YouTube/iframe embeds, data URLs,
  relative paths and local file URLs are unsupported.
- Paragraphs retain text and decoded HTML entities. Inline formatting and
  links become plain text. Tables and unsupported tags produce a validation
  error instead of silently losing their content.
- Put captions in paragraphs before media. CSS, fonts, scripts, external
  layouts and event handlers are not imported.

The source for the sample and copyable prompt is
`chamathdilshan.dev/lib/admin/article-template.ts`.

## Implementation and deployment

`POST /api/admin/posts/import-preview` accepts `{ "html": "..." }` and returns
`{ "article": { ... }, "warnings": [...] }`. It requires the same admin session,
trusted origin and no-cache policy as other admin endpoints. Parsing does not
fetch media or execute HTML. The browser uses the existing article editor and
CRUD API to save the returned structured draft.

Section videos are optional in older articles and stored in the existing
sections JSON column; no database migration is required. Deploy the backend
and frontend changes together (backend first if deployment is sequential).
