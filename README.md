# The House of Dumb S#iT — Private Commission Demo

This package adds a four-profile demonstration workspace and a shared group conversation to the existing House patronage prototype.

## Open the demo

Open `demo.html` in a browser. No build step is required.

### Demo logins

| Profile | Username | Key | Access |
|---|---|---|---|
| Artist | `artist` | `artist123` | Read and send messages |
| Patron | `patron` | `patron123` | Read and send messages |
| Concierge / Account Manager | `concierge` | `concierge123` | Read and send messages; mediates the relationship |
| Super Admin | `house` | `house123` | Read-only oversight; cannot send messages |

The shared room includes the artist, patron and concierge as active participants. All four profiles can view the same conversation. Super Admin's message composer is disabled, and the send handler independently rejects attempts to send from that role.

## What is implemented

- Four role-specific demo logins.
- One shared commission conversation visible to all four profiles.
- Artist, patron and concierge can send messages.
- Super Admin can view the complete conversation but cannot send.
- Concierge is presented as the dedicated relationship mediator / key account manager.
- Overview, group conversation and commission-record views.
- Messages persist in the browser's `localStorage` for the demo.
- The existing `index.html`, `artist.html`, `house-desk.html` and `admin.html` from the earlier prototype are included.
- `supabase-chat-schema.sql` provides a starting point for a secure Supabase implementation with membership-based read access and role-based write access.

## Important limitations — demo only

This is a front-end prototype, not production authentication or a secure multi-user application.

- Demo credentials are hard-coded in browser JavaScript. Anyone who can inspect the page can find them.
- Messages are stored in the current browser's local storage. They do not synchronise between different devices or browsers.
- Clearing browser data removes the demo conversation.
- Do not enter real names, confidential briefs, contracts, private artwork, personal information or procurement documents.
- `noindex` metadata is not access control and does not protect private information.

## Production architecture

Use Supabase Auth for individual accounts, PostgreSQL for profiles/conversations/messages, Row Level Security for per-conversation access, and Supabase Realtime for live message delivery. Store confidential files in private Storage buckets and issue short-lived signed URLs only to authorised participants. Never put a Supabase service-role key in browser code.

The included SQL creates the profile, conversation, membership and message tables and policies. Create Auth users separately, map their UUIDs to `house_profiles`, create the commission conversation, and add all four profiles to `house_conversation_members`. Set `can_write = false` for the `super_admin` membership and `true` for the artist, patron and concierge memberships. Enable Realtime for `house_messages` in the Supabase dashboard.

The SQL is a starting migration, not a complete production deployment. Review it with your Supabase project configuration, add carefully scoped staff-management policies, audit logging, file-access policies, rate limits, notification handling and account recovery before launch.
