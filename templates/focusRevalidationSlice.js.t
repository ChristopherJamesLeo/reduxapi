import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL   = '{{apiUrl}}/{{lowerName}}';
const CACHE_KEY = '{{lowerName}}_cache';
const STALE_MS  = 30_000; // refetch if data is older than this when tab regains focus

// ─── Cache Helpers ───────────────────────────────────────────────────────────
const saveCache = (data) => {
  try {
    sessionStorage.setItem(CACHE_KEY, JSON.stringify({ data, cachedAt: Date.now() }));
  } catch {}
};
const loadCache = () => {
  try {
    const raw = sessionStorage.getItem(CACHE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch { return null; }
};

// ─── Thunks ─────────────────────────────────────────────────────────────────

export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL);
      const data = response.data.data ?? response.data;
      saveCache(data);
      return data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Called by the focus/visibility listener — only fetches if data is stale
export const revalidate{{Name}}OnFocus = createAsyncThunk(
  '{{lowerName}}/revalidateOnFocus',
  async (_, { getState, dispatch, rejectWithValue }) => {
    const { lastFetchedAt, loading } = getState().{{lowerName}};
    if (loading) return; // already in flight
    const isStale = !lastFetchedAt || Date.now() - lastFetchedAt > STALE_MS;
    if (!isStale) return; // fresh enough — skip

    try {
      const response = await axios.get(API_URL);
      const data = response.data.data ?? response.data;
      saveCache(data);
      return data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Register focus/visibility listeners — call once in your app entry point
export const start{{Name}}FocusRevalidation = () => (dispatch) => {
  const onFocus = () => dispatch(revalidate{{Name}}OnFocus());

  // Browser tab becomes active again
  window.addEventListener('focus', onFocus);

  // Page visibility (phone screen unlock, alt-tab back)
  const onVisibilityChange = () => {
    if (document.visibilityState === 'visible') dispatch(revalidate{{Name}}OnFocus());
  };
  document.addEventListener('visibilitychange', onVisibilityChange);

  // Teardown — return this function and call it on app unmount
  return () => {
    window.removeEventListener('focus', onFocus);
    document.removeEventListener('visibilitychange', onVisibilityChange);
  };
};

// ─── Slice ───────────────────────────────────────────────────────────────────

const cached = loadCache();

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: cached?.data ?? [],
    loading: false,
    revalidating: false,  // silent background refetch (don't show loading spinner)
    error: null,
    lastFetchedAt: cached?.cachedAt ?? null, // epoch ms
  },
  reducers: {
    reset{{Name}}Status: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      // Initial / manual fetch
      .addCase(fetch{{Name}}s.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
        state.lastFetchedAt = Date.now();
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      // Focus revalidation — silent background refetch
      .addCase(revalidate{{Name}}OnFocus.pending, (state) => {
        state.revalidating = true;
      })
      .addCase(revalidate{{Name}}OnFocus.fulfilled, (state, action) => {
        state.revalidating = false;
        if (action.payload !== undefined) {
          state.data = action.payload;
          state.lastFetchedAt = Date.now();
          state.error = null;
        }
      })
      .addCase(revalidate{{Name}}OnFocus.rejected, (state, action) => {
        state.revalidating = false;
        // Don't overwrite main error — this is a background refresh failure
      });
  },
});

export const { reset{{Name}}Status } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Quick-start:
//
// 1. In main.jsx — register focus listeners once after store creation:
//      import { start{{Name}}FocusRevalidation } from '…/{{lowerName}}Slice';
//      store.dispatch(start{{Name}}FocusRevalidation());
//
// 2. In your component — fetch normally on mount:
//      const dispatch = useDispatch();
//      const { data, loading, revalidating, lastFetchedAt } = useSelector(s => s.{{lowerName}});
//      useEffect(() => { dispatch(fetch{{Name}}s()); }, []);
//
// 3. State hints:
//      loading        → show full-page spinner (first load)
//      revalidating   → show subtle refresh indicator (e.g. small spinner in corner)
//      lastFetchedAt  → display "Last updated X ago"
//      data           → always show — even stale data is better than a blank screen
//
// Config (top of file):
//   STALE_MS = 30_000   ms before data is considered stale and refetched on focus
//   CACHE_KEY           sessionStorage key for cross-tab cache seeding
