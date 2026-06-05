import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

// ─── Deduplication Registry ──────────────────────────────────────────────────
// Maps request keys → in-flight Promise
// While a request is in-flight, any duplicate call waits on the same Promise
// and receives the same response — the API is only called once.

const _inFlight = {};

const deduped = (key, requestFn) => {
  if (_inFlight[key]) return _inFlight[key]; // reuse existing promise
  _inFlight[key] = requestFn().finally(() => {
    delete _inFlight[key]; // clean up after resolve/reject
  });
  return _inFlight[key];
};

// ─── Thunks ─────────────────────────────────────────────────────────────────

// Multiple components dispatching this simultaneously share one API call
export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { rejectWithValue }) => {
    try {
      const data = await deduped('{{lowerName}}_fetchAll',
        () => axios.get(API_URL).then(r => r.data)
      );
      return data.data ?? data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Per-ID deduplication — same ID requested by N components = 1 API call
export const fetch{{Name}}ById = createAsyncThunk(
  '{{lowerName}}/fetchById',
  async (id, { rejectWithValue }) => {
    try {
      const data = await deduped(`{{lowerName}}_byId_${id}`,
        () => axios.get(`${API_URL}/${id}`).then(r => r.data)
      );
      return { id, item: data.data ?? data };
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Parameterized fetch — deduped by serialized params
export const fetch{{Name}}ByParams = createAsyncThunk(
  '{{lowerName}}/fetchByParams',
  async (params = {}, { rejectWithValue }) => {
    const key = `{{lowerName}}_params_${JSON.stringify(params)}`;
    try {
      const data = await deduped(key,
        () => axios.get(API_URL, { params }).then(r => r.data)
      );
      return data.data ?? data;
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
    items: {},     // { [id]: item } — indexed single-item results
    loading: false,
    error: null,
  },
  reducers: {
    clear{{Name}}Items: (state) => {
      state.items = {};
      state.list = [];
    },
  },
  extraReducers: (builder) => {
    builder
      // fetchAll — all concurrent callers share this one loading state
      .addCase(fetch{{Name}}s.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.list = action.payload;
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      // fetchById — stores in items map
      .addCase(fetch{{Name}}ById.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(fetch{{Name}}ById.fulfilled, (state, action) => {
        state.loading = false;
        state.items[action.payload.id] = action.payload.item;
      })
      .addCase(fetch{{Name}}ById.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      // fetchByParams
      .addCase(fetch{{Name}}ByParams.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(fetch{{Name}}ByParams.fulfilled, (state, action) => {
        state.loading = false;
        state.list = action.payload;
      })
      .addCase(fetch{{Name}}ByParams.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});

export const { clear{{Name}}Items } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// How deduplication works:
//
//   Sidebar   → dispatch(fetch{{Name}}s())  ─┐
//   Header    → dispatch(fetch{{Name}}s())  ─┤─→ ONE axios.get('/{{lowerName}}')
//   Dashboard → dispatch(fetch{{Name}}s())  ─┘    all 3 get the same response
//
// Per-ID dedup:
//   Card A → dispatch(fetch{{Name}}ById(1)) ─┐
//   Card B → dispatch(fetch{{Name}}ById(1)) ─┴─→ ONE axios.get('/{{lowerName}}/1')
//
// Param-based dedup:
//   dispatch(fetch{{Name}}ByParams({ page: 1 }));  // fires API
//   dispatch(fetch{{Name}}ByParams({ page: 1 }));  // waits on same Promise
//
// The dedup window lasts until the API responds.
// After that, the next dispatch always makes a fresh call.
