import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const HTTP_URL = '{{apiUrl}}/{{lowerName}}';
// WebSocket URL: replace http(s) with ws(s) — or set explicitly below
const WS_URL = '{{apiUrl}}'.replace(/^http/, 'ws') + '/ws/{{lowerName}}';

// ─── WebSocket Manager ───────────────────────────────────────────────────────

let _socket            = null;
let _reconnectTimer    = null;
let _reconnectAttempts = 0;
const MAX_RECONNECT    = 5;
const RECONNECT_DELAY  = 3000; // ms (multiplied per attempt)

export const connect{{Name}}Socket = (customUrl) => (dispatch) => {
  if (_socket?.readyState === WebSocket.OPEN) return; // already connected

  const url = customUrl || WS_URL;
  _socket = new WebSocket(url);

  _socket.onopen = () => {
    _reconnectAttempts = 0;
    dispatch(set{{Name}}SocketStatus('connected'));
    dispatch(set{{Name}}SocketError(null));
  };

  _socket.onmessage = (event) => {
    try {
      const message = JSON.parse(event.data);
      dispatch(handle{{Name}}Event(message));
    } catch { /* ignore malformed messages */ }
  };

  _socket.onclose = (event) => {
    dispatch(set{{Name}}SocketStatus('disconnected'));
    if (!event.wasClean && _reconnectAttempts < MAX_RECONNECT) {
      _reconnectAttempts++;
      const delay = RECONNECT_DELAY * _reconnectAttempts;
      _reconnectTimer = setTimeout(
        () => dispatch(connect{{Name}}Socket(customUrl)),
        delay
      );
    }
  };

  _socket.onerror = () => {
    dispatch(set{{Name}}SocketStatus('error'));
    dispatch(set{{Name}}SocketError('WebSocket connection error'));
  };
};

export const disconnect{{Name}}Socket = () => () => {
  if (_reconnectTimer) { clearTimeout(_reconnectTimer); _reconnectTimer = null; }
  if (_socket) { _socket.close(1000, 'Client disconnect'); _socket = null; }
};

export const sendTo{{Name}}Socket = (message) => () => {
  if (_socket?.readyState === WebSocket.OPEN) {
    _socket.send(JSON.stringify(message));
  }
};

// ─── SSE (Server-Sent Events) Alternative ────────────────────────────────────
// Use this instead of WebSocket for read-only real-time streams

let _sseSource = null;

export const connect{{Name}}SSE = (customUrl) => (dispatch) => {
  if (_sseSource) _sseSource.close();

  const url = customUrl || `${HTTP_URL}/stream`;
  _sseSource = new EventSource(url);

  _sseSource.onopen = () => dispatch(set{{Name}}SocketStatus('connected'));

  _sseSource.onmessage = (event) => {
    try {
      const message = JSON.parse(event.data);
      dispatch(handle{{Name}}Event(message));
    } catch { /* ignore */ }
  };

  _sseSource.addEventListener('error', () => {
    dispatch(set{{Name}}SocketStatus('error'));
  });
};

export const disconnect{{Name}}SSE = () => () => {
  if (_sseSource) { _sseSource.close(); _sseSource = null; }
};

// ─── Initial HTTP Fetch ──────────────────────────────────────────────────────

export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.get(HTTP_URL);
      return response.data.data ?? response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: [],
    socketStatus: 'idle',  // 'idle' | 'connected' | 'disconnected' | 'error'
    socketError: null,
    lastEvent: null,       // most recent raw event from server
    loading: false,
    error: null,
  },
  reducers: {
    set{{Name}}SocketStatus: (state, action) => {
      state.socketStatus = action.payload;
    },
    set{{Name}}SocketError: (state, action) => {
      state.socketError = action.payload;
    },

    // ── Incoming event router ──────────────────────────────────────────────
    // Extend this reducer to handle your real-time events.
    // The `message.type` field drives which action to take.
    handle{{Name}}Event: (state, action) => {
      const message = action.payload;
      state.lastEvent = message;

      switch (message.type) {
        // Item created by another user → add to list
        case '{{lowerName}}.created': {
          const exists = state.data.some(i => i.id === message.data.id);
          if (!exists) state.data.unshift(message.data);
          break;
        }
        // Item updated by another user → replace in list
        case '{{lowerName}}.updated': {
          const index = state.data.findIndex(i => i.id === message.data.id);
          if (index !== -1) state.data[index] = message.data;
          break;
        }
        // Item deleted by another user → remove from list
        case '{{lowerName}}.deleted': {
          state.data = state.data.filter(i => i.id !== message.data.id);
          break;
        }
        // Add more cases here to handle custom events from your backend:
        // case '{{lowerName}}.status_changed': { ... break; }
        default:
          break;
      }
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
      });
  },
});

export const {
  set{{Name}}SocketStatus,
  set{{Name}}SocketError,
  handle{{Name}}Event,
} = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Quick-start (WebSocket):
//
// 1. Connect when component mounts:
//      useEffect(() => {
//        dispatch(connect{{Name}}Socket());
//        return () => dispatch(disconnect{{Name}}Socket());
//      }, []);
//
// 2. Initial load via HTTP, then live updates via WS:
//      dispatch(fetch{{Name}}s());     // HTTP: load current list
//      dispatch(connect{{Name}}Socket()); // WS: receive real-time changes
//
// 3. Send a message to server:
//      dispatch(sendTo{{Name}}Socket({ type: 'subscribe', room: '{{lowerName}}_updates' }));
//
// Quick-start (SSE — read-only stream, simpler):
//      dispatch(connect{{Name}}SSE());
//      return () => dispatch(disconnect{{Name}}SSE());
//
// Backend event format expected:
//   { "type": "{{lowerName}}.created", "data": { ...item } }
//   { "type": "{{lowerName}}.updated", "data": { ...item } }
//   { "type": "{{lowerName}}.deleted", "data": { "id": 1 } }
//
// State hints:
//   state.socketStatus → 'connected' | 'disconnected' | 'error'
//   state.lastEvent    → inspect last received event for debugging
