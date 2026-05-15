<script setup lang="ts">
import type { EntryFormPayload, Participant, SealEntry } from '~/types'

interface Props {
  open: boolean
  entry?: SealEntry | null
  preselectedParticipantId?: string | null
}

const props = withDefaults(defineProps<Props>(), {
  entry: null,
  preselectedParticipantId: null,
})

const emit = defineEmits<{
  'update:open': [value: boolean]
  saved: []
}>()

const participants = useParticipantsStore()
const entries = useEntriesStore()
const { today } = useDateFormat()

const approvedList = computed<Participant[]>(() => participants.approved)

const form = reactive<EntryFormPayload>({
  participant_id: '',
  entry_date: today(),
  seals_count: 0,
  closed_count: 0,
  comment: '',
})

const submitting = ref(false)
const error = ref<string | null>(null)

const isEditMode = computed(() => props.entry !== null)

watch(
  () => [props.open, props.entry, props.preselectedParticipantId],
  () => {
    if (!props.open) return
    if (props.entry) {
      form.participant_id = props.entry.participant_id
      form.entry_date = props.entry.entry_date
      form.seals_count = props.entry.seals_count
      form.closed_count = props.entry.closed_count
      form.comment = props.entry.comment ?? ''
    }
    else {
      form.participant_id = props.preselectedParticipantId ?? approvedList.value[0]?.id ?? ''
      form.entry_date = today()
      form.seals_count = 0
      form.closed_count = 0
      form.comment = ''
    }
    error.value = null
  },
  { immediate: true },
)

const close = () => emit('update:open', false)

const onSubmit = async () => {
  if (!form.participant_id) {
    error.value = 'Оберіть учасника'
    return
  }
  if (form.seals_count < 0 || form.closed_count < 0) {
    error.value = 'Кількість не може бути відʼємною'
    return
  }
  if (form.closed_count > form.seals_count) {
    error.value = 'Закрито не може перевищувати загалом'
    return
  }
  submitting.value = true
  error.value = null
  try {
    if (props.entry) {
      await entries.update(props.entry.id, {
        participant_id: form.participant_id,
        entry_date: form.entry_date,
        seals_count: form.seals_count,
        closed_count: form.closed_count,
        comment: form.comment.trim() || null,
      })
    }
    else {
      await entries.create({ ...form })
    }
    emit('saved')
    close()
  }
  catch (e) {
    error.value = e instanceof Error ? e.message : 'Не вдалося зберегти запис'
  }
  finally {
    submitting.value = false
  }
}
</script>

<template>
  <BaseModal
    :open="open"
    :title="isEditMode ? 'Редагувати запис' : 'Новий запис'"
    size="md"
    @update:open="(v) => $emit('update:open', v)"
    @close="close"
  >
    <form
      class="space-y-4"
      @submit.prevent="onSubmit"
    >
      <div>
        <label class="label">Учасник</label>
        <select
          v-model="form.participant_id"
          class="input"
          required
        >
          <option
            value=""
            disabled
          >
            — оберіть учасника —
          </option>
          <option
            v-for="p in approvedList"
            :key="p.id"
            :value="p.id"
          >
            {{ p.nickname }}{{ p.real_name ? ` · ${p.real_name}` : '' }}
          </option>
        </select>
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label">Дата</label>
          <input
            v-model="form.entry_date"
            type="date"
            class="input"
            required
          >
        </div>
        <div class="flex items-end" />
      </div>

      <div class="grid grid-cols-2 gap-3">
        <div>
          <label class="label">Зібрано печаток</label>
          <input
            v-model.number="form.seals_count"
            type="number"
            min="0"
            class="input"
            required
          >
        </div>
        <div>
          <label class="label">З них закрито</label>
          <input
            v-model.number="form.closed_count"
            type="number"
            min="0"
            class="input"
            required
          >
        </div>
      </div>

      <div>
        <label class="label">Коментар</label>
        <textarea
          v-model="form.comment"
          rows="2"
          class="input resize-none"
          placeholder="Необовʼязково"
          maxlength="500"
        />
      </div>

      <div
        v-if="error"
        class="text-sm text-rose-300 bg-rose-500/10 border border-rose-400/30 rounded-lg px-3 py-2"
      >
        {{ error }}
      </div>

      <div class="flex items-center justify-end gap-2 pt-2">
        <BaseButton
          variant="ghost"
          @click="close"
        >
          Скасувати
        </BaseButton>
        <BaseButton
          type="submit"
          :loading="submitting"
        >
          {{ isEditMode ? 'Зберегти' : 'Додати запис' }}
        </BaseButton>
      </div>
    </form>
  </BaseModal>
</template>
