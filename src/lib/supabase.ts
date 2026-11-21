import { createClient } from '@supabase/supabase-js';

let supabaseClient: any = null;

export function getSupabaseConfig(): { url: string; anonKey: string } {
  const customUrl = typeof window !== 'undefined' ? localStorage.getItem('habit_tracker_supabase_url') : null;
  const customKey = typeof window !== 'undefined' ? localStorage.getItem('habit_tracker_supabase_anon_key') : null;

  const url = customUrl || import.meta.env.VITE_SUPABASE_URL || '';
  const anonKey = customKey || import.meta.env.VITE_SUPABASE_ANON_KEY || '';

  return { url: url.trim(), anonKey: anonKey.trim() };
}

export function saveSupabaseConfig(url: string, anonKey: string) {
  if (typeof window !== 'undefined') {
    if (url.trim()) {
      localStorage.setItem('habit_tracker_supabase_url', url.trim());
    } else {
      localStorage.removeItem('habit_tracker_supabase_url');
    }

    if (anonKey.trim()) {
      localStorage.setItem('habit_tracker_supabase_anon_key', anonKey.trim());
    } else {
      localStorage.removeItem('habit_tracker_supabase_anon_key');
    }
    supabaseClient = null;
  }
}

export function isSupabaseConfigured(): boolean {
  const { url, anonKey } = getSupabaseConfig();
  if (!url || !anonKey) return false;
  try {
    const parsed = new URL(url);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch {
    return false;
  }
}

export function getSupabase() {
  const { url: supabaseUrl, anonKey: supabaseAnonKey } = getSupabaseConfig();

  if (!supabaseUrl || !supabaseAnonKey) {
    return null;
  }

  try {
    const parsed = new URL(supabaseUrl);
    if (!['http:', 'https:'].includes(parsed.protocol)) {
      return null;
    }
  } catch (e) {
    return null;
  }

  if (!supabaseClient) {
    try {
      supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true,
        },
      });
    } catch (err) {
      console.warn('Failed to initialize Supabase client:', err);
      return null;
    }
  }
  return supabaseClient;
}

