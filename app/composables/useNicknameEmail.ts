const DOMAIN = 'clan.pw'

/**
 * Supabase Auth працює через email, а гравці реєструються лише за ніком.
 * Тому ми детерміновано перетворюємо нік на синтетичний email:
 *   нік -> utf8 bytes -> hex -> `u<hex>@clan.pw`
 * Те саме перетворення під час логіну дає той самий email.
 */
export function useNicknameEmail() {
  function toEmail(nickname: string): string {
    const normalized = nickname.trim().toLowerCase()
    const bytes = new TextEncoder().encode(normalized)
    let hex = ''
    for (const b of bytes) hex += b.toString(16).padStart(2, '0')
    return `u${hex}@${DOMAIN}`
  }

  /** Якщо введено email (містить @) — використовуємо як є, інакше перетворюємо нік. */
  function resolveLogin(input: string): string {
    const value = input.trim()
    return value.includes('@') ? value.toLowerCase() : toEmail(value)
  }

  return { toEmail, resolveLogin }
}
