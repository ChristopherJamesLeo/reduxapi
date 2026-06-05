import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';
const QUEUE_KEY = '{{lowerName}}_offline_queue';

// ─── Persistence Helpers ─────────────────────────────────────────────────────
const loadQueue = () => {
  try { return JSON.parse(localStorage.getItem(QUEUE_KEY) || '[]'); }
  catch { return []; }
};
const saveQueue = (queue) => {
  localStorage.setItem(QUEUE_KEY, JSON.stringify(queue));
};

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
  async (newData, { dispatch, rejectWithValue }) => {
    if (!navigator.onLine) {
      const queueId = `q_${Date.now()}`;
      dispatch(enqueue{{Name}}({ queueId, method: 'POST', data: newData, timestamp: new Date().toISOString() }));
      // Optimistically show in UI with _queued flag
      return { queued: true, item: { ...newData, _queueId: queueId, _queued: true } };
    }
    try {
      const response = await axios.post(API_URL, newData);
      return { queued: false, item: response.data.data ?? response.data };
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const update{{Name}} = createAsyncThunk(
  '{{lowerName}}/update',
  async ({ id, updateData }, { dispatch, rejectWithValue }) => {
    if (!navigator.onLine) {
      const queueId = `q_${Date.now()}`;
      dispatch(enqueue{{Name}}({ queueId, method: 'PUT', resourceId: id, data: updateData, timestamp: new Date().toISOString() }));
      return { queued: true, item: { id, ...updateData, _queued: true } };
    }
    try {
      const response = await axios.put(`${API_URL}/${id}`, updateData);
      return { queued: false, item: response.data.data ?? response.data };
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

export const delete{{Name}} = createAsyncThunk(
  '{{lowerName}}/delete',
  async (id, { dispatch, rejectWithValue }) => {
    if (!navigator.onLine) {
      const queueId = `q_${Date.now()}`;
      dispatch(enqueue{{Name}}({ queueId, method: 'DELETE', resourceId: id, timestamp: new Date().toISOString() }));
      return { queued: true, resourceId: id };
    }
    try {
      await axios.delete(`${API_URL}/${id}`);
      return { queued: false, resourceId: id };
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Process every queued item now that we're back online
export const sync{{Name}}Queue = createAsyncThunk(
  '{{lowerName}}/syncQueue',
  async (_, { getState, rejectWithValue }) => {
    const queue = getState().{{lowerName}}.queue;
    if (!queue.length) return { synced: [], failed: [] };

    const synced = [];
    const failed = [];

    for (const item of queue) {
      try {
        if (item.method === 'POST') {
          const r = await axios.post(API_URL, item.data);
          synced.push({ queueId: item.queueId, response: r.data.data ?? r.data });
        } else if (item.method === 'PUT') {
          const r = await axios.put(`${API_URL}/${item.resourceId}`, item.data);
          synced.push({ queueId: item.queueId, response: r.data.data ?? r.data });
        } else if (item.method === 'DELETE') {
          await axios.delete(`${API_URL}/${item.resourceId}`);
          synced.push({ queueId: item.queueId, resourceId: item.resourceId });
        }
      } catch (error) {
        failed.push({ ...item, error: error.response?.data?.message || error.message });
      }
    }

    return { synced, failed };
  }
);

// Call once in app entry point — auto-syncs when network comes back
export const start{{Name}}NetworkListener = () => (dispatch) => {
  const onOnline = () => {
    dispatch(set{{Name}}Online(true));
    dispatch(sync{{Name}}Queue());
  };
  const onOffline = () => dispatch(set{{Name}}Online(false));

  window.addEventListener('online',  onOnline);
  window.addEventListener('offline', onOffline);

  return () => {
    window.removeEventListener('online',  onOnline);
    window.removeEventListener('offline', onOffline);
  };
};

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: [],
    queue: loadQueue(),    // persisted across page refreshes via localStorage
    isOnline: typeof navigator !== 'undefined' ? navigator.onLine : true,
    syncing: false,
    syncFailed: [],        // items that failed even after reconnect
    loading: false,
    error: null,
    success: false,
  },
  reducers: {
    enqueue{{Name}}: (state, action) => {
      state.queue.push(action.payload);
      saveQueue(state.queue);
    },
    set{{Name}}Online: (state, action) => {
      state.isOnline = action.payload;
    },
    reset{{Name}}Status: (state) => {
      state.success = false;
      state.error = null;
    },
    clear{{Name}}SyncFailed: (state) => {
      state.syncFailed = [];
    },
  },
  extraReducers: (builder) => {
    builder
      // Fetch
      .addCase(fetch{{Name}}s.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      // Create
      .addCase(create{{Name}}.fulfilled, (state, action) => {
        const { queued, item } = action.payload;
        state.data.unshift(item);  // show immediately whether queued or confirmed
        if (!queued) state.success = true;
      })
      .addCase(create{{Name}}.rejected, (state, action) => { state.error = action.payload; })

      // Update
      .addCase(update{{Name}}.fulfilled, (state, action) => {
        const { item } = action.payload;
        const index = state.data.findIndex(i => i.id === item.id);
        if (index !== -1) state.data[index] = item;
        if (!action.payload.queued) state.success = true;
      })
      .addCase(update{{Name}}.rejected, (state, action) => { state.error = action.payload; })

      // Delete
      .addCase(delete{{Name}}.fulfilled, (state, action) => {
        const { resourceId } = action.payload;
        state.data = state.data.filter(i => i.id !== resourceId);
        if (!action.payload.queued) state.success = true;
      })
      .addCase(delete{{Name}}.rejected, (state, action) => { state.error = action.payload; })

      // Sync Queue
      .addCase(sync{{Name}}Queue.pending, (state) => { state.syncing = true; })
      .addCase(sync{{Name}}Queue.fulfilled, (state, action) => {
        const { synced, failed } = action.payload;
        const syncedIds = new Set(synced.map(s => s.queueId));
        // Remove synced items' _queued flag from data
        state.data = state.data.map(item =>
          item._queueId && syncedIds.has(item._queueId)
            ? { ...item, _queued: false, _queueId: undefined }
            : item
        );
        // Remove successfully synced items from queue
        state.queue = state.queue.filter(q => !syncedIds.has(q.queueId));
        saveQueue(state.queue);
        state.syncFailed = failed;
        state.syncing = false;
        if (synced.length) state.success = true;
      })
      .addCase(sync{{Name}}Queue.rejected, (state) => { state.syncing = false; });
  },
});

export const {
  enqueue{{Name}},
  set{{Name}}Online,
  reset{{Name}}Status,
  clear{{Name}}SyncFailed,
} = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Quick-start:
// 1. In main.jsx — start listener once:
//      import { start{{Name}}NetworkListener } from '…/{{lowerName}}Slice';
//      store.dispatch(start{{Name}}NetworkListener());
//
// 2. In components — use normally (offline handling is automatic):
//      dispatch(create{{Name}}(data));   // queues if offline, sends if online
//      dispatch(update{{Name}}({ id, updateData }));
//      dispatch(delete{{Name}}(id));
//
// 3. State hints:
//      state.isOnline      → show "Offline Mode" banner
//      state.queue.length  → show "X changes pending sync" badge
//      state.syncing       → show sync spinner
//      state.syncFailed    → show "Some changes failed to sync" warning
//      item._queued        → show "Pending…" indicator per item
