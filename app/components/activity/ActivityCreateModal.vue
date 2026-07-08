<script setup lang="ts">
import type { ActivityAwardParticipant, ActivityType, Profile } from '~/types/activity'

interface Props {
  open: boolean
  type: ActivityType | null
  players: Profile[]
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'update:open': [value: boolean]
  'created': []
}>()

const activities = useActivitiesStore()
const { get } = useActivityTypes()
const { today } = useDateFormat()
const { formatPoints, parsePointsInput, pointsWord } = useFormatPoints()
const { calculateParticipantPoints } = useActivityAward()
const { getMessage } = useSupabaseErrorMessage()

const date = ref(today())
const description = ref('')
const pointsInput = ref('')
const participants = ref<ActivityAwardParticipant[]>([])
const submitting = ref(false)
const error = ref<string | null>(null)

const config = computed(() => (props.type ? get(props.type) : null))

const pointsValue = computed(() => parsePointsInput(pointsInput.value))

const modalDescription = computed(() => {
  if (!config.value || pointsValue.value == null) return ''
  return `${config.value.label} · база ${formatPoints(pointsValue.value)} ${pointsWord(pointsValue.value)}`
})

watch(
  () => props.open,
  (open) => {
    if (open && props.type) {
      date.value = today()
      description.value = ''
      participants.value = []
      error.value = null
      pointsInput.value = formatPoints(get(props.type).points)
    }
  },
)

watch(
  () => props.type,
  (type) => {
    if (type && props.open) {
      pointsInput.value = formatPoints(get(type).points)
    }
  },
)

const validateParticipants = (): string | null => {
  if (participants.value.length === 0) return 'Оберіть хоча б одного гравця'

  const twins = useTwinsStore()
  for (const p of participants.value) {
    if (!p.includeMain && p.twinIds.length === 0) {
      return 'Для кожного гравця оберіть основного або твінків'
    }

    for (const twinId of p.twinIds) {
      const twin = twins.getForProfile(p.profileId).find((t) => t.id === twinId)
      if (!twin) return 'Обраний твінк не належить гравцю'
    }
  }
  return null
}

const close = () => emit('update:open', false)

const onSubmit = async () => {
  if (!props.type) return
  if (pointsValue.value == null) {
    error.value = 'Введіть коректну кількість CR (до десятих, напр. 3.5)'
    return
  }

  const participantError = validateParticipants()
  if (participantError) {
    error.value = participantError
    return
  }

  submitting.value = true
  error.value = null
  try {
    await activities.create({
      type: props.type,
      date: date.value,
      description: description.value,
      participants: participants.value,
      points: pointsValue.value,
    })
    emit('created')
    close()
  }
  catch (e) {
    error.value = getMessage(e, 'Не вдалося нарахувати Cyber-кредити')
  }
  finally {
    submitting.value = false
  }
}

const estimatedTotal = computed(() => {
  if (pointsValue.value == null) return 0
  return participants.value.reduce(
    (sum, p) => sum + calculateParticipantPoints(pointsValue.value!, p),
    0,
  )
})
</script>

<template>
  <BaseModal
    :open="open"
    size="lg"
    :title="config?.quickLabel ?? 'Нова активність'"
    :description="modalDescription"
    @update:open="emit('update:open', $event)"
  >
    <div class="space-y-4">
      <div class="grid gap-4 sm:grid-cols-3">
        <div>
          <label class="label">Дата</label>
          <input
            v-model="date"
            type="date"
            class="input"
          >
        </div>
        <div>
          <label class="label">Бали за івент</label>
          <input
            v-model="pointsInput"
            type="number"
            min="0"
            step="0.1"
            inputmode="decimal"
            class="input"
            placeholder="3.5"
          >
        </div>
        <div>
          <label class="label">Опис (необов'язково)</label>
          <input
            v-model="description"
            type="text"
            class="input"
            maxlength="200"
            placeholder="Напр. ГВГ проти Invictus"
          >
        </div>
      </div>

      <div>
        <label class="label">Учасники</label>
        <ActivityParticipantSelector
          v-if="type"
          v-model="participants"
          :players="players"
          :activity-type="type"
        />
      </div>

      <p
        v-if="participants.length > 0 && pointsValue != null"
        class="text-xs text-slate-500"
      >
        Разом до нарахування:
        <CyberPoints
          :value="estimatedTotal"
          show-word
          icon-size="xs"
          class="inline-flex ml-1"
        />
      </p>

      <div
        v-if="error"
        class="text-sm text-rose-300 bg-rose-500/10 border border-rose-400/30 rounded-lg px-3 py-2"
      >
        {{ error }}
      </div>
    </div>

    <template #footer>
      <BaseButton
        variant="ghost"
        @click="close"
      >
        Скасувати
      </BaseButton>
      <BaseButton
        :loading="submitting"
        @click="onSubmit"
      >
        Нарахувати ({{ participants.length }})
      </BaseButton>
    </template>
  </BaseModal>
</template>
