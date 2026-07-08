export default defineNuxtConfig({
  compatibilityDate: '2025-05-15',
  devtools: { enabled: true },
  modules: ['@nuxtjs/tailwindcss', '@pinia/nuxt', '@vercel/analytics'],
  css: ['~/assets/css/main.css'],
  components: [
    { path: '~/components/ui', pathPrefix: false },
    { path: '~/components/activity', pathPrefix: false },
    '~/components',
  ],
  app: {
    head: {
      title: 'Збір Лунтіку на R9 — Cyberpunk',
      htmlAttrs: { lang: 'uk' },
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'theme-color', content: '#0b1220' },
        { name: 'description', content: 'Трекер збору печаток клану Cyberpunk на R9.' },
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
        { rel: 'apple-touch-icon', href: '/logo.jpg' },
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        {
          rel: 'stylesheet',
          href: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Orbitron:wght@500;700;900&family=Rajdhani:wght@500;600;700&display=swap',
        },
      ],
    },
  },
  runtimeConfig: {
    public: {
      supabaseUrl: process.env.SUPABASE_URL,
      supabaseKey: process.env.SUPABASE_KEY,
    },
  },
  typescript: {
    strict: true,
    shim: false,
  },
  vite: {
    optimizeDeps: {
      include: ['@supabase/supabase-js'],
    },
  },
})
