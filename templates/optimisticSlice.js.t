import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL);
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
      const response = await axios.post(API_URL, newData);
      return { tempId: newData._tempId, data: response.data.data ?? response.data };
    } catch (error) {
      return rejectWithValue({ tempId: newData._tempId, message: error.response?.data?.message || error.message });
    }
  }
);

export const update{{Name}} = createAsyncThunk(
  '{{lowerName}}/update',
  async ({ id, updateData }, { rejectWithValue }) => {
    try {
      const response = await axios.put(`${API_URL}/${id}`, updateData);
      return response.data.data ?? response.data;
    } catch (error) {
      return rejectWithValue({ id, message: error.response?.data?.message || error.message });
    }
  }
);

export const delete{{Name}} = createAsyncThunk(
  '{{lowerName}}/delete',
  async (id, { rejectWithValue }) => {
    try {
      await axios.delete(`${API_URL}/${id}`);
      return id;
    } catch (error) {
      return rejectWithValue({ id, message: error.response?.data?.message || error.message });
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
    optimisticAdd{{Name}}: (state, action) => {
      state.data.unshift({ ...action.payload, _optimistic: true });
    },
    optimisticUpdate{{Name}}: (state, action) => {
      const index = state.data.findIndex(item => item.id === action.payload.id);
      if (index !== -1) state.data[index] = { ...action.payload, _optimistic: true };
    },
    optimisticRemove{{Name}}: (state, action) => {
      state.data = state.data.filter(item => item.id !== action.payload);
    },
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
        state.data = action.payload.data ?? action.payload;
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      // Replace temp optimistic item with real server data
      .addCase(create{{Name}}.fulfilled, (state, action) => {
        const { tempId, data } = action.payload;
        const index = state.data.findIndex(item => item._tempId === tempId);
        if (index !== -1) {
          state.data[index] = data;
        } else {
          state.data.unshift(data);
        }
        state.success = true;
      })
      .addCase(create{{Name}}.rejected, (state, action) => {
        state.data = state.data.filter(item => item._tempId !== action.payload.tempId);
        state.error = action.payload.message;
      })

      // Confirm update (remove _optimistic flag)
      .addCase(update{{Name}}.fulfilled, (state, action) => {
        const index = state.data.findIndex(item => item.id === action.payload.id);
        if (index !== -1) state.data[index] = action.payload;
        state.success = true;
      })
      .addCase(update{{Name}}.rejected, (state, action) => {
        state.error = action.payload.message;
      })

      // Confirm delete (already removed optimistically)
      .addCase(delete{{Name}}.rejected, (state, action) => {
        state.error = action.payload.message;
      });
  },
});

export const {
  optimisticAdd{{Name}},
  optimisticUpdate{{Name}},
  optimisticRemove{{Name}},
  reset{{Name}}Status,
} = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage:
// Optimistic create →
//   const tempId = Date.now();
//   dispatch(optimisticAdd{{Name}}({ _tempId: tempId, ...formData }));
//   dispatch(create{{Name}}({ _tempId: tempId, ...formData }));
//
// Optimistic update →
//   dispatch(optimisticUpdate{{Name}}({ id, ...changes }));
//   dispatch(update{{Name}}({ id, updateData: changes }));
//
// Optimistic delete →
//   dispatch(optimisticRemove{{Name}}(id));
//   dispatch(delete{{Name}}(id));
