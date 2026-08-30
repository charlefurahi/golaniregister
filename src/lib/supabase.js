import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_ANON_KEY

// createClient() throws synchronously when the URL/key are missing or
// invalid. Since this module is imported before the app mounts, that
// throw used to crash the whole script with nothing rendered — a blank
// white page with no on-screen indication of what went wrong. This
// still creates the client the same way when configured correctly;
// it only changes what happens when it's NOT configured.
export const supabaseConfigError = (!url || !key)
  ? 'VITE_SUPABASE_URL au VITE_SUPABASE_ANON_KEY hazijawekwa. Kwenye Netlify: Site settings → Environment variables, ongeza hizo mbili kisha deploy tena (au tumia .env ukiwa local).'
  : null

if (supabaseConfigError) {
  console.error(supabaseConfigError)
}

export const supabase = supabaseConfigError ? null : createClient(url, key)