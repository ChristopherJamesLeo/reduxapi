import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = 'https://your-api-url.com/{{lowerName}}';

export const create{{Name}} = createAsyncThunk(
  '{{lowerName}}/create',
  async (newData, { rejectWithValue }) => {
    try {
      const response = await axios.post(API_URL, newData);
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: null,
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
      .addCase(create{{Name}}.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(create{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
        state.success = true;
      })
      .addCase(create{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});

export const { reset{{Name}}Status } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;
