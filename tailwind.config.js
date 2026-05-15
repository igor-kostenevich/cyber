export default {
  content: [
    './app/**/*.{vue,js,ts}',
    './components/**/*.{vue,js,ts}',
    './layouts/**/*.vue',
    './pages/**/*.vue',
    './composables/**/*.{js,ts}',
    './plugins/**/*.{js,ts}',
    './app.vue',
    './error.vue',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
        display: ['Orbitron', 'Rajdhani', 'Inter', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'ui-monospace', 'SFMono-Regular', 'monospace'],
      },
      colors: {
        cyber: {
          50: '#e6f6ff',
          100: '#c6ebff',
          200: '#8ed5ff',
          300: '#56beff',
          400: '#1fa6ff',
          500: '#0090ff',
          600: '#0074d1',
          700: '#0058a0',
          800: '#003c6e',
          900: '#001f3d',
        },
        neon: {
          blue: '#38bdf8',
          cyan: '#22d3ee',
          violet: '#a78bfa',
          pink: '#f472b6',
        },
        ink: {
          900: '#05070d',
          800: '#0a0f1c',
          700: '#0f1626',
          600: '#141d33',
        },
      },
      backgroundImage: {
        'cyber-radial':
          'radial-gradient(ellipse at top, rgba(56,189,248,0.18), transparent 60%), radial-gradient(ellipse at bottom right, rgba(167,139,250,0.12), transparent 55%), linear-gradient(180deg, #05070d 0%, #0a0f1c 50%, #05070d 100%)',
        'grid-overlay':
          'linear-gradient(rgba(56,189,248,0.06) 1px, transparent 1px), linear-gradient(90deg, rgba(56,189,248,0.06) 1px, transparent 1px)',
      },
      boxShadow: {
        'glow-sm': '0 0 12px rgba(56,189,248,0.25), 0 0 1px rgba(56,189,248,0.4) inset',
        glow: '0 0 24px rgba(56,189,248,0.35), 0 0 1px rgba(56,189,248,0.5) inset',
        'glow-lg': '0 0 48px rgba(56,189,248,0.45), 0 0 1px rgba(56,189,248,0.6) inset',
        'glow-violet': '0 0 28px rgba(167,139,250,0.35)',
        'glow-pink': '0 0 28px rgba(244,114,182,0.35)',
      },
      backdropBlur: {
        xs: '2px',
      },
      borderRadius: {
        '2xl': '1.25rem',
        '3xl': '1.75rem',
      },
      animation: {
        'pulse-slow': 'pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'fade-in': 'fadeIn 0.3s ease-out',
        'slide-up': 'slideUp 0.3s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
    },
  },
  plugins: [],
}
