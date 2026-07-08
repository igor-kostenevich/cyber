export default defineNuxtPlugin(() => {
  const auth = useAuthStore()
  const profile = useProfileStore()
  const settings = useActivitySettingsStore()

  const syncSettings = async (silent = false) => {
    await settings.fetch({ silent })
    settings.startRealtime()
  }

  const stopSettings = () => {
    settings.stopRealtime()
  }

  watch(
    () => auth.isAuthenticated && profile.loaded && profile.isApproved,
    (active) => {
      if (active) void syncSettings()
      else stopSettings()
    },
    { immediate: true },
  )

  if (import.meta.client) {
    const onVisible = () => {
      if (document.visibilityState === 'visible'
        && auth.isAuthenticated
        && profile.loaded
        && profile.isApproved) {
        void settings.fetch({ silent: true })
      }
    }
    document.addEventListener('visibilitychange', onVisible)

    const app = useNuxtApp()
    app.hook('app:beforeUnmount', () => {
      document.removeEventListener('visibilitychange', onVisible)
      stopSettings()
    })
  }
})
