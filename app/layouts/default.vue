<script setup lang="ts">
import { useSettingsStore } from '~/stores/settings'
import { useAuthStore } from '~/stores/auth'

const settings = useSettingsStore()
const auth = useAuthStore()
const route = useRoute()
const router = useRouter()

const isAdminArea = computed(() => route.path.startsWith('/admin'))

const logoSrc = computed(() => settings.data?.logo_url || '/logo.jpg')

const onLogout = async () => {
  await auth.logout()
  await router.push('/')
}
</script>

<template>
  <div class="relative min-h-screen flex flex-col">
    <header class="sticky top-0 z-30 backdrop-blur-md bg-ink-900/60 border-b border-white/5">
      <div class="container-page flex items-center justify-between py-4">
        <NuxtLink
          to="/"
          class="flex items-center gap-3 group"
        >
          <div class="relative h-11 w-11 rounded-xl overflow-hidden border border-white/15 shadow-glow-sm group-hover:shadow-glow transition-shadow bg-ink-800">
            <img
              :src="logoSrc"
              alt="Cyberpunk clan logo"
              class="h-full w-full object-cover"
              loading="eager"
              decoding="async"
            >
            <div class="pointer-events-none absolute inset-0 rounded-xl bg-gradient-to-tr from-cyan-400/10 via-transparent to-violet-400/10" />
          </div>
          <div class="leading-tight">
            <div class="font-display tracking-widest text-sm uppercase text-cyan-300/90">
              {{ settings.data?.clan_name || 'Cyberpunk' }}
            </div>
            <div class="text-xs text-slate-400">
              {{ settings.data?.title || 'Збір печаток' }}
            </div>
          </div>
        </NuxtLink>

        <ClientOnly>
          <div
            v-if="isAdminArea && auth.isAuthenticated"
            class="flex items-center gap-3"
          >
            <span class="hidden sm:inline text-xs text-slate-400">
              {{ auth.user?.email }}
            </span>
            <button
              class="btn-ghost text-sm py-2 px-4"
              @click="onLogout"
            >
              Вийти
            </button>
          </div>
        </ClientOnly>
      </div>
    </header>

    <main class="flex-1">
      <slot />
    </main>

    <footer class="py-8 mt-12 border-t border-white/5">
      <div class="container-page text-center text-xs text-slate-500">
        <div class="neon-divider mb-4 max-w-xs mx-auto" />
        <p>
          © {{ new Date().getFullYear() }} {{ settings.data?.clan_name || 'Cyberpunk' }} —
          трекер прогресу збору печаток
        </p>
      </div>
    </footer>
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
