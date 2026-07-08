export default defineNuxtRouteMiddleware(async (to) => {
  if (import.meta.server) return

  const auth = useAuthStore()
  if (!auth.initialized) await auth.init()

  if (!auth.isAuthenticated) {
    return navigateTo({ path: '/login', query: { redirect: to.fullPath } })
  }

  const profile = useProfileStore()
  if (!profile.loaded) await profile.fetchMine()

  if (!profile.isAdmin) {
    return navigateTo(profile.isApproved ? '/dashboard' : '/pending')
  }
})
