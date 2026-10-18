// Kalorien-Farbe nach Fortschritt zum Tagesziel — nur der Prozentwert zählt, egal ob 2000 oder 3000 kcal:
// 0–75 % Weiß -> Gelb, 75–100 % Gelb -> Grün, 100–105 % Grün, > 105 % Rot (Tagesbalken blinkt dann zusätzlich)
export const KCAL_WEISS = [255, 255, 255]
export const KCAL_GELB = [250, 204, 21]
export const KCAL_GRUEN = [34, 197, 94]
export const KCAL_ROT = [239, 68, 68]

const mische = (a, b, t) => a.map((x, i) => Math.round(x + (b[i] - x) * Math.min(Math.max(t, 0), 1)))
export const rgb = (c) => `rgb(${c.join(', ')})`

export const kalorienFarbe = (p) => rgb(
  p <= 75 ? mische(KCAL_WEISS, KCAL_GELB, p / 75)
    : p <= 100 ? mische(KCAL_GELB, KCAL_GRUEN, (p - 75) / 25)
    : p <= 105 ? KCAL_GRUEN
    : KCAL_ROT
)
