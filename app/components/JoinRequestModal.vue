<script setup lang="ts">
import type { JoinRequestPayload } from '~/types'

interface Props {
  open: boolean
}

defineProps<Props>()

const emit = defineEmits<{
  'update:open': [value: boolean]
  submitted: []
}>()

const participants = useParticipantsStore()
const { getMessage } = useSupabaseErrorMessage()

const form = reactive<JoinRequestPayload>({
  nickname: '',
  real_name: '',
})

const submitting = ref<boolean>(false)
const error = ref<string | null>(null)
const success = ref<boolean>(false)

const resetFormFields = (): void => {
  form.nickname = ''
  form.real_name = ''
}

const resetAll = (): void => {
  resetFormFields()
  error.value = null
  success.value = false
}

const close = (): void => {
  emit('update:open', false)
  setTimeout(resetAll, 300)
}

const onSubmit = async (): Promise<void> => {
  if (!form.nickname.trim()) {
    error.value = 'Нікнейм обовʼязковий'
    return
  }

  submitting.value = true
  error.value = null

  try {
    await participants.requestJoin({
      nickname: form.nickname,
      real_name: form.real_name,
    })
    resetFormFields()
    success.value = true
    emit('submitted')
  }
  catch (e) {
    console.error('[JoinRequestModal] Не вдалося створити заявку:', e)
    error.value = getMessage(e, 'Не вдалося надіслати заявку. Спробуйте ще раз.')
  }
  finally {
    submitting.value = false
  }
}
</script>

<template>
  <BaseModal
    :open="open"
    title="Подати заявку"
    description="Залиш свій нік — адмін підтвердить, і ти зʼявишся у списку."
    size="md"
    @update:open="(v) => $emit('update:open', v)"
    @close="close"
  >
    <form
      v-if="!success"
      class="space-y-4"
      @submit.prevent="onSubmit"
    >
      <div>
        <label class="label">Нікнейм*</label>
        <input
          v-model="form.nickname"
          class="input"
          placeholder="Наприклад: NeonRunner"
          maxlength="64"
          required
        >
      </div>

      <div>
        <label class="label">Імʼя / як до тебе звертатись</label>
        <input
          v-model="form.real_name"
          class="input"
          placeholder="Необовʼязково"
          maxlength="128"
        >
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
          Відправити заявку
        </BaseButton>
      </div>
    </form>

    <div
      v-else
      class="text-center py-4 space-y-3"
    >
      <div class="mx-auto h-14 w-14 rounded-full bg-emerald-500/15 border border-emerald-400/40 grid place-items-center shadow-glow">
        <svg
          width="28"
          height="28"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2.5"
          class="text-emerald-300"
        >
          <polyline points="20 6 9 17 4 12" />
        </svg>
      </div>
      <h4 class="font-display text-lg text-emerald-200">
        Заявку надіслано
      </h4>
      <p class="text-sm text-slate-400">
        Чекай підтвердження від адміна — ти зʼявишся у списку учасників.
      </p>
      <div class="pt-2">
        <BaseButton @click="close">
          Готово
        </BaseButton>
      </div>
    </div>
  </BaseModal>
</template>
