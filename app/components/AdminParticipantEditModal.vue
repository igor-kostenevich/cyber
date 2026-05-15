<script setup lang="ts">
import type { Participant } from '~/types'

interface Props {
  open: boolean
  participant: Participant | null
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:open': [value: boolean]
  saved: []
}>()

const participants = useParticipantsStore()

const form = reactive({
  nickname: '',
  real_name: '',
  comment: '',
})

const submitting = ref(false)
const error = ref<string | null>(null)

watch(
  () => [props.open, props.participant],
  () => {
    if (props.open && props.participant) {
      form.nickname = props.participant.nickname
      form.real_name = props.participant.real_name ?? ''
      form.comment = props.participant.comment ?? ''
      error.value = null
    }
  },
  { immediate: true },
)

const close = () => emit('update:open', false)

const onSubmit = async () => {
  if (!props.participant) return
  if (!form.nickname.trim()) {
    error.value = 'Нікнейм обовʼязковий'
    return
  }
  submitting.value = true
  error.value = null
  try {
    await participants.updateOne(props.participant.id, {
      nickname: form.nickname.trim(),
      real_name: form.real_name.trim() || null,
      comment: form.comment.trim() || null,
    })
    emit('saved')
    close()
  }
  catch (e) {
    error.value = e instanceof Error ? e.message : 'Не вдалося зберегти'
  }
  finally {
    submitting.value = false
  }
}
</script>

<template>
  <BaseModal
    :open="open"
    title="Редагувати учасника"
    size="md"
    @update:open="(v) => $emit('update:open', v)"
    @close="close"
  >
    <form
      class="space-y-4"
      @submit.prevent="onSubmit"
    >
      <div>
        <label class="label">Нікнейм*</label>
        <input
          v-model="form.nickname"
          class="input"
          required
          maxlength="64"
        >
      </div>
      <div>
        <label class="label">Імʼя</label>
        <input
          v-model="form.real_name"
          class="input"
          maxlength="128"
        >
      </div>
      <div>
        <label class="label">Коментар</label>
        <textarea
          v-model="form.comment"
          rows="3"
          class="input resize-none"
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
          Зберегти
        </BaseButton>
      </div>
    </form>
  </BaseModal>
</template>
