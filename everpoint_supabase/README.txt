EVERPOINT HOLDING — STATIC FRONTEND + SUPABASE

WHAT THIS VERSION DOES
- Static HTML/CSS/JavaScript hosted by Cloudflare.
- Supabase Auth provides shared employee/admin sign-in sessions.
- Supabase Postgres stores employees, progress, reimbursements, document status, notifications, announcements, applications and upload metadata.
- Supabase Storage stores employee PDFs in the private employee-documents bucket.
- FormSubmit can also receive applications/PDFs by email when configured.
- No Cloudflare Worker API or D1 database is required for this version.

IMPORTANT SECURITY NOTE
The admin email/password values in public/adminx.js are used as a convenience gate and to sign in to the Supabase Auth admin account. They are visible in the downloaded JavaScript. This is not a secret. Real authorization comes from Supabase Auth + RLS. Never put a Supabase service_role/secret key in the website.

SETUP — NO COMMAND PROMPT
1. Open your Supabase project.
2. Go to SQL Editor -> New query.
3. Open supabase_setup.sql from this ZIP, copy all of it into the SQL editor, and Run.
4. Go to Authentication -> Users -> Add user. Create:
   Email: admin@everpointholding.com
   Password: EP-Admin-2026
   Make sure the user is confirmed/active.
5. In SQL Editor, run the final admin profile statement from supabase_setup.sql (the commented INSERT at the bottom, after removing the -- comment markers), or run:
   insert into public.profiles (id,email,full_name,role,active)
   select id,email,'EverPoint Administrator','admin',true from auth.users where email='admin@everpointholding.com'
   on conflict (id) do update set role='admin', active=true, email=excluded.email;
6. Authentication -> Providers/Email: for this static admin-created employee workflow, turn OFF email confirmation if your project requires confirmation before a new employee can sign in. The admin creates the employee's Auth account from the admin panel using signUp.
7. Supabase Project Settings -> API: copy Project URL and Publishable key (or legacy anon key).
8. In public/supabase-config.js replace:
   SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co'
   SUPABASE_PUBLISHABLE_KEY = 'YOUR_SUPABASE_PUBLISHABLE_KEY'
   Do NOT use service_role/secret key.
9. Optional: in public/script.js replace FORM_ENDPOINT with your FormSubmit endpoint. Example: https://formsubmit.co/your@email.com
10. Upload the contents of everpoint_fullstack to GitHub, keeping public/ at the same level as wrangler.jsonc.
11. Cloudflare: repository = your GitHub repo; Root directory = everpoint_fullstack; Build command blank; Deploy command = npx wrangler deploy.

ADMIN LOGIN
URL: /adminx.html
Email: admin@everpointholding.com
Password: EP-Admin-2026

IF YOU CHANGE ADMIN CREDENTIALS
A) Change the Supabase Auth user's email/password in Supabase Authentication.
B) Change ADMIN_EMAIL and/or ADMIN_PASSWORD at the top of public/adminx.js to exactly match.
C) Redeploy through GitHub/Cloudflare.

ADMIN CAN
- Create employee Auth accounts and employee profiles.
- Activate/deactivate employees.
- Edit employee names/email/profile.
- Change application progress.
- Release/lock/pending documents.
- Set reimbursement amount and status: No funds, Yet to be approved, Approved, Approved and paid.
- Publish announcements.
- Send notifications through administrative actions.
- View applications.
- View uploaded PDF metadata in the admin inbox.

EMPLOYEE CAN
- Sign in from another device using their Supabase Auth account.
- See admin-controlled progress, documents, reimbursement amount/status, announcements and notifications.
- Download released PDFs.
- Upload PDFs to the private Supabase Storage bucket.

FORM SUBMIT
The website can send applications and uploaded PDFs to a FormSubmit endpoint if FORM_ENDPOINT is configured. The primary PDF copy is also stored in the private Supabase bucket.

LIMITATION
Admin-created Supabase Auth accounts from a browser require email confirmation to be disabled for this workflow. This is a convenience/static architecture. For a highly sensitive production HR system, use a server-side admin invite/create-user endpoint instead.
