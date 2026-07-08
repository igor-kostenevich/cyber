<script setup lang="ts">
import { useSettingsStore } from '~/stores/settings'
import { useAuthStore } from '~/stores/auth'
import { useProfileStore } from '~/stores/profile'

const settings = useSettingsStore()
const auth = useAuthStore()
const profile = useProfileStore()
const route = useRoute()
const router = useRouter()

const logoSrc = computed(() => settings.data?.logo_url || '/logo.jpg')

interface NavLink { to: string, label: string }

const navLinks = computed<NavLink[]>(() => {
  if (!auth.isAuthenticated || !profile.isApproved) return []
  const links: NavLink[] = [
    { to: '/dashboard', label: 'Кабінет' },
    { to: '/r9', label: 'R9' },
  ]
  if (profile.isAdmin) {
    links.push({ to: '/manage', label: 'Адмінка' })
  }
  if (profile.isSuperAdmin) {
    links.push({ to: '/admin', label: 'R9-адмін' })
  }
  return links
})

const isActive = (to: string) => route.path === to

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
          <div class="font-display tracking-widest text-sm uppercase text-cyan-300/90">
            {{ settings.data?.clan_name || 'Cyberpunk' }}
          </div>
        </NuxtLink>

        <ClientOnly>
          <div class="flex items-center gap-1.5 sm:gap-2">
            <nav
              v-if="navLinks.length"
              class="flex items-center gap-1"
            >
              <NuxtLink
                v-for="link in navLinks"
                :key="link.to"
                :to="link.to"
                class="px-2.5 sm:px-3 py-2 rounded-lg text-xs sm:text-sm font-medium transition-colors"
                :class="isActive(link.to)
                  ? 'text-cyan-200 bg-white/[0.06]'
                  : 'text-slate-300 hover:text-cyan-100 hover:bg-white/5'"
              >
                {{ link.label }}
              </NuxtLink>
            </nav>

            <template v-if="auth.isAuthenticated">
              <span class="hidden md:inline text-xs text-slate-400 max-w-[10rem] truncate">
                {{ profile.data?.nickname || auth.user?.email }}
              </span>
              <button
                class="btn-ghost text-xs sm:text-sm py-2 px-3 sm:px-4"
                @click="onLogout"
              >
                Вийти
              </button>
            </template>
            <template v-else>
              <NuxtLink
                to="/login"
                class="btn-ghost text-xs sm:text-sm py-2 px-3 sm:px-4"
              >
                Увійти
              </NuxtLink>
              <NuxtLink
                to="/register"
                class="btn-primary text-xs sm:text-sm py-2 px-3 sm:px-4"
              >
                Реєстрація
              </NuxtLink>
            </template>
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
          © {{ new Date().getFullYear() }} {{ settings.data?.clan_name || 'Cyberpunk' }} · CyberPW
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
