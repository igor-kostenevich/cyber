<script setup lang="ts">
import type { TabItem } from '~/types/activity'

definePageMeta({
  middleware: 'approved',
})

useHead({ title: 'Кабінет · Cyberpunk' })

const profile = useProfileStore()
const mounted = useClientMounted()
const showStats = computed(() => mounted.value && profile.loaded)
const rewards = useRewardsStore()
const requests = useRewardRequestsStore()
const history = useHistoryStore()
const { getMessage } = useSupabaseErrorMessage()
const leaderboard = useLeaderboard()

const activeTab = ref<string>('rewards')

const tabs = computed<TabItem[]>(() => [
  { id: 'rewards', label: 'Нагороди' },
  { id: 'requests', label: 'Мої заявки', badge: myPendingCount.value },
  { id: 'rating', label: 'Рейтинг' },
  { id: 'history', label: 'Історія' },
])

const myRow = computed(() =>
  leaderboard.rows.value.find((r) => r.profile_id === profile.data?.id) ?? null,
)
const myProfileId = computed(() => profile.data?.id)

const myPendingRequests = computed(() =>
  requests.pending.filter((r) => r.profile_id === myProfileId.value),
)

const myPendingCount = computed(() => myPendingRequests.value.length)

const pendingCountByReward = computed(() => {
  const counts: Record<string, number> = {}
  for (const r of myPendingRequests.value) {
    counts[r.reward_id] = (counts[r.reward_id] ?? 0) + (r.quantity ?? 1)
  }
  return counts
})

const reservedPoints = computed(() =>
  myPendingRequests.value.reduce((sum, r) => sum + rewardRequestTotalPoints(r), 0),
)

const availableBalance = computed(() =>
  Math.max(0, profile.balance - reservedPoints.value),
)

const actionError = ref<string | null>(null)
const submittingId = ref<string | null>(null)

const displayName = computed(() =>
  profile.data?.display_name || profile.data?.nickname || '…',
)

const editingName = ref(false)
const editNameValue = ref('')
const editNameError = ref<string | null>(null)
const savingName = ref(false)

function startEditName() {
  editNameValue.value = profile.data?.display_name || profile.data?.nickname || ''
  editNameError.value = null
  editingName.value = true
}

async function saveEditName() {
  if (!editNameValue.value.trim()) return
  savingName.value = true
  editNameError.value = null
  try {
    await profile.updateDisplayName(editNameValue.value)
    editingName.value = false
  }
  catch (e) {
    editNameError.value = e instanceof Error ? e.message : 'Помилка збереження'
  }
  finally {
    savingName.value = false
  }
}

function cancelEditName() {
  editingName.value = false
  editNameError.value = null
}

const queueTotalsByReward = computed(() => requests.queueTotalsByReward)

const refresh = async () => {
  await Promise.all([
    rewards.fetchAll(),
    requests.fetchAll(),
    leaderboard.load(),
    useActivitySettingsStore().fetch({ silent: true }),
  ])
}

onMounted(() => {
  void refresh()
})

const onRequest = async (rewardId: string, qty: number) => {
  actionError.value = null
  submittingId.value = rewardId
  try {
    await requests.createRequest(rewardId, qty)
    await Promise.all([requests.fetchAll(), history.fetchPage()])
  }
  catch (e) {
    actionError.value = getMessage(e, 'Не вдалося створити заявку')
  }
  finally {
    submittingId.value = null
  }
}
</script>

<template>
  <div class="container-page py-8 md:py-10 space-y-6">
    <header>
      <div class="text-xs uppercase tracking-widest text-cyan-300/80">
        Кабінет гравця
      </div>

      <div
        v-if="showStats && editingName"
        class="mt-1 flex items-center gap-2 flex-wrap"
      >
        <input
          v-model="editNameValue"
          class="input font-display text-2xl md:text-3xl py-1 px-3 max-w-xs"
          autofocus
          @keyup.enter="saveEditName"
          @keyup.escape="cancelEditName"
        >
        <BaseButton
          :loading="savingName"
          @click="saveEditName"
        >
          Зберегти
        </BaseButton>
        <BaseButton
          variant="ghost"
          @click="cancelEditName"
        >
          Скасувати
        </BaseButton>
        <p
          v-if="editNameError"
          class="w-full text-xs text-rose-400"
        >
          {{ editNameError }}
        </p>
      </div>

      <h1
        v-else
        class="font-display text-2xl md:text-3xl text-gradient-cyber"
      >
        Привіт,
        <template v-if="showStats">
          <button
            class="group inline-flex items-center gap-2 hover:opacity-80 transition-opacity"
            title="Редагувати імʼя"
            @click="startEditName"
          >
            <span class="neon-text">{{ displayName }}</span>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 20 20"
              fill="currentColor"
              class="h-4 w-4 text-cyan-400/60 group-hover:text-cyan-300 transition-colors shrink-0 mb-0.5"
            >
              <path d="M2.695 14.763l-1.262 3.154a.5.5 0 00.65.65l3.155-1.262a4 4 0 001.343-.885L17.5 5.5a2.121 2.121 0 00-3-3L3.58 13.42a4 4 0 00-.885 1.343z" />
            </svg>
          </button>
        </template>
        <template v-else>
          <span>…</span>
        </template>
      </h1>
    </header>

    <UserStats
      v-if="showStats"
      :balance="profile.balance"
      :rank="myRow?.rank ?? null"
      :month-points="myRow?.month_points ?? 0"
      :events-count="myRow?.events_count ?? 0"
    />
    <div
      v-else
      class="grid gap-3 sm:grid-cols-2 lg:grid-cols-4"
    >
      <GlowCard
        v-for="i in 4"
        :key="i"
        class="text-center min-h-[6.5rem] grid place-items-center"
      >
        <span class="text-slate-500">—</span>
      </GlowCard>
    </div>

    <RulesBlock />

    <GlowCard class="space-y-1">
      <TwinsEditor remote />
    </GlowCard>

    <div
      v-if="actionError"
      class="text-sm text-rose-300 bg-rose-500/10 border border-rose-400/30 rounded-lg px-3 py-2"
    >
      {{ actionError }}
    </div>

    <AdminTabs
      v-model="activeTab"
      :tabs="tabs"
    />

    <section
      v-show="activeTab === 'rewards'"
      class="animate-fade-in"
    >
      <RewardGrid
        :rewards="rewards.items"
        :available-balance="availableBalance"
        :loading="rewards.isLoading && !rewards.hasLoaded"
        :error="rewards.error"
        :pending-counts="pendingCountByReward"
        :queue-totals="queueTotalsByReward"
        :submitting-id="submittingId"
        @request="onRequest"
      />
    </section>

    <section
      v-show="activeTab === 'requests'"
      class="animate-fade-in"
    >
      <RewardRequestList
        :requests="requests.items"
        :loading="requests.isLoading && !requests.hasLoaded"
        :error="requests.error"
        :queue-positions="requests.queuePositions"
      />
    </section>

    <section
      v-show="activeTab === 'rating'"
      class="animate-fade-in"
    >
      <Leaderboard
        :rows="leaderboard.rows.value"
        :current-profile-id="profile.data?.id"
        :loading="leaderboard.isLoading.value && !leaderboard.hasLoaded.value"
        :error="leaderboard.error.value"
      />
    </section>

    <section
      v-show="activeTab === 'history'"
      class="animate-fade-in"
    >
      <HistoryPanel />
    </section>
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
