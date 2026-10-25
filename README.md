# The House of Dumb S#iT — Storefront + CMS starter

This package adds an admin CMS backed by Supabase. It lets you manage inventory and some storefront copy without editing HTML after setup.

## Files
- `index.html` — public storefront
- `admin.html` — admin sign-in, product manager and copy editor
- `config.js` — Supabase URL + browser-safe anon/publishable key
- `supabase-schema.sql` — database tables and row-level security policies

## Setup (one time)
1. Create a Supabase project at https://supabase.com/.
2. In Project Settings / API, copy the Project URL and the publishable/anon key. Add them to `config.js`. Do not use a service-role key in browser code.
3. In the Supabase SQL Editor, run all of `supabase-schema.sql`.
4. In Supabase Authentication, create your admin user with email/password. Disable public sign-ups if they are not needed.
5. Copy that user's UUID from Authentication -> Users. In SQL Editor, run:
   `insert into public.admin_users(user_id) values ('YOUR_AUTH_USER_UUID');`
6. Host the four files on a static host with HTTPS (Netlify, Vercel, Cloudflare Pages or your own host). Test both `index.html` and `admin.html` from the hosted origin. Avoid opening the files directly with `file://` for production use.
7. Visit `/admin.html`, sign in, add your real work, artist details, prices, image URLs, edition information and publish when ready.

## What the CMS supports
- Create, edit and delete listings
- Set title, artist, price, stock quantity, edition, description, image URL, background colour and status label
- Publish/unpublish listings
- Edit hero headline, hero intro and House statement
- Export product inventory as JSON and import JSON records

## Important limitations before live commerce
- This is a CMS starter, not a complete production commerce backend.
- Checkout in the storefront is still demo-only. It does not create server-side orders or collect payment.
- Stock quantity is displayed/admin-managed but is not atomically reserved during checkout. Before real sales, implement server-side order creation, payment provider webhooks and atomic inventory locking to prevent double-selling one-of-one works.
- Image fields currently accept hosted image URLs. Supabase Storage upload UI is not included yet.
- Add and test privacy policy, terms, shipping/returns policy, email confirmations, tax/shipping calculations, backups, and admin account recovery before launch.
- Public browser code contains only the Supabase anon/publishable key. Row Level Security protects writes, and admin writes require an allowlisted authenticated user.

## Local development
Supabase browser SDK is loaded from jsDelivr, so internet access is needed. Because browser auth and network calls may behave differently on `file://`, serve the directory locally with any static server, or deploy it to a staging host.
