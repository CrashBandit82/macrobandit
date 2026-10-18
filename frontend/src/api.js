import axios from 'axios'

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000/api'

const apiClient = axios.create({
  baseURL: API_BASE,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Error handler
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message)
    return Promise.reject(error)
  }
)

// Foods
export const foodApi = {
  list: () => apiClient.get('/foods'),
  get: (id) => apiClient.get(`/foods/${id}`),
  create: (data) => apiClient.post('/foods', data),
  delete: (id) => apiClient.delete(`/foods/${id}`),
}

// Barcode lookup
export const barcodeApi = {
  lookup: (barcode) => apiClient.get(`/barcode/${barcode}`),
}

// Daily logs
export const logApi = {
  add: (data) => apiClient.post('/logs', data),
  getToday: () => apiClient.get('/logs/today'),
  getByDate: (date) => apiClient.get(`/logs/date/${date}`),
  delete: (id) => apiClient.delete(`/logs/${id}`),
}

// Daily totals
export const totalsApi = {
  today: () => apiClient.get('/totals/today'),
  byDate: (date) => apiClient.get(`/totals/date/${date}`),
}

// Health check
export const healthApi = {
  check: () => apiClient.get('/health'),
}

export default apiClient
