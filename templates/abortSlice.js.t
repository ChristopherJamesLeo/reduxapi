import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

// ─── How Abort Works ─────────────────────────────────────────────────────────
// RTK's createAsyncThunk provides `signal` in the third callback argument.
// Passing `{ signal }` to axios cancels the HTTP request when:
//   - The dispatched promise's .abort() method is called
//   - The component unmounts (when using the cleanup pattern below)
//
// This prevents:
//   - Memory leaks from state updates on unmounted components
//   - Race conditions when navigating between pages quickly
//   - Stale responses from a previous route landing after a new one

// ─── Thunks ─────────────────────────────────────────────────────────────────

export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { signal, rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL, { signal });
      return response.data.data ?? response.data;
    } catch (error) {
      if (axios.isCancel(error) || error.name === 'CanceledError' || error.name === 'AbortError') {
        return rejectWithValue({ aborted: true, message: 'Request cancelled' });
      }
      return rejectWithValue({ aborted: false, message: error.response?.data?.message || error.message });
    }
  }
);

export const fetch{{Name}}ById = createAsyncThunk(
  '{{lowerName}}/fetchById',
  async (id, { signal, rejectWithValue }) => {
    try {
      const response = await axios.get(`${API_URL}/${id}`, { signal });
      return response.data.data ?? response.data;
    } catch (error) {
      if (axios.isCancel(error) || error.name === 'CanceledError' || error.name === 'AbortError') {
        return rejectWithValue({ aborted: true, message: 'Request cancelled' });
      }
      return rejectWithValue({ aborted: false, message: error.response?.data?.message || error.message });
    }
  }
);

export const create{{Name}} = createAsyncThunk(
  '{{lowerName}}/create',
  async (newData, { signal, rejectWithValue }) => {
    try {
      const response = await axios.post(API_URL, newData, { signal });
      return response.data.data ?? response.data;
    } catch (error) {
      if (axios.isCancel(error) || error.name === 'CanceledError' || error.name === 'AbortError') {
        return rejectWithValue({ aborted: true, message: 'Request cancelled' });
      }
      return rejectWithValue({ aborted: false, message: error.response?.data?.message || error.message });
    }
  }
);

export const update{{Name}} = createAsyncThunk(
  '{{lowerName}}/update',
  async ({ id, updateData }, { signal, rejectWithValue }) => {
    try {
      const response = await axios.put(`${API_URL}/${id}`, updateData, { signal });
      return response.data.data ?? response.data;
    } catch (error) {
      if (axios.isCancel(error) || error.name === 'CanceledError' || error.name === 'AbortError') {
        return rejectWithValue({ aborted: true, message: 'Request cancelled' });
      }
      return rejectWithValue({ aborted: false, message: error.response?.data?.message || error.message });
    }
  }
);

export const delete{{Name}} = createAsyncThunk(
  '{{lowerName}}/delete',
  async (id, { signal, rejectWithValue }) => {
    try {
      await axios.delete(`${API_URL}/${id}`, { signal });
      return id;
    } catch (error) {
      if (axios.isCancel(error) || error.name === 'CanceledError' || error.name === 'AbortError') {
        return rejectWithValue({ aborted: true, message: 'Request cancelled' });
      }
      return rejectWithValue({ aborted: false, message: error.response?.data?.message || error.message });
    }
  }
);

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: [],
    current: null,
    loading: false,
    aborted: false,  // true when a request was intentionally cancelled
    error: null,
    success: false,
  },
  reducers: {
    reset{{Name}}Status: (state) => {
      state.success = false;
      state.error = null;
      state.aborted = false;
    },
  },
  extraReducers: (builder) => {
    const onPending  = (state) => { state.loading = true; state.error = null; state.aborted = false; };
    const onRejected = (state, action) => {
      state.loading = false;
      if (action.payload?.aborted) {
        state.aborted = true; // aborted — don't show error UI
      } else {
        state.error = action.payload?.message ?? action.payload;
      }
    };

    builder
      .addCase(fetch{{Name}}s.pending, onPending)
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetch{{Name}}s.rejected, onRejected)

      .addCase(fetch{{Name}}ById.pending, onPending)
      .addCase(fetch{{Name}}ById.fulfilled, (state, action) => {
        state.loading = false;
        state.current = action.payload;
      })
      .addCase(fetch{{Name}}ById.rejected, onRejected)

      .addCase(create{{Name}}.pending, onPending)
      .addCase(create{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.data.unshift(action.payload);
        state.success = true;
      })
      .addCase(create{{Name}}.rejected, onRejected)

      .addCase(update{{Name}}.pending, onPending)
      .addCase(update{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        const index = state.data.findIndex(i => i.id === action.payload.id);
        if (index !== -1) state.data[index] = action.payload;
        state.success = true;
      })
      .addCase(update{{Name}}.rejected, onRejected)

      .addCase(delete{{Name}}.pending, onPending)
      .addCase(delete{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.data = state.data.filter(i => i.id !== action.payload);
        state.success = true;
      })
      .addCase(delete{{Name}}.rejected, onRejected);
  },
});

export const { reset{{Name}}Status } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage in React components:
//
// Pattern 1 — auto-cancel on unmount (most common):
//   useEffect(() => {
//     const promise = dispatch(fetch{{Name}}s());
//     return () => promise.abort();  // ← fires when component unmounts
//   }, [dispatch]);
//
// Pattern 2 — cancel on route change:
//   const promiseRef = useRef(null);
//   const load = () => { promiseRef.current = dispatch(fetch{{Name}}s()); };
//   const cancel = () => promiseRef.current?.abort();
//
// Pattern 3 — cancel previous before new fetch (search-as-you-type):
//   const lastReq = useRef(null);
//   const handleSearch = (q) => {
//     lastReq.current?.abort();
//     lastReq.current = dispatch(fetch{{Name}}s({ q }));
//   };
//
// State hints:
//   state.loading  → show spinner
//   state.aborted  → do NOT show error (silent cancel — don't alarm the user)
//   state.error    → show error only when aborted is false
