<script setup lang="ts">
import type { TabItem } from '~/types/activity'

definePageMeta({
  middleware: 'admin',
})

useHead({ title: 'Адмінка активності · Cyberpunk' })

const players = usePlayersStore()
const requests = useRewardRequestsStore()

const activeTab = ref<string>('activities')

const tabs = computed<TabItem[]>(() => [
  { id: 'players', label: 'Гравці', badge: players.pending.length },
  { id: 'activities', label: 'Активності' },
  { id: 'warehouse', label: 'Склад' },
  { id: 'requests', label: 'Заявки', badge: requests.pending.length },
  { id: 'history', label: 'Історія' },
])

onMounted(() => {
  // Підвантажуємо лічильники для бейджів вкладок.
  if (!players.hasLoaded) void players.fetchAll()
  if (!requests.hasLoaded) void requests.fetchAll()
})
</script>

<template>
  <div class="container-page py-8 md:py-10 space-y-6">
    <header>
      <div class="text-xs uppercase tracking-widest text-cyan-300/80">
        Адмін-панель
      </div>
      <h1 class="font-display text-2xl md:text-3xl text-gradient-cyber">
        Система активності клану
      </h1>
    </header>

    <AdminTabs
      v-model="activeTab"
      :tabs="tabs"
    />

    <div class="animate-fade-in">
      <AdminPlayers v-show="activeTab === 'players'" />
      <AdminActivities v-show="activeTab === 'activities'" />
      <AdminWarehouse v-show="activeTab === 'warehouse'" />
      <AdminRewardRequests v-show="activeTab === 'requests'" />
      <AdminHistory v-show="activeTab === 'history'" />
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
