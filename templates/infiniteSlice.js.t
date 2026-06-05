import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

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

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: [],
    nextCursor: null,
    hasMore: true,
    loading: false,
    loadingMore: false,
    error: null,
  },
  reducers: {
    reset{{Name}}s: (state) => {
      state.data = [];
      state.nextCursor = null;
      state.hasMore = true;
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetch{{Name}}s.pending, (state, action) => {
        if (action.meta.arg?.cursor) {
          state.loadingMore = true;
        } else {
          state.loading = true;
          state.data = [];
        }
        state.error = null;
      })
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.loadingMore = false;
        const items = action.payload.data ?? action.payload;
        state.data = [...state.data, ...items];
        state.nextCursor = action.payload.next_cursor ?? null;
        state.hasMore = !!action.payload.next_cursor;
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.loadingMore = false;
        state.error = action.payload;
      });
  },
});

export const { reset{{Name}}s } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage:
// Initial load  → dispatch(fetch{{Name}}s())
// Load more     → dispatch(fetch{{Name}}s({ cursor: state.{{lowerName}}.nextCursor }))
// Reset & reload→ dispatch(reset{{Name}}s()) then dispatch(fetch{{Name}}s())
// state.hasMore → false when all pages fetched
