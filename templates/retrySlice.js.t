import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

// ─── Retry Config (customize here) ──────────────────────────────────────────
const RETRY_ATTEMPTS  = 3;        // max number of attempts
const RETRY_DELAY_MS  = 2000;     // base delay (multiplied per attempt: 2s, 4s, 6s)

// ─── Retry Utility ───────────────────────────────────────────────────────────
const sleep = (ms) => new Promise((res) => setTimeout(res, ms));

const withRetry = async (requestFn, attempts = RETRY_ATTEMPTS, baseDelay = RETRY_DELAY_MS) => {
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      return await requestFn();
    } catch (error) {
      const isLast = attempt === attempts;
      const status  = error.response?.status;
      // Only retry on network failures or server errors (5xx)
      // Client errors (4xx) are not retried — they won't self-heal
      const isRetryable = !status || status === 0 || status >= 500;
      if (isLast || !isRetryable) throw error;
      await sleep(baseDelay * attempt); // 2s → 4s → 6s
    }
  }
};

// ─── Thunks ─────────────────────────────────────────────────────────────────

export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { rejectWithValue }) => {
    try {
      const data = await withRetry(() => axios.get(API_URL).then(r => r.data));
      return data.data ?? data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const create{{Name}} = createAsyncThunk(
  '{{lowerName}}/create',
  async (newData, { rejectWithValue }) => {
    try {
      const data = await withRetry(() => axios.post(API_URL, newData).then(r => r.data));
      return data.data ?? data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const update{{Name}} = createAsyncThunk(
  '{{lowerName}}/update',
  async ({ id, updateData }, { rejectWithValue }) => {
    try {
      const data = await withRetry(() => axios.put(`${API_URL}/${id}`, updateData).then(r => r.data));
      return data.data ?? data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const delete{{Name}} = createAsyncThunk(
  '{{lowerName}}/delete',
  async (id, { rejectWithValue }) => {
    try {
      await withRetry(() => axios.delete(`${API_URL}/${id}`));
      return id;
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
    loading: false,
    error: null,
    success: false,
  },
  reducers: {
    reset{{Name}}Status: (state) => {
      state.success = false;
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    const onPending  = (state) => { state.loading = true;  state.error = null; };
    const onRejected = (state, action) => { state.loading = false; state.error = action.payload; };

    builder
      .addCase(fetch{{Name}}s.pending, onPending)
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetch{{Name}}s.rejected, onRejected)

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
        const index = state.data.findIndex(item => item.id === action.payload.id);
        if (index !== -1) state.data[index] = action.payload;
        state.success = true;
      })
      .addCase(update{{Name}}.rejected, onRejected)

      .addCase(delete{{Name}}.pending, onPending)
      .addCase(delete{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.data = state.data.filter(item => item.id !== action.payload);
        state.success = true;
      })
      .addCase(delete{{Name}}.rejected, onRejected);
  },
});

export const { reset{{Name}}Status } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Retry behaviour:
// Attempt 1 fails → wait 2s  → Attempt 2
// Attempt 2 fails → wait 4s  → Attempt 3
// Attempt 3 fails → error reaches the UI
//
// Retried:     network errors, HTTP 0, HTTP 500–599
// Not retried: HTTP 400, 401, 403, 404, 422 (client errors won't self-heal)
//
// Customize at top of file:
//   RETRY_ATTEMPTS = 3
//   RETRY_DELAY_MS = 2000
