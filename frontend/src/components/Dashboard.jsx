import React, { useState, useEffect, useCallback, useRef } from 'react'
import { useTranslation } from 'react-i18next'
import { useAuth } from '../context/AuthContext'
import i18n from '../i18n.js'
import BarcodeScanner from './BarcodeScanner'
import { kalorienFarbe } from '../kcalFarbe'
import WeeklyTracker from './WeeklyTracker'
import WeightTracker from './WeightTracker'
import MonthlyStats from './MonthlyStats'
import PasswordStrength from './PasswordStrength'
import AdminPanel from './AdminPanel'
import MealTemplates from './MealTemplates'

const API_BASE = import.meta.env.VITE_API_URL || '/api'

// Schnelleingabe "200g Milch 3,5" / "Milch 3,5 200 g" / "200 Rinderfilet" / "0,5 l Milch": Menge und Suchbegriff
// trennen (kg und l werden in g umgerechnet, 1 l ≈ 1000 g). Eine Zahl am Ende zählt nur MIT Einheit als Menge —
// sonst wäre "Milch 3,5" eine Menge von 3,5 g.
const EINHEIT = '(g|gr|gramm|ml|kg|l|liter)'
function parseSchnelleingabe(text) {
  const t = (text || '').trim()
  const menge = (zahl, einheit) => {
    const v = parseFloat(zahl.replace(',', '.')) * (/^(kg|l|liter)$/i.test(einheit || '') ? 1000 : 1)
    return String(Math.round(v * 10) / 10)
  }
  let m = t.match(new RegExp(`^(\\d+(?:[.,]\\d+)?)\\s*${EINHEIT}?\\s+(.+)$`, 'i'))
  // ohne Einheit erst ab 10 als Gramm — "2 Eier" / "1 Apfel" sind Stückzahlen
  if (m && (m[2] || parseFloat(m[1].replace(',', '.')) >= 10)) return { menge: menge(m[1], m[2]), begriff: m[3].trim() }
  if (m) return { menge: '', begriff: m[3].trim() }   // Stückzahl nicht mitsuchen
  m = t.match(new RegExp(`^(.+?)\\s+(\\d+(?:[.,]\\d+)?)\\s*${EINHEIT}$`, 'i'))
  if (m) return { menge: menge(m[2], m[3]), begriff: m[1].trim() }
  return { menge: '', begriff: t }
}

// Nährwerte für eine Menge (g) aus den Werten je 100 g
const fuerMenge = (wert100, menge) => (wert100 == null || !menge ? null : (wert100 * parseFloat(menge)) / 100)

const USER_COLORS = [
  'from-pink-500 to-rose-500', 'from-teal-600 to-emerald-700', 'from-blue-500 to-cyan-500',
  'from-teal-500 to-emerald-500', 'from-green-500 to-lime-500', 'from-yellow-500 to-amber-500',
  'from-orange-500 to-red-500', 'from-fuchsia-500 to-pink-500', 'from-amber-600 to-orange-700',
  'from-sky-500 to-blue-600',
]


// Redesign 2026-10: Strich-Symbole statt Emojis, einheitliche Felder in Konto/Ziele
const Ico = ({ d, size = 18 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d={d} /></svg>
)
const kontoInput = 'w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3.5 h-11 text-sm font-semibold outline-none focus:border-emerald-500 transition-colors'
const kontoZurueck = 'flex-1 border border-slate-600 text-slate-200 font-semibold h-11 rounded-xl text-sm hover:bg-slate-800 transition-colors'

const pct = (value, goal) => goal > 0 ? Math.min(((value || 0) / goal) * 100, 100) : 0
const pctRoh = (value, goal) => goal > 0 ? ((value || 0) / goal) * 100 : 0


export default function Dashboard() {
  const { t } = useTranslation()
  const { user, logout, authFetch, refreshUser } = useAuth()

  const userColor = USER_COLORS[(user.id - 1) % USER_COLORS.length]

  const [goals, setGoals] = useState({
    kcal:    user.goal_kcal,
    protein: user.goal_protein,
    carbs:   user.goal_carbs,
    fat:     user.goal_fat,
    fiber:   user.goal_fiber,
  })

  const [activeMainTab, setActiveMainTab] = useState('nutrition')
  const [selectedDate, setSelectedDate] = useState(null)
  const [totals, setTotals] = useState(null)
  const [logs, setLogs] = useState([])
  const [foods, setFoods] = useState([])

  const [showScanner, setShowScanner] = useState(false)
  const [showFoodManager, setShowFoodManager] = useState(false)
  const [editingFood, setEditingFood] = useState(null)
  const [editingLog, setEditingLog] = useState(null)
  const [editLogAmount, setEditLogAmount] = useState('')
  const [editForm, setEditForm] = useState({})
  const [showAddManual, setShowAddManual] = useState(false)
  const [showEditGoals, setShowEditGoals] = useState(false)
  const [activeTab, setActiveTab] = useState('search')
  const [selectedFood, setSelectedFood] = useState(null)
  const [amount, setAmount] = useState('')
  const [searchQuery, setSearchQuery] = useState('')
  // BLS-Grundlebensmittel (lokal, Max Rubner-Institut) und Live-Suche Open Food Facts zum Suchbegriff
  const [refResults, setRefResults] = useState([])
  const [onlineResults, setOnlineResults] = useState(null)   // null = noch nicht gesucht
  const [onlineLoading, setOnlineLoading] = useState(false)
  const [onlineError, setOnlineError] = useState('')
  const schnell = parseSchnelleingabe(searchQuery)

  const [customName, setCustomName] = useState('')
  const [customKcal, setCustomKcal] = useState('')
  const [customProtein, setCustomProtein] = useState('')
  const [customCarbs, setCustomCarbs] = useState('')
  const [customFat, setCustomFat] = useState('')
  const [customFiber, setCustomFiber] = useState('')
  const [customAmount, setCustomAmount] = useState('')

  const [goalInputKcal, setGoalInputKcal] = useState('')
  const [goalInputProtein, setGoalInputProtein] = useState('')
  const [goalInputCarbs, setGoalInputCarbs] = useState('')
  const [goalInputFat, setGoalInputFat] = useState('')
  const [goalInputFiber, setGoalInputFiber] = useState('')

  const [showAdmin, setShowAdmin] = useState(false)
  const [overviewTab, setOverviewTab] = useState('week')
  const [pushEnabled, setPushEnabled] = useState(false)
  const [pushLoading, setPushLoading] = useState(false)
  const [reminderTime, setReminderTime] = useState('')
  const [reminderSaving, setReminderSaving] = useState(false)
  const [isOnline, setIsOnline] = useState(navigator.onLine)
  const [offlineQueue, setOfflineQueue] = useState(0)
  const reauthInFlightRef = useRef(false) // B1: Re-Auth nur einmal pro Online-Phase
  const [showShake, setShowShake] = useState(false)
  const [showFeedback, setShowFeedback] = useState(false)
  const [feedbackMsg, setFeedbackMsg] = useState('')
  const [feedbackSent, setFeedbackSent] = useState(false)
  const [showAccountMenu, setShowAccountMenu] = useState(false)
  const [accountTab, setAccountTab] = useState('menu')
  const [deletePassword, setDeletePassword] = useState('')
  const [deleteConfirm, setDeleteConfirm] = useState('')
  const [newUsername, setNewUsername] = useState('')
  const [pwCurrent, setPwCurrent] = useState('')
  const [pwNew, setPwNew] = useState('')
  const [pwConfirm, setPwConfirm] = useState('')

  const [error, setError] = useState(null)
  const [success, setSuccess] = useState(null)
  const [apiLoading, setApiLoading] = useState(false)

  useEffect(() => {
    if (success) { const timer = setTimeout(() => setSuccess(null), 3000); return () => clearTimeout(timer) }
  }, [success])
  useEffect(() => {
    if (error) { const timer = setTimeout(() => setError(null), 5000); return () => clearTimeout(timer) }
  }, [error])

  const loadDashboard = useCallback(async (date = null) => {
    try {
      const dateStr = date || new Date().toISOString().split('T')[0]
      const isToday = dateStr === new Date().toISOString().split('T')[0]
      const [totalsRes, logsRes] = await Promise.all([
        authFetch(`${API_BASE}/totals/${isToday ? 'today' : `date/${dateStr}`}`),
        authFetch(`${API_BASE}/logs/${isToday ? 'today' : `date/${dateStr}`}`),
      ])
      setTotals(await totalsRes.json())
      setLogs(await logsRes.json())
    } catch (err) { console.error(err) }
  }, [authFetch])

  const loadFoods = useCallback(async (q = '') => {
    try {
      const url = q ? `${API_BASE}/foods?search=${encodeURIComponent(q)}` : `${API_BASE}/foods`
      const res = await authFetch(url)
      setFoods(await res.json())
    } catch (err) { console.error(err) }
  }, [authFetch])

  useEffect(() => {
    const handleOnline  = () => {
      setIsOnline(true)
      reauthInFlightRef.current = false // neue Online-Phase → Re-Auth wieder erlauben
      if (navigator.serviceWorker.controller) {
        navigator.serviceWorker.controller.postMessage({ type: 'SYNC_NOW' })
      }
    }
    const handleOffline = () => setIsOnline(false)
    window.addEventListener('online',  handleOnline)
    window.addEventListener('offline', handleOffline)

    const handleSWMsg = (event) => {
      if (event.data?.type === 'OFFLINE_SYNCED') {
        setSuccess(t('dashboard.offlineSynced', { count: event.data.count }))
        setOfflineQueue(0)
        loadDashboard(selectedDate)
        checkPushStatus()
        authFetch(`${API_BASE}/auth/me`).then(r => r.json()).then(u => {
          if (u.reminder_time) setReminderTime(u.reminder_time)
        }).catch(() => {})
      }
      if (event.data?.type === 'OFFLINE_QUEUED') {
        setOfflineQueue(q => q + 1)
      }
      if (event.data?.type === 'QUEUE_COUNT') {
        setOfflineQueue(event.data.count)
      }
      if (event.data?.type === 'GET_TOKEN') {
        // SW fragt zur Sync-Zeit nach dem aktuellen Token
        event.ports?.[0]?.postMessage({ token: localStorage.getItem('access_token') })
      }
      if (event.data?.type === 'OFFLINE_AUTH_REQUIRED') {
        // B1: nur EINMAL pro Online-Phase re-authentifizieren (Loop-Schutz)
        if (reauthInFlightRef.current) return
        reauthInFlightRef.current = true
        const before = localStorage.getItem('access_token')
        // authFetch erneuert den Token bei 401 selbst; /auth/me mit gültigem Token bleibt 200
        authFetch(`${API_BASE}/auth/me`)
          .then(() => {
            const after = localStorage.getItem('access_token')
            // Nur erneut syncen, wenn sich der Token tatsächlich geändert hat → sonst kein Retry
            if (after && after !== before) {
              navigator.serviceWorker.controller?.postMessage({ type: 'SYNC_NOW' })
            }
          })
          .catch(() => {})
      }
    }
    navigator.serviceWorker.addEventListener('message', handleSWMsg)

    return () => {
      window.removeEventListener('online',  handleOnline)
      window.removeEventListener('offline', handleOffline)
      navigator.serviceWorker.removeEventListener('message', handleSWMsg)
    }
  }, [])

  useEffect(() => {
    loadDashboard(selectedDate)
    loadFoods()
  }, [loadDashboard, loadFoods, selectedDate])

  useEffect(() => {
    const begriff = parseSchnelleingabe(searchQuery).begriff
    const timer = setTimeout(async () => {
      loadFoods(begriff)
      setOnlineResults(null); setOnlineError('')
      if (begriff.length < 2) { setRefResults([]); return }
      try {
        const res = await authFetch(`${API_BASE}/reference-foods?q=${encodeURIComponent(begriff)}`)
        setRefResults(res.ok ? await res.json() : [])
      } catch { setRefResults([]) }
    }, 250)
    return () => clearTimeout(timer)
  }, [searchQuery, loadFoods, authFetch])

  // Open Food Facts erlaubt nur wenige Textsuchen pro Minute -> nur auf Knopfdruck
  const searchOnline = async () => {
    const begriff = parseSchnelleingabe(searchQuery).begriff
    if (begriff.length < 2) return
    setOnlineLoading(true); setOnlineError('')
    try {
      const res = await authFetch(`${API_BASE}/online-foods?q=${encodeURIComponent(begriff)}`)
      if (!res.ok) throw new Error()
      setOnlineResults(await res.json())
    } catch { setOnlineError(t('dashboard.onlineError')); setOnlineResults([]) }
    finally { setOnlineLoading(false) }
  }

  // Auswahl aus Suche/BLS/Online: Menge aus der Schnelleingabe übernehmen
  const waehleLebensmittel = (food) => { setSelectedFood(food); setAmount(schnell.menge || '') }

  const handleEditLog = async (e) => {
    e.preventDefault()
    if (!editLogAmount || parseFloat(editLogAmount) <= 0) return
    setApiLoading(true)
    try {
      await authFetch(`${API_BASE}/logs/${editingLog.id}`, { method: 'DELETE' })
      await authFetch(`${API_BASE}/logs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ food_item_id: editingLog.food_item_id, amount_grams: parseFloat(editLogAmount) })
      })
      setSuccess(t('dashboard.itemUpdated', { name: editingLog.food_name }))
      setEditingLog(null)
      loadDashboard(selectedDate)
    } catch { setError(t('dashboard.updateError')) } finally { setApiLoading(false) }
  }

  const handleBarcodeScanned = async (barcode) => {
    setShowScanner(false)
    setApiLoading(true)
    try {
      const res = await authFetch(`${API_BASE}/foods/barcode/${barcode}`)
      const data = await res.json()
      if (!res.ok) throw new Error(data.detail || 'Nicht gefunden')
      setSelectedFood({ ...data, _fromBarcode: data.id === 0, _barcode: barcode })
      setActiveTab('search')
      setShowAddManual(true)
    } catch {
      setError(t('dashboard.productNotFound'))
      setActiveTab('custom')
      setShowAddManual(true)
    } finally { setApiLoading(false) }
  }

  const handleAddMeal = async () => {
    if (!selectedFood || !amount) return
    setApiLoading(true)
    try {
      let foodId = selectedFood.id
      if (selectedFood._fromReference) {
        // BLS-Eintrag -> eigene Kopie (neue Zeile bzw. früher übernommene wiederverwenden)
        const useRes = await authFetch(`${API_BASE}/reference-foods/${encodeURIComponent(selectedFood._fromReference)}/use`, { method: 'POST' })
        if (!useRes.ok) throw new Error(t('dashboard.logError'))
        foodId = (await useRes.json()).id
        loadFoods()
      } else if (selectedFood._fromBarcode) {
        const saveRes = await authFetch(`${API_BASE}/foods/barcode/${selectedFood._barcode}/save`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: selectedFood.name,
            brand: selectedFood.brand,
            calories_per_100g: selectedFood.calories_per_100g,
            protein_per_100g: selectedFood.protein_per_100g,
            carbs_per_100g: selectedFood.carbs_per_100g,
            fat_per_100g: selectedFood.fat_per_100g,
            fiber_per_100g: selectedFood.fiber_per_100g,
          })
        })
        const saved = await saveRes.json()
        foodId = saved.id
        loadFoods()
      }
      const logRes = await authFetch(`${API_BASE}/logs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ food_item_id: foodId, amount_grams: parseFloat(amount) })
      })
      if (!logRes.ok) throw new Error(t('dashboard.logError'))
      setSuccess(t('dashboard.itemAdded', { name: selectedFood.name }))
      setSelectedFood(null); setAmount(''); setShowAddManual(false)
      loadDashboard(selectedDate)
    } catch (err) {
      setError(err.message || t('dashboard.logError'))
    } finally { setApiLoading(false) }
  }

  const handleCreateCustomMeal = async (e) => {
    e.preventDefault()
    setApiLoading(true)
    try {
      const f = 100 / parseFloat(customAmount)
      const foodRes = await authFetch(`${API_BASE}/foods`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: customName, brand: 'Manuell',
          calories_per_100g: parseFloat(customKcal) * f,
          protein_per_100g:  (parseFloat(customProtein) || 0) * f,
          carbs_per_100g:    (parseFloat(customCarbs)   || 0) * f,
          fat_per_100g:      (parseFloat(customFat)     || 0) * f,
          fiber_per_100g:    (parseFloat(customFiber)   || 0) * f,
        })
      })
      const newFood = await foodRes.json()
      await authFetch(`${API_BASE}/logs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ food_item_id: newFood.id, amount_grams: parseFloat(customAmount) })
      })
      setSuccess(t('dashboard.mealLogged'))
      setShowAddManual(false)
      loadFoods(); loadDashboard(selectedDate)
      setCustomName(''); setCustomAmount(''); setCustomKcal('')
      setCustomProtein(''); setCustomCarbs(''); setCustomFat(''); setCustomFiber('')
    } catch { setError(t('dashboard.saveError')) } finally { setApiLoading(false) }
  }

  const handleDeleteLog = async (logId) => {
    if (!window.confirm(t('dashboard.deleteLogConfirm'))) return
    await authFetch(`${API_BASE}/logs/${logId}`, { method: 'DELETE' })
    loadDashboard(selectedDate)
  }

  const handleChangeUsername = async (e) => {
    e.preventDefault()
    if (!newUsername.trim()) return
    setApiLoading(true)
    try {
      const res = await authFetch(`${API_BASE}/auth/username`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username: newUsername.trim() })
      })
      if (!res.ok) {
        const err = await res.json()
        throw new Error(err.detail || t('app.error'))
      }
      await refreshUser()
      setSuccess(t('dashboard.usernameChanged'))
      setShowAccountMenu(false)
      setNewUsername('')
    } catch (err) { setError(err.message) } finally { setApiLoading(false) }
  }

  const handleDeleteAccount = async (e) => {
    e.preventDefault()
    const confirmWord = t('dashboard.deleteConfirmWord')
    if (deleteConfirm !== confirmWord) { setError(t('dashboard.deleteConfirmMismatch')); return }
    setApiLoading(true)
    try {
      const res = await authFetch(`${API_BASE}/auth/account`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password: deletePassword })
      })
      if (!res.ok) {
        const err = await res.json()
        throw new Error(err.detail || t('app.error'))
      }
      logout()
    } catch (err) { setError(err.message) } finally { setApiLoading(false) }
  }

  const handleFeedback = async (e) => {
    e.preventDefault()
    if (!feedbackMsg.trim()) return
    setApiLoading(true)
    try {
      const res = await authFetch(`${API_BASE}/auth/feedback`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: feedbackMsg })
      })
      if (!res.ok) throw new Error('Fehler')
      setFeedbackSent(true)
      setFeedbackMsg('')
      setTimeout(() => { setShowFeedback(false); setFeedbackSent(false) }, 2500)
    } catch { setError(t('dashboard.sendError')) } finally { setApiLoading(false) }
  }

  const handleResendVerification = async () => {
    try {
      await authFetch(`${API_BASE}/auth/resend-verification`, { method: 'POST' })
      setSuccess(t('dashboard.verificationSent'))
    } catch { setError(t('dashboard.sendError')) }
  }

  const handleChangePassword = async (e) => {
    e.preventDefault()
    if (pwNew !== pwConfirm) { setError(t('dashboard.passwordMismatch')); return }
    setApiLoading(true)
    try {
      const res = await authFetch(`${API_BASE}/auth/password`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ current_password: pwCurrent, new_password: pwNew })
      })
      if (!res.ok) {
        const err = await res.json()
        throw new Error(err.detail || t('app.error'))
      }
      setSuccess(t('dashboard.passwordChanged'))
      setShowAccountMenu(false)
      setAccountTab('menu')
      setPwCurrent(''); setPwNew(''); setPwConfirm('')
    } catch (err) { setError(err.message) } finally { setApiLoading(false) }
  }

  const handleAvatarUpload = async (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    if (file.size > 5 * 1024 * 1024) { setError(t('dashboard.avatarTooBig')); return }
    setApiLoading(true)
    try {
      const formData = new FormData()
      formData.append('file', file)
      const res = await authFetch(`${API_BASE}/auth/avatar`, { method: 'POST', body: formData })
      if (!res.ok) {
        const err = await res.json()
        throw new Error(err.detail || t('dashboard.uploadFailed'))
      }
      setSuccess(t('dashboard.avatarUpdated'))
      await refreshUser()
    } catch (err) {
      setError(err.message || t('dashboard.uploadFailed'))
    } finally {
      setApiLoading(false)
      e.target.value = ''
    }
  }

  const handleSaveGoals = async (e) => {
    e.preventDefault()
    setApiLoading(true)
    try {
      const res = await authFetch(`${API_BASE}/auth/goals`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          goal_kcal:    parseInt(goalInputKcal,    10),
          goal_protein: parseInt(goalInputProtein, 10),
          goal_carbs:   parseInt(goalInputCarbs,   10),
          goal_fat:     parseInt(goalInputFat,     10),
          goal_fiber:   parseInt(goalInputFiber,   10),
        })
      })
      const updated = await res.json()
      setGoals({
        kcal:    updated.goal_kcal,
        protein: updated.goal_protein,
        carbs:   updated.goal_carbs,
        fat:     updated.goal_fat,
        fiber:   updated.goal_fiber,
      })
      setShowEditGoals(false)
      setSuccess(t('dashboard.goalsSaved'))
    } catch { setError(t('dashboard.saveError')) } finally { setApiLoading(false) }
  }

  const handleGoalUpdate = (updated) => {
    setGoals({
      kcal:    updated.goal_kcal,
      protein: updated.goal_protein,
      carbs:   updated.goal_carbs,
      fat:     updated.goal_fat,
      fiber:   updated.goal_fiber,
    })
  }

  const isToday = !selectedDate || selectedDate === new Date().toISOString().split('T')[0]

  const goToPrevDay = () => {
    const base = selectedDate ? new Date(selectedDate) : new Date()
    base.setDate(base.getDate() - 1)
    setSelectedDate(base.toISOString().split('T')[0])
  }

  const goToNextDay = () => {
    if (isToday) return
    const base = new Date(selectedDate)
    base.setDate(base.getDate() + 1)
    const next = base.toISOString().split('T')[0]
    const today = new Date().toISOString().split('T')[0]
    setSelectedDate(next >= today ? null : next)
  }

  const formatDisplayDate = () => {
    const date = selectedDate ? new Date(selectedDate + 'T12:00:00') : new Date()
    const today = new Date()
    const yesterday = new Date(); yesterday.setDate(today.getDate() - 1)
    const locale = i18n.language.startsWith('de') ? 'de-DE' : 'en-US'
    if (!selectedDate) return `${t('dashboard.today')}, ${date.toLocaleDateString(locale, { day: 'numeric', month: 'long' })}`
    if (date.toDateString() === yesterday.toDateString()) return `${t('dashboard.yesterday')}, ${date.toLocaleDateString(locale, { day: 'numeric', month: 'long' })}`
    return date.toLocaleDateString(locale, { weekday: 'long', day: 'numeric', month: 'long' })
  }

  const handleDeleteFood = async (foodId, foodName) => {
    if (!window.confirm(t('dashboard.deleteFoodConfirm', { name: foodName }))) return
    try {
      await authFetch(`${API_BASE}/foods/${foodId}`, { method: 'DELETE' })
      setSuccess(t('dashboard.itemDeleted', { name: foodName }))
      loadFoods()
    } catch { setError(t('dashboard.deleteError')) }
  }

  const handleToggleFamily = async (food) => {
    try {
      const res = await authFetch(`${API_BASE}/foods/${food.id}/toggle-family`, { method: 'POST' })
      const updated = await res.json()
      setSuccess(updated.is_family ? `${updated.name} wird mit der Familie geteilt` : `${updated.name} wird nicht mehr geteilt`)
      loadFoods()
    } catch { setError('Fehler beim Teilen') }
  }

  const handleEditFood = (food) => {
    setEditingFood(food)
    setEditForm({
      name: food.name,
      brand: food.brand || '',
      calories_per_100g: food.calories_per_100g || '',
      protein_per_100g: food.protein_per_100g || '',
      carbs_per_100g: food.carbs_per_100g || '',
      fat_per_100g: food.fat_per_100g || '',
      fiber_per_100g: food.fiber_per_100g || '',
      portion_label: food.portion_label || '',
      portion_size_g: food.portion_size_g || '',
    })
  }

  const handleSaveEditFood = async (e) => {
    e.preventDefault()
    setApiLoading(true)
    try {
      const res = await authFetch(`${API_BASE}/foods/${editingFood.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: editForm.name,
          brand: editForm.brand || null,
          calories_per_100g: parseFloat(editForm.calories_per_100g) || null,
          protein_per_100g:  parseFloat(editForm.protein_per_100g) || null,
          carbs_per_100g:    parseFloat(editForm.carbs_per_100g) || null,
          fat_per_100g:      parseFloat(editForm.fat_per_100g) || null,
          fiber_per_100g:    parseFloat(editForm.fiber_per_100g) || null,
          portion_label:     editForm.portion_label || null,
          portion_size_g:    parseFloat(editForm.portion_size_g) || null,
        })
      })
      if (!res.ok) throw new Error('Fehler')
      setSuccess(t('dashboard.foodSaved', { name: editForm.name }))
      setEditingFood(null)
      loadFoods()
    } catch { setError(t('dashboard.saveError')) } finally { setApiLoading(false) }
  }

  const checkPushStatus = async () => {
    if (!('Notification' in window) || !('serviceWorker' in navigator)) return
    if (Notification.permission === 'granted') {
      const reg = await navigator.serviceWorker.ready
      const sub = await reg.pushManager.getSubscription()
      setPushEnabled(!!sub)
    }
  }

  const togglePush = async () => {
    if (!('Notification' in window)) { setError(t('dashboard.pushNotSupported')); return }
    setPushLoading(true)
    try {
      const reg = await navigator.serviceWorker.ready
      if (pushEnabled) {
        const sub = await reg.pushManager.getSubscription()
        if (sub) {
          await authFetch(`${API_BASE}/push/unsubscribe`, {
            method: 'DELETE',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ endpoint: sub.endpoint, p256dh: btoa(String.fromCharCode(...new Uint8Array(sub.getKey('p256dh')))), auth: btoa(String.fromCharCode(...new Uint8Array(sub.getKey('auth')))) })
          })
          await sub.unsubscribe()
        }
        setPushEnabled(false)
        setSuccess(t('dashboard.pushDisabled'))
      } else {
        const permission = await Notification.requestPermission()
        if (permission !== 'granted') { setError(t('dashboard.pushDenied')); return }
        const keyRes = await authFetch(`${API_BASE}/push/vapid-public-key`)
        const { public_key } = await keyRes.json()
        const sub = await reg.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: public_key
        })
        await authFetch(`${API_BASE}/push/subscribe`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            endpoint: sub.endpoint,
            p256dh: btoa(String.fromCharCode(...new Uint8Array(sub.getKey('p256dh')))),
            auth: btoa(String.fromCharCode(...new Uint8Array(sub.getKey('auth'))))
          })
        })
        setPushEnabled(true)
        setSuccess(t('dashboard.pushEnabled'))
      }
    } catch (e) { setError('Fehler: ' + e.message) } finally { setPushLoading(false) }
  }

  const saveReminderTime = async (time) => {
    setReminderTime(time)
    setReminderSaving(true)
    try {
      await authFetch(`${API_BASE}/auth/reminder`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reminder_time: time || null })
      })
      setSuccess(time ? t('dashboard.reminderSet', { time }) : t('dashboard.reminderDisabled'))
    } catch { setError(t('dashboard.saveError')) }
    finally { setReminderSaving(false) }
  }

  const openEditGoals = () => {
    setGoalInputKcal(goals.kcal); setGoalInputProtein(goals.protein)
    setGoalInputCarbs(goals.carbs); setGoalInputFat(goals.fat); setGoalInputFiber(goals.fiber)
    setShowEditGoals(true)
  }

  const offlineBanner = (
    <div className="bg-orange-900/40 border border-orange-500/50 rounded-2xl px-4 py-3 mb-4 flex items-center justify-between gap-3">
      <div>
        <p className="text-orange-300 font-black text-sm">{t('dashboard.offlineMode')}</p>
        <p className="text-orange-400/70 text-xs mt-0.5">
          {offlineQueue > 0
            ? t('dashboard.offlineQueueText', { count: offlineQueue })
            : t('dashboard.offlineNewText')}
        </p>
      </div>
      {offlineQueue > 0 && (
        <span className="bg-orange-500 text-white font-black text-xs px-2 py-1 rounded-xl">{offlineQueue}</span>
      )}
    </div>
  )

  const deleteConfirmWord = t('dashboard.deleteConfirmWord')

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 pb-32 px-4 pt-4 safe-top safe-bottom relative selection:bg-emerald-700 selection:text-white flex flex-col">
      <div className="flex-grow">

        {/* Toast Messages */}
        {(error || success) && (
          <div className="fixed top-4 left-4 right-4 z-50 space-y-2 pointer-events-none">
            {error && <div className="p-4 bg-rose-600 text-white rounded-2xl shadow-2xl font-bold text-center pointer-events-auto">⚠️ {error}</div>}
            {success && <div className="p-4 bg-emerald-700 text-white rounded-2xl shadow-2xl font-bold text-center pointer-events-auto">✓ {success}</div>}
          </div>
        )}

        {/* E-Mail Verifikations-Banner */}
        {!user.is_verified && (
          <div className="bg-amber-900/40 border border-amber-500/50 rounded-2xl px-4 py-3 mb-4 flex items-center justify-between gap-3">
            <div>
              <p className="text-amber-300 font-black text-sm">{t('dashboard.emailNotVerified')}</p>
              <p className="text-amber-400/70 text-xs mt-0.5">{t('dashboard.emailNotVerifiedSub')}</p>
            </div>
            <button onClick={handleResendVerification}
              className="text-xs bg-amber-500 hover:bg-amber-400 text-slate-900 font-black px-3 py-1.5 rounded-xl whitespace-nowrap transition-colors">
              {t('dashboard.resend')}
            </button>
          </div>
        )}

        {/* Offline Banner */}
        {!isOnline && offlineBanner}

        {/* Header */}
        <div className="flex justify-between items-center py-1 mb-5">
          <div className="flex items-center gap-3">
            <label className="cursor-pointer relative group">
              <input type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={handleAvatarUpload} />
              {user.avatar_path ? (
                <img src={user.avatar_path} alt="Avatar"
                  className="w-10 h-10 rounded-full object-cover ring-1 ring-slate-700 group-hover:ring-emerald-500 transition-all" />
              ) : (
                <div className={`w-10 h-10 rounded-full flex items-center justify-center text-lg bg-gradient-to-r ${userColor} ring-1 ring-slate-700 group-hover:ring-emerald-500 transition-all`}>
                  👤
                </div>
              )}
              <div className="absolute inset-0 rounded-full bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                <span className="text-white text-xs">📷</span>
              </div>
            </label>
            <div>
              <div className="text-xs text-slate-400 font-medium">{t('dashboard.loggedInAs')}</div>
              <div className="font-bold text-base leading-tight text-white">{user.username}</div>
            </div>
          </div>
          <div className="flex gap-2">
            {user.is_admin && (
              <button onClick={() => setShowAdmin(true)}
                className="h-11 w-11 flex items-center justify-center text-amber-400 rounded-xl hover:bg-slate-800 transition-colors text-sm border border-slate-700"
                title="Admin Panel">
                🛡️
              </button>
            )}
            <button
              onClick={() => { setShowAccountMenu(true); setAccountTab('menu') }}
              className="h-11 px-4 text-slate-200 font-semibold rounded-xl hover:bg-slate-800 transition-colors text-sm border border-slate-700"
            >
              {t('dashboard.account')}
            </button>
          </div>
        </div>

        {/* Main Tab Switcher — volle Breite mit Unterstrich (wie IronBandit) */}
        <div className="flex border-b border-slate-700 mb-6">
          {[['nutrition', 'tabNutrition'], ['weight', 'tabWeight']].map(([tab, key]) => (
            <button key={tab} onClick={() => setActiveMainTab(tab)}
              className={`flex-1 py-3 -mb-px border-b-2 text-sm transition-colors ${
                activeMainTab === tab ? 'border-emerald-500 text-white font-bold' : 'border-transparent text-slate-400 font-medium hover:text-white'
              }`}>
              {t(`dashboard.${key}`)}
            </button>
          ))}
        </div>

        {activeMainTab === 'weight' && (
          <WeightTracker user={user} onGoalUpdate={handleGoalUpdate} userColor={userColor} />
        )}

        {activeMainTab === 'nutrition' && (<>

        <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4 mb-6">
          <div>
            <h1 className="text-3xl font-black tracking-tight text-white">{t('dashboard.title')}</h1>
            <div className="flex items-center gap-2 mt-2">
              <button onClick={goToPrevDay} aria-label="Vorheriger Tag" className="w-10 h-10 flex items-center justify-center border border-slate-700 hover:bg-slate-800 text-white rounded-xl transition-colors text-lg">‹</button>
              <span className="text-sm text-slate-300 font-bold min-w-[180px] text-center">{formatDisplayDate()}</span>
              <button onClick={goToNextDay} disabled={isToday}
                aria-label="Nächster Tag" className="w-10 h-10 flex items-center justify-center border border-slate-700 hover:bg-slate-800 disabled:opacity-30 disabled:cursor-not-allowed text-white rounded-xl transition-colors text-lg">›</button>
              {!isToday && (
                <button onClick={() => setSelectedDate(null)} className="text-xs text-emerald-400 font-black hover:text-emerald-300 transition-colors ml-1">
                  {t('dashboard.today')}
                </button>
              )}
            </div>
          </div>
        </div>

        {totals && (
          <>
            <div className="bg-slate-800 rounded-2xl p-5 border border-slate-700/70 mb-4">
              <div className="flex justify-between items-start mb-2">
                <h2 className="text-slate-400 text-sm font-semibold">{t('dashboard.calorieOverview')}</h2>
              </div>
              <div className="flex items-end justify-between gap-2 mb-4">
                <div className="flex items-baseline gap-2">
                  <span className="text-5xl font-extrabold tracking-tight text-white leading-none">{Math.round(totals.calories || 0)}</span>
                  <span className="text-slate-400 font-medium text-base">/ {goals.kcal} kcal</span>
                </div>
                <div className="text-right leading-tight">
                  <div className={`text-xl font-bold ${(goals.kcal - (totals.calories || 0)) >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>{Math.abs(Math.round(goals.kcal - (totals.calories || 0)))}</div>
                  <div className="text-xs text-slate-400">{(goals.kcal - (totals.calories || 0)) >= 0 ? t('dashboard.remaining') : t('dashboard.over')}</div>
                </div>
              </div>
              <div className="w-full bg-slate-900 h-2 rounded overflow-hidden">
                <div className={`h-full rounded transition-all duration-1000 ${pctRoh(totals.calories, goals.kcal) > 105 ? 'kcal-blink' : ''}`}
                  style={{ width: `${pct(totals.calories, goals.kcal)}%`, backgroundColor: kalorienFarbe(pctRoh(totals.calories, goals.kcal)) }} />
              </div>
              <div className="flex justify-between items-center mt-2">
                <span className="text-sm text-slate-400">{t('dashboard.progressOfGoal', { pct: Math.round(pctRoh(totals.calories, goals.kcal)) })}</span>
                <button onClick={openEditGoals}
                  className="py-2 text-emerald-400 hover:text-emerald-300 font-semibold text-sm transition-colors">
                  {t('dashboard.adjustGoals')}
                </button>
              </div>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5 mb-5">
              {[
                { key: 'macroProtein', value: totals.protein, goal: goals.protein, barColor: 'bg-blue-500',   labelColor: 'text-blue-400' },
                { key: 'macroCarbs',   value: totals.carbs,   goal: goals.carbs,   barColor: 'bg-amber-500',  labelColor: 'text-amber-400' },
                { key: 'macroFat',     value: totals.fat,     goal: goals.fat,     barColor: 'bg-rose-500',   labelColor: 'text-rose-400' },
                { key: 'macroFiber',   value: totals.fiber,   goal: goals.fiber,   barColor: 'bg-lime-500',   labelColor: 'text-lime-400' },
              ].map(({ key, value, goal: g, barColor, labelColor }) => (
                <div key={key} className="bg-slate-800 border border-slate-700/70 rounded-xl p-3.5 flex flex-col">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-[13px] text-slate-300 font-semibold">{t(`dashboard.${key}Short`)}</span>
                    <span className={`w-2 h-2 rounded-full ${barColor}`} />
                  </div>
                  <div className="text-[22px] font-bold text-white leading-none">
                    {Math.round(value || 0)} <span className="text-sm font-normal text-slate-400">/ {g} g</span>
                  </div>
                  <div className="w-full bg-slate-900 h-1 rounded mt-3 overflow-hidden">
                    <div className={`${barColor} h-full rounded transition-all duration-700`} style={{ width: `${pct(value, g)}%` }} />
                  </div>
                </div>
              ))}
            </div>
          </>
        )}

        {/* Wochen/Monats Tabs */}
        <div className="mb-4">
          <div className="flex bg-slate-800 border border-slate-700/70 p-1 rounded-xl mb-3">
            <button onClick={() => setOverviewTab('week')}
              className={`flex-1 py-2 rounded-lg text-sm transition-colors ${overviewTab === 'week' ? 'bg-slate-900 text-white font-semibold' : 'text-slate-400 font-medium hover:text-white'}`}>
              {t('dashboard.tabWeek')}
            </button>
            <button onClick={() => setOverviewTab('month')}
              className={`flex-1 py-2 rounded-lg text-sm transition-colors ${overviewTab === 'month' ? 'bg-slate-900 text-white font-semibold' : 'text-slate-400 font-medium hover:text-white'}`}>
              {t('dashboard.tabMonth')}
            </button>
          </div>
          {overviewTab === 'week' ? (
            <WeeklyTracker calorieGoal={goals.kcal} />
          ) : (
            <div className="bg-slate-800 border border-slate-700/70 rounded-2xl p-4">
              <MonthlyStats userColor={userColor} />
            </div>
          )}
        </div>

        {isToday && (
          <div className="grid grid-cols-2 gap-2.5 mb-6">
            <button onClick={() => setShowFoodManager(true)}
              className="h-12 rounded-xl border border-slate-600 text-slate-200 font-semibold flex items-center justify-center gap-2 hover:bg-slate-800 transition-colors text-sm">
              {t('dashboard.foodDatabase')}
            </button>
            <button onClick={() => setShowScanner(true)}
              className="h-12 rounded-xl bg-amber-500 text-slate-950 font-bold flex items-center justify-center gap-2 hover:bg-amber-400 transition-colors text-sm">
              {t('dashboard.scanBarcode')}
            </button>
          </div>
        )}

        {/* Heute verzehrt */}
        <div className="space-y-4">
          <div className="flex justify-between items-baseline">
            <h2 className="text-lg font-bold text-white">{isToday ? t('dashboard.todayConsumed') : t('dashboard.meals')}</h2>
            {logs.length > 0 && <span className="text-sm text-slate-400">{t('dashboard.entryCount', { count: logs.length })}</span>}
          </div>
          {logs.length === 0 ? (
            <div className="bg-slate-800/50 rounded-2xl border border-slate-700/70 text-center py-10">
              <p className="text-slate-400 font-medium">{t('dashboard.noEntries')}</p>
            </div>
          ) : (
            <div className="bg-slate-800 border border-slate-700/70 rounded-2xl overflow-hidden divide-y divide-slate-700/50">
              {logs.map((log) => (
                <div key={log.id} className="py-3 pl-4 pr-2 flex items-center justify-between">
                  <div className="flex-1 min-w-0">
                    <div className="flex justify-between gap-3">
                      <h3 className="font-semibold text-slate-100 text-[15px] truncate">{log.food_name}</h3>
                      <span className="font-bold text-white text-[15px] whitespace-nowrap">{Math.round(log.calories)} kcal</span>
                    </div>
                    <div className="flex flex-wrap gap-x-3 gap-y-0.5 mt-1 text-xs text-slate-400">
                      <span className="text-amber-400 font-semibold">{log.amount_grams} g</span>
                      <span><span className="text-blue-400">P</span> {log.protein.toFixed(1)}</span>
                      <span><span className="text-amber-400">K</span> {log.carbs.toFixed(1)}</span>
                      <span><span className="text-rose-400">F</span> {log.fat.toFixed(1)}</span>
                      <span><span className="text-lime-400">B</span> {log.fiber.toFixed(1)}</span>
                    </div>
                  </div>
                  {isToday && (
                    <div className="flex ml-1">
                      <button onClick={() => { setEditingLog(log); setEditLogAmount(log.amount_grams.toString()) }}
                        aria-label={t('dashboard.editEntry')} className="w-10 h-11 rounded-lg text-slate-400 flex items-center justify-center hover:bg-slate-700 hover:text-amber-400 transition-colors">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M4 20h4L19 9l-4-4L4 16v4z" /></svg>
                      </button>
                      <button onClick={() => handleDeleteLog(log.id)}
                        aria-label={t('dashboard.deleteEntry')} className="w-10 h-11 rounded-lg text-slate-400 flex items-center justify-center hover:bg-slate-700 hover:text-rose-400 transition-colors">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18" /></svg>
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        </>)}
      </div>

      {/* Footer */}
      <div className="mt-12 mb-6 text-center space-y-3">
        <div className="inline-flex items-center gap-0.5 text-sm font-semibold">
          <button onClick={() => setShowFeedback(true)} className="hover:opacity-80 transition-opacity" title="Feedback senden">
            <span className="text-orange-400">Crash</span>
            <span className="text-emerald-400">Bandit</span>
            <span className="text-slate-500 font-black">82</span>
          </button>
        </div>
        <div>
          <button onClick={() => setShowShake(true)} className="text-sm text-slate-500 hover:text-slate-300 transition-colors">
            🥤 Buy me a Shake
          </button>
        </div>
        <p className="text-slate-500 opacity-60 text-[10px] font-mono tracking-wider">v{__APP_VERSION__}</p>
      </div>

      {/* FAB */}
      {isToday && (
        <button onClick={() => { setSelectedFood(null); setShowAddManual(true) }}
          className={`fixed left-4 right-4 bottom-6 mx-auto max-w-md h-14 bg-gradient-to-r ${userColor} text-white rounded-xl shadow-xl flex items-center justify-center gap-2 text-base font-bold z-30`}
          style={{ marginBottom: 'env(safe-area-inset-bottom)' }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" aria-hidden="true"><path d="M12 5v14M5 12h14" /></svg>
          {t('dashboard.addMealButton')}
        </button>
      )}

      {/* MODAL: Feedback */}
      {showFeedback && (
        <div className="fixed inset-0 bg-slate-950/70 z-50 flex items-center justify-center p-4">
          <div className="bg-slate-800 border border-slate-700/70 rounded-2xl w-full max-w-md shadow-2xl">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-700">
              <h2 className="text-white font-black text-lg">{t('dashboard.feedbackTitle')}</h2>
              <button onClick={() => { setShowFeedback(false); setFeedbackSent(false); setFeedbackMsg('') }}
                className="text-slate-400 hover:text-white text-2xl leading-none transition-colors">✕</button>
            </div>
            <div className="px-6 py-6">
              {feedbackSent ? (
                <div className="text-center space-y-4 py-4">
                  <div className="text-5xl">🎉</div>
                  <p className="text-emerald-400 font-black text-lg">{t('dashboard.feedbackThanks')}</p>
                  <p className="text-slate-400 text-sm">{t('dashboard.feedbackWillContact')}</p>
                </div>
              ) : (
                <form onSubmit={handleFeedback} className="space-y-4">
                  <div>
                    <label className="block text-xs font-bold text-slate-400 mb-1">{t('dashboard.feedbackUsernameLabel')}</label>
                    <input type="text" value={user.username} readOnly
                      className="w-full bg-slate-900 border border-slate-700 text-slate-400 rounded-xl px-4 py-3 font-bold outline-none cursor-not-allowed" />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-400 mb-1">{t('dashboard.feedbackLabel')}</label>
                    <textarea value={feedbackMsg} onChange={e => setFeedbackMsg(e.target.value)}
                      placeholder={t('dashboard.feedbackPlaceholder')}
                      rows={5} required autoFocus
                      className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-3 font-bold outline-none focus:ring-2 focus:ring-emerald-500 placeholder-slate-600 resize-none" />
                  </div>
                  <div className="flex gap-2">
                    <button type="button" onClick={() => { setShowFeedback(false); setFeedbackMsg('') }}
                      className="flex-1 bg-slate-700 text-white font-bold py-3 rounded-xl">
                      {t('dashboard.cancelButton')}
                    </button>
                    <button type="submit" disabled={apiLoading || !feedbackMsg.trim()}
                      className={`flex-1 bg-gradient-to-r ${userColor} text-white font-black py-3 rounded-xl disabled:opacity-50`}>
                      {apiLoading ? t('dashboard.sending') : t('dashboard.sendButton')}
                    </button>
                  </div>
                </form>
              )}
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Buy me a Shake */}
      {showShake && (
        <div className="fixed inset-0 bg-slate-950/70 z-50 flex items-center justify-center p-4">
          <div className="bg-slate-800 border border-slate-700/70 rounded-2xl w-full max-w-md shadow-2xl">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-700">
              <h2 className="text-white font-semibold text-lg">{t('dashboard.shakeTitle')}</h2>
              <button onClick={() => setShowShake(false)} className="text-slate-400 hover:text-white text-2xl leading-none transition-colors">✕</button>
            </div>
            <div className="px-6 py-6 space-y-5">
              <p className="text-slate-400 text-sm leading-relaxed">{t('dashboard.shakeText')}</p>
              <a href="https://www.paypal.me/GeriPe" target="_blank" rel="noopener noreferrer"
                className="flex items-center justify-center gap-3 w-full bg-blue-600 hover:bg-blue-500 text-white font-black py-3.5 rounded-2xl transition-colors text-sm">
                {t('dashboard.shakePaypal')}
              </a>
              <div className="bg-slate-900 border border-slate-700 rounded-2xl p-4 text-center space-y-3">
                <p className="text-slate-400 text-xs font-bold">{t('dashboard.shakeSEPA')}</p>
                <div className="flex justify-center">
                  <img src="/qr-code.svg" alt="SEPA QR Code" className="w-40 h-40 rounded-lg bg-white p-2" />
                </div>
                <p className="text-slate-500 text-xs leading-relaxed whitespace-pre-line">{t('dashboard.shakeSEPAText')}</p>
              </div>
              <button onClick={() => setShowShake(false)}
                className="w-full bg-slate-700 hover:bg-slate-600 text-slate-300 font-bold py-3 rounded-2xl transition-colors text-sm">
                {t('dashboard.close')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Log-Menge bearbeiten */}
      {editingLog && (
        <div className="fixed inset-0 bg-slate-950/70 z-50 flex items-center justify-center p-4">
          <div className="bg-slate-800 w-full max-w-sm rounded-3xl p-6 border border-slate-700 shadow-2xl">
            <h2 className="text-xl font-black text-white mb-1">{t('dashboard.editAmountTitle')}</h2>
            <p className="text-slate-400 text-sm mb-4">{editingLog.food_name}</p>
            <form onSubmit={handleEditLog} className="space-y-4">
              <div className="relative">
                <input type="number" step="1" min="1" value={editLogAmount}
                  onChange={e => setEditLogAmount(e.target.value)}
                  className="w-full text-3xl font-black bg-slate-900 border border-slate-700 text-white rounded-2xl px-4 py-4 outline-none focus:ring-2 focus:ring-emerald-500 pr-16 text-center"
                  autoFocus />
                <span className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 font-bold text-lg">g</span>
              </div>
              <div className="text-center text-xs text-slate-500">
                {t('dashboard.currentAmount', { grams: editingLog.amount_grams, kcal: Math.round(editingLog.calories) })}
              </div>
              <div className="flex gap-2">
                <button type="button" onClick={() => setEditingLog(null)}
                  className="flex-1 bg-slate-700 text-white font-bold py-3 rounded-xl">{t('dashboard.cancelButton')}</button>
                <button type="submit" disabled={apiLoading}
                  className={`flex-1 bg-gradient-to-r ${userColor} text-white font-black py-3 rounded-xl disabled:opacity-50`}>
                  {apiLoading ? '...' : t('dashboard.saveButton')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {showScanner && <BarcodeScanner onScan={handleBarcodeScanned} onClose={() => setShowScanner(false)} />}

      {/* MODAL: Lebensmittel-Datenbank */}
      {showFoodManager && (
        <div className="fixed inset-0 bg-slate-950/70 z-40 flex items-center justify-center p-4">
          <div className="bg-slate-800 w-full max-w-lg rounded-3xl p-6 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-2xl font-black text-white">{t('dashboard.foodDbTitle')}</h2>
              <button onClick={() => setShowFoodManager(false)} className="text-slate-400 text-xl">✕</button>
            </div>
            <p className="text-slate-500 text-xs mb-4">{t('dashboard.foodDbInfo')}</p>
            <div className="space-y-2">
              {foods.filter(f => f.user_id !== null).length === 0 ? (
                <p className="text-slate-500 text-center py-6 text-sm">{t('dashboard.noOwnFoods')}</p>
              ) : (
                foods.filter(f => f.user_id !== null).map(f => (
                  <div key={f.id} className="bg-slate-900 rounded-2xl p-3 flex items-center justify-between gap-3">
                    <div className="flex-1 min-w-0">
                      <div className="text-white font-bold text-sm truncate">{f.name}</div>
                      <div className="text-slate-500 text-xs">{Math.round(f.calories_per_100g || 0)} kcal · P:{f.protein_per_100g?.toFixed(1)}g · K:{f.carbs_per_100g?.toFixed(1)}g · F:{f.fat_per_100g?.toFixed(1)}g</div>
                    </div>
                    <div className="flex gap-2 flex-shrink-0">
                      {user?.is_family_member && (
                        <button onClick={() => handleToggleFamily(f)}
                          title={f.is_family ? 'Nicht mehr teilen' : 'Mit Familie teilen'}
                          className={`w-9 h-9 rounded-xl flex items-center justify-center text-sm hover:bg-slate-700 ${f.is_family ? 'bg-emerald-900/40 text-emerald-400' : 'bg-slate-800 text-slate-500'}`}>
                          👨‍👩‍👧
                        </button>
                      )}
                      <button onClick={() => { handleEditFood(f); setShowFoodManager(false) }}
                        className="w-9 h-9 rounded-xl bg-slate-800 text-amber-400 flex items-center justify-center text-sm hover:bg-slate-700">✏️</button>
                      <button onClick={() => handleDeleteFood(f.id, f.name)}
                        className="w-9 h-9 rounded-xl bg-slate-800 text-rose-400 flex items-center justify-center text-sm hover:bg-slate-700">🗑️</button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      )}

      {/* MODAL: Lebensmittel bearbeiten */}
      {editingFood && (
        <div className="fixed inset-0 bg-slate-950/70 z-50 flex items-end justify-center">
          <div className="bg-slate-800 w-full max-w-lg rounded-t-3xl p-6 shadow-2xl safe-bottom max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-black text-white">{t('dashboard.editFoodTitle')}</h2>
              <button onClick={() => setEditingFood(null)} className="text-slate-400 text-xl">✕</button>
            </div>
            <form onSubmit={handleSaveEditFood} className="space-y-3">
              <div>
                <label className="block text-xs font-bold text-slate-400 mb-1">{t('dashboard.nameLabel')}</label>
                <input type="text" value={editForm.name} onChange={e => setEditForm({...editForm, name: e.target.value})}
                  className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-3 py-2 font-bold outline-none" required />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-400 mb-1">{t('dashboard.brandLabel')}</label>
                <input type="text" value={editForm.brand} onChange={e => setEditForm({...editForm, brand: e.target.value})}
                  className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-3 py-2 outline-none" />
              </div>
              <div className="grid grid-cols-2 gap-2">
                {[
                  ['calories_per_100g', t('dashboard.kcalPer100g')],
                  ['protein_per_100g',  t('dashboard.proteinG')],
                  ['carbs_per_100g',    t('dashboard.carbsG')],
                  ['fat_per_100g',      t('dashboard.fatG')],
                  ['fiber_per_100g',    t('dashboard.fiberG')],
                ].map(([key, label]) => (
                  <div key={key}>
                    <label className="block text-xs font-bold text-slate-400 mb-1">{label}</label>
                    <input type="number" step="0.1" value={editForm[key]}
                      onChange={e => setEditForm({...editForm, [key]: e.target.value})}
                      className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-3 py-2 outline-none" />
                  </div>
                ))}
                <div>
                  <label className="block text-xs font-bold text-slate-400 mb-1">{t('dashboard.portionLabel')}</label>
                  <input type="text" placeholder={t('dashboard.portionLabelPlaceholder')} value={editForm.portion_label}
                    onChange={e => setEditForm({...editForm, portion_label: e.target.value})}
                    className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-3 py-2 outline-none placeholder-slate-600" />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-400 mb-1">{t('dashboard.portionGrams')}</label>
                  <input type="number" step="1" placeholder={t('dashboard.portionGramsPlaceholder')} value={editForm.portion_size_g}
                    onChange={e => setEditForm({...editForm, portion_size_g: e.target.value})}
                    className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-3 py-2 outline-none placeholder-slate-600" />
                </div>
              </div>
              <div className="flex gap-2 pt-2">
                <button type="button" onClick={() => setEditingFood(null)} className="flex-1 bg-slate-700 text-white font-bold py-3 rounded-xl">{t('dashboard.cancelButton')}</button>
                <button type="submit" disabled={apiLoading} className={`flex-1 bg-gradient-to-r ${userColor} text-white font-black py-3 rounded-xl disabled:opacity-50`}>
                  {apiLoading ? '...' : t('dashboard.saveButton')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {showAdmin && <AdminPanel onClose={() => setShowAdmin(false)} />}

      {/* MODAL: Konto — Redesign 2026-10: Fenster von unten (Handy), Liste mit Symbolen */}
      {showAccountMenu && (
        <div className="fixed inset-0 bg-slate-950/70 z-50 flex items-end sm:items-center justify-center sm:p-4">
          <div className="bg-slate-900 border-t sm:border border-slate-700/70 w-full max-w-md rounded-t-2xl sm:rounded-2xl px-5 pt-3 pb-6 shadow-2xl max-h-[92vh] overflow-y-auto"
            style={{ paddingBottom: 'calc(1.5rem + env(safe-area-inset-bottom))' }}>
            <div className="mx-auto mb-3 h-1 w-10 rounded bg-slate-700 sm:hidden" />
            {!isOnline && offlineBanner}

            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-1">
                {accountTab !== 'menu' && (
                  <button onClick={() => setAccountTab('menu')} aria-label={t('dashboard.backToMenu')}
                    className="w-10 h-10 -ml-2 flex items-center justify-center rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 transition-colors">
                    <Ico d="M15 6l-6 6 6 6" />
                  </button>
                )}
                <h2 className="text-xl font-extrabold text-white tracking-tight">
                  {accountTab === 'menu'     && t('dashboard.accountTitle')}
                  {accountTab === 'username' && t('dashboard.accountUsername')}
                  {accountTab === 'password' && t('dashboard.accountPassword')}
                  {accountTab === 'delete'   && t('dashboard.accountDelete')}
                </h2>
              </div>
              <button onClick={() => { setShowAccountMenu(false); setAccountTab('menu'); setDeletePassword(''); setDeleteConfirm(''); setPwCurrent(''); setPwNew(''); setPwConfirm(''); setNewUsername('') }}
                aria-label={t('dashboard.close')}
                className="w-11 h-11 -mr-2 flex items-center justify-center rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 transition-colors">
                <Ico d="M6 6l12 12M18 6L6 18" />
              </button>
            </div>

            {accountTab === 'menu' && (
              <div className="space-y-4">
                <div className="bg-slate-800 border border-slate-700/70 rounded-xl divide-y divide-slate-700/60 overflow-hidden">
                  {[
                    { onClick: () => { setAccountTab('username'); setNewUsername(user.username) }, icon: 'M12 12a4 4 0 100-8 4 4 0 000 8zM4 21a8 8 0 0116 0', title: t('dashboard.changeUsernameTitle'), sub: `${t('dashboard.currentLabel')} ${user.username}`, chevron: true },
                    { onClick: () => setAccountTab('password'), icon: 'M8 20a4 4 0 100-8 4 4 0 000 8zM11 13l9-9M17 7l3 3', title: t('dashboard.changePasswordTitle'), sub: t('dashboard.changePasswordSub'), chevron: true },
                    { onClick: async () => {
                        try {
                          const res = await authFetch(`${API_BASE}/auth/export`)
                          const blob = await res.blob()
                          const url = URL.createObjectURL(blob)
                          const a = document.createElement('a')
                          a.href = url
                          a.download = `macrobandit_export_${new Date().toISOString().slice(0,10)}.csv`
                          a.click()
                          URL.revokeObjectURL(url)
                        } catch { setError(t('dashboard.exportFailed')) }
                      }, icon: 'M12 4v11M7 10l5 5 5-5M5 20h14', title: t('dashboard.exportTitle'), sub: t('dashboard.exportSub') },
                    { onClick: togglePush, disabled: pushLoading,
                      icon: pushEnabled ? 'M6 16v-5a6 6 0 0112 0v5l2 2H4l2-2zM10 21h4M4 4l16 16' : 'M6 16v-5a6 6 0 0112 0v5l2 2H4l2-2zM10 21h4',
                      title: pushLoading ? t('dashboard.waitButton') : pushEnabled ? t('dashboard.notifDisable') : t('dashboard.notifEnable'),
                      sub: t('dashboard.notifSub'), titleClass: pushEnabled ? 'text-amber-400' : 'text-white' },
                  ].map(row => (
                    <button key={row.title} onClick={row.onClick} disabled={row.disabled}
                      className="w-full flex items-center gap-3.5 px-4 py-3.5 hover:bg-slate-700/50 transition-colors text-left disabled:opacity-60">
                      <span className="w-9 h-9 flex-shrink-0 flex items-center justify-center rounded-lg bg-slate-900 text-slate-300"><Ico d={row.icon} /></span>
                      <span className="flex-1 min-w-0">
                        <span className={`block text-sm font-semibold ${row.titleClass || 'text-white'}`}>{row.title}</span>
                        <span className="block text-xs text-slate-400 truncate">{row.sub}</span>
                      </span>
                      {row.chevron && <span className="text-slate-500"><Ico d="M9 6l6 6-6 6" size={16} /></span>}
                    </button>
                  ))}
                  {pushEnabled && (
                    <div className="px-4 py-3.5">
                      <label htmlFor="reminder-time" className="block text-xs font-semibold text-slate-400 mb-2">{t('dashboard.reminderLabel')}</label>
                      <div className="flex items-center gap-3">
                        <input id="reminder-time" type="time" value={reminderTime} onChange={e => saveReminderTime(e.target.value)}
                          className="bg-slate-900 border border-slate-700 text-white rounded-xl px-3 h-10 font-semibold outline-none focus:border-emerald-500 transition-colors text-sm" />
                        {reminderTime && (
                          <button onClick={() => saveReminderTime('')} className="text-xs text-rose-400 hover:text-rose-300 font-semibold">
                            {t('dashboard.reminderDisableButton')}
                          </button>
                        )}
                        {reminderSaving && <span className="text-xs text-slate-500">{t('dashboard.reminderSaving')}</span>}
                      </div>
                      <p className="text-slate-500 text-xs mt-1.5">{t('dashboard.reminderHint')}</p>
                    </div>
                  )}
                </div>

                <div className="bg-slate-800 border border-slate-700/70 rounded-xl divide-y divide-slate-700/60 overflow-hidden">
                  <button onClick={logout}
                    className="w-full flex items-center gap-3.5 px-4 py-3.5 hover:bg-slate-700/50 transition-colors text-left">
                    <span className="w-9 h-9 flex-shrink-0 flex items-center justify-center rounded-lg bg-slate-900 text-slate-300"><Ico d="M15 4h3a2 2 0 012 2v12a2 2 0 01-2 2h-3M10 17l-5-5 5-5M5 12h11" /></span>
                    <span className="flex-1 min-w-0">
                      <span className="block text-sm font-semibold text-white">{t('dashboard.logoutTitle')}</span>
                      <span className="block text-xs text-slate-400 truncate">{t('dashboard.logoutSub')}</span>
                    </span>
                  </button>
                  <button onClick={() => setAccountTab('delete')}
                    className="w-full flex items-center gap-3.5 px-4 py-3.5 hover:bg-rose-950/40 transition-colors text-left">
                    <span className="w-9 h-9 flex-shrink-0 flex items-center justify-center rounded-lg bg-slate-900 text-rose-400"><Ico d="M4 7h16M10 11v6M14 11v6M6 7l1 12a2 2 0 002 2h6a2 2 0 002-2l1-12M9 7V4h6v3" /></span>
                    <span className="flex-1 min-w-0">
                      <span className="block text-sm font-semibold text-rose-400">{t('dashboard.deleteAccountTitle')}</span>
                      <span className="block text-xs text-slate-400 truncate">{t('dashboard.deleteAccountSub')}</span>
                    </span>
                    <span className="text-slate-500"><Ico d="M9 6l6 6-6 6" size={16} /></span>
                  </button>
                </div>
              </div>
            )}

            {accountTab === 'username' && (
              <form onSubmit={handleChangeUsername} className="space-y-4">
                <div>
                  <label htmlFor="acc-username" className="block text-xs font-semibold text-slate-400 mb-1.5">{t('dashboard.changeUsernameLabel')}</label>
                  <input id="acc-username" type="text" value={newUsername} onChange={e => setNewUsername(e.target.value)}
                    className={kontoInput}
                    required autoFocus minLength={3} maxLength={50} />
                </div>
                <div className="flex gap-2 pt-1">
                  <button type="button" onClick={() => setAccountTab('menu')} className={kontoZurueck}>{t('dashboard.backToMenu')}</button>
                  <button type="submit" disabled={apiLoading} className={`flex-1 bg-gradient-to-r ${userColor} text-white font-bold h-11 rounded-xl text-sm disabled:opacity-50`}>
                    {apiLoading ? '...' : t('dashboard.saveButton')}
                  </button>
                </div>
              </form>
            )}

            {accountTab === 'password' && (
              <form onSubmit={handleChangePassword} className="space-y-4">
                <div>
                  <label htmlFor="acc-pw-current" className="block text-xs font-semibold text-slate-400 mb-1.5">{t('dashboard.currentPasswordLabel')}</label>
                  <input id="acc-pw-current" type="password" value={pwCurrent} onChange={e => setPwCurrent(e.target.value)}
                    className={kontoInput}
                    required autoFocus />
                </div>
                <div>
                  <label htmlFor="acc-pw-new" className="block text-xs font-semibold text-slate-400 mb-1.5">{t('dashboard.newPasswordLabel')}</label>
                  <input id="acc-pw-new" type="password" value={pwNew} onChange={e => setPwNew(e.target.value)}
                    placeholder={t('auth.passwordMinHint')}
                    className={`${kontoInput} placeholder-slate-600`}
                    required />
                  <PasswordStrength password={pwNew} />
                </div>
                <div>
                  <label htmlFor="acc-pw-confirm" className="block text-xs font-semibold text-slate-400 mb-1.5">{t('dashboard.confirmLabel')}</label>
                  <input id="acc-pw-confirm" type="password" value={pwConfirm} onChange={e => setPwConfirm(e.target.value)}
                    className={`${kontoInput} ${pwConfirm && pwNew !== pwConfirm ? '!border-rose-500' : ''}`}
                    required />
                  {pwConfirm && pwNew !== pwConfirm && <p className="text-rose-400 text-xs mt-1.5 font-semibold">{t('dashboard.passwordMismatch')}</p>}
                </div>
                <div className="flex gap-2 pt-1">
                  <button type="button" onClick={() => setAccountTab('menu')} className={kontoZurueck}>{t('dashboard.backToMenu')}</button>
                  <button type="submit" disabled={apiLoading || (pwConfirm && pwNew !== pwConfirm)} className={`flex-1 bg-gradient-to-r ${userColor} text-white font-bold h-11 rounded-xl text-sm disabled:opacity-50`}>
                    {apiLoading ? '...' : t('dashboard.changeButton')}
                  </button>
                </div>
              </form>
            )}

            {accountTab === 'delete' && (
              <form onSubmit={handleDeleteAccount} className="space-y-4">
                <p className="text-slate-300 text-sm leading-relaxed bg-rose-950/40 border border-rose-500/30 rounded-xl px-4 py-3">
                  {t('dashboard.deleteWarning1')}{' '}
                  <strong className="text-rose-400">{t('dashboard.deleteWarningEmph')}</strong>
                  {t('dashboard.deleteWarning2')}
                </p>
                <div>
                  <label htmlFor="acc-del-pw" className="block text-xs font-semibold text-slate-400 mb-1.5">{t('dashboard.currentPasswordLabel')}</label>
                  <input id="acc-del-pw" type="password" value={deletePassword} onChange={e => setDeletePassword(e.target.value)}
                    className={kontoInput.replace('focus:border-emerald-500', 'focus:border-rose-500')}
                    required autoFocus />
                </div>
                <div>
                  <label htmlFor="acc-del-confirm" className="block text-xs font-semibold text-slate-400 mb-1.5">
                    {t('dashboard.deleteConfirmLabelPre')}{' '}
                    <span className="text-rose-400 font-bold">{deleteConfirmWord}</span>
                    {' '}{t('dashboard.deleteConfirmLabelPost')}
                  </label>
                  <input id="acc-del-confirm" type="text" value={deleteConfirm} onChange={e => setDeleteConfirm(e.target.value)}
                    placeholder={deleteConfirmWord}
                    className={`${kontoInput.replace('focus:border-emerald-500', 'focus:border-rose-500')} placeholder-slate-600 ${deleteConfirm && deleteConfirm !== deleteConfirmWord ? '!border-rose-500' : ''}`}
                    required />
                </div>
                <div className="flex gap-2 pt-1">
                  <button type="button" onClick={() => setAccountTab('menu')} className={kontoZurueck}>{t('dashboard.backToMenu')}</button>
                  <button type="submit" disabled={apiLoading || deleteConfirm !== deleteConfirmWord}
                    className="flex-1 bg-rose-600 hover:bg-rose-500 disabled:opacity-50 text-white font-bold h-11 rounded-xl text-sm transition-colors">
                    {apiLoading ? t('dashboard.deleting') : t('dashboard.deleteButton')}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

      {/* MODAL: Ziele ändern */}
      {showEditGoals && (
        <div className="fixed inset-0 bg-slate-950/70 z-50 flex items-end sm:items-center justify-center sm:p-4">
          <div className="bg-slate-900 border-t sm:border border-slate-700/70 w-full max-w-md rounded-t-2xl sm:rounded-2xl px-5 pt-3 pb-6 shadow-2xl max-h-[92vh] overflow-y-auto"
            style={{ paddingBottom: 'calc(1.5rem + env(safe-area-inset-bottom))' }}>
            <div className="mx-auto mb-3 h-1 w-10 rounded bg-slate-700 sm:hidden" />
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-extrabold text-white tracking-tight">{t('dashboard.goalsTitle')}</h2>
              <button onClick={() => setShowEditGoals(false)} aria-label={t('dashboard.close')}
                className="w-11 h-11 -mr-2 flex items-center justify-center rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 transition-colors">
                <Ico d="M6 6l12 12M18 6L6 18" />
              </button>
            </div>
            <form onSubmit={handleSaveGoals} className="space-y-4">
              <div>
                <label htmlFor="goal-kcal" className="block text-xs font-semibold text-slate-400 mb-1.5">{t('dashboard.calorieGoalLabel')}</label>
                <input id="goal-kcal" type="number" inputMode="numeric" value={goalInputKcal} onChange={e => setGoalInputKcal(e.target.value)} className={kontoInput} required />
              </div>
              <div className="grid grid-cols-2 gap-3">
                {[
                  { id: 'goal-protein', val: goalInputProtein, set: setGoalInputProtein, label: t('dashboard.macroProtein'), dot: 'bg-blue-400' },
                  { id: 'goal-carbs',   val: goalInputCarbs,   set: setGoalInputCarbs,   label: t('dashboard.macroCarbs'),   dot: 'bg-amber-400' },
                  { id: 'goal-fat',     val: goalInputFat,     set: setGoalInputFat,     label: t('dashboard.macroFat'),     dot: 'bg-rose-400' },
                  { id: 'goal-fiber',   val: goalInputFiber,   set: setGoalInputFiber,   label: t('dashboard.macroFiber'),   dot: 'bg-lime-400' },
                ].map(({ id, val, set, label, dot }) => (
                  <div key={id}>
                    <label htmlFor={id} className="flex items-center gap-1.5 text-xs font-semibold text-slate-400 mb-1.5">
                      <span className={`w-2 h-2 rounded-full ${dot}`} />{label} (g)
                    </label>
                    <input id={id} type="number" inputMode="numeric" value={val} onChange={e => set(e.target.value)} className={kontoInput} required />
                  </div>
                ))}
              </div>
              <div className="flex gap-2 pt-1">
                <button type="button" onClick={() => setShowEditGoals(false)} className={kontoZurueck}>{t('dashboard.cancelButton')}</button>
                <button type="submit" disabled={apiLoading} className={`flex-1 bg-gradient-to-r ${userColor} text-white font-bold h-11 rounded-xl text-sm disabled:opacity-50`}>
                  {apiLoading ? t('dashboard.saving') : t('dashboard.saveButton')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: Mahlzeit hinzufügen — Redesign 2026-10: Fenster von unten (Handy), flacher Stil */}
      {showAddManual && (
        <div className="fixed inset-0 bg-slate-950/70 z-40 flex items-end sm:items-center justify-center sm:p-4">
          <div className="bg-slate-900 border-t sm:border border-slate-700/70 w-full max-w-lg rounded-t-2xl sm:rounded-2xl px-5 pt-3 pb-6 shadow-2xl max-h-[92vh] overflow-y-auto"
            style={{ paddingBottom: 'calc(1.5rem + env(safe-area-inset-bottom))' }}>
            <div className="mx-auto mb-3 h-1 w-10 rounded bg-slate-700 sm:hidden" />
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-extrabold text-white tracking-tight">{t('dashboard.mealModalTitle')}</h2>
              <button onClick={() => setShowAddManual(false)} aria-label={t('dashboard.close')}
                className="w-11 h-11 -mr-2 flex items-center justify-center rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 transition-colors">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18" /></svg>
              </button>
            </div>

            {!selectedFood && (
              <div className="grid grid-cols-3 gap-1 bg-slate-800 p-1 rounded-xl mb-5">
                {[['search', 'tabSearch'], ['custom', 'tabCustom'], ['templates', 'tabTemplates']].map(([tab, key]) => (
                  <button key={tab} onClick={() => setActiveTab(tab)}
                    className={`py-2.5 rounded-lg text-sm transition-colors ${activeTab === tab ? 'bg-slate-900 text-white font-semibold' : 'text-slate-400 font-medium hover:text-white'}`}>
                    {t(`dashboard.${key}`)}
                  </button>
                ))}
              </div>
            )}

            {selectedFood ? (
              <div className="space-y-4">
                <div className="bg-slate-800 border border-slate-700/70 p-4 rounded-xl">
                  <h3 className="font-bold text-white text-lg leading-snug">{selectedFood.name}</h3>
                  <div className="flex flex-wrap items-center gap-x-2 gap-y-1 mt-1 text-xs">
                    {selectedFood.brand && <span className="text-slate-400">{selectedFood.brand}</span>}
                    <span className="text-amber-400 font-semibold">{Math.round(selectedFood.calories_per_100g || 0)} kcal / 100 g</span>
                    {selectedFood._fromBarcode && !selectedFood._online && <span className="text-emerald-400 font-medium">{t('dashboard.sourceScanned')}</span>}
                    {selectedFood._online && <span className="text-sky-400 font-medium">Open Food Facts</span>}
                    {selectedFood._fromReference && <span className="text-emerald-400 font-medium">BLS 4.0</span>}
                  </div>
                  <div className="mt-4 grid grid-cols-4 gap-2 text-center border-t border-slate-700/60 pt-3">
                    {[['kcal', selectedFood.calories_per_100g, 0, 'text-amber-400', 'text-slate-400'],
                      [t('dashboard.shortProtein'), selectedFood.protein_per_100g, 1, 'text-white', 'text-blue-400'],
                      [t('dashboard.shortCarbs'), selectedFood.carbs_per_100g, 1, 'text-white', 'text-amber-400'],
                      [t('dashboard.shortFat'), selectedFood.fat_per_100g, 1, 'text-white', 'text-rose-400']].map(([label, w, nk, farbe, labelFarbe]) => {
                      const v = fuerMenge(w, amount)
                      return (
                        <div key={label}>
                          <div className={`text-lg font-bold leading-tight ${farbe}`}>{v == null ? '–' : v.toFixed(nk)}</div>
                          <div className={`text-[11px] font-medium ${labelFarbe}`}>{label}{nk ? ' g' : ''}</div>
                        </div>
                      )
                    })}
                  </div>
                </div>
                <div className="flex gap-2.5">
                  <label className="flex items-center gap-1.5 h-[52px] w-32 rounded-xl border border-slate-700 bg-slate-800 px-3.5 focus-within:border-emerald-500 transition-colors">
                    <input type="number" inputMode="decimal" placeholder="0" value={amount} aria-label={t('dashboard.amountPlaceholder')}
                      onChange={e => setAmount(e.target.value)}
                      className="w-full bg-transparent text-white text-lg font-bold outline-none" autoFocus />
                    <span className="text-slate-400 text-sm">g</span>
                  </label>
                  <button onClick={handleAddMeal} disabled={!amount || apiLoading}
                    className={`flex-1 h-[52px] bg-gradient-to-r ${userColor} text-white font-bold rounded-xl disabled:opacity-50`}>
                    {apiLoading ? '...' : t('dashboard.addButton')}
                  </button>
                </div>
                <button onClick={() => setSelectedFood(null)}
                  className="w-full py-2.5 text-slate-400 hover:text-white font-medium text-sm transition-colors">
                  {t('dashboard.backButton')}
                </button>
              </div>
            ) : activeTab === 'templates' ? (
              <MealTemplates
                foods={foods}
                onApplied={() => { loadDashboard(selectedDate); setShowAddManual(false) }}
                userColor={userColor}
              />
            ) : activeTab === 'search' ? (
              <div className="space-y-4">
                <div>
                  <label htmlFor="mahlzeit-suche" className="block text-xs font-semibold text-slate-400 mb-1.5">{t('dashboard.searchLabel')}</label>
                  <div className="flex items-center gap-2.5 h-12 rounded-xl border border-slate-700 bg-slate-800 px-3.5 focus-within:border-emerald-500 transition-colors">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="11" cy="11" r="7" /><path d="M20 20l-4-4" /></svg>
                    <input id="mahlzeit-suche" type="text" placeholder={t('dashboard.searchPlaceholder')} value={searchQuery}
                      onChange={e => setSearchQuery(e.target.value)}
                      className="flex-1 bg-transparent text-white outline-none placeholder:text-slate-500" />
                  </div>
                  {schnell.menge && (
                    <p className="text-xs text-emerald-400 font-semibold mt-1.5">{t('dashboard.quickAmount', { grams: schnell.menge, term: schnell.begriff })}</p>
                  )}
                </div>
                {/* Live-Suche Open Food Facts (Markenprodukte) — hervorgehoben direkt unter dem Suchfeld, auf Knopfdruck */}
                {schnell.begriff.length >= 2 && (
                  <div className="space-y-1.5">
                    {onlineResults === null ? (
                      <button type="button" onClick={searchOnline} disabled={onlineLoading}
                        className="w-full h-12 bg-sky-600 hover:bg-sky-500 text-white font-bold rounded-xl text-sm flex items-center justify-center gap-2 transition-colors disabled:opacity-60 shadow-lg shadow-sky-900/30">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><circle cx="12" cy="12" r="9" /><path d="M3 12h18M12 3c2.5 2.5 3.5 5.5 3.5 9s-1 6.5-3.5 9c-2.5-2.5-3.5-5.5-3.5-9s1-6.5 3.5-9z" /></svg>
                        {onlineLoading ? t('dashboard.onlineSearching') : t('dashboard.onlineSearch', { term: schnell.begriff })}
                      </button>
                    ) : (
                      <div className="rounded-xl border border-sky-500/40 bg-sky-500/5 p-2.5 space-y-1.5">
                        <div className="flex items-center justify-between px-1">
                          <p className="text-[11px] font-bold text-sky-300 uppercase tracking-wider">{t('dashboard.onlineSection')}</p>
                          <button type="button" onClick={() => { setOnlineResults(null); setOnlineError('') }}
                            className="text-xs text-slate-400 hover:text-white py-1">{t('dashboard.onlineHide')}</button>
                        </div>
                        {onlineError && <p className="text-xs text-rose-400 px-1">{onlineError}</p>}
                        {!onlineError && onlineResults.length === 0 && <p className="text-xs text-slate-400 px-1">{t('dashboard.onlineNone')}</p>}
                        <div className="max-h-[32vh] overflow-y-auto space-y-1.5">
                          {onlineResults.map(r => (
                            <button key={`off-${r.code}`} onClick={() => waehleLebensmittel({ ...r, id: 0, _fromBarcode: true, _barcode: r.code, _online: true })}
                              className="w-full bg-slate-800 border border-slate-700/60 rounded-lg px-3 py-2.5 text-left hover:border-sky-500/60 transition-colors">
                              <div className="flex justify-between items-center gap-3">
                                <div className="min-w-0">
                                  <div className="font-semibold text-slate-100 text-sm truncate">{r.name}</div>
                                  {r.brand && <div className="text-xs text-slate-400 truncate">{r.brand}</div>}
                                </div>
                                <div className="text-[13px] text-amber-400 font-bold whitespace-nowrap">{Math.round(r.calories_per_100g || 0)} kcal</div>
                              </div>
                            </button>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                )}
                <div className="max-h-[48vh] overflow-y-auto space-y-4 -mx-1 px-1">
                  {foods.length > 0 && (
                    <div className="space-y-1.5">
                      <p className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">{t('dashboard.myFoodsSection')}</p>
                      {foods.map(f => (
                        <button key={f.id} onClick={() => waehleLebensmittel(f)}
                          className="w-full bg-slate-800 border border-slate-700/60 rounded-xl px-3.5 py-3 text-left hover:border-slate-500 transition-colors">
                          <div className="flex justify-between items-center gap-3">
                            <div className="min-w-0">
                              <div className="font-semibold text-slate-100 truncate">{f.name}</div>
                              {(f.brand || f.use_count > 0 || (f.is_family && f.user_id !== user.id)) && (
                                <div className="text-xs text-slate-400 truncate">
                                  {[f.brand, f.use_count > 0 ? `${f.use_count}×` : null, f.is_family && f.user_id !== user.id ? t('dashboard.familyTag') : null].filter(Boolean).join(' · ')}
                                </div>
                              )}
                            </div>
                            <div className="text-[13px] text-amber-400 font-bold whitespace-nowrap">{Math.round(f.calories_per_100g || 0)} kcal</div>
                          </div>
                        </button>
                      ))}
                    </div>
                  )}
                  {foods.length === 0 && refResults.length === 0 && !onlineResults?.length && (
                    <p className="text-slate-500 text-center py-4 text-sm">{t('dashboard.noResults')}</p>
                  )}

                  {/* Grundlebensmittel aus dem Bundeslebensmittelschlüssel (lokal) */}
                  {refResults.length > 0 && (
                    <div className="space-y-1.5">
                      <p className="text-[11px] font-bold text-slate-500 uppercase tracking-wider">{t('dashboard.blsSection')}</p>
                      {refResults.map(r => (
                        <button key={`bls-${r.code}`} onClick={() => waehleLebensmittel({ ...r, id: 0, _fromReference: r.code })}
                          className="w-full bg-slate-800 border border-emerald-500/25 rounded-xl px-3.5 py-3 text-left hover:border-emerald-500/60 transition-colors">
                          <div className="flex justify-between items-center gap-3">
                            <div className="font-semibold text-slate-100 text-sm">{r.name}</div>
                            <div className="text-[13px] text-amber-400 font-bold whitespace-nowrap">{Math.round(r.calories_per_100g || 0)} kcal</div>
                          </div>
                        </button>
                      ))}
                      <p className="text-[11px] text-slate-500">{t('dashboard.blsSource')}</p>
                    </div>
                  )}

                </div>
              </div>
            ) : (
              <form onSubmit={handleCreateCustomMeal} className="space-y-2.5">
                <input type="text" placeholder={t('dashboard.mealNamePlaceholder')} value={customName} onChange={e => setCustomName(e.target.value)}
                  className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3.5 py-3 outline-none focus:border-emerald-500 placeholder:text-slate-500" required />
                <div className="grid grid-cols-2 gap-2.5">
                  <input type="number" placeholder={t('dashboard.weightGPlaceholder')} value={customAmount} onChange={e => setCustomAmount(e.target.value)}
                    className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3.5 py-3 outline-none focus:border-emerald-500 placeholder:text-slate-500" required />
                  <input type="number" placeholder={t('dashboard.kcalPlaceholder')} value={customKcal} onChange={e => setCustomKcal(e.target.value)}
                    className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3.5 py-3 outline-none focus:border-emerald-500 placeholder:text-slate-500" required />
                </div>
                <div className="grid grid-cols-2 gap-2.5">
                  <input type="number" placeholder={t('dashboard.proteinPlaceholder')} value={customProtein} onChange={e => setCustomProtein(e.target.value)}
                    className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3.5 py-3 outline-none focus:border-emerald-500 placeholder:text-slate-500" />
                  <input type="number" placeholder={t('dashboard.carbsPlaceholder')} value={customCarbs} onChange={e => setCustomCarbs(e.target.value)}
                    className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3.5 py-3 outline-none focus:border-emerald-500 placeholder:text-slate-500" />
                </div>
                <div className="grid grid-cols-2 gap-2.5">
                  <input type="number" placeholder={t('dashboard.fatPlaceholder')} value={customFat} onChange={e => setCustomFat(e.target.value)}
                    className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3.5 py-3 outline-none focus:border-emerald-500 placeholder:text-slate-500" />
                  <input type="number" placeholder={t('dashboard.fiberPlaceholder')} value={customFiber} onChange={e => setCustomFiber(e.target.value)}
                    className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl px-3.5 py-3 outline-none focus:border-emerald-500 placeholder:text-slate-500" />
                </div>
                <button type="submit" disabled={apiLoading}
                  className={`w-full mt-2 h-[52px] bg-gradient-to-r ${userColor} text-white font-bold rounded-xl disabled:opacity-50`}>
                  {apiLoading ? t('dashboard.savingAndLogging') : t('dashboard.saveAndLog')}
                </button>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
