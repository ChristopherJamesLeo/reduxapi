import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL   = '{{apiUrl}}/{{lowerName}}';
const CACHE_KEY = '{{lowerName}}_degraded_cache';

// ─── Cache Helpers ───────────────────────────────────────────────────────────
const persistCache = (data) => {
  try {
    localStorage.setItem(CACHE_KEY, JSON.stringify({
      data,
      savedAt: new Date().toISOString(),
    }));
  } catch {}
};

const readCache = () => {
  try {
    const raw = localStorage.getItem(CACHE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch { return null; }
};

// ─── Thunks ─────────────────────────────────────────────────────────────────

export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL, { timeout: 10_000 });
      const data = response.data.data ?? response.data;
      persistCache(data);     // always save a fresh copy when online
      return { data, fromCache: false };
    } catch (error) {
      // Server down or no internet — fall back to last known good cache
      const cached = readCache();
      if (cached) {
        return { data: cached.data, fromCache: true, cachedAt: cached.savedAt };
      }
      // No cache either — propagate error
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const create{{Name}} = createAsyncThunk(
  '{{lowerName}}/create',
  async (newData, { getState, rejectWithValue }) => {
    const { degraded } = getState().{{lowerName}};
    if (degraded) {
      return rejectWithValue('Offline mode: ဖန်တီးမှုများကို ယာယီ မပြုလုပ်နိုင်ပါ');
    }
    try {
      const response = await axios.post(API_URL, newData);
      return response.data.data ?? response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const update{{Name}} = createAsyncThunk(
  '{{lowerName}}/update',
  async ({ id, updateData }, { getState, rejectWithValue }) => {
    const { degraded } = getState().{{lowerName}};
    if (degraded) {
      return rejectWithValue('Offline mode: ပြင်ဆင်မှုများကို ယာယီ မပြုလုပ်နိုင်ပါ');
    }
    try {
      const response = await axios.put(`${API_URL}/${id}`, updateData);
      return response.data.data ?? response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const delete{{Name}} = createAsyncThunk(
  '{{lowerName}}/delete',
  async (id, { getState, rejectWithValue }) => {
    const { degraded } = getState().{{lowerName}};
    if (degraded) {
      return rejectWithValue('Offline mode: ဖျက်သိမ်းမှုများကို ယာယီ မပြုလုပ်နိုင်ပါ');
    }
    try {
      await axios.delete(`${API_URL}/${id}`);
      return id;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Register online/offline listeners — call once in app entry point
export const start{{Name}}DegradationListener = () => (dispatch) => {
  const onOnline  = () => {
    dispatch(set{{Name}}Degraded(false));
    dispatch(fetch{{Name}}s()); // re-fetch fresh data when network returns
  };
  const onOffline = () => dispatch(set{{Name}}Degraded(true));

  window.addEventListener('online',  onOnline);
  window.addEventListener('offline', onOffline);

  return () => {
    window.removeEventListener('online',  onOnline);
    window.removeEventListener('offline', onOffline);
  };
};

// ─── Slice ───────────────────────────────────────────────────────────────────

const cachedEntry = readCache();

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: cachedEntry?.data ?? [],
    loading: false,
    error: null,
    success: false,

    // Degradation state
    degraded: !navigator.onLine,    // true = serving from cache / offline
    fromCache: !!cachedEntry,       // true = current data is from cache
    cachedAt: cachedEntry?.savedAt ?? null,  // ISO timestamp of cache
    cacheAvailable: !!cachedEntry,  // false = no cache, full blank screen
  },
  reducers: {
    set{{Name}}Degraded: (state, action) => {
      state.degraded = action.payload;
      if (action.payload) state.fromCache = true;
    },
    reset{{Name}}Status: (state) => {
      state.success = false;
      state.error   = null;
    },
    clear{{Name}}Cache: () => {
      try { localStorage.removeItem(CACHE_KEY); } catch {}
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetch{{Name}}s.pending, (state) => {
        state.loading = true;
        state.error   = null;
      })
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.data    = action.payload.data;
        state.fromCache = action.payload.fromCache;
        state.cachedAt  = action.payload.cachedAt ?? new Date().toISOString();
        state.cacheAvailable = true;
        if (action.payload.fromCache) {
          state.degraded = true;  // fell back to cache = we're degraded
        } else {
          state.degraded = false;
          state.success  = true;
        }
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading  = false;
        state.degraded = true;
        state.error    = action.payload; // only set when cache also unavailable
      })

      .addCase(create{{Name}}.fulfilled, (state, action) => {
        state.data.unshift(action.payload);
        state.success = true;
      })
      .addCase(create{{Name}}.rejected, (state, action) => { state.error = action.payload; })

      .addCase(update{{Name}}.fulfilled, (state, action) => {
        const idx = state.data.findIndex(i => i.id === action.payload.id);
        if (idx !== -1) state.data[idx] = action.payload;
        state.success = true;
      })
      .addCase(update{{Name}}.rejected, (state, action) => { state.error = action.payload; })

      .addCase(delete{{Name}}.fulfilled, (state, action) => {
        state.data    = state.data.filter(i => i.id !== action.payload);
        state.success = true;
      })
      .addCase(delete{{Name}}.rejected, (state, action) => { state.error = action.payload; });
  },
});

export const {
  set{{Name}}Degraded,
  reset{{Name}}Status,
  clear{{Name}}Cache,
} = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Quick-start:
//
// 1. In main.jsx — start listener once:
//      import { start{{Name}}DegradationListener } from '…/{{lowerName}}Slice';
//      store.dispatch(start{{Name}}DegradationListener());
//
// 2. In your component:
//      const { data, loading, degraded, fromCache, cachedAt, cacheAvailable, error } =
//        useSelector(s => s.{{lowerName}});
//      useEffect(() => { dispatch(fetch{{Name}}s()); }, []);
//
// 3. Show degradation banners:
//      {degraded && fromCache && (
//        <Banner>📦 Offline Mode — {cachedAt} မှ Cache Data ပြသနေသည်</Banner>
//      )}
//      {degraded && !cacheAvailable && (
//        <ErrorPage>⚠️ Server ချိတ်ဆက်မရ၊ Cache Data လည်း မရှိပါ</ErrorPage>
//      )}
//      {!degraded && fromCache === false && <span>🟢 Live data</span>}
//
// 4. Disable write actions in degraded mode:
//      <button disabled={degraded} onClick={() => dispatch(create{{Name}}(data))}>
//        {degraded ? 'Offline (Read-only)' : 'Create'}
//      </button>
//
// Config (top of file):
//   CACHE_KEY    localStorage key — change if multiple slices needed
//   timeout      axios timeout in fetch (default 10_000 ms)
