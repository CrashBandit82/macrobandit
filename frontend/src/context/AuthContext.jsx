import { createContext, useContext, useState, useEffect, useCallback } from "react";

const API = import.meta.env.VITE_API_URL || "/api";
const AuthContext = createContext(null);

// B2/B3: aktuellen Token an den Service Worker melden (für die Offline-Queue-Sync).
// Bei Logout token=null. Wird nicht persistiert, lebt nur im SW-Speicher.
function notifySW(token) {
  if (!("serviceWorker" in navigator)) return;
  navigator.serviceWorker.ready
    .then((reg) => (reg.active || navigator.serviceWorker.controller)?.postMessage({ type: "SET_TOKEN", token: token ?? null }))
    .catch(() => {});
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  const logout = useCallback(() => {
    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    notifySW(null);
    // Zwischengespeicherte, authentifizierte API-Antworten löschen, damit auf
    // geteilten Geräten nach dem Logout keine fremden Daten im Cache Storage
    // verbleiben.
    if ("caches" in window) {
      caches.keys().then((keys) =>
        keys.filter((k) => k.includes("-api")).forEach((k) => caches.delete(k))
      ).catch(() => {});
    }
    setUser(null);
  }, []);

  const fetchMe = useCallback(async (token) => {
    const res = await fetch(`${API}/auth/me`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    if (!res.ok) throw new Error("unauthorized");
    return res.json();
  }, []);

  const refreshTokens = useCallback(async () => {
    const refresh = localStorage.getItem("refresh_token");
    if (!refresh) return null;
    const res = await fetch(`${API}/auth/refresh`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: refresh })
    });
    if (!res.ok) return null;
    const data = await res.json();
    localStorage.setItem("access_token", data.access_token);
    localStorage.setItem("refresh_token", data.refresh_token);
    notifySW(data.access_token);
    return data.access_token;
  }, []);

  useEffect(() => {
    async function restore() {
      let token = localStorage.getItem("access_token");
      if (!token) { setLoading(false); return; }
      try {
        const me = await fetchMe(token);
        setUser(me);
      } catch {
        const newToken = await refreshTokens();
        if (newToken) {
          try {
            const me = await fetchMe(newToken);
            setUser(me);
          } catch { logout(); }
        } else { logout(); }
      } finally { setLoading(false); }
    }
    restore();
  }, [fetchMe, refreshTokens, logout]);

  const login = async (email, password) => {
    const res = await fetch(`${API}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password })
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || "Login fehlgeschlagen");
    }
    const data = await res.json();
    localStorage.setItem("access_token", data.access_token);
    localStorage.setItem("refresh_token", data.refresh_token);
    notifySW(data.access_token);
    const me = await fetchMe(data.access_token);
    setUser(me);
  };

  const register = async (email, username, password) => {
    const res = await fetch(`${API}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, username, password })
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || "Registrierung fehlgeschlagen");
    }
    await login(email, password);
  };

  const refreshUser = useCallback(async () => {
    const token = localStorage.getItem("access_token");
    if (!token) return;
    try {
      const me = await fetchMe(token);
      setUser(me);
    } catch {}
  }, [fetchMe]);

  const authFetch = useCallback(async (url, options = {}) => {
    let token = localStorage.getItem("access_token");
    const makeReq = (t) => fetch(url, {
      ...options,
      headers: { ...options.headers, Authorization: `Bearer ${t}` }
    });
    let res = await makeReq(token);
    if (res.status === 401) {
      const newToken = await refreshTokens();
      if (!newToken) { logout(); throw new Error("Session abgelaufen"); }
      res = await makeReq(newToken);
      if (res.status === 401) { logout(); throw new Error("Session abgelaufen"); }
    }
    return res;
  }, [refreshTokens, logout]);

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, register, authFetch, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
