module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/components/**/*.{rb,erb}',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Noto Sans KR"', 'sans-serif']
      }
    }
  },
  plugins: [
    require('daisyui')
  ],
  daisyui: {
    themes: [
      {
        nongsa: {
          primary: '#16a34a',
          secondary: '#f59e0b',
          accent: '#10b981',
          neutral: '#3d4451',
          'base-100': '#ffffff',
          'base-200': '#f3f4f6',
          'base-300': '#e5e7eb',
          'base-content': '#111827',
          info: '#3abff8',
          success: '#10b981',
          warning: '#f59e0b',
          error: '#ef4444'
        }
      }
    ],
    base: true,
    styled: true,
    utils: true,
    logs: false
  }
}
