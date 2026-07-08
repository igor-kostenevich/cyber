<script setup lang="ts">
definePageMeta({
  middleware: 'auth',
})

useHead({ title: 'Очікування підтвердження · Cyberpunk' })

const auth = useAuthStore()
const profile = useProfileStore()
const router = useRouter()
const { format } = useDateFormat()

const checking = ref(false)

const statusMeta = computed(() => {
  switch (profile.data?.status) {
    case 'blocked':
      return { label: 'Заблоковано', cls: 'badge-err' }
    case 'approved':
      return { label: 'Підтверджено', cls: 'badge-ok' }
    default:
      return { label: 'Очікує підтвердження', cls: 'badge-warn' }
  }
})

const registeredAt = computed(() => {
  const raw = profile.data?.created_at
  return raw ? format(raw) : null
})

const goWhenReady = async () => {
  if (profile.isAdmin) return router.replace('/manage')
  if (profile.isApproved) return router.replace('/dashboard')
}

onMounted(async () => {
  if (!profile.loaded) await profile.fetchMine()
  await goWhenReady()
})

const refreshStatus = async () => {
  checking.value = true
  try {
    await profile.fetchMine()
    await goWhenReady()
  }
  finally {
    checking.value = false
  }
}

const onLogout = async () => {
  await auth.logout()
  await router.push('/')
}

const isBlocked = computed(() => profile.data?.status === 'blocked')
</script>

<template>
  <div class="container-page min-h-[80vh] flex items-center justify-center py-12">
    <GlowCard
      class="w-full max-w-md text-center space-y-5 animate-fade-in"
      :tone="isBlocked ? 'pink' : 'default'"
    >
      <div
        class="mx-auto h-14 w-14 rounded-full grid place-items-center"
        :class="isBlocked
          ? 'bg-rose-500/15 border border-rose-400/30'
          : 'bg-amber-500/15 border border-amber-400/30 animate-pulse-slow'"
      >
        <span class="text-2xl">{{ isBlocked ? '🚫' : '⏳' }}</span>
      </div>

      <div class="space-y-2">
        <h1 class="font-display text-2xl text-gradient-cyber">
          {{ isBlocked ? 'Акаунт заблоковано' : 'Очікування підтвердження' }}
        </h1>
        <p class="text-sm text-slate-400">
          Привіт, <span class="text-cyan-200">{{ profile.data?.nickname }}</span>!
        </p>
        <div class="flex flex-col items-center gap-1.5 pt-1">
          <span
            class="badge text-sm px-3 py-1"
            :class="statusMeta.cls"
          >
            {{ statusMeta.label }}
          </span>
          <p
            v-if="registeredAt"
            class="text-xs text-slate-500"
          >
            Зареєстровано {{ registeredAt }}
          </p>
        </div>
      </div>

      <p
        v-if="!isBlocked"
        class="text-sm text-slate-300/90"
      >
        Ваш акаунт зареєстровано і очікує підтвердження адміністрацією клану.
        Після підтвердження ви отримаєте доступ до системи активності.
      </p>
      <p
        v-else
        class="text-sm text-slate-300/90"
      >
        Доступ до системи активності призупинено. Зверніться до адміністрації клану.
      </p>

      <div
        v-if="!isBlocked"
        class="text-left border-t border-white/5 pt-4"
      >
        <TwinsEditor remote />
      </div>

      <div class="flex items-center justify-center gap-2">
        <BaseButton
          v-if="!isBlocked"
          :loading="checking"
          @click="refreshStatus"
        >
          Перевірити статус
        </BaseButton>
        <BaseButton
          variant="ghost"
          @click="onLogout"
        >
          Вийти
        </BaseButton>
      </div>
    </GlowCard>
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
</style>
