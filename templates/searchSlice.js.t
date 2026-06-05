import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

export const search{{Name}}s = createAsyncThunk(
  '{{lowerName}}/search',
  async (filters = {}, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL, { params: filters });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: [],
    meta: null,
    filters: {},
    loading: false,
    error: null,
  },
  reducers: {
    set{{Name}}Filters: (state, action) => {
      state.filters = { ...state.filters, ...action.payload };
    },
    clear{{Name}}Filters: (state) => {
      state.filters = {};
      state.data = [];
      state.meta = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(search{{Name}}s.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(search{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.data ?? action.payload;
        state.meta = action.payload.meta ?? null;
      })
      .addCase(search{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});

export const { set{{Name}}Filters, clear{{Name}}Filters } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage:
// Basic search   → dispatch(search{{Name}}s({ q: 'term' }))
// With filters   → dispatch(search{{Name}}s({ status: 'active', category: 'books', page: 2 }))
// Save & search  → dispatch(set{{Name}}Filters({ status: 'active' })) then dispatch(search{{Name}}s(filters))
// Clear          → dispatch(clear{{Name}}Filters())
