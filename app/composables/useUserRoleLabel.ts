import type { UserRole } from '~/types/activity'

const LABELS: Record<UserRole, string> = {
  user: 'Гравець',
  admin: 'Адмін',
  super_admin: 'Головний адмін',
}

const BADGE_CLASS: Record<UserRole, string> = {
  user: 'badge bg-white/5 text-slate-400 border border-white/10',
  admin: 'badge-info',
  super_admin: 'badge bg-violet-500/15 text-violet-200 border border-violet-400/35',
}

export function useUserRoleLabel() {
  function label(role: UserRole): string {
    return LABELS[role]
  }

  function badgeClass(role: UserRole): string {
    return BADGE_CLASS[role]
  }

  return { label, badgeClass, LABELS, BADGE_CLASS }
}
