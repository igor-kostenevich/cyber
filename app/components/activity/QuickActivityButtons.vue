<script setup lang="ts">
import type { ActivityType } from '~/types/activity'

interface Props {
  editable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  editable: false,
})

const emit = defineEmits<{ select: [type: ActivityType] }>()

const settings = useActivitySettingsStore()
const { list } = useActivityTypes()
const { formatPoints, parsePointsInput } = useFormatPoints()
const { getMessage } = useSupabaseErrorMessage()

const draftPoints = ref<Partial<Record<ActivityType, string | number>>>({})
const focusedType = ref<ActivityType | null>(null)
const savingType = ref<ActivityType | null>(null)
const savedType = ref<ActivityType | null>(null)
const saveError = ref<string | null>(null)

let savedFlashTimer: ReturnType<typeof setTimeout> | null = null

const syncDraftFromSettings = () => {
  for (const item of list.value) {
    if (item.type === focusedType.value || savingType.value === item.type) continue
    draftPoints.value[item.type] = formatPoints(item.points)
  }
}

watch(
  () => settings.pointsByType,
  () => syncDraftFromSettings(),
  { deep: true },
)

watch(
  () => settings.hasLoaded,
  (loaded) => {
    if (loaded) syncDraftFromSettings()
  },
  { immediate: true },
)

const flashSaved = (type: ActivityType) => {
  savedType.value = type
  if (savedFlashTimer) clearTimeout(savedFlashTimer)
  savedFlashTimer = setTimeout(() => {
    if (savedType.value === type) savedType.value = null
  }, 1800)
}

const savePoints = async (type: ActivityType) => {
  saveError.value = null

  const parsed = parsePointsInput(draftPoints.value[type])
  if (parsed == null) {
    saveError.value = 'Введіть коректну кількість CR'
    draftPoints.value[type] = formatPoints(settings.getPoints(type))
    return
  }

  draftPoints.value[type] = formatPoints(parsed)

  if (parsed === settings.getPoints(type)) {
    flashSaved(type)
    return
  }

  savingType.value = type
  try {
    await settings.update(type, parsed)
    flashSaved(type)
  }
  catch (e) {
    saveError.value = getMessage(e, 'Не вдалося зберегти Cyber-кредити')
    draftPoints.value[type] = formatPoints(settings.getPoints(type))
  }
  finally {
    savingType.value = null
  }
}

const onPointsFocus = (type: ActivityType) => {
  focusedType.value = type
  saveError.value = null
}

const onPointsBlur = (type: ActivityType) => {
  if (!props.editable) return
  focusedType.value = null
  void savePoints(type)
}

const onPointsChange = (type: ActivityType) => {
  if (!props.editable) return
  void savePoints(type)
}

const onPointsKeydown = (event: KeyboardEvent, type: ActivityType) => {
  if (event.key === 'Enter') {
    event.preventDefault()
    ;(event.target as HTMLInputElement).blur()
  }
}
</script>

<template>
  <div class="space-y-2">
    <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
      <div
        v-for="t in list"
        :key="t.type"
        class="card-cyber p-4 transition-all duration-200 hover:-translate-y-1 hover:shadow-glow"
      >
        <div class="flex items-center justify-between gap-2">
          <button
            type="button"
            class="flex min-w-0 flex-1 items-center gap-3 text-left"
            @click="emit('select', t.type)"
          >
            <span class="text-2xl shrink-0">{{ t.emoji }}</span>
            <span class="font-display text-sm text-cyan-100 truncate">
              {{ t.quickLabel }}
            </span>
          </button>

          <span
            v-if="!editable"
            class="badge text-xs shrink-0"
            :class="t.accent"
          >+<CyberPoints
            :value="t.points"
            icon-size="xs"
            class="inline-flex"
          /></span>
          <div
            v-else
            class="relative shrink-0"
          >
            <input
              v-model="draftPoints[t.type]"
              type="number"
              min="0"
              step="0.1"
              inputmode="decimal"
              class="input w-20 py-1 px-2 text-xs text-right transition-colors"
              :class="[
                t.accent,
                savedType === t.type ? 'ring-1 ring-emerald-400/60' : '',
              ]"
              :disabled="savingType === t.type"
              @focus="onPointsFocus(t.type)"
              @keydown="onPointsKeydown($event, t.type)"
              @change="onPointsChange(t.type)"
              @blur="onPointsBlur(t.type)"
            >
            <span
              v-if="savedType === t.type"
              class="absolute -bottom-4 right-0 text-[9px] text-emerald-300 whitespace-nowrap"
            >
              Збережено
            </span>
          </div>
        </div>
      </div>
    </div>

    <p
      v-if="editable"
      class="text-xs text-slate-500"
    >
      Змініть CR на картці — збережеться при виході з поля, Enter або зміні значення.
    </p>

    <p
      v-if="settings.error && editable"
      class="text-xs text-amber-300"
    >
      Налаштування не завантажились з бази: {{ settings.error }}.
      Виконайте міграції Supabase і оновіть сторінку.
    </p>

    <p
      v-if="saveError"
      class="text-xs text-rose-300"
    >
      {{ saveError }}
    </p>
  </div>
</template>
