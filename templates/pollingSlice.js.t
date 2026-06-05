import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

let pollingTimer = null;

export const fetch{{Name}} = createAsyncThunk(
  '{{lowerName}}/fetch',
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL);
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const startPolling{{Name}} = (intervalMs = 5000) => (dispatch) => {
  dispatch(fetch{{Name}}());
  pollingTimer = setInterval(() => dispatch(fetch{{Name}}()), intervalMs);
};

export const stopPolling{{Name}} = () => () => {
  if (pollingTimer) {
    clearInterval(pollingTimer);
    pollingTimer = null;
  }
};

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: null,
    isPolling: false,
    lastUpdated: null,
    loading: false,
    error: null,
  },
  reducers: {
    setPolling{{Name}}: (state, action) => {
      state.isPolling = action.payload;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetch{{Name}}.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(fetch{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.data ?? action.payload;
        state.lastUpdated = new Date().toISOString();
      })
      .addCase(fetch{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});

export const { setPolling{{Name}} } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage:
// Start polling every 5s  → dispatch(startPolling{{Name}}(5000))
// Start polling every 10s → dispatch(startPolling{{Name}}(10000))
// Stop polling            → dispatch(stopPolling{{Name}}())
// Manual fetch            → dispatch(fetch{{Name}}())
// Last updated timestamp  → state.{{lowerName}}.lastUpdated
