import { useState, useEffect, useCallback } from "react"
import { useTranslation } from "react-i18next"
import { useAuth } from "../context/AuthContext"

const API = import.meta.env.VITE_API_URL || "/api"

const Ico = ({ d, size = 18 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d={d} /></svg>
)

export default function AdminPanel({ onClose }) {
  const { t } = useTranslation()
  const { authFetch } = useAuth()
  const [users, setUsers] = useState([])
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState("")
  const [error, setError] = useState(null)
  const [success, setSuccess] = useState(null)
  const [activeTab, setActiveTab] = useState("users")
  const [broadcastSubject, setBroadcastSubject] = useState("")
  const [broadcastMsg, setBroadcastMsg] = useState("")
  const [inactiveDays, setInactiveDays] = useState(30)
  const [warningDays, setWarningDays] = useState(7)
  const [sending, setSending] = useState(false)
  const [loadingId, setLoadingId] = useState(null)

  useEffect(() => {
    if (success) { const t = setTimeout(() => setSuccess(null), 3000); return () => clearTimeout(t) }
  }, [success])

  const load = useCallback(async () => {
    try {
      const [usersRes, statsRes] = await Promise.all([
        authFetch(`${API}/admin/users`),
        authFetch(`${API}/admin/stats`)
      ])
      setUsers(await usersRes.json())
      setStats(await statsRes.json())
    } catch (e) { setError(t('admin.loadError')) }
    finally { setLoading(false) }
  }, [authFetch, t])

  useEffect(() => { load() }, [load])

  const deleteUser = async (user) => {
    if (!window.confirm(t('admin.deleteUserConfirm', { username: user.username, email: user.email }))) return
    setLoadingId(`del-${user.id}`)
    try {
      const res = await authFetch(`${API}/admin/users/${user.id}`, { method: "DELETE" })
      const data = await res.json()
      if (!res.ok) throw new Error(data.detail)
      setSuccess(data.message)
      load()
    } catch (e) { setError(e.message) } finally { setLoadingId(null) }
  }

  const toggleActive = async (user) => {
    setLoadingId(`active-${user.id}`)
    try {
      const res = await authFetch(`${API}/admin/users/${user.id}/toggle-active`, { method: "PUT" })
      const data = await res.json()
      if (!res.ok) throw new Error(data.detail)
      setSuccess(data.message)
      load()
    } catch (e) { setError(e.message) } finally { setLoadingId(null) }
  }

  const toggleVerified = async (user) => {
    const action = user.is_verified ? t('admin.revokeVerification') : t('admin.manualVerify')
    if (!window.confirm(t('admin.confirmAction', { action, username: user.username }))) return
    setLoadingId(`ver-${user.id}`)
    try {
      const res = await authFetch(`${API}/admin/users/${user.id}/toggle-verified`, { method: "PUT" })
      const data = await res.json()
      if (!res.ok) throw new Error(data.detail)
      setSuccess(data.message)
      load()
    } catch (e) { setError(e.message) } finally { setLoadingId(null) }
  }

  const resendVerification = async (user) => {
    if (!window.confirm(t('admin.resendVerificationConfirm', { username: user.username, email: user.email }))) return
    setLoadingId(`resend-${user.id}`)
    try {
      const res = await authFetch(`${API}/admin/users/${user.id}/resend-verification`, { method: "POST" })
      const data = await res.json()
      if (!res.ok) throw new Error(data.detail)
      setSuccess(t('admin.verificationSentTo', { username: user.username }))
    } catch (e) { setError(e.message) } finally { setLoadingId(null) }
  }

  const handleBroadcast = async (e) => {
    e.preventDefault()
    if (!broadcastSubject.trim() || !broadcastMsg.trim()) return
    if (!window.confirm(t('admin.confirmBroadcast'))) return
    setSending(true)
    try {
      const res = await authFetch(`${API}/admin/broadcast`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ subject: broadcastSubject, message: broadcastMsg })
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.detail)
      setSuccess(data.message)
      setBroadcastSubject(""); setBroadcastMsg("")
    } catch (e) { setError(e.message) } finally { setSending(false) }
  }

  const handleNotifyInactive = async () => {
    if (!window.confirm(t('admin.inactiveConfirm', { days: inactiveDays }))) return
    setSending(true)
    try {
      const res = await authFetch(`${API}/admin/notify-inactive`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ days_inactive: inactiveDays, warning_days: warningDays })
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.detail)
      setSuccess(data.message)
    } catch (e) { setError(e.message) } finally { setSending(false) }
  }

  const filtered = users.filter(u =>
    u.username.toLowerCase().includes(search.toLowerCase()) ||
    u.email.toLowerCase().includes(search.toLowerCase())
  )

  const tabs = [
    { id: "users",     label: t('admin.tabUsers') },
    { id: "broadcast", label: t('admin.tabBroadcast') },
    { id: "inactive",  label: t('admin.tabInactive') },
  ]

  const feld = "w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-3.5 h-11 text-sm outline-none focus:border-emerald-500 transition-colors placeholder-slate-500"
  const aktion = "w-9 h-9 rounded-lg flex items-center justify-center transition-colors disabled:opacity-50"
  const warte = <span className="w-3.5 h-3.5 rounded-full border-2 border-current border-t-transparent animate-spin" />

  return (
    <div className="fixed inset-0 bg-slate-950 z-50 flex flex-col overflow-hidden">

      <div className="border-b border-slate-800 px-4 py-3 flex items-center justify-between flex-shrink-0"
        style={{ paddingTop: 'calc(0.75rem + env(safe-area-inset-top))' }}>
        <div className="flex items-center gap-3">
          <span className="w-9 h-9 flex items-center justify-center rounded-lg bg-amber-500/15 text-amber-400">
            <Ico d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6l8-3z" />
          </span>
          <div>
            <h1 className="text-white font-extrabold text-lg leading-tight tracking-tight">{t('admin.title')}</h1>
            <p className="text-slate-400 text-xs">{t('admin.subtitle')}</p>
          </div>
        </div>
        <button onClick={onClose} aria-label={t('admin.close')}
          className="w-11 h-11 -mr-2 flex items-center justify-center rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 transition-colors">
          <Ico d="M6 6l12 12M18 6L6 18" />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto">
       <div className="max-w-3xl mx-auto p-4 space-y-4">

        {error   && <div className="bg-rose-950/60 border border-rose-500/50 text-rose-300 rounded-xl px-4 py-2.5 text-sm font-semibold">{error}</div>}
        {success && <div className="bg-emerald-950/60 border border-emerald-500/50 text-emerald-300 rounded-xl px-4 py-2.5 text-sm font-semibold">{success}</div>}

        <div className="grid grid-cols-3 gap-1 bg-slate-800 p-1 rounded-xl">
          {tabs.map(tab => (
            <button key={tab.id} onClick={() => setActiveTab(tab.id)}
              className={`py-2.5 rounded-lg text-sm transition-colors ${activeTab === tab.id ? "bg-slate-900 text-white font-semibold" : "text-slate-400 font-medium hover:text-white"}`}>
              {tab.label}
            </button>
          ))}
        </div>

        {/* ── TAB: Broadcast ── */}
        {activeTab === "broadcast" && (
          <div className="bg-slate-800 border border-slate-700/70 rounded-2xl p-5 space-y-4">
            <div>
              <h3 className="text-white font-bold text-[15px]">{t('admin.broadcastTitle')}</h3>
              <p className="text-slate-400 text-xs mt-0.5">{t('admin.broadcastInfo')}</p>
            </div>
            <form onSubmit={handleBroadcast} className="space-y-3">
              <div>
                <label htmlFor="adm-subject" className="block text-xs font-semibold text-slate-400 mb-1.5">{t('admin.subjectLabel')}</label>
                <input id="adm-subject" type="text" value={broadcastSubject} onChange={e => setBroadcastSubject(e.target.value)}
                  placeholder={t('admin.subjectPlaceholder')} className={feld} required />
              </div>
              <div>
                <label htmlFor="adm-msg" className="block text-xs font-semibold text-slate-400 mb-1.5">{t('admin.messageLabel')}</label>
                <textarea id="adm-msg" value={broadcastMsg} onChange={e => setBroadcastMsg(e.target.value)}
                  placeholder={t('admin.messagePlaceholder')}
                  rows={6} required
                  className={feld.replace('h-11', 'py-3') + " resize-none"} />
              </div>
              <button type="submit" disabled={sending || !broadcastSubject.trim() || !broadcastMsg.trim()}
                className="w-full bg-emerald-700 hover:bg-emerald-600 disabled:opacity-50 text-white font-bold h-11 rounded-xl text-sm transition-colors">
                {sending ? t('admin.sending') : t('admin.sendToUsers', { count: stats?.verified_users || '—' })}
              </button>
            </form>
          </div>
        )}

        {/* ── TAB: Inaktiv ── */}
        {activeTab === "inactive" && (
          <div className="bg-slate-800 border border-slate-700/70 rounded-2xl p-5 space-y-4">
            <div>
              <h3 className="text-white font-bold text-[15px]">{t('admin.inactiveTitle')}</h3>
              <p className="text-slate-400 text-xs mt-0.5">{t('admin.inactiveInfo')}</p>
            </div>
            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label htmlFor="adm-inactive" className="block text-xs font-semibold text-slate-400 mb-1.5">{t('admin.inactiveDaysLabel')}</label>
                  <input id="adm-inactive" type="number" inputMode="numeric" value={inactiveDays} onChange={e => setInactiveDays(parseInt(e.target.value))}
                    min={7} max={365} className={feld} />
                </div>
                <div>
                  <label htmlFor="adm-warning" className="block text-xs font-semibold text-slate-400 mb-1.5">{t('admin.warningDaysLabel')}</label>
                  <input id="adm-warning" type="number" inputMode="numeric" value={warningDays} onChange={e => setWarningDays(parseInt(e.target.value))}
                    min={1} max={30} className={feld} />
                </div>
              </div>
              <p className="text-slate-500 text-xs">{t('admin.inactiveSince', { days: inactiveDays })}</p>
              <div className="bg-slate-900 border border-slate-700/60 rounded-xl p-3.5 text-xs text-slate-400 space-y-1">
                <p className="font-semibold text-slate-300">{t('admin.mailContains')}</p>
                <p>{t('admin.mailHint1', { days: inactiveDays })}</p>
                <p>{t('admin.mailHint2', { days: warningDays })}</p>
                <p>{t('admin.mailHint3')}</p>
                <p className="text-amber-400 font-semibold pt-1">{t('admin.noDelete')}</p>
              </div>
              <button onClick={handleNotifyInactive} disabled={sending}
                className="w-full bg-amber-500 hover:bg-amber-400 disabled:opacity-50 text-slate-950 font-bold h-11 rounded-xl text-sm transition-colors">
                {sending ? t('admin.sending') : t('admin.sendWarnings')}
              </button>
            </div>
          </div>
        )}

        {/* ── TAB: Users ── */}
        {activeTab === "users" && <>

        {stats && (
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {[
              { label: t('admin.totalUsers'), value: stats.total_users,    dot: "bg-cyan-400" },
              { label: t('admin.verified'),   value: stats.verified_users, dot: "bg-emerald-400" },
              { label: t('admin.totalLogs'),  value: stats.total_logs,     dot: "bg-amber-400" },
              { label: t('admin.todayLogs'),  value: stats.today_logs,     dot: "bg-purple-400" },
            ].map(s => (
              <div key={s.label} className="bg-slate-800 border border-slate-700/70 rounded-xl px-4 py-3">
                <div className="flex items-center gap-1.5 text-slate-400 text-xs font-medium"><span className={`w-2 h-2 rounded-full ${s.dot}`} />{s.label}</div>
                <div className="text-2xl font-extrabold text-white mt-1 tracking-tight">{s.value}</div>
              </div>
            ))}
          </div>
        )}

        <div className="relative">
          <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none"><Ico d="M11 18a7 7 0 100-14 7 7 0 000 14zM20 20l-4-4" /></span>
          <input
            type="text" placeholder={t('admin.searchPlaceholder')} value={search} aria-label={t('admin.searchPlaceholder')}
            onChange={e => setSearch(e.target.value)}
            className={feld.replace('bg-slate-900', 'bg-slate-800') + " pl-10"}
          />
        </div>

        {loading ? (
          <div className="text-slate-400 text-center py-8 text-sm">{t('admin.loading')}</div>
        ) : (
          <div className="bg-slate-800 border border-slate-700/70 rounded-2xl divide-y divide-slate-700/60 overflow-hidden">
            {filtered.map(user => (
              <div key={user.id} className="px-4 py-3.5">
                <div className="flex items-start justify-between gap-3">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-white font-semibold">{user.username}</span>
                      {user.is_admin    && <span className="text-[11px] bg-amber-500/15 text-amber-400 px-1.5 py-0.5 rounded font-semibold">{t('admin.badgeAdmin')}</span>}
                      {!user.is_active  && <span className="text-[11px] bg-rose-500/15 text-rose-400 px-1.5 py-0.5 rounded font-semibold">{t('admin.badgeBanned')}</span>}
                      {!user.is_verified && <span className="text-[11px] bg-slate-700 text-slate-300 px-1.5 py-0.5 rounded font-semibold">{t('admin.badgeUnverified')}</span>}
                    </div>
                    <div className="text-slate-400 text-xs mt-0.5 truncate">{user.email}</div>
                    <div className="flex flex-wrap gap-x-3 gap-y-0.5 mt-1 text-xs text-slate-500">
                      <span>seit {user.created_at}</span>
                      <span>{user.log_count} Logs</span>
                      {user.last_active && <span>zuletzt {user.last_active}</span>}
                    </div>
                  </div>

                  {!user.is_admin && (
                    <div className="flex gap-1 flex-shrink-0">
                      {!user.is_verified && (
                        <>
                          <button
                            onClick={() => resendVerification(user)}
                            disabled={loadingId === `resend-${user.id}`}
                            title={t('admin.resendVerificationConfirm', { username: user.username, email: user.email })}
                            aria-label={t('admin.resendVerificationConfirm', { username: user.username, email: user.email })}
                            className={`${aktion} text-sky-400 hover:bg-slate-700`}
                          >
                            {loadingId === `resend-${user.id}` ? warte : <Ico d="M4 5h16a1 1 0 011 1v12a1 1 0 01-1 1H4a1 1 0 01-1-1V6a1 1 0 011-1zM3 7l9 6 9-6" size={16} />}
                          </button>
                          <button
                            onClick={() => toggleVerified(user)}
                            disabled={loadingId === `ver-${user.id}`}
                            title={t('admin.manualVerify')} aria-label={t('admin.manualVerify')}
                            className={`${aktion} text-emerald-400 hover:bg-slate-700`}
                          >
                            {loadingId === `ver-${user.id}` ? warte : <Ico d="M5 12l5 5 9-10" size={16} />}
                          </button>
                        </>
                      )}
                      <button
                        onClick={() => toggleActive(user)}
                        title={user.is_active ? t('admin.badgeBanned') : "Entsperren"}
                        aria-label={user.is_active ? t('admin.badgeBanned') : "Entsperren"}
                        disabled={loadingId === `active-${user.id}`}
                        className={`${aktion} ${user.is_active ? "text-amber-400 hover:bg-slate-700" : "text-slate-300 bg-slate-700 hover:bg-slate-600"}`}
                      >
                        {loadingId === `active-${user.id}` ? warte : <Ico d={user.is_active ? "M6 11h12a1 1 0 011 1v8a1 1 0 01-1 1H6a1 1 0 01-1-1v-8a1 1 0 011-1zM8 11V7a4 4 0 018 0v4" : "M6 11h12a1 1 0 011 1v8a1 1 0 01-1 1H6a1 1 0 01-1-1v-8a1 1 0 011-1zM8 11V7a4 4 0 017.5-2"} size={16} />}
                      </button>
                      <button
                        onClick={() => deleteUser(user)}
                        disabled={loadingId === `del-${user.id}`}
                        title={t('admin.deleteUserConfirm', { username: user.username, email: user.email })}
                        aria-label={t('admin.deleteUserConfirm', { username: user.username, email: user.email })}
                        className={`${aktion} text-rose-400 hover:bg-rose-950/60`}
                      >
                        {loadingId === `del-${user.id}` ? warte : <Ico d="M4 7h16M10 11v6M14 11v6M6 7l1 12a2 2 0 002 2h6a2 2 0 002-2l1-12M9 7V4h6v3" size={16} />}
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))}
            {filtered.length === 0 && (
              <div className="text-slate-500 text-center py-8 text-sm">{t('admin.noUsers')}</div>
            )}
          </div>
        )}
        </>}
       </div>
      </div>
    </div>
  )
}
