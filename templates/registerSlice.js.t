import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}';

export const register = createAsyncThunk(
  'register/request',
  async (userData, { rejectWithValue }) => {
    try {
      const response = await axios.post(`${API_URL}/register`, userData);
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || 'Registration failed');
    }
  }
);

const registerSlice = createSlice({
  name: 'register',
  initialState: {
    loading: false,
    error: null,
    success: false,
    message: null,
  },
  reducers: {
    clearRegisterError: (state) => { state.error = null; },
    resetRegister: (state) => {
      state.loading = false;
      state.error = null;
      state.success = false;
      state.message = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(register.pending, (state) => { state.loading = true; state.error = null; state.success = false; })
      .addCase(register.fulfilled, (state, action) => {
        state.loading = false;
        state.success = true;
        state.message = action.payload?.message || 'Registration successful';
      })
      .addCase(register.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});

export const { clearRegisterError, resetRegister } = registerSlice.actions;
export default registerSlice.reducer;
