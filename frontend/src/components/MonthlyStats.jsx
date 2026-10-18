import { useState, useEffect, useCallback } from "react"
import { useTranslation } from "react-i18next"
import { useAuth } from "../context/AuthContext"
import i18n from "../i18n.js"

const API = import.meta.env.VITE_API_URL || "/api"

export default function MonthlyStats({ userColor }) {
  const { t } = useTranslation()
  const { authFetch } = useAuth()
  const today = new Date()
  const [year,  setYear]  = useState(today.getFullYear())
  const [month, setMonth] = useState(today.getMonth() + 1)
  const [data,  setData]  = useState(null)
  const [loading, setLoading] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const res = await authFetch(`${API}/monthly?year=${year}&month=${month}`)
      setData(await res.json())
    } catch (e) { console.error(e) }
    finally { setLoading(false) }
  }, [authFetch, year, month])

  useEffect(() => { load() }, [load])

  const prevMonth = () => {
    if (month === 1) { setMonth(12); setYear(y => y - 1) }
    else setMonth(m => m - 1)
  }
  const nextMonth = () => {
    if (month === 12) { setMonth(1); setYear(y => y + 1) }
    else setMonth(m => m + 1)
  }
  const isCurrentMonth = year === today.getFullYear() && month === today.getMonth() + 1

  const getMonthName = (y, m) => {
    const locale = i18n.language.startsWith('de') ? 'de-DE' : 'en-US'
    return new Date(y, m - 1, 1).toLocaleDateString(locale, { month: 'long' })
  }

  if (loading) return <div className="text-slate-400 text-center py-6 text-sm">{t('monthly.loading')}</div>

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <button onClick={prevMonth} className="w-9 h-9 bg-slate-800 rounded-xl text-white flex items-center justify-center hover:bg-slate-700">‹</button>
        <h3 className="text-white font-black text-base">{getMonthName(year, month)} {year}</h3>
        <button onClick={nextMonth} disabled={isCurrentMonth}
          className="w-9 h-9 bg-slate-800 rounded-xl text-white flex items-center justify-center hover:bg-slate-700 disabled:opacity-30">›</button>
      </div>

      {!data || data.days_tracked === 0 ? (
        <div className="text-slate-500 text-center py-8 text-sm">{t('monthly.noData')}</div>
      ) : (
        <>
          <div className="grid grid-cols-2 gap-3">
            {[
              { label: t('monthly.daysTracked'),  value: `${data.days_tracked} / ${data.days_in_month}`, color: "text-cyan-400" },
              { label: t('monthly.goalReached'),  value: `${data.goal_reached_days} Tage`,               color: "text-emerald-400" },
              { label: t('monthly.avgCalories'),  value: `${Math.round(data.avg_calories)} kcal`,        color: "text-amber-400" },
              { label: t('monthly.avgProtein'),   value: `${data.avg_protein}g`,                         color: "text-blue-400" },
              { label: t('monthly.avgCarbs'),     value: `${data.avg_carbs}g`,                           color: "text-orange-400" },
              { label: t('monthly.avgFat'),       value: `${data.avg_fat}g`,                             color: "text-pink-400" },
            ].map(s => (
              <div key={s.label} className="bg-slate-900 rounded-2xl p-3 text-center">
                <div className={`text-xl font-black ${s.color}`}>{s.value}</div>
                <div className="text-slate-500 text-xs mt-0.5">{s.label}</div>
              </div>
            ))}
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="bg-emerald-900/20 border border-emerald-800/50 rounded-2xl p-3 text-center">
              <div className="text-xs text-emerald-400 font-bold mb-1">{t('monthly.bestDay')}</div>
              <div className="text-white font-black">{data.best_day?.date}</div>
              <div className="text-emerald-400 text-sm">{Math.round(data.best_day?.calories)} kcal</div>
            </div>
            <div className="bg-slate-900 rounded-2xl p-3 text-center">
              <div className="text-xs text-slate-400 font-bold mb-1">{t('monthly.lowestDay')}</div>
              <div className="text-white font-black">{data.worst_day?.date}</div>
              <div className="text-slate-400 text-sm">{Math.round(data.worst_day?.calories)} kcal</div>
            </div>
          </div>

          {data.daily && data.daily.length > 0 && (
            <div className="bg-slate-900 rounded-2xl p-4">
              <p className="text-xs text-slate-500 font-bold mb-3">{t('monthly.dailyChart')}</p>
              <div className="relative flex items-end gap-0.5" style={{height: '80px'}}>
                {data.daily.map((d, i) => {
                  const maxCal = Math.max(...data.daily.map(x => x.calories))
                  const height = maxCal > 0 ? Math.max(4, (d.calories / maxCal) * 80) : 4
                  return (
                    <div key={i} className="flex-1 flex flex-col justify-end items-center group relative" style={{height: '80px'}}>
                      <div
                        style={{ height: `${height}px` }}
                        className={`w-full rounded-sm ${d.goal_reached ? 'bg-emerald-500' : 'bg-slate-600'}`}
                      />
                      <div className="absolute bottom-full mb-1 bg-slate-800 text-white text-xs px-1.5 py-0.5 rounded hidden group-hover:block whitespace-nowrap z-10">
                        {d.date}: {Math.round(d.calories)} kcal
                      </div>
                    </div>
                  )
                })}
              </div>
              <div className="flex justify-between mt-1">
                <span className="text-slate-600 text-xs">1.</span>
                <span className="text-slate-600 text-xs">{data.days_in_month}.</span>
              </div>
              <div className="flex items-center gap-3 mt-2">
                <div className="flex items-center gap-1"><div className="w-3 h-3 rounded-sm bg-emerald-500"/><span className="text-slate-500 text-xs">{t('monthly.goalReached')}</span></div>
                <div className="flex items-center gap-1"><div className="w-3 h-3 rounded-sm bg-slate-600"/><span className="text-slate-500 text-xs">{t('monthly.goalNotReached')}</span></div>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}
