export type UserRole = 'user' | 'admin' | 'super_admin'
export type UserStatus = 'pending' | 'approved' | 'blocked'
export type ActivityType = 'server_boss' | 'gvg' | 'rb_boss' | 'craft'
export type ActivityAwardMode = 'main' | 'main_with_twin' | 'twin_only'
export type RewardRequestStatus = 'pending' | 'waiting' | 'completed' | 'rejected'

export type HistoryType =
  | 'points_award'
  | 'points_spend'
  | 'reward_grant'
  | 'reward_request'
  | 'stock_add'
  | 'user_register'
  | 'user_approve'
  | 'user_status'
  | 'role_change'
  | 'reward_update'

export interface Profile {
  id: string
  nickname: string
  display_name: string | null
  comment: string | null
  role: UserRole
  status: UserStatus
  points_balance: number
  profession: number | null
  created_at: string
}

export interface ProfileTwin {
  id: string
  profile_id: string
  nickname: string
  profession: number | null
  created_at: string
}

export interface TwinDraft {
  nickname: string
  profession: number | null
}

export interface ActivityAwardParticipant {
  profileId: string
  includeMain: boolean
  twinIds: string[]
}

export interface Activity {
  id: string
  type: ActivityType
  points: number
  description: string | null
  activity_date: string
  created_by: string | null
  created_at: string
}

export interface ActivityParticipant {
  id: string
  activity_id: string
  profile_id: string
  points_awarded: number
  created_at: string
}

export interface Reward {
  id: string
  key: string
  name: string
  image_url: string | null
  price_points: number
  price_checks: number
  stock: number
  is_available: boolean
  sort_order: number
  created_at: string
}

export interface RewardRequest {
  id: string
  profile_id: string
  reward_id: string
  price_points: number
  quantity: number
  status: RewardRequestStatus
  created_at: string
  resolved_at: string | null
  resolved_by: string | null
}

export interface HistoryEntry {
  id: string
  type: HistoryType
  actor_id: string | null
  profile_id: string | null
  reward_id: string | null
  activity_id: string | null
  points: number | null
  amount: number | null
  description: string | null
  created_at: string
}

export interface RegisterPayload {
  nickname: string
  password: string
  display_name?: string
  comment?: string
  profession?: number | null
  twins?: TwinDraft[]
}

export interface TabItem {
  id: string
  label: string
  badge?: number
}

export interface LeaderboardRow {
  profile_id: string
  nickname: string
  display_name: string | null
  role: UserRole
  total_points: number
  month_points: number
  events_count: number
  rank: number
  profession: number | null
}

export interface RewardRequestView extends RewardRequest {
  profile?: Pick<Profile, 'id' | 'nickname' | 'display_name' | 'points_balance' | 'profession'> | null
  reward?: Pick<Reward, 'id' | 'name' | 'image_url' | 'stock' | 'price_points'> | null
}

export interface HistoryEntryView extends HistoryEntry {
  actor?: { nickname: string } | null
  subject?: { nickname: string, profession?: number | null } | null
  reward?: Pick<Reward, 'name' | 'image_url'> | null
}
