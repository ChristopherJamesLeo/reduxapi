import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';
const BATCH_WINDOW_MS = 50; // collect IDs for 50ms then fire one request

// ─── Batch Collector ─────────────────────────────────────────────────────────
// All dispatch(request{{Name}}(id)) calls within 50ms are merged into one
// API call: GET /{{lowerName}}?ids=1,2,3
// Each caller gets the matching item from the single response.

let _batchTimer   = null;
let _pendingIds   = [];
let _pendingResolver = null;

const flushBatch = (dispatch) => {
  const ids = [..._pendingIds];
  _pendingIds = [];
  _batchTimer = null;
  dispatch(fetch{{Name}}Batch(ids));
};

// Single-item request — automatically batched with concurrent calls
export const request{{Name}} = (id) => (dispatch, getState) => {
  // Return from cache immediately if already loaded
  const cached = getState().{{lowerName}}.itemCache[id];
  if (cached) return Promise.resolve(cached);

  if (!_pendingIds.includes(id)) _pendingIds.push(id);
  if (_batchTimer) clearTimeout(_batchTimer);
  _batchTimer = setTimeout(() => flushBatch(dispatch), BATCH_WINDOW_MS);
};

// Fired once per batch window with all collected IDs
export const fetch{{Name}}Batch = createAsyncThunk(
  '{{lowerName}}/fetchBatch',
  async (ids, { rejectWithValue }) => {
    try {
      // Sends: GET /{{lowerName}}?ids=1,2,3
      const response = await axios.get(API_URL, { params: { ids: ids.join(',') } });
      return response.data.data ?? response.data; // expect array
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Fetch all (non-batched, standard list fetch)
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

// Manually batch-fetch a known set of IDs (bypasses the timer)
export const fetch{{Name}}ByIds = createAsyncThunk(
  '{{lowerName}}/fetchByIds',
  async (ids, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL, { params: { ids: ids.join(',') } });
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
    list: [],
    itemCache: {},   // { [id]: item } — populated by every batch/list fetch
    loading: false,
    batchLoading: false,
    error: null,
  },
  reducers: {
    clear{{Name}}Cache: (state) => { state.itemCache = {}; },
  },
  extraReducers: (builder) => {
    const cacheItems = (state, items) => {
      if (Array.isArray(items)) {
        items.forEach(item => { if (item.id) state.itemCache[item.id] = item; });
      }
    };

    builder
      // List
      .addCase(fetch{{Name}}s.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.list = action.payload;
        cacheItems(state, action.payload);
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      // Auto-batched (timer-based)
      .addCase(fetch{{Name}}Batch.pending, (state) => { state.batchLoading = true; state.error = null; })
      .addCase(fetch{{Name}}Batch.fulfilled, (state, action) => {
        state.batchLoading = false;
        cacheItems(state, action.payload);
      })
      .addCase(fetch{{Name}}Batch.rejected, (state, action) => {
        state.batchLoading = false;
        state.error = action.payload;
      })

      // Manual batch by IDs
      .addCase(fetch{{Name}}ByIds.pending, (state) => { state.batchLoading = true; state.error = null; })
      .addCase(fetch{{Name}}ByIds.fulfilled, (state, action) => {
        state.batchLoading = false;
        cacheItems(state, action.payload);
      })
      .addCase(fetch{{Name}}ByIds.rejected, (state, action) => {
        state.batchLoading = false;
        state.error = action.payload;
      });
  },
});

export const { clear{{Name}}Cache } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage:
//
// Auto-batched (3 components call within 50ms → 1 API request):
//   // Component A
//   dispatch(request{{Name}}(1));
//   // Component B (same render cycle)
//   dispatch(request{{Name}}(2));
//   // Component C (same render cycle)
//   dispatch(request{{Name}}(3));
//   // → Single request: GET /{{lowerName}}?ids=1,2,3
//
// Manual batch by known IDs:
//   dispatch(fetch{{Name}}ByIds([1, 2, 3]));
//
// Read from cache (after any batch has run):
//   const item = useSelector(s => s.{{lowerName}}.itemCache[id]);
//
// Backend must accept:  GET /{{lowerName}}?ids=1,2,3  → returns array
// BATCH_WINDOW_MS (default 50ms) — increase for slower render cycles
