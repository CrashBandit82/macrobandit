module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#3b82f6',
        success: '#10b981',
        danger: '#ef4444',
        warning: '#f59e0b',
      },
      spacing: {
        'safe': 'max(1rem, env(safe-area-inset-bottom))',
      }
    },
  },
  plugins: [],
}
