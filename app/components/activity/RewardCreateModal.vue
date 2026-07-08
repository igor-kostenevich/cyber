<script setup lang="ts">
interface Props {
  open: boolean
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'update:open': [value: boolean]
  'created': []
}>()

const rewards = useRewardsStore()
const { upload } = useRewardImageUpload()
const { getMessage } = useSupabaseErrorMessage()

const name = ref('')
const pricePoints = ref(1)
const initialStock = ref(0)
const imageFile = ref<File | null>(null)
const imagePreview = ref<string | null>(null)
const submitting = ref(false)
const error = ref<string | null>(null)

const fileInput = ref<HTMLInputElement | null>(null)

watch(
  () => props.open,
  (open) => {
    if (open) {
      name.value = ''
      pricePoints.value = 1
      initialStock.value = 0
      imageFile.value = null
      error.value = null
    }
  },
)

const close = () => emit('update:open', false)

const onPickImage = () => fileInput.value?.click()

const onFileChange = (e: Event) => {
  const file = (e.target as HTMLInputElement).files?.[0] ?? null
  if (imagePreview.value) URL.revokeObjectURL(imagePreview.value)
  imageFile.value = file
  imagePreview.value = file ? URL.createObjectURL(file) : null
}

const onSubmit = async () => {
  const trimmed = name.value.trim()
  if (!trimmed) {
    error.value = 'Введіть назву нагороди'
    return
  }

  submitting.value = true
  error.value = null
  try {
    const id = await rewards.createReward(trimmed, pricePoints.value, initialStock.value)
    if (imageFile.value) {
      const url = await upload(id, imageFile.value)
      await rewards.updateReward(id, { image_url: url })
    }
    emit('created')
    close()
  }
  catch (e) {
    error.value = getMessage(e, 'Не вдалося створити нагороду')
  }
  finally {
    submitting.value = false
  }
}

onBeforeUnmount(() => {
  if (imagePreview.value) URL.revokeObjectURL(imagePreview.value)
})
</script>

<template>
  <BaseModal
    :open="open"
    title="Нова нагорода"
    description="Додайте предмет на склад клану"
    @update:open="emit('update:open', $event)"
  >
    <form
      class="space-y-4"
      @submit.prevent="onSubmit"
    >
      <div class="flex items-start gap-4">
        <button
          type="button"
          class="h-20 w-20 rounded-xl overflow-hidden bg-ink-800/60 grid place-items-center shrink-0 border border-white/10 hover:border-cyan-400/40 transition-colors"
          title="Завантажити зображення"
          @click="onPickImage"
        >
          <img
            v-if="imagePreview"
            :src="imagePreview"
            alt=""
            class="h-full w-full object-cover"
          >
          <span
            v-else
            class="text-2xl opacity-60"
          >📷</span>
        </button>
        <input
          ref="fileInput"
          type="file"
          accept="image/jpeg,image/png,image/webp,image/gif"
          class="hidden"
          @change="onFileChange"
        >

        <div class="flex-1 space-y-3">
          <div>
            <label class="label">Назва</label>
            <input
              v-model="name"
              type="text"
              class="input"
              placeholder="Меч літнього вітру"
              required
            >
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="label">Ціна (CR)</label>
              <input
                v-model.number="pricePoints"
                type="number"
                min="0"
                class="input"
                required
              >
            </div>
            <div>
              <label class="label">На складі</label>
              <input
                v-model.number="initialStock"
                type="number"
                min="0"
                class="input"
              >
            </div>
          </div>
        </div>
      </div>

      <div
        v-if="error"
        class="text-sm text-rose-300 bg-rose-500/10 border border-rose-400/30 rounded-lg px-3 py-2"
      >
        {{ error }}
      </div>

      <div class="flex justify-end gap-2 pt-2">
        <BaseButton
          type="button"
          variant="ghost"
          @click="close"
        >
          Скасувати
        </BaseButton>
        <BaseButton
          type="submit"
          :loading="submitting"
        >
          Додати
        </BaseButton>
      </div>
    </form>
  </BaseModal>
</template>
