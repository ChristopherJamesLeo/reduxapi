import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

// ─── Utilities ───────────────────────────────────────────────────────────────

// Debounce: delays execution until user stops calling for `delay` ms
const debounce = (fn, delay) => {
  let timer = null;
  return (...args) => {
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => { fn(...args); timer = null; }, delay);
  };
};

// Throttle: allows one call per `limit` ms, ignores the rest
const throttle = (fn, limit) => {
  let inThrottle = false;
  return (...args) => {
    if (!inThrottle) {
      fn(...args);
      inThrottle = true;
      setTimeout(() => { inThrottle = false; }, limit);
    }
  };
};

// ─── Thunks ─────────────────────────────────────────────────────────────────

export const search{{Name}}s = createAsyncThunk(
  '{{lowerName}}/search',
  async (params = {}, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL, { params });
      return response.data.data ?? response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const submit{{Name}} = createAsyncThunk(
  '{{lowerName}}/submit',
  async (data, { rejectWithValue }) => {
    try {
      const response = await axios.post(API_URL, data);
      return response.data.data ?? response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// ─── Debounced / Throttled Helpers ───────────────────────────────────────────

// Debounced search: waits 500ms after last call before firing
// Use in onChange / search input handlers
export const debounced{{Name}}Search = debounce((dispatch, params) => {
  dispatch(search{{Name}}s(params));
}, 500);

// Throttled submit: one API call per 2 seconds max
// Use on buttons that users might click multiple times rapidly
export const throttled{{Name}}Submit = throttle((dispatch, data) => {
  dispatch(submit{{Name}}(data));
}, 2000);

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: [],
    result: null,
    loading: false,    // search in progress
    submitting: false, // form/button submission in progress
    error: null,
    success: false,
  },
  reducers: {
    reset{{Name}}Status: (state) => {
      state.success = false;
      state.error = null;
    },
    clear{{Name}}Results: (state) => {
      state.data = [];
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(search{{Name}}s.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(search{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(search{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(submit{{Name}}.pending, (state) => { state.submitting = true; state.error = null; })
      .addCase(submit{{Name}}.fulfilled, (state, action) => {
        state.submitting = false;
        state.result = action.payload;
        state.success = true;
      })
      .addCase(submit{{Name}}.rejected, (state, action) => {
        state.submitting = false;
        state.error = action.payload;
      });
  },
});

export const { reset{{Name}}Status, clear{{Name}}Results } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage:
// Debounced search (in onChange) → debounced{{Name}}Search(dispatch, { q: inputValue })
// Throttled button submit        → throttled{{Name}}Submit(dispatch, formData)
// Direct search (no debounce)    → dispatch(search{{Name}}s({ q: 'laptop', page: 1 }))
// Clear search results           → dispatch(clear{{Name}}Results())
//
// state.loading    → true while search API is in-flight
// state.submitting → true while submit API is in-flight (disable button to prevent double submit)
