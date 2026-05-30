import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}';

export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { getState, rejectWithValue }) => {
    try {
      const token = getState().auth?.token;
      const response = await axios.get(API_URL, {
        headers: { Authorization: `Bearer ${token}` },
      });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const create{{Name}} = createAsyncThunk(
  '{{lowerName}}/create',
  async (newData, { getState, rejectWithValue }) => {
    try {
      const token = getState().auth?.token;
      const response = await axios.post(API_URL, newData, {
        headers: { Authorization: `Bearer ${token}` },
      });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const update{{Name}} = createAsyncThunk(
  '{{lowerName}}/update',
  async ({ id, updateData }, { getState, rejectWithValue }) => {
    try {
      const token = getState().auth?.token;
      const response = await axios.put(`${API_URL}/${id}`, updateData, {
        headers: { Authorization: `Bearer ${token}` },
      });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const delete{{Name}} = createAsyncThunk(
  '{{lowerName}}/delete',
  async (id, { getState, rejectWithValue }) => {
    try {
      const token = getState().auth?.token;
      await axios.delete(`${API_URL}/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
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
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(create{{Name}}.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(create{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.data.unshift(action.payload);
        state.success = true;
      })
      .addCase(create{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      .addCase(update{{Name}}.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(update{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        const index = state.data.findIndex(item => item.id === action.payload.id);
        if (index !== -1) state.data[index] = action.payload;
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
