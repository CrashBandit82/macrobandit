import { useState, useEffect, useCallback } from "react"
import { useTranslation } from "react-i18next"
import { useAuth } from "../context/AuthContext"

const API = import.meta.env.VITE_API_URL || "/api"

export default function MealTemplates({ foods, onApplied, userColor }) {
  const { t } = useTranslation()
  const { authFetch } = useAuth()
  const [templates, setTemplates] = useState([])
  const [loading, setLoading] = useState(true)
  const [showCreate, setShowCreate] = useState(false)
  const [newName, setNewName] = useState("")
  const [selectedItems, setSelectedItems] = useState([])
  const [foodSearch, setFoodSearch] = useState("")
  const [success, setSuccess] = useState(null)
  const [error, setError] = useState(null)
  const [applying, setApplying] = useState(null)
  const [editingId, setEditingId] = useState(null)

  useEffect(() => {
    if (success) { const t = setTimeout(() => setSuccess(null), 3000); return () => clearTimeout(t) }
  }, [success])

  const load = useCallback(async () => {
    try {
      const res = await authFetch(`${API}/templates`)
      setTemplates(await res.json())
    } catch (e) { console.error(e) }
    finally { setLoading(false) }
  }, [authFetch])

  useEffect(() => { load() }, [load])

  const applyTemplate = async (template) => {
    setApplying(template.id)
    try {
      const res = await authFetch(`${API}/templates/${template.id}/apply`, { method: "POST" })
      const data = await res.json()
      if (!res.ok) throw new Error(data.detail)
      setSuccess(t('templates.applied', { name: template.name, count: data.count }))
      onApplied()
    } catch (e) { setError(e.message) }
    finally { setApplying(null) }
  }

  const deleteTemplate = async (id) => {
    if (!window.confirm(t('templates.deleteConfirm'))) return
    await authFetch(`${API}/templates/${id}`, { method: "DELETE" })
    load()
  }

  const addFoodToNew = (food) => {
    if (selectedItems.find(i => i.food.id === food.id)) return
    setSelectedItems(prev => [...prev, { food, amount: food.portion_size_g || 100 }])
    setFoodSearch("")
  }

  const updateAmount = (foodId, amount) => {
    setSelectedItems(prev => prev.map(i => i.food.id === foodId ? { ...i, amount } : i))
  }

  const removeFoodFromNew = (foodId) => {
    setSelectedItems(prev => prev.filter(i => i.food.id !== foodId))
  }

  const closeForm = () => {
    setShowCreate(false); setEditingId(null)
    setNewName(""); setSelectedItems([]); setFoodSearch("")
  }

  const startEdit = (tmpl) => {
    setError(null)
    setEditingId(tmpl.id)
    setNewName(tmpl.name)
    setSelectedItems(tmpl.items.map(item => ({
      food: foods.find(f => f.id === item.food_item_id) || { id: item.food_item_id, name: item.food_name },
      amount: item.amount_grams
    })))
    setFoodSearch("")
    setShowCreate(true)
  }

  const saveTemplate = async () => {
    if (!newName.trim() || selectedItems.length === 0) return
    if (selectedItems.some(i => !(parseFloat(i.amount) > 0))) { setError(t('templates.amountError')); return }
    try {
      const res = await authFetch(editingId ? `${API}/templates/${editingId}` : `${API}/templates`, {
        method: editingId ? "PUT" : "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: newName.trim(),
          items: selectedItems.map(i => ({ food_item_id: i.food.id, amount_grams: parseFloat(i.amount) }))
        })
      })
      if (!res.ok) throw new Error("Fehler")
      setSuccess(t('templates.saved'))
      setError(null)
      closeForm()
      load()
    } catch (e) { setError(t('templates.saveError')) }
  }

  const filteredFoods = foods.filter(f =>
    f.name.toLowerCase().includes(foodSearch.toLowerCase()) &&
    !selectedItems.find(i => i.food.id === f.id)
  ).slice(0, 8)

  if (loading) return <div className="text-slate-400 text-center py-4 text-sm">{t('templates.loading')}</div>

  return (
    <div className="space-y-3">
      {error   && <div className="bg-rose-950/60 border border-rose-500/50 text-rose-300 rounded-xl px-4 py-2.5 text-sm font-semibold">{error}</div>}
      {success && <div className="bg-emerald-950/60 border border-emerald-500/50 text-emerald-300 rounded-xl px-4 py-2.5 text-sm font-semibold">{success}</div>}

      {templates.length === 0 && !showCreate && (
        <div className="text-center py-6">
          <p className="text-slate-400 text-sm mb-3">{t('templates.empty')}</p>
        </div>
      )}

      {templates.filter(tmpl => tmpl.id !== editingId).map(tmpl => (
        <div key={tmpl.id} className="bg-slate-800 rounded-xl p-4 border border-slate-700/70">
          <div className="flex items-start justify-between gap-2 mb-2">
            <div>
              <h4 className="text-white font-semibold text-[15px]">{tmpl.name}</h4>
              <span className="text-xs text-amber-400 font-bold">{t('templates.kcalTotal', { kcal: Math.round(tmpl.total_kcal) })}</span>
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => applyTemplate(tmpl)}
                disabled={applying === tmpl.id}
                className={`bg-gradient-to-r ${userColor} text-white font-bold px-3.5 h-9 rounded-lg text-xs disabled:opacity-50`}
              >
                {applying === tmpl.id ? t('templates.applying') : t('templates.applyButton')}
              </button>
              <button onClick={() => startEdit(tmpl)} aria-label={t('templates.edit')} className="w-9 h-9 flex items-center justify-center rounded-lg text-slate-400 hover:text-white hover:bg-slate-700 transition-colors">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M4 20h4L19 9l-4-4L4 16v4zM13.5 6.5l4 4" /></svg>
                </button>
              <button onClick={() => deleteTemplate(tmpl.id)} aria-label={t('templates.delete')} className="w-9 h-9 flex items-center justify-center rounded-lg text-slate-400 hover:text-rose-400 hover:bg-slate-700 transition-colors">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true"><path d="M4 7h16M10 11v6M14 11v6M6 7l1 12a2 2 0 002 2h6a2 2 0 002-2l1-12M9 7V4h6v3" /></svg>
                </button>
            </div>
          </div>
          <div className="flex flex-wrap gap-1.5">
            {tmpl.items.map(item => (
              <span key={item.id} className="text-xs bg-slate-900 text-slate-300 px-2 py-1 rounded-md">
                {item.food_name} {item.amount_grams}g
              </span>
            ))}
          </div>
        </div>
      ))}

      {!showCreate ? (
        <button
          onClick={() => setShowCreate(true)}
          className="w-full h-12 rounded-xl border border-dashed border-slate-600 text-slate-300 hover:border-slate-400 hover:text-white transition-colors text-sm font-semibold"
        >
          {t('templates.createNew')}
        </button>
      ) : (
        <div className="bg-slate-800 rounded-xl p-4 border border-slate-700/70 space-y-3">
          <h4 className="text-white font-semibold text-[15px]">{editingId ? t('templates.editTitle') : t('templates.newTitle')}</h4>
          <input
            type="text" placeholder={t('templates.namePlaceholder')}
            value={newName} onChange={e => setNewName(e.target.value)}
            className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-3.5 py-3 text-sm font-semibold outline-none focus:border-emerald-500 transition-colors"
            autoFocus
          />

          <input
            type="text" placeholder={t('templates.foodSearch')}
            value={foodSearch} onChange={e => setFoodSearch(e.target.value)}
            className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-3.5 py-3 text-sm outline-none focus:border-emerald-500 transition-colors"
          />
          {foodSearch && (
            <div className="max-h-32 overflow-y-auto space-y-1">
              {filteredFoods.map(f => (
                <button key={f.id} onClick={() => addFoodToNew(f)}
                  className="w-full text-left px-3 py-2.5 bg-slate-900 hover:bg-slate-700 rounded-lg text-sm text-white transition-colors">
                  {f.name} <span className="text-slate-500 text-xs">— {Math.round(f.calories_per_100g || 0)} kcal/100g</span>
                </button>
              ))}
              {filteredFoods.length === 0 && <p className="text-slate-500 text-xs px-3">{t('templates.notFound')}</p>}
            </div>
          )}

          {selectedItems.length > 0 && (
            <div className="space-y-2">
              {selectedItems.map(({ food, amount }) => (
                <div key={food.id} className="flex items-center gap-2">
                  <span className="text-white text-xs flex-1 truncate">{food.name}</span>
                  {food.portion_size_g && (
                    <button
                      onClick={() => updateAmount(food.id, food.portion_size_g)}
                      className="text-xs text-cyan-400 bg-slate-800 px-2 py-1 rounded-lg"
                    >
                      {food.portion_label}
                    </button>
                  )}
                  <div className="flex items-center gap-1">
                    <input
                      type="number" value={amount}
                      onChange={e => updateAmount(food.id, e.target.value)}
                      className="w-16 bg-slate-900 border border-slate-700 text-white rounded-lg px-2 py-1.5 text-xs text-center outline-none focus:border-emerald-500"
                    />
                    <span className="text-slate-500 text-xs">g</span>
                  </div>
                  <button onClick={() => removeFoodFromNew(food.id)} aria-label={t('templates.delete')} className="w-8 h-8 flex items-center justify-center rounded-lg text-slate-400 hover:text-rose-400">
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18" /></svg>
                    </button>
                </div>
              ))}
            </div>
          )}

          <div className="flex gap-2 pt-1">
            <button onClick={closeForm}
              className="flex-1 border border-slate-600 text-slate-200 font-semibold h-11 rounded-xl text-sm hover:bg-slate-700 transition-colors">{t('templates.cancel')}</button>
            <button
              onClick={saveTemplate}
              disabled={!newName.trim() || selectedItems.length === 0}
              className={`flex-1 bg-gradient-to-r ${userColor} text-white font-bold h-11 rounded-xl text-sm disabled:opacity-40`}
            >
              {t('templates.save')}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
