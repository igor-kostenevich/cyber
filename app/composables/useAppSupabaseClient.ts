import { createClient, type SupabaseClient } from '@supabase/supabase-js'

let cachedClient: SupabaseClient | null = null

export function useAppSupabaseClient(): SupabaseClient {
  if (cachedClient) return cachedClient

  const config = useRuntimeConfig()
  const url = config.public.supabaseUrl as string | undefined
  const key = config.public.supabaseKey as string | undefined

  if (!url || !key) {
    throw new Error(
      'Supabase credentials are missing. Set SUPABASE_URL and SUPABASE_KEY in your .env file.',
    )
  }

  cachedClient = createClient(url, key, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: false,
    },
  })

  return cachedClient
}
