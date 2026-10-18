import { useState, useEffect } from "react"
import { useTranslation } from "react-i18next"
import { useAuth } from "../context/AuthContext"
import { kalorienFarbe, rgb, KCAL_GRUEN, KCAL_ROT } from '../kcalFarbe'

const API = import.meta.env.VITE_API_URL || "/api"

export default function WeeklyTracker({ calorieGoal = 2000 }) {
  const { t } = useTranslation()
  const { authFetch } = useAuth()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      try {
        const res = await authFetch(`${API}/weekly?calorie_goal=${calorieGoal}`)
        if (res.ok) setData(await res.json())
      } catch (e) {
        console.error("Weekly load error:", e)
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [authFetch, calorieGoal])

  if (loading) {
    return (
      <div className="bg-slate-800 border border-slate-700/70 rounded-2xl p-4 animate-pulse">
        <div className="h-4 bg-slate-700 rounded w-1/3 mb-4" />
        <div className="flex items-end gap-2 h-20">
          {[...Array(7)].map((_, i) => (
            <div key={i} className="flex-1 bg-slate-700 rounded-t" style={{ height: `${30 + i * 8}%` }} />
          ))}
        </div>
      </div>
    )
  }

  if (!data) return null

  const today = new Date().toISOString().split("T")[0]
  const maxCal = Math.max(...data.days.map(d => d.calories), calorieGoal)

  return (
    <div className="bg-slate-800 border border-slate-700/70 rounded-2xl p-5 shadow-lg">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-white font-semibold text-sm">{t('weekly.title')}</h2>
        <span className="text-slate-400 text-xs font-bold">
          {t('weekly.avgCalories', { avg: data.avg_daily })}
        </span>
      </div>

      <div className="flex items-end gap-1.5 h-24 mb-3">
        {data.days.map((day) => {
          const isToday = day.date === today
          const pct = day.calories > 0 ? Math.min((day.calories / maxCal) * 100, 100) : 0
          const goalPct = Math.min((calorieGoal / maxCal) * 100, 100)

          return (
            <div key={day.date} className="flex-1 flex flex-col items-center gap-1 h-full justify-end relative">
              <div
                className="absolute w-full border-t border-dashed border-slate-600 opacity-40"
                style={{ bottom: `${goalPct}%` }}
              />
              <div className="w-full relative" style={{ height: `${Math.max(pct, 3)}%` }}>
                <div
                  className={`w-full h-full rounded-t transition-all ${
                    day.calories === 0 ? "bg-slate-700" : ""
                  } ${isToday ? "ring-2 ring-cyan-400 ring-opacity-60" : ""}`}
                  style={day.calories > 0 && calorieGoal > 0
                    ? { backgroundColor: kalorienFarbe((day.calories / calorieGoal) * 100) } : undefined}
                />
              </div>
              <span className={`text-xs font-black ${isToday ? "text-cyan-400" : "text-slate-500"}`}>
                {day.day_name}
              </span>
            </div>
          )
        })}
      </div>

      <div className="flex justify-between text-xs text-slate-500 border-t border-slate-700 pt-3 font-bold">
        <span>
          <span className="text-white font-black">{Math.round(data.weekly_total)}</span> / {Math.round(data.weekly_goal)} kcal
        </span>
        <div className="flex items-center gap-3">
          <span className="flex items-center gap-1">
            <span className="w-2 h-2 rounded-sm inline-block" style={{ backgroundColor: rgb(KCAL_GRUEN) }} /> {t('weekly.goalReached')}
          </span>
          <span className="flex items-center gap-1">
            <span className="w-2 h-2 rounded-sm inline-block" style={{ backgroundColor: rgb(KCAL_ROT) }} /> {t('weekly.overGoal')}
          </span>
          <span className="flex items-center gap-1">
            <span className="w-2 h-2 rounded-sm bg-cyan-500 inline-block" /> {t('weekly.today')}
          </span>
        </div>
      </div>
    </div>
  )
}
