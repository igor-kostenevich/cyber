<script setup lang="ts">
definePageMeta({
  middleware: 'auth',
})

useHead({ title: 'Адмінка · Cyberpunk' })

type Tab = 'requests' | 'participants' | 'settings'

const participants = useParticipantsStore()
const entries = useEntriesStore()
const settings = useSettingsStore()

const activeTab = ref<Tab>('requests')

const tabs: Array<{ id: Tab, label: string, badge?: () => number }> = [
  { id: 'requests', label: 'Заявки', badge: () => participants.pending.length },
  { id: 'participants', label: 'Учасники', badge: () => participants.approved.length },
  { id: 'settings', label: 'Налаштування' },
]

const refresh = async () => {
  await Promise.all([
    participants.fetchAll(),
    entries.fetchAll(),
    settings.fetch(),
  ])
}

onMounted(() => {
  refresh()
})

const settingsForm = reactive({
  title: '',
  clan_name: '',
  target_seals: 0,
  logo_url: '',
})

watch(
  () => settings.data,
  (data) => {
    if (!data) return
    settingsForm.title = data.title
    settingsForm.clan_name = data.clan_name
    settingsForm.target_seals = data.target_seals
    settingsForm.logo_url = data.logo_url ?? ''
  },
  { immediate: true, deep: true },
)

const savingSettings = ref(false)
const settingsError = ref<string | null>(null)
const settingsSaved = ref(false)

const onSaveSettings = async () => {
  savingSettings.value = true
  settingsError.value = null
  settingsSaved.value = false
  try {
    await settings.update({
      title: settingsForm.title.trim(),
      clan_name: settingsForm.clan_name.trim(),
      target_seals: Number(settingsForm.target_seals) || 0,
      logo_url: settingsForm.logo_url.trim() || null,
    })
    settingsSaved.value = true
    setTimeout(() => (settingsSaved.value = false), 2000)
  }
  catch (e) {
    settingsError.value = e instanceof Error ? e.message : 'Не вдалося зберегти'
  }
  finally {
    savingSettings.value = false
  }
}
</script>

<template>
  <div class="container-page py-8 md:py-10">
    <header class="mb-6">
      <div class="flex items-center justify-between flex-wrap gap-3">
        <div>
          <div class="text-xs uppercase tracking-widest text-cyan-300/80">
            Адмін-панель
          </div>
          <h1 class="font-display text-2xl md:text-3xl text-gradient-cyber">
            Керування трекером
          </h1>
        </div>
      </div>
    </header>

    <nav class="mb-6 flex items-center gap-2 flex-wrap">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        class="px-4 py-2 rounded-xl text-sm font-medium transition-colors flex items-center gap-2"
        :class="
          activeTab === tab.id
            ? 'bg-gradient-to-r from-cyan-500/25 to-blue-500/25 border border-cyan-400/40 text-cyan-100 shadow-glow-sm'
            : 'glass text-slate-300 hover:text-cyan-100 hover:border-cyan-300/30'
        "
        @click="activeTab = tab.id"
      >
        {{ tab.label }}
        <span
          v-if="tab.badge && tab.badge() > 0"
          class="badge-info text-[10px] px-2 py-0"
        >
          {{ tab.badge() }}
        </span>
      </button>
    </nav>

    <div v-if="activeTab === 'requests'">
      <AdminRequests />
    </div>

    <div v-else-if="activeTab === 'participants'">
      <AdminParticipants />
    </div>

    <div
      v-else-if="activeTab === 'settings'"
      class="space-y-4"
    >
      <h2 class="font-display text-xl text-cyan-100">
        Налаштування додатка
      </h2>

      <form
        class="card-cyber p-6 space-y-4 max-w-2xl"
        @submit.prevent="onSaveSettings"
      >
        <div>
          <label class="label">Заголовок</label>
          <input
            v-model="settingsForm.title"
            class="input"
            maxlength="120"
          >
        </div>
        <div>
          <label class="label">Назва клану</label>
          <input
            v-model="settingsForm.clan_name"
            class="input"
            maxlength="60"
          >
        </div>
        <div>
          <label class="label">Ціль (печаток)</label>
          <input
            v-model.number="settingsForm.target_seals"
            type="number"
            min="0"
            class="input"
          >
        </div>
        <div>
          <label class="label">Логотип URL</label>
          <input
            v-model="settingsForm.logo_url"
            class="input"
            placeholder="https://..."
          >
        </div>

        <div
          v-if="settingsError"
          class="text-sm text-rose-300 bg-rose-500/10 border border-rose-400/30 rounded-lg px-3 py-2"
        >
          {{ settingsError }}
        </div>
        <div
          v-else-if="settingsSaved"
          class="text-sm text-emerald-300 bg-emerald-500/10 border border-emerald-400/30 rounded-lg px-3 py-2"
        >
          Збережено
        </div>

        <div class="flex items-center justify-end">
          <BaseButton
            type="submit"
            :loading="savingSettings"
          >
            Зберегти
          </BaseButton>
        </div>
      </form>
    </div>
  </div>
</template>

<style scoped>
.container-page {
  width: 100%;
  max-width: 80rem;
  margin-left: auto;
  margin-right: auto;
  padding-left: 1rem;
  padding-right: 1rem;
}
@media (min-width: 768px) {
  .container-page {
    padding-left: 2rem;
    padding-right: 2rem;
  }
}
</style>
