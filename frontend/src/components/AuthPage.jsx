import { useState } from "react"
import { useTranslation } from "react-i18next"
import { useAuth } from "../context/AuthContext"
import PasswordStrength from "./PasswordStrength"

const API = import.meta.env.VITE_API_URL || "/api"

export default function AuthPage({ resetToken, initialMode = "login", onBack }) {
  const { t } = useTranslation()
  const { login } = useAuth()
  const [mode, setMode] = useState(resetToken ? "reset" : initialMode)
  const [form, setForm] = useState({ email: "", username: "", password: "" })
  const [forgotEmail, setForgotEmail] = useState("")
  const [resetPw, setResetPw] = useState("")
  const [resetPwConfirm, setResetPwConfirm] = useState("")
  const [registeredEmail, setRegisteredEmail] = useState("")
  const [error, setError] = useState("")
  const [success, setSuccess] = useState("")
  const [loading, setLoading] = useState(false)

  const set = (field) => (e) => setForm({ ...form, [field]: e.target.value })

  const submit = async (e) => {
    e.preventDefault()
    setError(""); setSuccess("")
    setLoading(true)
    try {
      if (mode === "login") {
        try {
          await login(form.email, form.password)
        } catch (err) {
          const msg = Array.isArray(err.message) ? err.message.join(", ") : err.message
          throw new Error(msg)
        }

      } else if (mode === "register") {
        const res = await fetch(`${API}/auth/register`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email: form.email, username: form.username, password: form.password })
        })
        if (!res.ok) {
          const err = await res.json()
          const msg = Array.isArray(err.detail)
            ? err.detail.map(e => e.msg).join(", ")
            : err.detail || t('auth.registerFailed')
          throw new Error(msg)
        }
        setRegisteredEmail(form.email)
        setMode("registered")

      } else if (mode === "forgot") {
        const res = await fetch(`${API}/auth/forgot-password`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email: forgotEmail })
        })
        const data = await res.json()
        setSuccess(data.message || t('auth.emailSent'))

      } else if (mode === "reset") {
        if (resetPw !== resetPwConfirm) { setError(t('auth.passwordMismatch')); setLoading(false); return }
        const res = await fetch(`${API}/auth/reset-password`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ token: resetToken, new_password: resetPw })
        })
        if (!res.ok) {
          const err = await res.json()
          throw new Error(err.detail || t('app.error'))
        }
        setSuccess(t('auth.passwordChanged'))
        setTimeout(() => {
          window.history.replaceState({}, "", "/")
          setMode("login")
        }, 2000)
      }
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-slate-900 flex flex-col items-center justify-center px-4">
      <div className="mb-8 text-center">
        <h1 className="text-4xl font-black tracking-tight text-emerald-400 mb-2">
          {t('auth.appName')}
        </h1>
        <p className="text-slate-400 font-bold">{t('auth.subtitle')}</p>
      </div>

      <div className="bg-slate-800 rounded-3xl shadow-xl w-full max-w-sm p-6 border border-slate-700">

        {/* Registrierung erfolgreich */}
        {mode === "registered" && (
          <div className="text-center space-y-4">
            <div className="text-5xl mb-2">📧</div>
            <h3 className="text-white font-black text-xl">{t('auth.registeredTitle')}</h3>
            <p className="text-slate-400 text-sm leading-relaxed">
              {t('auth.registeredText1')}<br />
              <strong className="text-emerald-400">{registeredEmail}</strong><br />
              {t('auth.registeredText2')}
            </p>
            <div className="bg-slate-900 rounded-2xl p-4 text-left space-y-2">
              <p className="text-slate-300 text-sm font-bold">{t('auth.registeredStepsTitle')}</p>
              <p className="text-slate-400 text-xs">{t('auth.registeredStep1')}</p>
              <p className="text-slate-400 text-xs">{t('auth.registeredStep2')}</p>
              <p className="text-slate-400 text-xs">{t('auth.registeredStep3')}</p>
            </div>
            <button
              onClick={() => { setMode("login"); setForm({ email: registeredEmail, username: "", password: "" }) }}
              className="w-full bg-gradient-to-r from-emerald-700 to-teal-700 text-white font-black py-3 rounded-xl"
            >
              {t('auth.toLogin')}
            </button>
            <p className="text-slate-600 text-xs">{t('auth.noEmail')}</p>
          </div>
        )}

        {/* Login / Register Tabs */}
        {(mode === "login" || mode === "register") && (
          <div className="flex bg-slate-900 p-1 rounded-xl mb-6">
            <button onClick={() => { setMode("login"); setError(""); setSuccess("") }}
              className={`flex-1 py-2 rounded-lg text-sm font-black transition-colors ${mode === "login" ? "bg-emerald-700 text-white" : "text-slate-400 hover:text-white"}`}>
              {t('auth.loginTab')}
            </button>
            <button onClick={() => { setMode("register"); setError(""); setSuccess("") }}
              className={`flex-1 py-2 rounded-lg text-sm font-black transition-colors ${mode === "register" ? "bg-emerald-700 text-white" : "text-slate-400 hover:text-white"}`}>
              {t('auth.registerTab')}
            </button>
          </div>
        )}

        {mode === "forgot" && (
          <div className="mb-4">
            <h2 className="text-white font-black text-lg">{t('auth.forgotHeader')}</h2>
            <p className="text-slate-400 text-sm mt-1">{t('auth.forgotSubtitle')}</p>
          </div>
        )}
        {mode === "reset" && (
          <div className="mb-4">
            <h2 className="text-white font-black text-lg">{t('auth.resetHeader')}</h2>
          </div>
        )}

        {error && (
          <div className="bg-rose-900/50 border border-rose-500 text-rose-300 rounded-xl px-4 py-3 mb-4 text-sm font-bold">
            ⚠️ {error}
          </div>
        )}
        {success && (
          <div className="bg-emerald-900/50 border border-emerald-500 text-emerald-300 rounded-xl px-4 py-3 mb-4 text-sm font-bold">
            ✓ {success}
          </div>
        )}

        {mode !== "registered" && (
          <form onSubmit={submit} className="space-y-4">

            {mode === "login" && (
              <>
                <div>
                  <label className="block text-slate-400 text-xs font-bold mb-1">{t('auth.emailLabel')}</label>
                  <input type="email" value={form.email} onChange={set("email")} required placeholder={t('auth.emailPlaceholder')}
                    className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-3 font-bold outline-none focus:ring-2 focus:ring-emerald-500 placeholder-slate-400" />
                </div>
                <div>
                  <label className="block text-slate-400 text-xs font-bold mb-1">{t('auth.passwordLabel')}</label>
                  <input type="password" value={form.password} onChange={set("password")} required placeholder={t('auth.passwordPlaceholder')}
                    className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-3 font-bold outline-none focus:ring-2 focus:ring-emerald-500 placeholder-slate-400" />
                </div>
                <div className="text-right">
                  <button type="button" onClick={() => { setMode("forgot"); setError(""); setSuccess("") }}
                    className="text-xs text-slate-500 hover:text-slate-300 transition-colors font-bold">
                    {t('auth.forgotPassword')}
                  </button>
                </div>
              </>
            )}

            {mode === "register" && (
              <>
                <div>
                  <label className="block text-slate-400 text-xs font-bold mb-1">{t('auth.emailLabel')}</label>
                  <input type="email" value={form.email} onChange={set("email")} required placeholder={t('auth.emailPlaceholder')}
                    className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-3 font-bold outline-none focus:ring-2 focus:ring-emerald-500 placeholder-slate-400" />
                </div>
                <div>
                  <label className="block text-slate-400 text-xs font-bold mb-1">{t('auth.usernameLabel')}</label>
                  <input type="text" value={form.username} onChange={set("username")} required placeholder={t('auth.usernamePlaceholder')}
                    className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-3 font-bold outline-none focus:ring-2 focus:ring-emerald-500 placeholder-slate-400" />
                </div>
                <div>
                  <label className="block text-slate-400 text-xs font-bold mb-1">{t('auth.passwordLabel')}</label>
                  <input type="password" value={form.password} onChange={set("password")} required placeholder={t('auth.passwordMinHint')}
                    className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-3 font-bold outline-none focus:ring-2 focus:ring-emerald-500 placeholder-slate-400" />
                  <PasswordStrength password={form.password} />
                </div>
              </>
            )}

            {mode === "forgot" && (
              <div>
                <label className="block text-slate-400 text-xs font-bold mb-1">{t('auth.yourEmailLabel')}</label>
                <input type="email" value={forgotEmail} onChange={e => setForgotEmail(e.target.value)} required
                  placeholder={t('auth.emailPlaceholder')}
                  className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-3 font-bold outline-none focus:ring-2 focus:ring-emerald-500 placeholder-slate-400" />
              </div>
            )}

            {mode === "reset" && (
              <>
                <div>
                  <label className="block text-slate-400 text-xs font-bold mb-1">{t('auth.newPasswordLabel')}</label>
                  <input type="password" value={resetPw} onChange={e => setResetPw(e.target.value)} required
                    placeholder={t('auth.passwordMinHint')} autoFocus
                    className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-3 font-bold outline-none focus:ring-2 focus:ring-emerald-500 placeholder-slate-400" />
                  <PasswordStrength password={resetPw} />
                </div>
                <div>
                  <label className="block text-slate-400 text-xs font-bold mb-1">{t('auth.repeatLabel')}</label>
                  <input type="password" value={resetPwConfirm} onChange={e => setResetPwConfirm(e.target.value)} required
                    placeholder={t('auth.passwordPlaceholder')}
                    className={`w-full bg-slate-900 border text-white rounded-xl px-4 py-3 font-bold outline-none focus:ring-2 focus:ring-emerald-500 placeholder-slate-400 ${
                      resetPwConfirm && resetPw !== resetPwConfirm ? "border-rose-500" : "border-slate-700"
                    }`} />
                  {resetPwConfirm && resetPw !== resetPwConfirm && (
                    <p className="text-rose-400 text-xs mt-1 font-bold">{t('auth.passwordMismatch')}</p>
                  )}
                </div>
              </>
            )}

            <button type="submit" disabled={loading}
              className="w-full bg-gradient-to-r from-emerald-700 to-teal-700 hover:from-emerald-400 hover:to-cyan-400 disabled:opacity-50 text-white font-black py-3 rounded-xl transition-all mt-2">
              {loading ? t('auth.loading')
                : mode === "login" ? t('auth.loginButton')
                : mode === "register" ? t('auth.registerButton')
                : mode === "forgot" ? t('auth.sendResetLink')
                : t('auth.setPassword')}
            </button>

            {(mode === "forgot" || mode === "reset") && (
              <button type="button" onClick={() => { setMode("login"); setError(""); setSuccess("") }}
                className="w-full text-center text-xs text-slate-500 hover:text-slate-300 transition-colors font-bold mt-2">
                {t('auth.backToLogin')}
              </button>
            )}

          </form>
        )}

      </div>

      {onBack && (
        <button onClick={onBack} className="text-zinc-600 hover:text-zinc-400 text-xs mt-4 transition-colors">
          {t('auth.backToHome')}
        </button>
      )}
      <p className="text-slate-600 text-xs mt-3 font-bold">{t('auth.footer')}</p>
    </div>
  )
}
