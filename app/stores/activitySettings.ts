import { defineStore } from 'pinia'
import type { RealtimeChannel } from '@supabase/supabase-js'
import { roundPoints } from '~/composables/useFormatPoints'
import type { AsyncStateStatus } from '~/types'
import type { ActivityType } from '~/types/activity'

const FALLBACK_POINTS: Record<ActivityType, number> = {
  gvg: 3,
  rb_boss: 2,
  server_boss: 3,
  craft: 1,
}

const DEFAULT_TWIN_BONUS: Record<ActivityType, boolean> = {
  gvg: true,
  rb_boss: true,
  server_boss: false,
  craft: false,
}

function mergeSettingsRows(
  rows: Array<{ type: string, points: number | string, twin_bonus_enabled?: boolean | null }> | null | undefined,
): {
  points: Record<ActivityType, number>
  twinBonus: Record<ActivityType, boolean>
} {
  const points = { ...FALLBACK_POINTS }
  const twinBonus = { ...DEFAULT_TWIN_BONUS }
  for (const row of rows ?? []) {
    const type = row.type as ActivityType
    if (type in points) {
      points[type] = Number(row.points)
      if (row.twin_bonus_enabled != null) {
        twinBonus[type] = Boolean(row.twin_bonus_enabled)
      }
    }
  }
  return { points, twinBonus }
}

export const useActivitySettingsStore = defineStore('activitySettings', () => {
  const pointsByType = ref<Record<ActivityType, number>>({ ...FALLBACK_POINTS })
  const twinBonusByType = ref<Record<ActivityType, boolean>>({ ...DEFAULT_TWIN_BONUS })
  const status = ref<AsyncStateStatus>('idle')
  const error = ref<string | null>(null)

  let realtimeChannel: RealtimeChannel | null = null

  const isLoading = computed(() => status.value === 'loading')
  const hasLoaded = computed(() => status.value === 'success' || status.value === 'error')

  function getPoints(type: ActivityType): number {
    return pointsByType.value[type] ?? FALLBACK_POINTS[type]
  }

  function getTwinBonusEnabled(type: ActivityType): boolean {
    return twinBonusByType.value[type] ?? DEFAULT_TWIN_BONUS[type] ?? false
  }

  function setPoint(type: ActivityType, points: number) {
    pointsByType.value = {
      ...pointsByType.value,
      [type]: roundPoints(points),
    }
  }

  async function fetch(options?: { silent?: boolean }) {
    const client = useAppSupabaseClient()
    if (!options?.silent) {
      status.value = 'loading'
      error.value = null
    }

    try {
      const { data, error: err } = await client
        .from('activity_type_settings')
        .select('type, points, twin_bonus_enabled')

      if (err) throw err

      const merged = mergeSettingsRows(data)
      pointsByType.value = merged.points
      twinBonusByType.value = merged.twinBonus
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити налаштування Cyber-кредитів'
      if (!options?.silent) status.value = 'error'
    }
  }

  async function update(type: ActivityType, points: number) {
    const client = useAppSupabaseClient()
    const normalized = roundPoints(points)

    const { error: upsertErr } = await client
      .from('activity_type_settings')
      .upsert({ type, points: normalized }, { onConflict: 'type' })

    if (upsertErr) {
      const { error: rpcErr } = await client.rpc('update_activity_type_points', {
        p_type: type,
        p_points: normalized,
      })
      if (rpcErr) throw rpcErr
    }

    setPoint(type, normalized)
  }

  function startRealtime() {
    if (realtimeChannel) return

    const client = useAppSupabaseClient()
    const applyRemote = (row: {
      type?: string
      points?: number | string
      twin_bonus_enabled?: boolean | null
    }) => {
      const type = row.type as ActivityType | undefined
      if (!type || !(type in FALLBACK_POINTS)) return
      if (row.points != null) setPoint(type, Number(row.points))
      if (row.twin_bonus_enabled != null) {
        twinBonusByType.value = {
          ...twinBonusByType.value,
          [type]: Boolean(row.twin_bonus_enabled),
        }
      }
    }

    realtimeChannel = client
      .channel('activity-type-settings')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'activity_type_settings' },
        (payload) => applyRemote(payload.new as { type?: string, points?: number | string, twin_bonus_enabled?: boolean | null }),
      )
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'activity_type_settings' },
        (payload) => applyRemote(payload.new as { type?: string, points?: number | string, twin_bonus_enabled?: boolean | null }),
      )
      .subscribe()
  }

  function stopRealtime() {
    realtimeChannel?.unsubscribe()
    realtimeChannel = null
  }

  return {
    pointsByType,
    twinBonusByType,
    status,
    error,
    isLoading,
    hasLoaded,
    getPoints,
    getTwinBonusEnabled,
    setPoint,
    fetch,
    update,
    startRealtime,
    stopRealtime,
  }
})
