import type { PostgrestError } from '@supabase/supabase-js'

interface MaybePostgrestError extends Partial<PostgrestError> {
  status?: number
  statusCode?: number | string
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

export function useSupabaseErrorMessage() {
  function getMessage(err: unknown, fallback = 'Сталася помилка. Спробуйте ще раз.'): string {
    if (!err) return fallback
    if (typeof err === 'string') return err

    const e = isObject(err) ? (err as MaybePostgrestError) : null
    const code = e?.code
    const status = e?.status ?? e?.statusCode

    switch (code) {
      case '23505':
        return 'Запис з такими даними вже існує (можливо, цей нікнейм уже зайнято).'
      case '23503':
        return 'Порушено звʼязок між записами.'
      case '23514':
        return 'Дані не відповідають правилам бази (наприклад, недопустимий статус).'
      case '42501':
        return 'Недостатньо прав для цієї дії.'
      case 'PGRST116':
        return 'Запис не знайдено або він недоступний.'
      case 'PGRST301':
        return 'Доступ заборонено політиками безпеки (RLS).'
    }

    if (status === 401 || String(status) === '401') {
      return 'Сесія завершилась або немає прав. Спробуйте увійти ще раз.'
    }
    if (status === 403 || String(status) === '403') {
      return 'Дію заборонено політиками безпеки.'
    }
    if (status === 409 || String(status) === '409') {
      return 'Конфлікт даних. Можливо, такий запис уже існує.'
    }

    if (err instanceof Error && err.message) return err.message
    if (e?.message) return e.message

    return fallback
  }

  return { getMessage }
}
