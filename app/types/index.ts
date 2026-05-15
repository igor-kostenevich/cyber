export type ParticipantStatus = 'pending' | 'approved' | 'rejected'

export interface Participant {
  id: string
  nickname: string
  real_name: string | null
  comment: string | null
  status: ParticipantStatus
  created_at: string
}

export interface SealEntry {
  id: string
  participant_id: string
  entry_date: string
  seals_count: number
  closed_count: number
  comment: string | null
  created_at: string
}

export interface AppSettings {
  id: number
  target_seals: number
  title: string
  clan_name: string
  logo_url: string | null
}

export interface ParticipantStats {
  total: number
  closed: number
  unclosed: number
  entriesCount: number
  lastEntryDate: string | null
}

export interface ProgressSummary {
  target: number
  collected: number
  remaining: number
  percent: number
  approvedCount: number
  withDebtCount: number
}

export interface AuthUser {
  id: string
  email: string | null
}

export type AsyncStateStatus = 'idle' | 'loading' | 'success' | 'error'

export interface JoinRequestPayload {
  nickname: string
  real_name: string
  comment?: string
}

export interface EntryFormPayload {
  participant_id: string
  entry_date: string
  seals_count: number
  closed_count: number
  comment: string
}
