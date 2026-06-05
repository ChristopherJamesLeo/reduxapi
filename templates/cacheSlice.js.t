import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';
const DEFAULT_TTL_MS = 5 * 60 * 1000; // 5 minutes

// ─── Thunks ─────────────────────────────────────────────────────────────────

export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchWithCache',
  async ({ ttl = DEFAULT_TTL_MS, force = false } = {}, { getState, rejectWithValue }) => {
    const slice = getState().{{lowerName}};
    const age = slice.lastFetched ? Date.now() - slice.lastFetched : Infinity;
    const isFresh = age < ttl && slice.data.length > 0;

    // Return cached data immediately (no API call)
    if (!force && isFresh) {
      return { data: slice.data, fromCache: true };
    }

    try {
      const response = await axios.get(API_URL);
      return { data: response.data.data ?? response.data, fromCache: false };
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Silent background revalidation — show stale data, update quietly
export const revalidate{{Name}}s = createAsyncThunk(
  '{{lowerName}}/revalidate',
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL);
      return response.data.data ?? response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: [],
    lastFetched: null,   // Unix timestamp of last successful fetch
    loading: false,      // true only on first load (no cached data yet)
    revalidating: false, // true during silent background refresh
    error: null,
  },
  reducers: {
    invalidate{{Name}}Cache: (state) => {
      state.lastFetched = null; // forces next fetch to hit the API
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetch{{Name}}s.pending, (state, action) => {
        const force = action.meta.arg?.force;
        if (!force && state.data.length > 0) {
          state.revalidating = true; // stale-while-revalidate: keep showing old data
        } else {
          state.loading = true;
        }
        state.error = null;
      })
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.revalidating = false;
        if (!action.payload.fromCache) {
          state.data = action.payload.data;
          state.lastFetched = Date.now();
        }
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.revalidating = false;
        state.error = action.payload;
      })

      .addCase(revalidate{{Name}}s.pending, (state) => {
        state.revalidating = true;
        state.error = null;
      })
      .addCase(revalidate{{Name}}s.fulfilled, (state, action) => {
        state.revalidating = false;
        state.data = action.payload;
        state.lastFetched = Date.now();
      })
      .addCase(revalidate{{Name}}s.rejected, (state, action) => {
        state.revalidating = false;
        state.error = action.payload; // silently failed — old data still shown
      });
  },
});

export const { invalidate{{Name}}Cache } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage:
// First load / respect TTL    → dispatch(fetch{{Name}}s())
// Custom TTL (10 min)         → dispatch(fetch{{Name}}s({ ttl: 10 * 60 * 1000 }))
// Force bypass cache          → dispatch(fetch{{Name}}s({ force: true }))
// Silent background refresh   → dispatch(revalidate{{Name}}s())
// Invalidate (expire cache)   → dispatch(invalidate{{Name}}Cache())
//
// state.loading      → spinner on first load
// state.revalidating → subtle indicator; old data still visible
// state.lastFetched  → Date.now() timestamp, use to show "Last updated X ago"
