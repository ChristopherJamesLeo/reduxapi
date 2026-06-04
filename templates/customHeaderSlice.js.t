import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

// Define your custom headers here
const getHeaders = () => ({
  Authorization: `Bearer ${localStorage.getItem('token')}`,
  // 'X-Custom-Header': 'value',
  // 'Accept-Language': 'en',
});

export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL, { headers: getHeaders() });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const fetchPaginated{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchPaginated',
  async (page = 1, { rejectWithValue }) => {
    try {
      const response = await axios.get(`${API_URL}?page=${page}`, { headers: getHeaders() });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const create{{Name}} = createAsyncThunk(
  '{{lowerName}}/create',
  async (newData, { rejectWithValue }) => {
    try {
      const response = await axios.post(API_URL, newData, { headers: getHeaders() });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const update{{Name}} = createAsyncThunk(
  '{{lowerName}}/update',
  async ({ id, updateData }, { rejectWithValue }) => {
    try {
      const response = await axios.put(`${API_URL}/${id}`, updateData, { headers: getHeaders() });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const delete{{Name}} = createAsyncThunk(
  '{{lowerName}}/delete',
  async (id, { rejectWithValue }) => {
    try {
      await axios.delete(`${API_URL}/${id}`, { headers: getHeaders() });
      return id;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: [],
    links: null,
    meta: null,
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
    builder
      .addCase(fetch{{Name}}s.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
        state.links = null;
        state.meta = null;
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(fetchPaginated{{Name}}s.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(fetchPaginated{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.data;
        state.links = action.payload.links;
        state.meta = action.payload.meta;
      })
      .addCase(fetchPaginated{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(create{{Name}}.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(create{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.data.unshift(action.payload.data ?? action.payload);
        state.success = true;
      })
      .addCase(create{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(update{{Name}}.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(update{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        const updated = action.payload.data ?? action.payload;
        const index = state.data.findIndex(item => item.id === updated.id);
        if (index !== -1) state.data[index] = updated;
        state.success = true;
      })
      .addCase(update{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(delete{{Name}}.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(delete{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.data = state.data.filter(item => item.id !== action.payload);
        if (state.meta) state.meta.total -= 1;
        state.success = true;
      })
      .addCase(delete{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});

export const { reset{{Name}}Status } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;
