<script setup lang="ts">
interface Props {
  remote?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  remote: false,
})

const localTwins = defineModel<string[]>({ default: () => [] })

const twins = useTwinsStore()
const { getMessage } = useSupabaseErrorMessage()

const draft = ref('')
const busy = ref(false)
const error = ref<string | null>(null)

const list = computed(() => (props.remote ? twins.mine : localTwins.value.map((nickname, index) => ({
  id: `local-${index}`,
  nickname,
}))))

onMounted(() => {
  if (props.remote) void twins.fetchMine()
})

const addTwin = async () => {
  const nick = draft.value.trim()
  if (!nick) return

  error.value = null
  busy.value = true
  try {
    if (props.remote) {
      await twins.add(nick)
    }
    else {
      if (localTwins.value.some((t) => t.toLowerCase() === nick.toLowerCase())) {
        error.value = 'Такий твінк уже додано'
        return
      }
      localTwins.value = [...localTwins.value, nick]
    }
    draft.value = ''
  }
  catch (e) {
    error.value = getMessage(e, 'Не вдалося додати твінка')
  }
  finally {
    busy.value = false
  }
}

const removeTwin = async (id: string, nickname: string) => {
  if (props.remote) {
    busy.value = true
    error.value = null
    try {
      await twins.remove(id)
    }
    catch (e) {
      error.value = getMessage(e, 'Не вдалося видалити твінка')
    }
    finally {
      busy.value = false
    }
    return
  }

  localTwins.value = localTwins.value.filter((t) => t !== nickname)
}

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Enter') {
    event.preventDefault()
    void addTwin()
  }
}
</script>

<template>
  <div class="space-y-3">
    <div class="flex items-center justify-between gap-2">
      <label class="label mb-0">Твінки (неосновні персонажі)</label>
      <span class="text-[10px] text-slate-500">лише нік</span>
    </div>

    <p class="text-xs text-slate-500 leading-relaxed">
      Додайте альтернативних персонажів. За участь твінком у деяких івентах основний
      персонаж може отримати додаткові 20% Cyber-кредитів.
    </p>

    <div
      v-if="list.length"
      class="flex flex-wrap gap-2"
    >
      <span
        v-for="t in list"
        :key="t.id"
        class="inline-flex items-center gap-1.5 rounded-md border border-slate-600/40 bg-slate-800/50 px-2 py-1 text-xs text-slate-300"
      >
        <span class="opacity-60">👤</span>
        <span class="font-display text-slate-200">{{ t.nickname }}</span>
        <button
          type="button"
          class="text-slate-500 hover:text-rose-300 transition-colors ml-0.5"
          :disabled="busy"
          aria-label="Видалити твінка"
          @click="removeTwin(t.id, t.nickname)"
        >
          ×
        </button>
      </span>
    </div>

    <div class="flex items-center gap-2">
      <input
        v-model="draft"
        type="text"
        class="input flex-1"
        maxlength="40"
        placeholder="Нік твінка"
        :disabled="busy"
        @keydown="onKeydown"
      >
      <button
        type="button"
        class="btn-ghost px-3 py-2 text-lg leading-none shrink-0"
        :disabled="busy || !draft.trim()"
        title="Додати твінка"
        @click="addTwin"
      >
        +
      </button>
    </div>

    <p
      v-if="error"
      class="text-xs text-rose-300"
    >
      {{ error }}
    </p>
  </div>
</template>
