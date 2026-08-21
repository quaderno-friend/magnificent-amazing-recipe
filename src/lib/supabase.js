import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  // Vite inlines VITE_* at build time. If the build had no env, the app would
  // otherwise fail deep inside createClient with an unhelpful stack trace.
  throw new Error(
    'Supabase is not configured. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY — ' +
    'locally in .env, and as repository secrets for the GitHub Actions build.'
  )
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
