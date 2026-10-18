import { createContext, useContext, useState, useEffect } from "react"

const ThemeContext = createContext(null)

export function ThemeProvider({ children }) {
  const [isDark, setIsDark] = useState(() => {
    const saved = localStorage.getItem("theme")
    return saved ? saved === "dark" : true  // Standard: Dark
  })

  useEffect(() => {
    const root = document.documentElement
    if (isDark) {
      root.classList.remove("light-mode")
    } else {
      root.classList.add("light-mode")
    }
    localStorage.setItem("theme", isDark ? "dark" : "light")
  }, [isDark])

  const toggleTheme = () => setIsDark(d => !d)

  return (
    <ThemeContext.Provider value={{ isDark, toggleTheme }}>
      {children}
    </ThemeContext.Provider>
  )
}

export const useTheme = () => useContext(ThemeContext)
