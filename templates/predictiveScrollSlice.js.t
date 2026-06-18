import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

const MAX_CACHE_SIZE = 50;       // LRU cap — oldest entry evicted past this size
const CACHE_TTL = 5 * 60 * 1000; // 5 min — entries older than this are refetched
const BATCH_WINDOW = 50;         // ms — ids queued within this window share 1 request

// ─── Network-aware guard ──────────────────────────────────────────────────
// Skips prefetching on data-saver mode or slow connections (2g/slow-2g).
// Protects mobile users from wasted bandwidth.

const canPrefetch = () => {
  const conn = typeof navigator !== 'undefined' && navigator.connection;
  if (!conn) return true;
  if (conn.saveData) return false;
  return !['slow-2g', '2g'].includes(conn.effectiveType);
};

// ─── In-flight registry (race-condition guard) ────────────────────────────
// Aborts a stale request for the same id-set before starting a new one, and
// lets concurrent callers for the same id-set share one Promise (dedupe).

const _controllers = {};   // { [key]: AbortController }
const _inFlight = {};      // { [key]: Promise }

// ─── Batch queue (backend-load guard) ──────────────────────────────────────
// Collects ids requested within BATCH_WINDOW ms and fires ONE
// `?ids=1,2,3` request instead of N separate requests.

let _queue = new Set();
let _timer = null;

function flushQueue(dispatch) {
  const ids = Array.from(_queue);
  _queue = new Set();
  _timer = null;
  if (ids.length) dispatch(prefetchBatch{{Name}}(ids));
}

// ─── Thunks ─────────────────────────────────────────────────────────────────

// Infinite scroll list fetch — same contract as the `infinite` template
export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchInfinite',
  async ({ cursor = null, limit = 20 } = {}, { rejectWithValue }) => {
    try {
      const params = { limit };
      if (cursor) params.cursor = cursor;
      const response = await axios.get(API_URL, { params });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Call on hover / near-viewport (IntersectionObserver). Queues the id and
// fires ONE batched request per BATCH_WINDOW ms — never one request per id.
export const queuePrefetch{{Name}} = (id) => (dispatch, getState) => {
  if (!canPrefetch()) return;                          // respect data-saver / slow network
  const state = getState().{{lowerName}};
  const cached = state.detailCache[id];
  const fresh = cached && Date.now() - state.fetchedAt[id] < CACHE_TTL;
  if (fresh || state.loadingIds.includes(id)) return;   // already warm or already queued

  _queue.add(id);
  if (!_timer) {
    _timer = setTimeout(() => flushQueue(dispatch), BATCH_WINDOW);
  }
};

// Internal — fires the actual batched GET `?ids=1,2,3`. Aborts any stale
// request sharing the exact same id set, and dedupes identical concurrent calls.
export const prefetchBatch{{Name}} = createAsyncThunk(
  '{{lowerName}}/prefetchBatch',
  async (ids, { rejectWithValue }) => {
    const key = ids.slice().sort().join(',');

    _controllers[key]?.abort();
    const controller = new AbortController();
    _controllers[key] = controller;

    if (_inFlight[key]) return _inFlight[key];

    _inFlight[key] = axios
      .get(API_URL, { params: { ids: ids.join(',') }, signal: controller.signal })
      .then((res) => res.data.data ?? res.data)
      .finally(() => {
        delete _inFlight[key];
        delete _controllers[key];
      });

    try {
      return await _inFlight[key];
    } catch (error) {
      if (axios.isCancel(error)) return rejectWithValue('aborted');
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Navigate to detail page — instant (0 ms) if the LRU cache has a fresh entry
export const fetch{{Name}}ById = createAsyncThunk(
  '{{lowerName}}/fetchById',
  async (id, { getState, rejectWithValue }) => {
    const state = getState().{{lowerName}};
    const cached = state.detailCache[id];
    const fresh = cached && Date.now() - state.fetchedAt[id] < CACHE_TTL;
    if (fresh) return { id, data: cached };

    try {
      const response = await axios.get(`${API_URL}/${id}`);
      return { id, data: response.data.data ?? response.data };
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: [],            // accumulated infinite-scroll items
    nextCursor: null,
    hasMore: true,
    loading: false,
    loadingMore: false,

    detailCache: {},      // { [id]: item } — LRU + TTL capped
    cacheOrder: [],        // LRU order, oldest first
    fetchedAt: {},         // { [id]: epoch ms } — for TTL staleness check
    loadingIds: [],        // ids currently being prefetched — UI can ignore these

    error: null,
  },
  reducers: {
    reset{{Name}}s: (state) => {
      state.data = [];
      state.nextCursor = null;
      state.hasMore = true;
      state.error = null;
    },
    evict{{Name}}FromCache: (state, action) => {
      const id = action.payload;
      delete state.detailCache[id];
      delete state.fetchedAt[id];
      state.cacheOrder = state.cacheOrder.filter((x) => x !== id);
    },
    clear{{Name}}Cache: (state) => {
      state.detailCache = {};
      state.fetchedAt = {};
      state.cacheOrder = [];
    },
  },
  extraReducers: (builder) => {
    builder
      // ── Infinite list fetch ──────────────────────────────────────────────
      .addCase(fetch{{Name}}s.pending, (state, action) => {
        if (action.meta.arg?.cursor) state.loadingMore = true;
        else { state.loading = true; state.data = []; }
        state.error = null;
      })
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.loadingMore = false;
        const items = action.payload.data ?? action.payload;
        state.data = [...state.data, ...items];
        state.nextCursor = action.payload.next_cursor ?? null;
        state.hasMore = !!action.payload.next_cursor;

        // Warm the cache from list rows that already carry full detail
        const now = Date.now();
        items.forEach((item) => {
          if (!item?.id) return;
          state.detailCache[item.id] = item;
          state.fetchedAt[item.id] = now;
          state.cacheOrder = state.cacheOrder.filter((x) => x !== item.id);
          state.cacheOrder.push(item.id);
        });
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.loadingMore = false;
        state.error = action.payload;
      })

      // ── Batched prefetch result ──────────────────────────────────────────
      .addCase(prefetchBatch{{Name}}.pending, (state, action) => {
        state.loadingIds = [...new Set([...state.loadingIds, ...action.meta.arg])];
      })
      .addCase(prefetchBatch{{Name}}.fulfilled, (state, action) => {
        const now = Date.now();
        action.payload.forEach((item) => {
          if (!item?.id) return;
          state.detailCache[item.id] = item;
          state.fetchedAt[item.id] = now;
          state.cacheOrder = state.cacheOrder.filter((x) => x !== item.id);
          state.cacheOrder.push(item.id);

          // LRU eviction — drop oldest entries past MAX_CACHE_SIZE
          while (state.cacheOrder.length > MAX_CACHE_SIZE) {
            const oldest = state.cacheOrder.shift();
            delete state.detailCache[oldest];
            delete state.fetchedAt[oldest];
          }
        });
        state.loadingIds = state.loadingIds.filter((id) => !action.meta.arg.includes(id));
      })
      .addCase(prefetchBatch{{Name}}.rejected, (state, action) => {
        // Prefetch is best-effort — silently drop failures, just clear the loading flag
        state.loadingIds = state.loadingIds.filter((id) => !action.meta.arg.includes(id));
      })

      // ── Direct fetch-by-id (navigated detail page) ───────────────────────
      .addCase(fetch{{Name}}ById.pending, (state, action) => {
        const cached = state.detailCache[action.meta.arg];
        const fresh = cached && Date.now() - state.fetchedAt[action.meta.arg] < CACHE_TTL;
        if (!fresh) state.loadingIds = [...new Set([...state.loadingIds, action.meta.arg])];
        state.error = null;
      })
      .addCase(fetch{{Name}}ById.fulfilled, (state, action) => {
        const { id, data } = action.payload;
        state.detailCache[id] = data;
        state.fetchedAt[id] = Date.now();
        state.cacheOrder = state.cacheOrder.filter((x) => x !== id);
        state.cacheOrder.push(id);
        state.loadingIds = state.loadingIds.filter((x) => x !== id);
      })
      .addCase(fetch{{Name}}ById.rejected, (state, action) => {
        state.loadingIds = state.loadingIds.filter((x) => x !== action.meta.arg);
        state.error = action.payload;
      });
  },
});

export const { reset{{Name}}s, evict{{Name}}FromCache, clear{{Name}}Cache } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage:
//
// Initial load   → dispatch(fetch{{Name}}s())
// Load more      → dispatch(fetch{{Name}}s({ cursor: state.{{lowerName}}.nextCursor }))
// Warm on scroll → dispatch(queuePrefetch{{Name}}(id))   // IntersectionObserver callback
// Open detail    → dispatch(fetch{{Name}}ById(id))       // instant if cache fresh
// Reset & reload → dispatch(reset{{Name}}s())
//
// state.hasMore           → false when all pages fetched
// state.loadingIds        → ids currently warming — never show a spinner for these
// state.detailCache[id]   → read directly for instant render, skip dispatch entirely
