/*
  EVERPOINT HOLDING — SUPABASE CONNECTION
  1) Replace SUPABASE_URL with your Project URL.
  2) Replace SUPABASE_PUBLISHABLE_KEY with your Publishable key (or legacy anon key).
  NEVER put a Supabase service_role/secret key in this file.
*/
const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'YOUR_SUPABASE_PUBLISHABLE_KEY';

window.epSupabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
});
