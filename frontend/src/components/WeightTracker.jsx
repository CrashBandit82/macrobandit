import { useState, useEffect, useCallback } from "react"
import { useTranslation } from "react-i18next"
import { useAuth } from "../context/AuthContext"

const API = import.meta.env.VITE_API_URL || "/api"

function calcTDEE(gender, age, heightCm, weightKg, activity, goal) {
  if (!gender || !age || !heightCm || !weightKg) return null
  const bmr = gender === "male"
    ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
    : 10 * weightKg + 6.25 * heightCm - 5 * age - 161

  const multipliers = { sedentary: 1.2, light: 1.375, moderate: 1.55, active: 1.725, veryActive: 1.9 }
  const tdee = bmr * (multipliers[activity] || 1.2)

  const goalOffset = { lose: -500, maintain: 0, gain: 300 }
  return Math.round(tdee + (goalOffset[goal] || 0))
}

function WeightChart({ entries, chartMinMsg }) {
  if (!entries || entries.length < 2) return (
    <div className="flex items-center justify-center h-32 text-slate-500 text-sm">
      {chartMinMsg}
    </div>
  )

  const W = 320, H = 120, PAD = 16
  const weights = entries.map(e => e.weight_kg)
  const min = Math.min(...weights) - 1
  const max = Math.max(...weights) + 1
  const range = max - min || 1

  const points = entries.map((e, i) => {
    const x = PAD + (i / (entries.length - 1)) * (W - PAD * 2)
    const y = PAD + ((max - e.weight_kg) / range) * (H - PAD * 2)
    return `${x},${y}`
  })

  const firstPt = points[0].split(",")
  const lastPt  = points[points.length - 1].split(",")

  return (
    <svg viewBox={`0 0 ${W} ${H}`} className="w-full" style={{ height: 120 }}>
      {[0, 0.5, 1].map(t => (
        <line key={t}
          x1={PAD} y1={PAD + t * (H - PAD * 2)}
          x2={W - PAD} y2={PAD + t * (H - PAD * 2)}
          stroke="#334155" strokeWidth="1" strokeDasharray="4,4"
        />
      ))}
      <polyline
        points={points.join(" ")}
        fill="none" stroke="#34d399" strokeWidth="2.5"
        strokeLinejoin="round" strokeLinecap="round"
      />
      <polygon
        points={`${PAD},${H - PAD} ${points.join(" ")} ${W - PAD},${H - PAD}`}
        fill="url(#weightGrad)" opacity="0.15"
      />
      <defs>
        <linearGradient id="weightGrad" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#34d399" />
          <stop offset="100%" stopColor="#34d399" stopOpacity="0" />
        </linearGradient>
      </defs>
      <circle cx={firstPt[0]} cy={firstPt[1]} r="4" fill="#94a3b8" />
      <circle cx={lastPt[0]} cy={lastPt[1]} r="5" fill="#34d399" stroke="#0f172a" strokeWidth="2" />
      <text x={PAD} y={H - 2} fill="#64748b" fontSize="9" textAnchor="middle">
        {entries[0].date.slice(5).replace("-", ".")}
      </text>
      <text x={W - PAD} y={H - 2} fill="#64748b" fontSize="9" textAnchor="middle">
        {entries[entries.length - 1].date.slice(5).replace("-", ".")}
      </text>
      <text x={parseFloat(lastPt[0])} y={parseFloat(lastPt[1]) - 8} fill="#34d399" fontSize="10" textAnchor="middle" fontWeight="bold">
        {entries[entries.length - 1].weight_kg}
      </text>
    </svg>
  )
}

export default function WeightTracker({ user, onGoalUpdate, userColor }) {
  const { t } = useTranslation()
  const { authFetch } = useAuth()

  const [history, setHistory] = useState(null)
  const [weightInput, setWeightInput] = useState("")
  const [loading, setLoading] = useState(true)
  const [success, setSuccess] = useState(null)
  const [error, setError] = useState(null)

  const [gender, setGender]     = useState(user.gender || "male")
  const [age, setAge]           = useState(user.age || "")
  const [height, setHeight]     = useState(user.height_cm || "")
  const [activity, setActivity] = useState("moderate")
  const [goal, setGoal]         = useState("maintain")
  const [tdeeResult, setTdeeResult] = useState(null)
  const [baseTdee, setBaseTdee] = useState(null)
  const [showTDEE, setShowTDEE] = useState(false)

  useEffect(() => {
    if (success) { const t = setTimeout(() => setSuccess(null), 3000); return () => clearTimeout(t) }
  }, [success])
  useEffect(() => {
    if (error) { const t = setTimeout(() => setError(null), 4000); return () => clearTimeout(t) }
  }, [error])

  const loadHistory = useCallback(async () => {
    try {
      const res = await authFetch(`${API}/weight/history?days=60`)
      if (res.ok) {
        const data = await res.json()
        setHistory(data)
        if (data.latest) setWeightInput(data.latest.toString())
      }
    } catch (e) { console.error(e) }
    finally { setLoading(false) }
  }, [authFetch])

  useEffect(() => { loadHistory() }, [loadHistory])

  const handleLogWeight = async (e) => {
    e.preventDefault()
    const kg = parseFloat(weightInput)
    if (!kg || kg <= 0) return
    try {
      const res = await authFetch(`${API}/weight`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ weight_kg: kg })
      })
      if (!res.ok) throw new Error("Fehler")
      setSuccess(t('weight.saved'))
      loadHistory()
    } catch { setError(t('weight.saveError')) }
  }

  const handleCalcTDEE = async () => {
    const w = history?.latest || parseFloat(weightInput) || null
    const result = calcTDEE(gender, parseInt(age), parseInt(height), w, activity, goal)
    if (!result) { setError(t('weight.fillAllFields')); return }
    setTdeeResult(result)
    setBaseTdee(result)

    await authFetch(`${API}/weight/profile`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ gender, age: parseInt(age), height_cm: parseInt(height) })
    })
  }

  const handleApplyGoal = async () => {
    if (!tdeeResult) return
    try {
      const res = await authFetch(`${API}/auth/goals`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          goal_kcal:    tdeeResult,
          goal_protein: user.goal_protein,
          goal_carbs:   user.goal_carbs,
          goal_fat:     user.goal_fat,
          goal_fiber:   user.goal_fiber,
        })
      })
      if (res.ok) {
        const updated = await res.json()
        onGoalUpdate(updated)
        setSuccess(t('weight.goalSet', { kcal: tdeeResult }))
      }
    } catch { setError(t('weight.applyError')) }
  }

  const trendColor = !history?.trend ? "text-slate-400"
    : history.trend < -0.1 ? "text-emerald-400"
    : history.trend > 0.1  ? "text-rose-400"
    : "text-amber-400"

  const trendIcon = !history?.trend ? "→"
    : history.trend < -0.1 ? "↓"
    : history.trend > 0.1  ? "↑"
    : "→"

  const activityOptions = [
    { val: "sedentary",  label: t('weight.activitySedentary') },
    { val: "light",      label: t('weight.activityLight') },
    { val: "moderate",   label: t('weight.activityModerate') },
    { val: "active",     label: t('weight.activityActive') },
    { val: "veryActive", label: t('weight.activityVeryActive') },
  ]

  const goalOptions = [
    { val: "lose",     label: t('weight.goalLose'),     icon: "📉" },
    { val: "maintain", label: t('weight.goalMaintain'), icon: "⚖️" },
    { val: "gain",     label: t('weight.goalGain'),     icon: "📈" },
  ]

  if (loading) return (
    <div className="space-y-4 animate-pulse">
      <div className="h-32 bg-slate-800 rounded-3xl" />
      <div className="h-48 bg-slate-800 rounded-3xl" />
    </div>
  )

  return (
    <div className="space-y-4">

      {error   && <div className="p-3 bg-rose-600 text-white rounded-2xl font-bold text-sm text-center">⚠️ {error}</div>}
      {success && <div className="p-3 bg-emerald-700 text-white rounded-2xl font-bold text-sm text-center">✓ {success}</div>}

      <div className="bg-slate-800 border border-slate-700/70 rounded-2xl p-5 shadow-lg">
        <h3 className="text-white font-semibold text-sm mb-4">{t('weight.title')}</h3>
        <form onSubmit={handleLogWeight} className="flex gap-3">
          <div className="relative flex-1">
            <input
              type="number" step="0.1" min="20" max="300"
              value={weightInput}
              onChange={e => setWeightInput(e.target.value)}
              placeholder={t('weight.placeholder')}
              className="w-full bg-slate-900 border border-slate-700 text-white text-2xl font-black rounded-2xl px-4 py-3 outline-none focus:ring-2 focus:ring-emerald-500 pr-12"
            />
            <span className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 font-bold">{t('weight.unit')}</span>
          </div>
          <button type="submit"
            className={`px-6 rounded-2xl bg-gradient-to-r ${userColor} text-white font-black shadow-lg`}>
            ✓
          </button>
        </form>

        {history && history.entries.length > 0 && (
          <div className="grid grid-cols-3 gap-3 mt-4">
            <div className="bg-slate-900 rounded-2xl p-3 text-center">
              <div className="text-xs text-slate-500 font-bold mb-1">{t('weight.current')}</div>
              <div className="text-lg font-black text-white">{history.latest} {t('weight.unit')}</div>
            </div>
            <div className="bg-slate-900 rounded-2xl p-3 text-center">
              <div className="text-xs text-slate-500 font-bold mb-1">{t('weight.start')}</div>
              <div className="text-lg font-black text-slate-300">{history.start_weight} {t('weight.unit')}</div>
            </div>
            <div className="bg-slate-900 rounded-2xl p-3 text-center">
              <div className="text-xs text-slate-500 font-bold mb-1">{t('weight.trend7d')}</div>
              <div className={`text-lg font-black ${trendColor}`}>
                {trendIcon} {history.trend !== null ? `${Math.abs(history.trend)} ${t('weight.unit')}` : "—"}
              </div>
            </div>
          </div>
        )}
      </div>

      {history && history.entries.length > 0 && (
        <div className="bg-slate-800 border border-slate-700/70 rounded-2xl p-5 shadow-lg">
          <h3 className="text-white font-semibold text-sm mb-3">{t('weight.chartTitle')}</h3>
          <WeightChart entries={history.entries} chartMinMsg={t('weight.chartMin')} />
        </div>
      )}

      <div className="bg-slate-800 border border-slate-700/70 rounded-2xl p-5 shadow-lg">
        <button
          onClick={() => setShowTDEE(!showTDEE)}
          className="w-full flex items-center justify-between"
        >
          <h3 className="text-white font-semibold text-sm">{t('weight.tdeeTitle')}</h3>
          <span className="text-slate-400 text-lg">{showTDEE ? "▲" : "▼"}</span>
        </button>
        <p className="text-xs text-slate-500 mt-1">{t('weight.tdeeFormula')}</p>

        {showTDEE && (
          <div className="mt-4 space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-400 mb-2">{t('weight.genderLabel')}</label>
              <div className="flex gap-2">
                {[["male", t('weight.male')], ["female", t('weight.female')]].map(([val, label]) => (
                  <button key={val} type="button" onClick={() => setGender(val)}
                    className={`flex-1 py-2.5 rounded-xl font-black text-sm transition-colors ${
                      gender === val
                        ? `bg-gradient-to-r ${userColor} text-white`
                        : "bg-slate-900 text-slate-400 hover:text-white"
                    }`}>
                    {label}
                  </button>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold text-slate-400 mb-1">{t('weight.ageLabel')}</label>
                <div className="relative">
                  <input type="number" min="10" max="100" value={age} onChange={e => setAge(e.target.value)}
                    placeholder="30"
                    className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-2.5 font-bold outline-none focus:ring-2 focus:ring-emerald-500 pr-12" />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 text-xs">{t('weight.ageUnit')}</span>
                </div>
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-400 mb-1">{t('weight.heightLabel')}</label>
                <div className="relative">
                  <input type="number" min="100" max="250" value={height} onChange={e => setHeight(e.target.value)}
                    placeholder="175"
                    className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-2.5 font-bold outline-none focus:ring-2 focus:ring-emerald-500 pr-8" />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 text-xs">{t('weight.heightUnit')}</span>
                </div>
              </div>
            </div>

            <div className="bg-slate-900 rounded-xl px-4 py-2.5 flex justify-between items-center">
              <span className="text-xs text-slate-400 font-bold">{t('weight.weightFromTracker')}</span>
              <span className="text-white font-black">
                {history?.latest || parseFloat(weightInput) || "—"} {t('weight.unit')}
              </span>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-400 mb-2">{t('weight.activityLabel')}</label>
              <div className="space-y-2">
                {activityOptions.map(({ val, label }) => (
                  <button key={val} type="button" onClick={() => setActivity(val)}
                    className={`w-full text-left px-4 py-2.5 rounded-xl text-sm font-bold transition-colors ${
                      activity === val
                        ? "bg-slate-600 text-white border border-emerald-500"
                        : "bg-slate-900 text-slate-400 hover:text-white"
                    }`}>
                    {label}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-400 mb-2">{t('weight.goalLabel')}</label>
              <div className="space-y-2">
                {goalOptions.map(({ val, label, icon }) => (
                  <button key={val} type="button" onClick={() => setGoal(val)}
                    className={`w-full text-left px-4 py-2.5 rounded-xl text-sm font-bold transition-colors ${
                      goal === val
                        ? "bg-slate-600 text-white border border-emerald-500"
                        : "bg-slate-900 text-slate-400 hover:text-white"
                    }`}>
                    {icon} {label}
                  </button>
                ))}
              </div>
            </div>

            <button onClick={handleCalcTDEE}
              className={`w-full py-3.5 rounded-2xl bg-gradient-to-r ${userColor} text-white font-black shadow-lg`}>
              {t('weight.calcButton')}
            </button>

            {tdeeResult && (
              <div className="bg-slate-900 rounded-2xl p-5 border border-emerald-500/30">
                <div className="text-center mb-4">
                  <div className="text-xs text-slate-400 font-bold mb-1">{t('weight.tdeeResultLabel')}</div>
                  <div className="text-5xl font-extrabold text-emerald-400">
                    {tdeeResult}
                  </div>
                  <div className="text-slate-400 font-bold">{t('weight.tdeeUnit')}</div>
                </div>
                <div className="grid grid-cols-3 gap-2 text-center text-xs mb-4">
                  {[
                    { labelKey: 'weight.btnLose',     value: (baseTdee || tdeeResult) - 500, color: "text-emerald-400" },
                    { labelKey: 'weight.btnMaintain', value: (baseTdee || tdeeResult),       color: "text-white" },
                    { labelKey: 'weight.btnGain',     value: (baseTdee || tdeeResult) + 300, color: "text-amber-400" },
                  ].map(({ labelKey, value, color }) => (
                    <button key={labelKey} type="button" onClick={() => setTdeeResult(value)}
                      className={`rounded-xl p-2 transition-all ${
                        tdeeResult === value
                          ? "bg-slate-600 border border-emerald-500"
                          : "bg-slate-800 hover:bg-slate-700"
                      }`}>
                      <div className="text-slate-400">{t(labelKey)}</div>
                      <div className={`font-black ${color}`}>{value}</div>
                    </button>
                  ))}
                </div>
                <button onClick={handleApplyGoal}
                  className={`w-full py-3 rounded-xl bg-gradient-to-r ${userColor} text-white font-black`}>
                  {t('weight.applyGoal', { kcal: tdeeResult })}
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
