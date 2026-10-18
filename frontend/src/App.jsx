import { useEffect, useRef, useState } from "react"
import { useTranslation } from "react-i18next"
import { AuthProvider, useAuth } from "./context/AuthContext"
import AuthPage from "./components/AuthPage"
import Dashboard from "./components/Dashboard"
import PasswordStrength from "./components/PasswordStrength"

const API = import.meta.env.VITE_API_URL || "/api"
const GRAD = "bg-gradient-to-r from-emerald-700 to-teal-700"

const LEGAL_KEYS = {
  impressum:  { titleKey: 'app.legalImpressumTitle',  contentKey: 'app.legalImpressumContent' },
  datenschutz:{ titleKey: 'app.legalDatenschutzTitle', contentKey: 'app.legalDatenschutzContent' },
  nutzung:    { titleKey: 'app.legalNutzungTitle',    contentKey: 'app.legalNutzungContent' },
}

/* ── Theme tokens (MacroBandit palette: emerald/cyan accents on slate) ────── */
function tokens(isDark) {
  return isDark
    ? {
        page: "bg-slate-950", text: "text-white", soft: "text-slate-300", muted: "text-slate-400",
        mutedHover: "text-slate-400 hover:text-white",
        card: "bg-slate-900", border: "border-slate-800",
        input: "bg-slate-950 border-slate-700 text-white placeholder-slate-400",
        header: "bg-slate-950/80 border-slate-800",
        track: "bg-slate-950", sub: "bg-slate-950 border-slate-800",
        accent: "text-emerald-400",
        chip: "bg-slate-900 border-slate-800 text-slate-300",
        ghost: "bg-slate-800 hover:bg-slate-700 text-white border-slate-700",
      }
    : {
        page: "bg-slate-50", text: "text-slate-900", soft: "text-slate-600", muted: "text-slate-500",
        mutedHover: "text-slate-500 hover:text-slate-900",
        card: "bg-white", border: "border-slate-200",
        input: "bg-white border-slate-300 text-slate-900 placeholder-slate-500",
        header: "bg-white/80 border-slate-200",
        track: "bg-slate-100", sub: "bg-slate-50 border-slate-200",
        accent: "text-emerald-600",
        chip: "bg-white border-slate-200 text-slate-600",
        ghost: "bg-slate-100 hover:bg-slate-200 text-slate-900 border-slate-300",
      }
}

/* ── Generic legal / info modal ───────────────────────────────────────────── */
function Modal({ title, children, onClose, tk, isDark }) {
  return (
    <div className="fixed inset-0 bg-black/70 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
      <div className={`${isDark ? "bg-slate-900" : "bg-white"} border ${tk.border} rounded-2xl w-full max-w-lg max-h-[85vh] flex flex-col`}>
        <div className={`flex items-center justify-between px-6 py-4 border-b ${tk.border}`}>
          <h2 className={`${tk.text} font-black text-lg tracking-wide`}>{title}</h2>
          <button onClick={onClose} className={`${tk.mutedHover} text-2xl leading-none transition-colors`}>✕</button>
        </div>
        <div className={`overflow-y-auto px-6 py-5 ${tk.soft} text-sm leading-relaxed whitespace-pre-line`}>
          {children}
        </div>
      </div>
    </div>
  )
}

/* ── "Buy me a Shake" donation modal ──────────────────────────────────────── */
function ShakeModal({ onClose, tk, isDark }) {
  const { t } = useTranslation()
  return (
    <div className="fixed inset-0 bg-black/70 z-50 flex items-center justify-center p-4 backdrop-blur-sm">
      <div className={`${isDark ? "bg-slate-900" : "bg-white"} border ${tk.border} rounded-2xl w-full max-w-md`}>
        <div className={`flex items-center justify-between px-6 py-4 border-b ${tk.border}`}>
          <h2 className={`${tk.text} font-black text-lg tracking-widest uppercase`}>{t('app.shakeTitle')}</h2>
          <button onClick={onClose} className={`${tk.mutedHover} text-2xl leading-none transition-colors`}>✕</button>
        </div>
        <div className="px-6 py-6 space-y-6">
          <p className={`${tk.muted} text-sm leading-relaxed`}>{t('app.shakeText')}</p>
          <a href="https://www.paypal.me/GeriPe" target="_blank" rel="noopener noreferrer"
            className="flex items-center justify-center gap-3 w-full bg-blue-600 hover:bg-blue-500 text-white font-black py-3.5 rounded-xl transition-colors text-sm">
            {t('app.shakePaypal')}
          </a>
          <div className={`${tk.sub} border rounded-xl p-4 text-center space-y-3`}>
            <p className={`${tk.muted} text-xs font-bold uppercase tracking-widest`}>{t('app.shakeSEPA')}</p>
            <div className="flex justify-center">
              <img src="/qr-code.svg" alt="SEPA QR Code" className="w-40 h-40 rounded-lg bg-white p-2" />
            </div>
            <p className={`${tk.muted} text-xs leading-relaxed whitespace-pre-line`}>{t('app.shakeSEPAText')}</p>
          </div>
          <button onClick={onClose} className={`w-full ${tk.ghost} border font-bold py-3 rounded-xl transition-colors text-sm`}>
            {t('app.shakeBack')}
          </button>
        </div>
      </div>
    </div>
  )
}

/* ── iOS/fallback install instructions modal ──────────────────────────────── */
function InstallHelpModal({ onClose, tk, isDark }) {
  const { t } = useTranslation()
  const ios = [t('app.pwaIosStep1'), t('app.pwaIosStep2'), t('app.pwaIosStep3')]
  const android = [t('app.pwaAndroidStep1'), t('app.pwaAndroidStep2'), t('app.pwaAndroidStep3')]
  const Col = ({ icon, title, steps, num }) => (
    <div className={`${tk.sub} border rounded-xl p-4`}>
      <div className="flex items-center gap-2 mb-3">
        <span className="text-xl">{icon}</span>
        <span className={`${tk.text} font-black text-xs uppercase tracking-widest`}>{title}</span>
      </div>
      {steps.map((s, i) => (
        <div key={i} className="flex gap-3 mb-2">
          <span className={`${num} font-black text-xs mt-0.5 flex-shrink-0`}>{i + 1}.</span>
          <span className={`${tk.soft} text-xs leading-relaxed`}>{s}</span>
        </div>
      ))}
    </div>
  )
  return (
    <Modal title={t('app.installHelpTitle')} onClose={onClose} tk={tk} isDark={isDark}>
      <p className={`${tk.muted} text-xs mb-4`}>{t('app.pwaSubtitle')}</p>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <Col icon="🍎" title={t('app.pwaIos')} steps={ios} num="text-emerald-400" />
        <Col icon="🤖" title={t('app.pwaAndroid')} steps={android} num="text-cyan-400" />
      </div>
    </Modal>
  )
}

/* ── Share fallback menu (browsers without navigator.share) ───────────────── */
function ShareModal({ onClose, tk, isDark }) {
  const { t } = useTranslation()
  const [copied, setCopied] = useState(false)
  const url = "https://macrobandit.at/"
  const text = t('app.shareText')
  const e = encodeURIComponent
  const targets = [
    { label: "WhatsApp", color: "bg-[#25D366]", href: `https://wa.me/?text=${e(text + " " + url)}` },
    { label: "Telegram", color: "bg-[#229ED9]", href: `https://t.me/share/url?url=${e(url)}&text=${e(text)}` },
    { label: "X", color: "bg-black", href: `https://twitter.com/intent/tweet?text=${e(text)}&url=${e(url)}` },
    { label: "Facebook", color: "bg-[#1877F2]", href: `https://www.facebook.com/sharer/sharer.php?u=${e(url)}` },
    { label: "E-Mail", color: "bg-slate-500", href: `mailto:?subject=${e("MacroBandit")}&body=${e(text + " " + url)}` },
  ]
  const copy = async () => {
    try { await navigator.clipboard.writeText(url); setCopied(true); setTimeout(() => setCopied(false), 2000) }
    catch { /* Clipboard nicht verfügbar */ }
  }
  return (
    <div className="fixed inset-0 bg-black/70 z-50 flex items-center justify-center p-4 backdrop-blur-sm" onClick={onClose}>
      <div onClick={ev => ev.stopPropagation()} className={`${isDark ? "bg-slate-900" : "bg-white"} border ${tk.border} rounded-2xl w-full max-w-sm`}>
        <div className={`flex items-center justify-between px-6 py-4 border-b ${tk.border}`}>
          <h2 className={`${tk.text} font-black text-lg`}>{t('app.shareTitle')}</h2>
          <button onClick={onClose} className={`${tk.mutedHover} text-2xl leading-none transition-colors`}>✕</button>
        </div>
        <div className="px-6 py-6 space-y-3">
          <div className="grid grid-cols-1 gap-2">
            {targets.map(s => (
              <a key={s.label} href={s.href} target="_blank" rel="noopener noreferrer" onClick={onClose}
                className={`${s.color} text-white font-black text-sm py-3 rounded-xl text-center transition-opacity hover:opacity-90`}>
                {s.label}
              </a>
            ))}
          </div>
          <button onClick={copy}
            className={`w-full ${tk.ghost} border font-bold py-3 rounded-xl transition-colors text-sm`}>
            {copied ? t('app.shareCopied') : t('app.shareCopy')}
          </button>
        </div>
      </div>
    </div>
  )
}

/* ── Inline auth card with Anmelden / Registrieren tabs ───────────────────── */
function AuthCard({ tk, isDark, onLegal }) {
  const { t } = useTranslation()
  const { login } = useAuth()
  const [mode, setMode] = useState("login")            // login | register | forgot | registered
  const [form, setForm] = useState({ email: "", username: "", password: "" })
  const [forgotEmail, setForgotEmail] = useState("")
  const [agreed, setAgreed] = useState(false)
  const [registeredEmail, setRegisteredEmail] = useState("")
  const [error, setError] = useState("")
  const [success, setSuccess] = useState("")
  const [loading, setLoading] = useState(false)

  const set = (f) => (e) => setForm({ ...form, [f]: e.target.value })
  const label = `block ${tk.muted} text-xs font-bold uppercase tracking-widest mb-1`
  const field = `w-full ${tk.input} border rounded-xl px-4 py-3 font-bold outline-none focus:ring-2 focus:ring-emerald-500`

  const submit = async (e) => {
    e.preventDefault()
    setError(""); setSuccess(""); setLoading(true)
    try {
      if (mode === "login") {
        try { await login(form.email, form.password) }
        catch (err) { throw new Error(Array.isArray(err.message) ? err.message.join(", ") : err.message) }
      } else if (mode === "register") {
        const res = await fetch(`${API}/auth/register`, {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email: form.email, username: form.username, password: form.password }),
        })
        if (!res.ok) {
          const err = await res.json()
          throw new Error(Array.isArray(err.detail) ? err.detail.map(x => x.msg).join(", ") : err.detail || t('auth.registerFailed'))
        }
        setRegisteredEmail(form.email); setMode("registered")
      } else if (mode === "forgot") {
        const res = await fetch(`${API}/auth/forgot-password`, {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email: forgotEmail }),
        })
        const data = await res.json()
        setSuccess(data.message || t('auth.emailSent'))
      }
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className={`${tk.card} border ${tk.border} rounded-3xl shadow-xl w-full max-w-md p-6`}>
      {mode === "registered" ? (
        <div className="text-center space-y-4">
          <div className="text-5xl mb-1">📧</div>
          <h3 className={`${tk.text} font-black text-xl`}>{t('auth.registeredTitle')}</h3>
          <p className={`${tk.muted} text-sm leading-relaxed`}>
            {t('auth.registeredText1')}<br />
            <strong className="text-emerald-400">{registeredEmail}</strong><br />
            {t('auth.registeredText2')}
          </p>
          <div className={`${tk.sub} border rounded-2xl p-4 text-left space-y-2`}>
            <p className={`${tk.soft} text-sm font-bold`}>{t('auth.registeredStepsTitle')}</p>
            <p className={`${tk.muted} text-xs`}>{t('auth.registeredStep1')}</p>
            <p className={`${tk.muted} text-xs`}>{t('auth.registeredStep2')}</p>
            <p className={`${tk.muted} text-xs`}>{t('auth.registeredStep3')}</p>
          </div>
          <button onClick={() => { setMode("login"); setForm({ email: registeredEmail, username: "", password: "" }) }}
            className={`w-full ${GRAD} text-white font-black py-3 rounded-xl`}>
            {t('auth.toLogin')}
          </button>
          <p className={`${tk.muted} text-xs`}>{t('auth.noEmail')}</p>
        </div>
      ) : (
        <>
          {(mode === "login" || mode === "register") && (
            <div className={`flex ${tk.track} border ${tk.border} p-1 rounded-xl mb-6`}>
              <button onClick={() => { setMode("login"); setError(""); setSuccess("") }}
                className={`flex-1 py-2 rounded-lg text-sm font-black transition-colors ${mode === "login" ? "bg-emerald-700 text-white" : `${tk.mutedHover}`}`}>
                {t('auth.loginTab')}
              </button>
              <button onClick={() => { setMode("register"); setError(""); setSuccess("") }}
                className={`flex-1 py-2 rounded-lg text-sm font-black transition-colors ${mode === "register" ? "bg-emerald-700 text-white" : `${tk.mutedHover}`}`}>
                {t('auth.registerTab')}
              </button>
            </div>
          )}

          {mode === "forgot" && (
            <div className="mb-4">
              <h2 className={`${tk.text} font-black text-lg`}>{t('auth.forgotHeader')}</h2>
              <p className={`${tk.muted} text-sm mt-1`}>{t('auth.forgotSubtitle')}</p>
            </div>
          )}

          {error && <div className="bg-rose-900/40 border border-rose-500 text-rose-300 rounded-xl px-4 py-3 mb-4 text-sm font-bold">⚠️ {error}</div>}
          {success && <div className="bg-emerald-900/40 border border-emerald-500 text-emerald-300 rounded-xl px-4 py-3 mb-4 text-sm font-bold">✓ {success}</div>}

          <form onSubmit={submit} className="space-y-4">
            {(mode === "login" || mode === "register") && (
              <div>
                <label className={label}>{t('auth.emailLabel')}</label>
                <input type="email" value={form.email} onChange={set("email")} required placeholder={t('auth.emailPlaceholder')} className={field} />
              </div>
            )}
            {mode === "register" && (
              <div>
                <label className={label}>{t('auth.usernameLabel')}</label>
                <input type="text" value={form.username} onChange={set("username")} required placeholder={t('auth.usernamePlaceholder')} className={field} />
              </div>
            )}
            {(mode === "login" || mode === "register") && (
              <div>
                <label className={label}>{t('auth.passwordLabel')}</label>
                <input type="password" value={form.password} onChange={set("password")} required
                  placeholder={mode === "register" ? t('auth.passwordMinHint') : t('auth.passwordPlaceholder')} className={field} />
                {mode === "register" && <PasswordStrength password={form.password} />}
              </div>
            )}

            {mode === "login" && (
              <div className="text-right">
                <button type="button" onClick={() => { setMode("forgot"); setError(""); setSuccess("") }}
                  className={`text-xs ${tk.mutedHover} transition-colors font-bold`}>
                  {t('auth.forgotPassword')}
                </button>
              </div>
            )}

            {mode === "register" && (
              <label className="flex items-start gap-3 cursor-pointer group">
                <div className="relative mt-0.5 flex-shrink-0">
                  <input type="checkbox" checked={agreed} onChange={e => setAgreed(e.target.checked)} className="sr-only" />
                  <div className={`w-5 h-5 rounded border-2 flex items-center justify-center transition-colors ${agreed ? "bg-emerald-500 border-emerald-500" : `${isDark ? "border-slate-600" : "border-slate-400"} group-hover:border-emerald-500`}`}>
                    {agreed && <span className="text-white text-xs font-black">✓</span>}
                  </div>
                </div>
                <span className={`${tk.muted} text-sm leading-relaxed`}>
                  {t('app.registerGateAccept')}{" "}
                  <button type="button" onClick={() => onLegal("nutzung")} className={`${tk.accent} underline`}>{t('app.nutzung')}</button>
                  {" "}{t('app.registerGateAnd')}{" "}
                  <button type="button" onClick={() => onLegal("datenschutz")} className={`${tk.accent} underline`}>{t('app.datenschutz')}</button>
                  {t('app.registerGateRead') ? ` ${t('app.registerGateRead')}` : ''}
                </span>
              </label>
            )}

            {mode === "forgot" && (
              <div>
                <label className={label}>{t('auth.yourEmailLabel')}</label>
                <input type="email" value={forgotEmail} onChange={e => setForgotEmail(e.target.value)} required placeholder={t('auth.emailPlaceholder')} className={field} />
              </div>
            )}

            <button type="submit" disabled={loading || (mode === "register" && !agreed)}
              className={`w-full ${GRAD} hover:from-emerald-800 hover:to-teal-800 disabled:opacity-40 disabled:cursor-not-allowed text-white font-black py-3 rounded-xl transition-all mt-2`}>
              {loading ? t('auth.loading')
                : mode === "login" ? t('auth.loginButton')
                : mode === "register" ? t('auth.registerButton')
                : t('auth.sendResetLink')}
            </button>

            {mode === "forgot" && (
              <button type="button" onClick={() => { setMode("login"); setError(""); setSuccess("") }}
                className={`w-full text-center text-xs ${tk.mutedHover} transition-colors font-bold mt-2`}>
                {t('auth.backToLogin')}
              </button>
            )}
          </form>
        </>
      )}
    </div>
  )
}

/* ── Small presentational cards ───────────────────────────────────────────── */
function SectionHead({ tk, label, headline, sub }) {
  return (
    <div className="text-center max-w-2xl mx-auto mb-10">
      <h2 className={`${tk.text} font-black text-2xl sm:text-3xl tracking-tight mb-3`}>{headline}</h2>
      <p className={`${tk.muted} text-sm sm:text-base leading-relaxed`}>{sub}</p>
    </div>
  )
}

/* ── Root landing page (structure modeled on IronBandit, MacroBandit brand) ── */
function LandingPage() {
  const { t } = useTranslation()
  const [isDark, setIsDark] = useState(() => {
    const saved = localStorage.getItem("theme")
    return saved ? saved === "dark" : true
  })
  const tk = tokens(isDark)

  const [legalModal, setLegalModal] = useState(null)
  const [showShake, setShowShake] = useState(false)
  const [showInstallHelp, setShowInstallHelp] = useState(false)
  const [showShare, setShowShare] = useState(false)

  const deferredPrompt = useRef(null)
  const [canInstall, setCanInstall] = useState(false)
  const [bannerClosed, setBannerClosed] = useState(() => sessionStorage.getItem("installBannerClosed") === "1")

  useEffect(() => {
    localStorage.setItem("theme", isDark ? "dark" : "light")
    document.body.style.backgroundColor = isDark ? "#020617" : "#f8fafc"
  }, [isDark])

  useEffect(() => {
    const onBip = (e) => { e.preventDefault(); deferredPrompt.current = e; setCanInstall(true) }
    const onInstalled = () => { deferredPrompt.current = null; setCanInstall(false) }
    window.addEventListener("beforeinstallprompt", onBip)
    window.addEventListener("appinstalled", onInstalled)
    return () => {
      window.removeEventListener("beforeinstallprompt", onBip)
      window.removeEventListener("appinstalled", onInstalled)
    }
  }, [])

  const handleInstall = async () => {
    const d = deferredPrompt.current
    if (d) {
      d.prompt()
      await d.userChoice
      deferredPrompt.current = null
      setCanInstall(false)
    } else {
      setShowInstallHelp(true)
    }
  }

  const handleShare = async () => {
    const data = { title: "MacroBandit", text: t('app.shareText'), url: "https://macrobandit.at/" }
    if (navigator.share) {
      try { await navigator.share(data) } catch { /* vom Nutzer abgebrochen */ }
    } else {
      setShowShare(true)
    }
  }

  const scrollTop = () => window.scrollTo({ top: 0, behavior: "smooth" })

  const featIcons = [
    { icon: "📷", color: "from-sky-700 to-blue-700" },
    { icon: "⚖️", color: "from-emerald-700 to-teal-700" },
    { icon: "🔥", color: "from-amber-700 to-orange-700" },
    { icon: "📊", color: "from-green-700 to-emerald-800" },
    { icon: "🚫", color: "from-rose-700 to-red-700" },
    { icon: "📱", color: "from-slate-600 to-slate-800" },
  ]
  const features = featIcons.map((f, i) => ({ ...f, title: t(`app.featGrid${i + 1}Title`), text: t(`app.featGrid${i + 1}Text`) }))
  const steps = [1, 2, 3, 4].map(n => ({ title: t(`app.howStep${n}Title`), text: t(`app.howStep${n}Text`) }))
  const benefits = [
    { icon: "✅", title: t('app.benefit1Title'), text: t('app.benefit1Text') },
    { icon: "🛡️", title: t('app.benefit2Title'), text: t('app.benefit2Text') },
    { icon: "⚡", title: t('app.benefit3Title'), text: t('app.benefit3Text') },
    { icon: "📵", title: t('app.benefit4Title'), text: t('app.benefit4Text') },
  ]

  return (
    <div className={`min-h-screen ${tk.page} ${tk.text} overflow-x-hidden`}>

      {/* ── Header / Nav ─────────────────────────────────────────────── */}
      <header className={`sticky top-0 z-40 backdrop-blur border-b ${tk.header}`}>
        <div className="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
          <button onClick={scrollTop} className="flex items-center gap-2.5 min-w-0">
            <img src="/logo.png" alt="MacroBandit" className="w-9 h-9 rounded-full flex-shrink-0" />
            <span className={`${tk.text} font-black tracking-widest text-sm sm:text-base truncate`}>MACROBANDIT</span>
          </button>
          <div className="flex items-center gap-2">
            {canInstall && (
              <button onClick={handleInstall}
                className={`hidden sm:inline-flex items-center ${GRAD} text-white font-black text-xs px-4 py-2 rounded-full`}>
                {t('app.installApp')}
              </button>
            )}
            <button onClick={handleShare} aria-label={t('app.shareButton')}
              className={`inline-flex items-center gap-1.5 h-10 px-3 sm:px-4 rounded-full border ${tk.border} ${tk.card} ${tk.text} font-black text-xs`}>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" className="w-4 h-4">
                <circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" />
                <line x1="8.6" y1="13.5" x2="15.4" y2="17.5" /><line x1="15.4" y1="6.5" x2="8.6" y2="10.5" />
              </svg>
              <span className="hidden sm:inline">{t('app.shareButton')}</span>
            </button>
            <button onClick={() => setIsDark(d => !d)} aria-label="Theme"
              className={`w-10 h-10 rounded-full border ${tk.border} ${tk.card} flex items-center justify-center text-lg`}>
              {isDark ? "☀️" : "🌙"}
            </button>
          </div>
        </div>
      </header>

      {/* ── Hero (logo + slogan + description  |  auth tabs) ──────────── */}
      <section className="max-w-6xl mx-auto px-4 pt-12 pb-16 grid lg:grid-cols-2 gap-10 lg:gap-12 items-center">
        <div className="text-center lg:text-left">
          <img src="/logo.png" alt="MacroBandit" className="w-32 h-32 sm:w-36 sm:h-36 mx-auto lg:mx-0 rounded-full mb-6 drop-shadow-xl" />
          <p className={`${tk.text} font-black text-xl tracking-widest uppercase mb-3`}>{t('app.name')}</p>
          <h1 className="font-black tracking-tight uppercase leading-tight text-2xl sm:text-4xl mb-4 break-words">
            {t('app.tagline1')}<br />
            <span className={tk.accent}>{t('app.tagline2')}</span>
          </h1>
          <p className={`${tk.soft} font-bold text-base sm:text-lg mb-3`}>{t('app.subtitle')}</p>
          <p className={`${tk.muted} text-sm sm:text-base leading-relaxed max-w-xl mx-auto lg:mx-0 mb-6`}>{t('app.description')}</p>
          <div className="flex flex-wrap gap-2 justify-center lg:justify-start">
            {[t('app.badgeFree'), t('app.badgeNoAds'), t('app.badgeInstall')].map((b, i) => (
              <span key={i} className={`${tk.chip} border rounded-full px-3 py-1.5 text-xs font-bold`}>{b}</span>
            ))}
          </div>
        </div>
        <div className="flex justify-center lg:justify-end">
          <AuthCard tk={tk} isDark={isDark} onLegal={setLegalModal} />
        </div>
      </section>

      {/* ── Feature tiles grid ───────────────────────────────────────── */}
      <section className="max-w-6xl mx-auto px-4 py-14">
        <SectionHead tk={tk} label={t('app.featuresLabel')} headline={t('app.featuresHeadline')} sub={t('app.featuresSub')} />
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {features.map((f, i) => (
            <div key={i} className={`${tk.card} border ${tk.border} rounded-2xl p-5`}>
              <div className={`w-11 h-11 rounded-xl bg-gradient-to-br ${f.color} flex items-center justify-center text-xl mb-4`}>{f.icon}</div>
              <h3 className={`${tk.text} font-black text-sm tracking-wide uppercase mb-2`}>{f.title}</h3>
              <p className={`${tk.muted} text-sm leading-relaxed`}>{f.text}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── Schwester-App / Cross-Promo: IronBandit ──────────────────── */}
      <section className="max-w-6xl mx-auto px-4 pb-14">
        <a href="https://ironbandit.at" target="_blank" rel="noopener noreferrer"
          className={`group block ${tk.card} border ${tk.border} rounded-2xl p-6 sm:p-7 hover:border-orange-500 transition-colors`}>
          <div className="flex flex-col sm:flex-row items-center gap-5 text-center sm:text-left">
            <img src="/iron_logo.png" alt="IronBandit" className="w-16 h-16 rounded-full flex-shrink-0 drop-shadow-lg" />
            <div className="min-w-0 flex-1">
              <p className="text-orange-500 font-black text-xs tracking-[0.25em] uppercase mb-1">{t('app.sisterLabel')}</p>
              <h3 className={`${tk.text} font-black text-lg sm:text-xl mb-1`}>{t('app.sisterHeadline')}</h3>
              <p className={`${tk.muted} text-sm leading-relaxed`}>{t('app.sisterText')}</p>
            </div>
            <span className="bg-gradient-to-r from-orange-700 to-red-700 group-hover:from-orange-400 group-hover:to-red-400 text-white font-black text-sm px-5 py-3 rounded-full whitespace-nowrap flex-shrink-0 transition-all">
              {t('app.sisterCta')} →
            </span>
          </div>
        </a>
      </section>

      {/* ── "So funktioniert MacroBandit" — numbered steps ───────────── */}
      <section className={`border-y ${tk.border} ${isDark ? "bg-slate-900/40" : "bg-white"}`}>
        <div className="max-w-6xl mx-auto px-4 py-16">
          <SectionHead tk={tk} label={t('app.howLabel')} headline={t('app.howHeadline')} sub={t('app.howSub')} />
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {steps.map((s, i) => (
              <div key={i} className={`${tk.sub} border rounded-2xl p-5`}>
                <div className={`w-10 h-10 rounded-xl ${GRAD} text-white font-black flex items-center justify-center mb-4`}>{i + 1}</div>
                <h3 className={`${tk.text} font-black text-sm tracking-wide uppercase mb-2`}>{s.title}</h3>
                <p className={`${tk.muted} text-sm leading-relaxed`}>{s.text}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Benefits — icon cards ────────────────────────────────────── */}
      <section className="max-w-6xl mx-auto px-4 py-16">
        <SectionHead tk={tk} label={t('app.benefitsLabel')} headline={t('app.benefitsHeadline')} sub={t('app.benefitsSub')} />
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {benefits.map((b, i) => (
            <div key={i} className={`${tk.card} border ${tk.border} rounded-2xl p-5 text-center`}>
              <div className="text-3xl mb-3">{b.icon}</div>
              <h3 className={`${tk.text} font-black text-sm tracking-wide uppercase mb-2`}>{b.title}</h3>
              <p className={`${tk.muted} text-sm leading-relaxed`}>{b.text}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── Footer ───────────────────────────────────────────────────── */}
      <footer className={`border-t ${tk.border} px-4 py-10`}>
        <div className="max-w-6xl mx-auto space-y-5 text-center">
          <div className="flex items-center justify-center gap-x-5 gap-y-2 flex-wrap text-sm font-bold">
            <button onClick={scrollTop} className={`${tk.mutedHover} transition-colors`}>{t('app.footerStart')}</button>
            <button onClick={handleInstall} className={`${tk.mutedHover} transition-colors`}>{t('app.footerInstall')}</button>
            <a href="https://ironbandit.at" target="_blank" rel="noopener noreferrer" className={`${tk.mutedHover} transition-colors`}>{t('app.footerIron')}</a>
            <button onClick={() => setLegalModal("impressum")} className={`${tk.mutedHover} transition-colors`}>{t('app.impressum')}</button>
            <button onClick={() => setLegalModal("datenschutz")} className={`${tk.mutedHover} transition-colors`}>{t('app.datenschutz')}</button>
            <button onClick={() => setLegalModal("nutzung")} className={`${tk.mutedHover} transition-colors`}>{t('app.nutzung')}</button>
          </div>
          <button onClick={() => setShowShake(true)} className={`${tk.mutedHover} transition-colors text-sm font-bold`}>
            {t('app.buyShake')}
          </button>
          <p className="text-emerald-500/80 text-xs font-black tracking-widest uppercase">{t('app.footerSlogan')}</p>
          <p className={`${tk.muted} opacity-60 text-[10px] font-mono tracking-wider`}>v{__APP_VERSION__}</p>
        </div>
      </footer>

      {legalModal && (
        <Modal title={t(LEGAL_KEYS[legalModal].titleKey)} onClose={() => setLegalModal(null)} tk={tk} isDark={isDark}>
          {t(LEGAL_KEYS[legalModal].contentKey)}
        </Modal>
      )}
      {showShake && <ShakeModal onClose={() => setShowShake(false)} tk={tk} isDark={isDark} />}
      {showInstallHelp && <InstallHelpModal onClose={() => setShowInstallHelp(false)} tk={tk} isDark={isDark} />}
      {showShare && <ShareModal onClose={() => setShowShare(false)} tk={tk} isDark={isDark} />}

      {/* ── Automatischer Install-Banner (sobald Chrome die Seite als installierbar meldet) ── */}
      {canInstall && !bannerClosed && (
        <div className="fixed inset-x-0 bottom-0 z-50 p-3 sm:p-4 flex justify-center pointer-events-none">
          <div className={`pointer-events-auto ${tk.card} border ${tk.border} shadow-2xl rounded-2xl w-full max-w-md p-4 flex items-center gap-3`}>
            <img src="/icon-192.png" alt="MacroBandit" className="w-11 h-11 rounded-full flex-shrink-0" />
            <div className="min-w-0 flex-1">
              <p className={`${tk.text} font-black text-sm leading-tight`}>{t('app.installBannerTitle')}</p>
              <p className={`${tk.muted} text-xs leading-snug mt-0.5`}>{t('app.installBannerText')}</p>
            </div>
            <div className="flex flex-col gap-1.5 flex-shrink-0">
              <button onClick={handleInstall} className={`${GRAD} text-white font-black text-xs px-4 py-2 rounded-full whitespace-nowrap`}>
                {t('app.installBannerCta')}
              </button>
              <button onClick={() => { setBannerClosed(true); sessionStorage.setItem("installBannerClosed", "1") }}
                className={`${tk.mutedHover} text-xs font-bold transition-colors`}>
                {t('app.installBannerLater')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

/* ── App shell / routing ──────────────────────────────────────────────────── */
function AppInner() {
  const { t } = useTranslation()
  const { user, loading } = useAuth()
  const [resetToken, setResetToken] = useState(null)
  const [verifyStatus, setVerifyStatus] = useState(null)
  const [verifyMsg, setVerifyMsg] = useState("")

  useEffect(() => {
    // SW-Registrierung + Update-Erkennung läuft zentral in <UpdateNotification />.
    const params = new URLSearchParams(window.location.search)
    const token = params.get("token")
    const path = window.location.pathname

    if (token && path === "/reset-password") {
      setResetToken(token)
    }
    if (token && path === "/verify-email") {
      setVerifyStatus("loading")
      fetch(`/api/auth/verify-email?token=${token}`)
        .then(r => r.json())
        .then(data => {
          setVerifyStatus("success")
          setVerifyMsg(data.message || t('app.emailVerified'))
          window.history.replaceState({}, "", "/")
        })
        .catch(() => {
          setVerifyStatus("error")
          setVerifyMsg(t('app.invalidLink'))
        })
    }
  }, [])

  if (loading || verifyStatus === "loading") {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="text-slate-400 text-sm">
          {verifyStatus === "loading" ? t('app.verifying') : t('app.loading')}
        </div>
      </div>
    )
  }

  if (verifyStatus === "success" || verifyStatus === "error") {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center px-4">
        <div className="bg-slate-900 border border-slate-800 rounded-3xl p-8 max-w-sm w-full text-center">
          <div className="text-4xl mb-4">{verifyStatus === "success" ? "✅" : "❌"}</div>
          <h2 className="text-white font-black text-xl mb-2">
            {verifyStatus === "success" ? t('app.emailVerified') : t('app.error')}
          </h2>
          <p className="text-slate-400 mb-6 text-sm">{verifyMsg}</p>
          <button onClick={() => setVerifyStatus(null)}
            className={`w-full ${GRAD} text-white font-black py-3 rounded-xl`}>
            {t('app.toLogin')}
          </button>
        </div>
      </div>
    )
  }

  if (user) return <Dashboard />
  if (resetToken) return <AuthPage resetToken={resetToken} onBack={() => setResetToken(null)} />
  return <LandingPage />
}

/* ── Update-Benachrichtigung (Service-Worker-Lifecycle) ───────────────────────
   Erkennt über den vorhandenen SW-Lifecycle, dass eine neue Version installiert
   wurde ('waiting'/updatefound), und zeigt ein unaufdringliches Banner. Der
   Reload passiert AUSSCHLIESSLICH nach Klick – nie automatisch. */
function UpdateNotification() {
  const { t } = useTranslation()
  const [waitingWorker, setWaitingWorker] = useState(null)
  const [visible, setVisible] = useState(false)
  const userTriggered = useRef(false)

  useEffect(() => {
    if (!("serviceWorker" in navigator)) return
    let refreshing = false

    // Der neue SW aktiviert sich erst nach SKIP_WAITING (= User-Klick) und
    // übernimmt via clients.claim() die Kontrolle → dann feuert controllerchange.
    // Nur in diesem Fall (userTriggered) neu laden, damit Erstinstall & fremde
    // Auslöser NICHT ungewollt reloaden und Eingaben verloren gehen.
    const onControllerChange = () => {
      if (!userTriggered.current || refreshing) return
      refreshing = true
      window.location.reload()
    }
    navigator.serviceWorker.addEventListener("controllerchange", onControllerChange)

    navigator.serviceWorker.register("/sw.js").then((reg) => {
      const showUpdate = (worker) => {
        if (!worker) return
        setWaitingWorker(worker)
        setVisible(true)
      }
      // Es wartet bereits ein neuer SW (z. B. Tab war länger offen).
      if (reg.waiting && navigator.serviceWorker.controller) showUpdate(reg.waiting)

      reg.addEventListener("updatefound", () => {
        const nw = reg.installing
        if (!nw) return
        nw.addEventListener("statechange", () => {
          // 'installed' + bereits vorhandener Controller = echtes Update (kein Erstinstall).
          if (nw.state === "installed" && navigator.serviceWorker.controller) showUpdate(nw)
        })
      })
    }).catch(() => {})

    return () => navigator.serviceWorker.removeEventListener("controllerchange", onControllerChange)
  }, [])

  const reload = () => {
    userTriggered.current = true
    if (waitingWorker) {
      waitingWorker.postMessage({ type: "SKIP_WAITING" })
      // Sicherheitsnetz: bleibt controllerchange aus, laden wir selbst neu.
      // (Feuert controllerchange, ist die Seite bereits weg und dieser Timer verfällt.)
      setTimeout(() => window.location.reload(), 2500)
    } else {
      window.location.reload()
    }
  }

  if (!visible) return null
  return (
    <div className="fixed inset-x-0 top-0 z-[60] p-3 flex justify-center pointer-events-none">
      <div className="pointer-events-auto bg-gradient-to-r from-emerald-700 to-teal-700 text-white shadow-2xl rounded-2xl w-full max-w-md px-4 py-3 flex items-center gap-3">
        <span className="text-xl flex-shrink-0" aria-hidden="true">🚀</span>
        <p className="font-black text-sm leading-tight flex-1 min-w-0">{t('app.updateAvailable')}</p>
        <button onClick={reload}
          className="bg-white/95 hover:bg-white text-emerald-700 font-black text-xs px-4 py-2 rounded-full whitespace-nowrap flex-shrink-0 transition-colors">
          {t('app.updateReload')}
        </button>
      </div>
    </div>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <UpdateNotification />
      <AppInner />
    </AuthProvider>
  )
}
