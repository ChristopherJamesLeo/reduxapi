import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL    = '{{apiUrl}}/{{lowerName}}';
const HEALTH_URL = '{{apiUrl}}/health'; // ← change to your health-check endpoint

// ─── Circuit Breaker Config ──────────────────────────────────────────────────
const FAILURE_THRESHOLD  = 5;       // consecutive failures → open (trip) circuit
const SUCCESS_THRESHOLD  = 2;       // consecutive successes → close circuit from half_open
const RECOVERY_TIMEOUT   = 30_000;  // ms before auto-probe when circuit is open
const PING_INTERVAL      = 10_000;  // ms between background health pings

// Circuit states:
//   closed    → normal, all requests pass through
//   open      → tripped, all requests blocked, show maintenance UI
//   half_open → probing, one test request allowed; close on success, re-open on fail

let _pingTimer     = null;
let _recoveryTimer = null;

// ─── Thunks ─────────────────────────────────────────────────────────────────

// Background health ping (not a user-facing API call)
export const ping{{Name}}Health = createAsyncThunk(
  '{{lowerName}}/pingHealth',
  async (_, { getState, rejectWithValue }) => {
    const { circuitState } = getState().{{lowerName}};
    if (circuitState === 'open') return rejectWithValue({ skipped: true });

    try {
      await axios.get(HEALTH_URL, { timeout: 5000 });
      return { pingOk: true };
    } catch (error) {
      return rejectWithValue({
        skipped: false,
        message: error.response?.data?.message || error.message,
        statusCode: error.response?.status,
      });
    }
  }
);

// Guarded fetch — aborts early if circuit is open, records failure on error
export const fetch{{Name}}s = createAsyncThunk(
  '{{lowerName}}/fetchAll',
  async (_, { getState, rejectWithValue }) => {
    const { circuitState } = getState().{{lowerName}};
    if (circuitState === 'open') {
      return rejectWithValue({ blocked: true, message: 'Server is currently under maintenance' });
    }

    try {
      const response = await axios.get(API_URL);
      return response.data.data ?? response.data;
    } catch (error) {
      return rejectWithValue({
        blocked: false,
        message: error.response?.data?.message || error.message,
        statusCode: error.response?.status,
      });
    }
  }
);

// Start periodic health pings — call once in app entry point
export const start{{Name}}CircuitBreaker = () => (dispatch) => {
  if (_pingTimer) clearInterval(_pingTimer);
  dispatch(ping{{Name}}Health());
  _pingTimer = setInterval(() => dispatch(ping{{Name}}Health()), PING_INTERVAL);
};

export const stop{{Name}}CircuitBreaker = () => () => {
  if (_pingTimer)     { clearInterval(_pingTimer);    _pingTimer     = null; }
  if (_recoveryTimer) { clearTimeout(_recoveryTimer); _recoveryTimer = null; }
};

// Schedule a recovery probe (call in useEffect when circuitState turns 'open')
export const schedule{{Name}}Recovery = () => (dispatch) => {
  if (_recoveryTimer) clearTimeout(_recoveryTimer);
  _recoveryTimer = setTimeout(() => {
    dispatch(set{{Name}}CircuitState('half_open'));
    dispatch(ping{{Name}}Health());
  }, RECOVERY_TIMEOUT);
};

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    data: [],
    loading: false,
    error: null,
    success: false,

    // Circuit breaker state
    circuitState: 'closed',      // 'closed' | 'open' | 'half_open'
    consecutiveFailures: 0,
    consecutiveSuccesses: 0,
    serverStatus: 'unknown',     // 'healthy' | 'degraded' | 'down' | 'unknown'
    lastPingAt: null,
    latencyMs: null,
    blockedCount: 0,             // how many requests were blocked while open
  },
  reducers: {
    set{{Name}}CircuitState: (state, action) => {
      state.circuitState = action.payload;
    },
    reset{{Name}}Status: (state) => {
      state.success = false;
      state.error   = null;
    },
    reset{{Name}}Circuit: (state) => {
      state.circuitState        = 'closed';
      state.consecutiveFailures = 0;
      state.consecutiveSuccesses = 0;
      state.serverStatus        = 'unknown';
      state.blockedCount        = 0;
    },
  },
  extraReducers: (builder) => {
    builder
      // ── Health ping ────────────────────────────────────────────────────────
      .addCase(ping{{Name}}Health.fulfilled, (state) => {
        state.lastPingAt = new Date().toISOString();
        state.latencyMs  = Date.now() - new Date(state.lastPingAt).getTime();
        state.consecutiveFailures  = 0;
        state.consecutiveSuccesses += 1;

        if (state.circuitState === 'half_open' &&
            state.consecutiveSuccesses >= SUCCESS_THRESHOLD) {
          state.circuitState = 'closed';
        }
        state.serverStatus = 'healthy';
      })
      .addCase(ping{{Name}}Health.rejected, (state, action) => {
        if (action.payload?.skipped) return;

        state.lastPingAt = new Date().toISOString();
        state.consecutiveSuccesses = 0;
        state.consecutiveFailures += 1;

        if (state.circuitState === 'half_open') {
          state.circuitState = 'open';
          state.serverStatus = 'down';
        } else if (
          state.circuitState === 'closed' &&
          state.consecutiveFailures >= FAILURE_THRESHOLD
        ) {
          state.circuitState = 'open';
          state.serverStatus = 'down';
        } else {
          state.serverStatus = state.consecutiveFailures >= 2 ? 'degraded' : state.serverStatus;
        }
      })

      // ── Guarded fetch ─────────────────────────────────────────────────────
      .addCase(fetch{{Name}}s.pending, (state) => {
        state.loading = true;
        state.error   = null;
      })
      .addCase(fetch{{Name}}s.fulfilled, (state, action) => {
        state.loading = false;
        state.data    = action.payload;
        state.success = true;
        // Successful real API call also counts as a health signal
        state.consecutiveFailures  = 0;
        state.consecutiveSuccesses += 1;
        if (state.consecutiveSuccesses >= SUCCESS_THRESHOLD) state.circuitState = 'closed';
      })
      .addCase(fetch{{Name}}s.rejected, (state, action) => {
        state.loading = false;
        if (action.payload?.blocked) {
          state.blockedCount += 1;
        } else {
          state.error = action.payload?.message || 'Request failed';
          state.consecutiveSuccesses = 0;
          state.consecutiveFailures += 1;
          if (state.consecutiveFailures >= FAILURE_THRESHOLD) {
            state.circuitState = 'open';
            state.serverStatus = 'down';
          }
        }
      });
  },
});

export const {
  set{{Name}}CircuitState,
  reset{{Name}}Status,
  reset{{Name}}Circuit,
} = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Quick-start:
//
// 1. Start circuit breaker in main.jsx (once):
//      import { start{{Name}}CircuitBreaker } from '…/{{lowerName}}Slice';
//      store.dispatch(start{{Name}}CircuitBreaker());
//
// 2. Schedule recovery probe when circuit opens (App.jsx):
//      const { circuitState } = useSelector(s => s.{{lowerName}});
//      useEffect(() => {
//        if (circuitState === 'open') dispatch(schedule{{Name}}Recovery());
//      }, [circuitState]);
//
// 3. In other slices — guard expensive calls:
//      const { circuitState } = getState().{{lowerName}};
//      if (circuitState === 'open') return rejectWithValue('Blocked by circuit breaker');
//
// 4. Show maintenance UI:
//      {circuitState === 'open'      && <Banner>⚠️ Server is under maintenance</Banner>}
//      {circuitState === 'half_open' && <Banner>🔄 Reconnecting…</Banner>}
//      {circuitState === 'closed'    && <span>🟢 {latencyMs}ms</span>}
//      {serverStatus === 'degraded'  && <Banner>⚡ Server responding slowly</Banner>}
//
// Config (top of file):
//   FAILURE_THRESHOLD = 5       consecutive fails  → open circuit
//   SUCCESS_THRESHOLD = 2       consecutive passes → close circuit (from half_open)
//   RECOVERY_TIMEOUT  = 30_000  ms → auto-probe after opening
//   PING_INTERVAL     = 10_000  ms → background health ping frequency
