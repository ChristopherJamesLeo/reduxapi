import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

// ─── Thunks ─────────────────────────────────────────────────────────────────

// Normal list fetch
export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL);
      return response.data.data ?? response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Fetch single item — checks prefetch cache first (instant if already prefetched)
export const fetch{{Name}}ById = createAsyncThunk(
  '{{lowerName}}/fetchById',
  async (id, { getState, rejectWithValue }) => {
    const cached = getState().{{lowerName}}.prefetchCache[id];
    if (cached) return { id, data: cached, fromPrefetch: true };

    try {
      const response = await axios.get(`${API_URL}/${id}`);
      return { id, data: response.data.data ?? response.data, fromPrefetch: false };
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Silent background prefetch — call on hover / scroll-near / link intent
// Fails silently so it never breaks the UI
export const prefetch{{Name}} = createAsyncThunk(
  '{{lowerName}}/prefetch',
  async (id, { getState }) => {
    if (getState().{{lowerName}}.prefetchCache[id]) return null; // already cached
    try {
      const response = await axios.get(`${API_URL}/${id}`);
      return { id, data: response.data.data ?? response.data };
    } catch {
      return null; // prefetch is best-effort — silently ignore failures
    }
  }
);

// Prefetch a list of IDs (e.g. all visible rows in a table)
export const prefetch{{Name}}List = createAsyncThunk(
  '{{lowerName}}/prefetchList',
  async (ids, { getState, dispatch }) => {
    const cache = getState().{{lowerName}}.prefetchCache;
    const missing = ids.filter(id => !cache[id]);
    await Promise.allSettled(missing.map(id => dispatch(prefetch{{Name}}(id))));
    return null;
  }
);

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    list: [],
    current: null,        // currently viewed item
    prefetchCache: {},    // { [id]: item } — warmed by hover/scroll
    loading: false,
    loadingById: false,   // true only when item NOT in prefetch cache
    error: null,
  },
  reducers: {
    clear{{Name}}PrefetchCache: (state) => {
      state.prefetchCache = {};
    },
    evict{{Name}}FromCache: (state, action) => {
      delete state.prefetchCache[action.payload];
    },
  },
  extraReducers: (builder) => {
    builder
      // List
      .addCase(fetch{{Name}}s.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.list = action.payload;
        // Warm cache from list items (if they have enough detail)
        action.payload.forEach(item => {
          if (item.id) state.prefetchCache[item.id] = item;
        });
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      // Fetch by ID (instant if prefetched, loader if not)
      .addCase(fetch{{Name}}ById.pending, (state, action) => {
        const cached = state.prefetchCache[action.meta.arg];
        if (!cached) state.loadingById = true; // only show loader on cache miss
        state.error = null;
      })
      .addCase(fetch{{Name}}ById.fulfilled, (state, action) => {
        state.loadingById = false;
        state.current = action.payload.data;
        state.prefetchCache[action.payload.id] = action.payload.data;
      })
      .addCase(fetch{{Name}}ById.rejected, (state, action) => {
        state.loadingById = false;
        state.error = action.payload;
      })

      // Prefetch — silent, only warms the cache
      .addCase(prefetch{{Name}}.fulfilled, (state, action) => {
        if (action.payload) {
          state.prefetchCache[action.payload.id] = action.payload.data;
        }
      });
      // prefetch rejected is intentionally not handled — silent failure
  },
});

export const { clear{{Name}}PrefetchCache, evict{{Name}}FromCache } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage:
//
// Warm cache on list hover (React):
//   <tr onMouseEnter={() => dispatch(prefetch{{Name}}(room.id))}>
//
// Warm cache when row scrolls into view (Intersection Observer):
//   const observer = new IntersectionObserver(([entry]) => {
//     if (entry.isIntersecting) dispatch(prefetch{{Name}}(id));
//   });
//
// Warm all visible rows at once:
//   dispatch(prefetch{{Name}}List(visibleIds));
//
// Navigate to detail (0ms load if prefetched):
//   dispatch(fetch{{Name}}ById(id));   // instant if cache hit
//
// state.loadingById → show spinner ONLY on cache miss
// state.prefetchCache → check if an id is warmed: !!state.prefetchCache[id]
