import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';


const API_URL = 'https://your-api-url.com/features';


export const fetchfeaturess = createAsyncThunk(
  'features/fetchAll',
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL);
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);


export const createfeatures = createAsyncThunk(
  'features/create',
  async (newData, { rejectWithValue }) => {
    try {
      const response = await axios.post(API_URL, newData);
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);


export const updatefeatures = createAsyncThunk(
  'features/update',
  async ({ id, updateData }, { rejectWithValue }) => {
    try {
      const response = await axios.put(`${API_URL}/${id}`, updateData);
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);


export const deletefeatures = createAsyncThunk(
  'features/delete',
  async (id, { rejectWithValue }) => {
    try {
      await axios.delete(`${API_URL}/${id}`);
      return id; // UI ကနေ ဖယ်ထုတ်ဖို့ ID ကို ပြန်ပေးမယ်
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

const featuresSlice = createSlice({
  name: 'features',
  initialState: {
    data: [],
    loading: false,
    error: null,
    success: false, // UI မှာ အောင်မြင်ကြောင်း notification ပြဖို့
  },
  reducers: {
    resetfeaturesStatus: (state) => {
      state.success = false;
      state.error = null;
    }
  },
  extraReducers: (builder) => {
    builder
  
      .addCase(fetchfeaturess.pending, (state) => { state.loading = true; })
      .addCase(fetchfeaturess.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetchfeaturess.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })


      .addCase(createfeatures.fulfilled, (state, action) => {
        state.data.unshift(action.payload); // အသစ်ကို ထိပ်ဆုံးမှာ ထည့်မယ်
        state.success = true;
      })


      .addCase(updatefeatures.fulfilled, (state, action) => {
        const index = state.data.findIndex(item => item.id === action.payload.id);
        if (index !== -1) {
          state.data[index] = action.payload;
        }
        state.success = true;
      })


      .addCase(deletefeatures.fulfilled, (state, action) => {
        state.data = state.data.filter(item => item.id !== action.payload);
        state.success = true;
      });
  },
});

export const { resetfeaturesStatus } = featuresSlice.actions;
export default featuresSlice.reducer;