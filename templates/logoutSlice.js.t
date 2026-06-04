import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}';

export const logout = createAsyncThunk(
  'logout/request',
  async (_, { getState, rejectWithValue }) => {
    try {
      const token = getState().login?.token;
      await axios.post(`${API_URL}/logout`, {}, {
        headers: { Authorization: `Bearer ${token}` },
      });
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      return null;
    } catch (error) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      return rejectWithValue(error.response?.data?.message || 'Logout failed');
    }
  }
);

const logoutSlice = createSlice({
  name: 'logout',
  initialState: {
    loading: false,
    error: null,
  },
  reducers: {
    resetLogout: (state) => { state.loading = false; state.error = null; },
  },
  extraReducers: (builder) => {
    builder
      .addCase(logout.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(logout.fulfilled, (state) => { state.loading = false; })
      .addCase(logout.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});

export const { resetLogout } = logoutSlice.actions;
export default logoutSlice.reducer;
