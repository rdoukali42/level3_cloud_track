import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:30081',
});

// Debug: log every request URL and method
api.interceptors.request.use(config => {
  console.log(`[API DEBUG] ${config.method.toUpperCase()} ${config.baseURL}${config.url}`);
  const token = localStorage.getItem('jwt');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// api.interceptors.request.use(config => {
//   const token = localStorage.getItem('jwt');
//   if (token) {
//     config.headers.Authorization = `Bearer ${token}`;
//   }
//   return config;
// });

export default api;