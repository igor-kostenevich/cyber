<script setup lang="ts">
import type { TwinDraft } from '~/types/activity'
import { PROFESSIONS } from '~/composables/useProfessions'

interface Props {
  remote?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  remote: false,
})

const localTwins = defineModel<TwinDraft[]>({ default: () => [] })

const twins = useTwinsStore()
const { getMessage } = useSupabaseErrorMessage()

const draft = reactive<TwinDraft>({ nickname: '', profession: null })
const busy = ref(false)
const error = ref<string | null>(null)

const list = computed(() =>
  props.remote
    ? twins.mine
    : localTwins.value.map((t, index) => ({
        id: `local-${index}`,
        profile_id: '',
        nickname: t.nickname,
        profession: t.profession,
        created_at: '',
      })),
)

onMounted(() => {
  if (props.remote) void twins.fetchMine()
})

const addTwin = async () => {
  const nick = draft.nickname.trim()
  if (!nick) return
  if (!draft.profession) {
    error.value = 'Оберіть клас твінка'
    return
  }

  error.value = null
  busy.value = true
  try {
    if (props.remote) {
      await twins.add(nick, draft.profession)
    }
    else {
      if (localTwins.value.some((t) => t.nickname.toLowerCase() === nick.toLowerCase())) {
        error.value = 'Такий твінк уже додано'
        return
      }
      localTwins.value = [...localTwins.value, { nickname: nick, profession: draft.profession }]
    }
    draft.nickname = ''
    draft.profession = null
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

  localTwins.value = localTwins.value.filter((t) => t.nickname !== nickname)
}

const updateTwinProfession = async (twinId: string, profession: number | null) => {
  if (!props.remote) return
  try {
    await twins.updateProfession(twinId, profession)
  }
  catch (e) {
    error.value = getMessage(e, 'Не вдалося оновити профу')
  }
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
    </div>

    <p class="text-xs text-slate-500 leading-relaxed">
      Додайте альтернативних персонажів. За участь твінком у деяких івентах основний
      персонаж може отримати додаткові 20% Cyber-кредитів.
    </p>

    <div
      v-if="list.length"
      class="flex flex-wrap gap-2"
    >
      <div
        v-for="t in list"
        :key="t.id"
        class="inline-flex items-center gap-1.5 rounded-md border border-slate-600/40 bg-slate-800/50 px-2 py-1 text-xs text-slate-300"
      >
        <ProfessionIcon
          :profession="t.profession"
          size="xs"
        />
        <span class="font-display text-slate-200">{{ t.nickname }}</span>
        <select
          v-if="remote"
          class="bg-transparent text-[10px] text-slate-400 outline-none cursor-pointer hover:text-slate-200 transition-colors ml-0.5"
          :value="t.profession ?? ''"
          @change="updateTwinProfession(t.id, ($event.target as HTMLSelectElement).value ? Number(($event.target as HTMLSelectElement).value) : null)"
        >
          <option value="">—</option>
          <option
            v-for="prof in PROFESSIONS"
            :key="prof.id"
            :value="prof.id"
          >
            {{ prof.name }}
          </option>
        </select>
        <button
          type="button"
          class="text-slate-500 hover:text-rose-300 transition-colors ml-0.5"
          :disabled="busy"
          aria-label="Видалити твінка"
          @click="removeTwin(t.id, t.nickname)"
        >
          ×
        </button>
      </div>
    </div>

    <div class="space-y-2">
      <div class="flex items-center gap-2">
        <input
          v-model="draft.nickname"
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
          :disabled="busy || !draft.nickname.trim()"
          title="Додати твінка"
          @click="addTwin"
        >
          +
        </button>
      </div>

      <div class="grid grid-cols-2 gap-1.5">
        <button
          v-for="prof in PROFESSIONS"
          :key="prof.id"
          type="button"
          class="flex items-center gap-2 px-2.5 py-1.5 rounded-lg border text-xs transition-all"
          :class="draft.profession === prof.id
            ? 'bg-cyan-500/20 border-cyan-400/50 text-cyan-100'
            : 'glass border-white/8 text-slate-500 hover:border-white/20 hover:text-slate-300'"
          @click="draft.profession = draft.profession === prof.id ? null : prof.id"
        >
          <img
            :src="prof.icon"
            :alt="prof.name"
            class="h-4 w-4 object-contain shrink-0"
          >
          <span>{{ prof.name }}</span>
        </button>
      </div>
      <p class="text-[10px] text-slate-500">
        Клас твінка <span class="text-rose-400">*</span>
      </p>
    </div>

    <p
      v-if="error"
      class="text-xs text-rose-300"
    >
      {{ error }}
    </p>
  </div>
</template>
