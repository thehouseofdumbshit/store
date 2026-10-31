# The House of Dumb S#iT — multi-page patronage site (v2)

## Pages
- `index.html` — home
- `artists.html` — separate searchable public artist directory
- `patronage.html` — separate explanation of patronage
- `commissions.html` — separate commission entry page
- `artist.html` — artist sign-in, account creation, profile editor and commission notifications
- `patron.html` — patron sign-in, account creation, artist discovery and commission dashboard
- `artist-profile.html` — public artist profile view

## Supabase setup
1. Create a Supabase project.
2. If the base schema has not already been run, run `supabase-schema.sql` first.
3. Run `supabase-migration-v2.sql` in Supabase SQL Editor. This adds patron profiles, ties commission requests to the signed-in patron and selected artist, and installs the relevant RLS policies.
4. In `config.js`, set your Supabase Project URL and Publishable key (or legacy anon key). Never use a `service_role` or secret key in browser code.
5. In Supabase Authentication → URL Configuration, set your Site URL and add the deployed website URL to Redirect URLs. For local testing, add the local development origin you use.
6. In Authentication → Providers → Email, choose whether to require email confirmation. If enabled, users must confirm their email and then sign in before their profile record is created on first dashboard visit.
7. Deploy all files together to the same static hosting origin. The pages link to one another by relative paths.

## User journeys
### Artist
- Opens `artist.html`, creates account or signs in with email/password.
- First successful dashboard visit creates an unpublished artist profile associated with their Supabase Auth UID.
- Artist edits profile and chooses whether to publish it.
- New patron enquiries selecting that artist appear under Commission Invitations on the artist dashboard.

### Patron
- Opens `patron.html`, creates account or signs in.
- First successful dashboard visit creates a private patron profile.
- Searches published artists by name, practice and location.
- Selects Commission and submits a brief. The record is linked to the authenticated patron and selected artist.
- Sees their commission history in the dashboard.

## Important security and implementation notes
- This is a functional front-end integration starter, not a production security audit.
- The browser uses only the Supabase publishable/anon key. Never expose a service-role key.
- Commission inserts require an authenticated patron and a published artist. Patrons can read only their own commissions. Artists can read only commissions addressed to their own artist profile.
- The base schema contains broad insert policies for public enquiries. The v2 migration removes the public commission insert policy and replaces it with authenticated patron submissions.
- Existing prototype tables such as `artist_suggestions` and `patron_references` have not been fully redesigned for private multi-user patron dashboards in this version.
- The artist dashboard currently displays commission notifications and brief details; it does not yet provide accept/decline controls, group-chat creation or email/push notifications.
- Concierge and Super Admin workflows, staff-only oversight, contract/document storage, audit trails, file access policies, and private correspondence are not implemented in these pages. Keep the previous private-chat prototype separate until the role model is integrated deliberately.
- For production, review every RLS policy and add server-side validation, rate limiting, audit logging, email verification, account recovery, and private Storage policies.
