import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

export const fetch{{Name}}Summary = createAsyncThunk(
  '{{lowerName}}/fetchSummary',
  async (params = {}, { rejectWithValue }) => {
    try {
      const response = await axios.get(`${API_URL}/summary`, { params });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const fetch{{Name}}Chart = createAsyncThunk(
  '{{lowerName}}/fetchChart',
  async ({ metric, range = '7d', interval = 'day' } = {}, { rejectWithValue }) => {
    try {
      const response = await axios.get(`${API_URL}/chart`, { params: { metric, range, interval } });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const fetch{{Name}}Metrics = createAsyncThunk(
  '{{lowerName}}/fetchMetrics',
  async (params = {}, { rejectWithValue }) => {
    try {
      const response = await axios.get(`${API_URL}/metrics`, { params });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    summary: null,
    chart: [],
    metrics: [],
    loadingSummary: false,
    loadingChart: false,
    loadingMetrics: false,
    error: null,
  },
  reducers: {
    clear{{Name}}Data: (state) => {
      state.summary = null;
      state.chart = [];
      state.metrics = [];
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetch{{Name}}Summary.pending, (state) => { state.loadingSummary = true; state.error = null; })
      .addCase(fetch{{Name}}Summary.fulfilled, (state, action) => {
        state.loadingSummary = false;
        state.summary = action.payload.data ?? action.payload;
      })
      .addCase(fetch{{Name}}Summary.rejected, (state, action) => {
        state.loadingSummary = false;
        state.error = action.payload;
      })

      .addCase(fetch{{Name}}Chart.pending, (state) => { state.loadingChart = true; state.error = null; })
      .addCase(fetch{{Name}}Chart.fulfilled, (state, action) => {
        state.loadingChart = false;
        state.chart = action.payload.data ?? action.payload;
      })
      .addCase(fetch{{Name}}Chart.rejected, (state, action) => {
        state.loadingChart = false;
        state.error = action.payload;
      })

      .addCase(fetch{{Name}}Metrics.pending, (state) => { state.loadingMetrics = true; state.error = null; })
      .addCase(fetch{{Name}}Metrics.fulfilled, (state, action) => {
        state.loadingMetrics = false;
        state.metrics = action.payload.data ?? action.payload;
      })
      .addCase(fetch{{Name}}Metrics.rejected, (state, action) => {
        state.loadingMetrics = false;
        state.error = action.payload;
      });
  },
});

export const { clear{{Name}}Data } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage:
// KPI cards   → dispatch(fetch{{Name}}Summary({ period: 'month' }))
// Line chart  → dispatch(fetch{{Name}}Chart({ metric: 'revenue', range: '30d', interval: 'day' }))
// Metric list → dispatch(fetch{{Name}}Metrics({ group: 'region' }))
// Clear all   → dispatch(clear{{Name}}Data())
