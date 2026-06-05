import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

// ─── Thunks ─────────────────────────────────────────────────────────────────

export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL);
      return response.data.data ?? response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const create{{Name}} = createAsyncThunk(
  '{{lowerName}}/create',
  async (data, { rejectWithValue }) => {
    try {
      const response = await axios.post(API_URL, data);
      return { tempId: data._tempId, item: response.data.data ?? response.data };
    } catch (error) {
      return rejectWithValue({ tempId: data._tempId, message: error.response?.data?.message || error.message });
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

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: [],
    _snapshot: null, // deep copy saved before every optimistic mutation
    loading: false,
    error: null,
    success: false,
  },
  reducers: {
    // ── Optimistic mutations (call BEFORE dispatching the async thunk) ────────

    // Add new item immediately; replace with real item on API success
    optimisticAdd{{Name}}: (state, action) => {
      state._snapshot = JSON.parse(JSON.stringify(state.data));
      state.data.unshift({ ...action.payload, _optimistic: true });
    },

    // Update item immediately; confirm (strip _optimistic flag) on API success
    optimisticUpdate{{Name}}: (state, action) => {
      state._snapshot = JSON.parse(JSON.stringify(state.data));
      const index = state.data.findIndex(item => item.id === action.payload.id);
      if (index !== -1) {
        state.data[index] = { ...state.data[index], ...action.payload, _optimistic: true };
      }
    },

    // Remove item immediately; restore from snapshot if API fails
    optimisticRemove{{Name}}: (state, action) => {
      state._snapshot = JSON.parse(JSON.stringify(state.data));
      state.data = state.data.filter(item => item.id !== action.payload);
    },

    // Manual rollback (emergency use)
    rollback{{Name}}: (state) => {
      if (state._snapshot !== null) {
        state.data = state._snapshot;
        state._snapshot = null;
      }
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
        state.data = action.payload;
        state._snapshot = null;
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      // ── Create ──────────────────────────────────────────────────────────────
      // Success: swap temp item for the real server item
      .addCase(create{{Name}}.fulfilled, (state, action) => {
        const { tempId, item } = action.payload;
        const index = state.data.findIndex(i => i._tempId === tempId);
        if (index !== -1) { state.data[index] = item; } else { state.data.unshift(item); }
        state._snapshot = null;
        state.success = true;
      })
      // Failure: restore snapshot (remove the temp item from the list)
      .addCase(create{{Name}}.rejected, (state, action) => {
        if (state._snapshot !== null) { state.data = state._snapshot; state._snapshot = null; }
        state.error = action.payload.message;
      })

      // ── Update ──────────────────────────────────────────────────────────────
      // Success: replace with confirmed server data (removes _optimistic flag)
      .addCase(update{{Name}}.fulfilled, (state, action) => {
        const index = state.data.findIndex(item => item.id === action.payload.id);
        if (index !== -1) state.data[index] = action.payload;
        state._snapshot = null;
        state.success = true;
      })
      // Failure: restore snapshot (revert the field changes)
      .addCase(update{{Name}}.rejected, (state, action) => {
        if (state._snapshot !== null) { state.data = state._snapshot; state._snapshot = null; }
        state.error = action.payload.message;
      })

      // ── Delete ──────────────────────────────────────────────────────────────
      // Success: clear snapshot (delete confirmed)
      .addCase(delete{{Name}}.fulfilled, (state) => {
        state._snapshot = null;
        state.success = true;
      })
      // Failure: restore snapshot (put the deleted item back in the list)
      .addCase(delete{{Name}}.rejected, (state, action) => {
        if (state._snapshot !== null) { state.data = state._snapshot; state._snapshot = null; }
        state.error = action.payload.message;
      });
  },
});

export const {
  optimisticAdd{{Name}},
  optimisticUpdate{{Name}},
  optimisticRemove{{Name}},
  rollback{{Name}},
  reset{{Name}}Status,
} = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Usage — Bookmark example (optimistic toggle):
//   dispatch(optimisticUpdate{{Name}}({ id: 1, bookmarked: true }));
//   dispatch(update{{Name}}({ id: 1, updateData: { bookmarked: true } }));
//   // → 401/500 returned? bookmarked state auto-reverts to false
//
// Usage — Delete with restore on fail:
//   dispatch(optimisticRemove{{Name}}(id));
//   dispatch(delete{{Name}}(id));
//   // → API fails? deleted item automatically reappears
//
// Usage — Create with rollback:
//   const tempId = Date.now();
//   dispatch(optimisticAdd{{Name}}({ _tempId: tempId, title: 'New Item' }));
//   dispatch(create{{Name}}({ _tempId: tempId, title: 'New Item' }));
//   // → API fails? temp item automatically removed from the list
