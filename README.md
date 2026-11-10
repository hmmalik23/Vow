# VOW Version 2 — MVP package

## Included
- `index.html`: responsive VOW front-end prototype
- `manifest.webmanifest`: installable PWA metadata
- `sw.js`: basic offline cache
- `supabase_schema.sql`: starter PostgreSQL schema and row-level security policies

## Run the prototype
Open `index.html` in a modern browser. It stores demo data in that browser's local storage. For PWA installation/offline testing, host on HTTPS or localhost.

## Publish free with GitHub Pages
1. Sign in to GitHub and create a new repository named `vow-app`.
2. Upload all files from this folder to the repository root.
3. Open Settings → Pages.
4. Under Build and deployment, select Deploy from a branch, branch `main`, folder `/ (root)`, then Save.
5. Wait for GitHub Pages to publish the HTTPS URL.
6. Open that URL on Android Chrome and choose Install app / Add to Home screen. On iPhone Safari, use Share → Add to Home Screen.

## Connect real authentication and database
1. Create a Supabase project on the free tier. Review current quotas and terms before launch.
2. In Supabase Authentication → Providers, enable Email, Phone (SMS provider configuration may have separate costs), and Google.
3. For Google sign-in, create OAuth credentials in Google Cloud Console and enter the client ID/secret in Supabase's Google provider settings. Configure the exact redirect URLs Supabase gives you.
4. In Supabase SQL Editor, review and run `supabase_schema.sql` in a development project.
5. In the front end, add the Supabase JavaScript client and initialize it with the project URL and anon/publishable key. Never put the service_role key in client-side code.
6. Replace localStorage demo operations with authenticated database queries and real-time subscriptions.
7. Test row-level security with two separate test accounts: verify that a private VOW is invisible to a non-participant, while a public VOW is discoverable without leaking private group chat or participant-only records.

## Important implementation notes
- This is still a front-end demo. The sign-in buttons are previews; they do not authenticate users yet.
- Public/private filtering in this demo is a user-interface demonstration, not security. Real privacy must be enforced by backend row-level security and server-side authorization.
- Local demo accept/complete actions are not legally verified signatures. Production signatures need clear consent, signer identity assurance appropriate to risk, timestamps, versioned terms, evidence/audit trail, and jurisdiction-specific legal review.
- SMS OTP may incur provider charges. Google OAuth and email provider limits also depend on current provider policies.
- Keep bets non-cash for the first release. Do not implement stakes involving money, deposits, payouts or payment processing until specialist legal/compliance review for each launch jurisdiction.
- Before production: add invite tokens, participant onboarding, robust status transition functions, immutable event history, reporting/blocking, data export/deletion, rate limits, backups, monitoring and security testing.
