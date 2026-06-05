import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

const toFormData = (data) => {
  const form = new FormData();
  Object.entries(data).forEach(([key, value]) => {
    if (Array.isArray(value)) {
      value.forEach((v) => form.append(`${key}[]`, v));
    } else if (value !== undefined && value !== null) {
      form.append(key, value);
    }
  });
  return form;
};

export const upload{{Name}} = createAsyncThunk(
  '{{lowerName}}/upload',
  async (data, { rejectWithValue }) => {
    try {
      const response = await axios.post(API_URL, toFormData(data), {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const updateUpload{{Name}} = createAsyncThunk(
  '{{lowerName}}/updateUpload',
  async ({ id, data }, { rejectWithValue }) => {
    try {
      const form = toFormData(data);
      form.append('_method', 'PUT');
      const response = await axios.post(`${API_URL}/${id}`, form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
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
    progress: 0,
    loading: false,
    error: null,
    success: false,
  },
  reducers: {
    reset{{Name}}Upload: (state) => {
      state.data = null;
      state.progress = 0;
      state.success = false;
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(upload{{Name}}.pending, (state) => { state.loading = true; state.error = null; state.progress = 0; })
      .addCase(upload{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.data ?? action.payload;
        state.progress = 100;
        state.success = true;
      })
      .addCase(upload{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
        state.progress = 0;
      })

      .addCase(updateUpload{{Name}}.pending, (state) => { state.loading = true; state.error = null; state.progress = 0; })
      .addCase(updateUpload{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload.data ?? action.payload;
        state.progress = 100;
        state.success = true;
      })
      .addCase(updateUpload{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
        state.progress = 0;
      });
  },
});

export const { reset{{Name}}Upload } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage:
// Create with file → dispatch(upload{{Name}}({ title: 'Photo', file: fileInput.files[0] }))
// Update with file → dispatch(updateUpload{{Name}}({ id: 1, data: { title: 'New', file: file } }))
// Reset after done → dispatch(reset{{Name}}Upload())
// Plain fields + File objects are auto-converted to FormData
