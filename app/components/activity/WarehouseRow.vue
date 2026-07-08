<script setup lang="ts">
import type { Reward } from '~/types/activity'

interface Props {
  reward: Reward
}

const props = defineProps<Props>()
const emit = defineEmits<{ deleted: [] }>()

const rewards = useRewardsStore()
const { upload } = useRewardImageUpload()
const { getMessage } = useSupabaseErrorMessage()

const name = ref(props.reward.name)
const stockDelta = ref<number | null>(null)
const pricePoints = ref(props.reward.price_points)
const isAvailable = ref(props.reward.is_available)
const imageUrl = ref(props.reward.image_url)

const busy = ref(false)
const uploading = ref(false)
const saved = ref(false)
const error = ref<string | null>(null)

const fileInput = ref<HTMLInputElement | null>(null)
let savedTimer: ReturnType<typeof setTimeout> | null = null

const stockBadgeClass = computed(() =>
  props.reward.stock > 0
    ? 'bg-emerald-500/20 text-emerald-200 border-emerald-400/50'
    : 'bg-rose-500/20 text-rose-200 border-rose-400/50',
)

watch(
  () => props.reward,
  (r) => {
    name.value = r.name
    pricePoints.value = r.price_points
    isAvailable.value = r.is_available
    imageUrl.value = r.image_url
  },
)

const showSaved = () => {
  if (savedTimer) clearTimeout(savedTimer)
  saved.value = true
  savedTimer = setTimeout(() => {
    saved.value = false
    savedTimer = null
  }, 1800)
}

const onPickImage = () => fileInput.value?.click()

const onFileChange = async (e: Event) => {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return

  uploading.value = true
  error.value = null
  try {
    const url = await upload(props.reward.id, file)
    await rewards.updateReward(props.reward.id, { image_url: url })
    imageUrl.value = url
    showSaved()
  }
  catch (err) {
    error.value = getMessage(err, 'Не вдалося завантажити зображення')
  }
  finally {
    uploading.value = false
    if (fileInput.value) fileInput.value.value = ''
  }
}

const save = async () => {
  busy.value = true
  saved.value = false
  error.value = null
  try {
    const trimmed = name.value.trim()
    if (!trimmed) {
      error.value = 'Назва не може бути порожньою'
      return
    }

    const changed
      = trimmed !== props.reward.name
      || pricePoints.value !== props.reward.price_points
      || isAvailable.value !== props.reward.is_available

    if (changed) {
      await rewards.updateReward(props.reward.id, {
        name: trimmed,
        price_points: pricePoints.value,
        is_available: isAvailable.value,
      })
    }
    if (stockDelta.value && stockDelta.value !== 0) {
      await rewards.adjustStock(props.reward.id, stockDelta.value)
      stockDelta.value = null
    }
    showSaved()
  }
  catch (e) {
    error.value = getMessage(e, 'Не вдалося зберегти')
  }
  finally {
    busy.value = false
  }
}

const remove = async () => {
  if (!confirm(`Видалити «${props.reward.name}»? Цю дію не можна скасувати.`)) return

  busy.value = true
  error.value = null
  try {
    await rewards.deleteReward(props.reward.id)
    emit('deleted')
  }
  catch (e) {
    error.value = getMessage(e, 'Не вдалося видалити')
  }
  finally {
    busy.value = false
  }
}

onBeforeUnmount(() => {
  if (savedTimer) clearTimeout(savedTimer)
})
</script>

<template>
  <li class="glass rounded-xl p-4">
    <div class="flex flex-col gap-4 xl:flex-row xl:items-end xl:gap-5">
      <!-- Фото + бейдж кількості -->
      <div class="shrink-0">
        <label class="label">Склад</label>
        <div class="flex items-center gap-2">
          <button
            type="button"
            class="relative block h-[2.625rem] w-[2.625rem] shrink-0 rounded-xl overflow-hidden bg-ink-800/60 border border-white/10 hover:border-cyan-400/40 transition-colors disabled:opacity-50"
            title="Завантажити зображення"
            :disabled="uploading || busy"
            @click="onPickImage"
          >
            <img
              v-if="imageUrl"
              :src="imageUrl"
              :alt="reward.name"
              class="absolute inset-0 h-full w-full object-cover object-center"
              loading="lazy"
            >
            <span
              v-else
              class="absolute inset-0 grid place-items-center text-lg opacity-60"
            >🎁</span>

            <span
              v-if="uploading"
              class="absolute inset-0 grid place-items-center bg-ink-900/70 text-xs text-cyan-200"
            >…</span>
          </button>

          <span
            class="inline-flex min-w-[2.5rem] h-[2.625rem] px-2 items-center justify-center rounded-xl border text-sm font-bold tabular-nums"
            :class="stockBadgeClass"
            :title="`На складі: ${reward.stock}`"
          >
            {{ reward.stock }}
          </span>
        </div>
        <input
          ref="fileInput"
          type="file"
          accept="image/jpeg,image/png,image/webp,image/gif"
          class="hidden"
          @change="onFileChange"
        >
      </div>

      <!-- Назва -->
      <div class="flex-1 min-w-0">
        <label
          class="label"
          :for="`reward-name-${reward.id}`"
        >Назва</label>
        <input
          :id="`reward-name-${reward.id}`"
          v-model="name"
          type="text"
          class="input py-2 text-sm"
          placeholder="Назва нагороди"
        >
      </div>

      <!-- Поля -->
      <div class="flex flex-wrap items-end gap-3">
        <div class="w-[5.5rem]">
          <label class="label">Зміна</label>
          <input
            v-model.number="stockDelta"
            type="number"
            class="input py-2"
            placeholder="±0"
            title="Введіть +10 або -5"
          >
        </div>
        <div class="w-[8.5rem]">
          <label class="label">Ціна (CR)</label>
          <input
            v-model.number="pricePoints"
            type="number"
            min="0"
            class="input py-2"
            title="Ціна в Cyber-кредитах"
          >
        </div>
        <div class="pb-2.5">
          <label class="flex items-center gap-2 text-sm text-slate-300 whitespace-nowrap">
            <input
              v-model="isAvailable"
              type="checkbox"
              class="h-4 w-4 accent-cyan-400"
            >
            Доступна
          </label>
        </div>
      </div>

      <!-- Дії -->
      <div class="flex flex-wrap items-center gap-2 shrink-0 xl:ml-4 xl:pl-4 xl:border-l xl:border-white/10">
        <BaseButton
          variant="ghost"
          :disabled="busy || uploading"
          @click="remove"
        >
          Видалити
        </BaseButton>
        <BaseButton
          class="min-w-[6.75rem]"
          :variant="saved ? 'success' : 'primary'"
          :loading="busy"
          :disabled="uploading || saved"
          @click="save"
        >
          {{ saved ? 'Збережено' : 'Зберегти' }}
        </BaseButton>
      </div>
    </div>

    <div
      v-if="error"
      class="mt-3 text-sm text-rose-300 bg-rose-500/10 border border-rose-400/30 rounded-lg px-3 py-2"
    >
      {{ error }}
    </div>
  </li>
</template>
