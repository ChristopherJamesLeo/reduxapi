import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const BASE_URL = '{{apiUrl}}';

// ─── Axios Instance ──────────────────────────────────────────────────────────
// Use `apiClient` in all your other slices instead of plain `axios`
// so every request automatically gets a valid token.

export const apiClient = axios.create({ baseURL: BASE_URL });

// ─── Token Refresh Queue ─────────────────────────────────────────────────────
// Holds requests that arrived while a refresh was already in-flight.
// They all resolve/reject together once the refresh completes.

let _isRefreshing = false;
let _queue = [];

const processQueue = (error, token = null) => {
  _queue.forEach(({ resolve, reject }) => {
    if (error) { reject(error); } else { resolve(token); }
  });
  _queue = [];
};

// ─── Thunks ─────────────────────────────────────────────────────────────────

export const login{{Name}} = createAsyncThunk(
  '{{lowerName}}/login',
  async (credentials, { rejectWithValue }) => {
    try {
      const response = await axios.post(`${BASE_URL}/login`, credentials);
      const { access_token, refresh_token, user } = response.data;
      localStorage.setItem('accessToken', access_token);
      localStorage.setItem('refreshToken', refresh_token);
      return { accessToken: access_token, refreshToken: refresh_token, user };
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Login failed');
    }
  }
);

export const logout{{Name}} = createAsyncThunk(
  '{{lowerName}}/logout',
  async (_, { rejectWithValue }) => {
    try {
      await apiClient.post('/logout');
    } catch (_) {
      // Ignore logout API errors — clear local state regardless
    } finally {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
    }
  }
);

export const refreshAccessToken = createAsyncThunk(
  '{{lowerName}}/refreshToken',
  async (_, { getState, rejectWithValue }) => {
    try {
      const token = getState().{{lowerName}}.refreshToken
        || localStorage.getItem('refreshToken');
      const response = await axios.post(`${BASE_URL}/auth/refresh`, {
        refresh_token: token,
      });
      const { access_token, refresh_token } = response.data;
      localStorage.setItem('accessToken', access_token);
      if (refresh_token) localStorage.setItem('refreshToken', refresh_token);
      return { accessToken: access_token, refreshToken: refresh_token ?? token };
    } catch (error) {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      return rejectWithValue(error.response?.data?.message || 'Session expired');
    }
  }
);

// ─── Interceptor Setup ───────────────────────────────────────────────────────
// Call this ONCE in your app entry point (e.g. main.jsx) AFTER creating the store:
//
//   import { setupApiInterceptors } from '@james/reduxapi-helper-cli/slices/{{lowerName}}Slice';
//   setupApiInterceptors(store);
//
export const setupApiInterceptors = (store) => {

  // Attach access token to every outgoing request
  apiClient.interceptors.request.use((config) => {
    const token = store.getState().{{lowerName}}.accessToken
      || localStorage.getItem('accessToken');
    if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
  });

  // On 401 → refresh token, retry original request; on refresh failure → logout
  apiClient.interceptors.response.use(
    (response) => response,
    async (error) => {
      const original = error.config;

      if (error.response?.status !== 401 || original._retry) {
        return Promise.reject(error);
      }

      // Another refresh is already in-flight: queue this request
      if (_isRefreshing) {
        return new Promise((resolve, reject) => {
          _queue.push({ resolve, reject });
        }).then((newToken) => {
          original.headers.Authorization = `Bearer ${newToken}`;
          return apiClient(original);
        }).catch(err => Promise.reject(err));
      }

      original._retry = true;
      _isRefreshing = true;

      try {
        const result = await store.dispatch(refreshAccessToken());
        if (refreshAccessToken.rejected.match(result)) throw new Error(result.payload);

        const newToken = result.payload.accessToken;
        processQueue(null, newToken);
        original.headers.Authorization = `Bearer ${newToken}`;
        return apiClient(original);
      } catch (err) {
        processQueue(err, null);
        store.dispatch(logout{{Name}}());
        return Promise.reject(err);
      } finally {
        _isRefreshing = false;
      }
    }
  );
};

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    user:            JSON.parse(localStorage.getItem('user')) || null,
    accessToken:     localStorage.getItem('accessToken') || null,
    refreshToken:    localStorage.getItem('refreshToken') || null,
    isAuthenticated: !!localStorage.getItem('accessToken'),
    loading:         false,
    error:           null,
  },
  reducers: {
    clear{{Name}}Error: (state) => { state.error = null; },
  },
  extraReducers: (builder) => {
    builder
      // Login
      .addCase(login{{Name}}.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(login{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.user            = action.payload.user;
        state.accessToken     = action.payload.accessToken;
        state.refreshToken    = action.payload.refreshToken;
        state.isAuthenticated = true;
      })
      .addCase(login{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      // Token refresh (silent)
      .addCase(refreshAccessToken.fulfilled, (state, action) => {
        state.accessToken  = action.payload.accessToken;
        state.refreshToken = action.payload.refreshToken;
      })
      .addCase(refreshAccessToken.rejected, (state, action) => {
        state.error = action.payload;
      })

      // Logout
      .addCase(logout{{Name}}.fulfilled, (state) => {
        state.user            = null;
        state.accessToken     = null;
        state.refreshToken    = null;
        state.isAuthenticated = false;
      });
  },
});

export const { clear{{Name}}Error } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// ─── Quick-start ─────────────────────────────────────────────────────────────
//
// 1. Register the slice in your store (auto-done by CLI).
//
// 2. Wire up interceptors in main.jsx AFTER store creation:
//      import { setupApiInterceptors } from '@james/reduxapi-helper-cli/slices/{{lowerName}}Slice';
//      setupApiInterceptors(store);
//
// 3. In every other slice, import `apiClient` instead of `axios`:
//      import { apiClient } from '@james/reduxapi-helper-cli/slices/{{lowerName}}Slice';
//      const response = await apiClient.get('/rooms');
//      // → token is added automatically; expired token is silently refreshed
//
// 4. In components:
//      const { user, isAuthenticated, loading, error } = useSelector(s => s.{{lowerName}});
//      dispatch(login{{Name}}({ email, password }));
//      dispatch(logout{{Name}}());
