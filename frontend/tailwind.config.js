/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      // Redesign 2026-10: moderner, weniger rundlich — gilt für alle Bildschirme
      fontFamily: {
        sans: ['Manrope', 'ui-sans-serif', 'system-ui', '-apple-system', 'Segoe UI', 'sans-serif'],
      },
      fontWeight: {
        black: '800',      // bisher 900: wirkt mit Manrope zu wuchtig
      },
      borderRadius: {
        xl: '10px',        // bisher 12px
        '2xl': '12px',     // bisher 16px
        '3xl': '14px',     // bisher 24px
      },
      boxShadow: {
        md: '0 2px 6px rgba(0, 0, 0, 0.16)',
        lg: '0 4px 12px rgba(0, 0, 0, 0.18)',
        xl: '0 6px 18px rgba(0, 0, 0, 0.22)',
        '2xl': '0 10px 30px rgba(0, 0, 0, 0.28)',
      },
    },
  },
  plugins: [],
}
