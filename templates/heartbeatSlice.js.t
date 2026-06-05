import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const BASE_URL    = '{{apiUrl}}';
const HEALTH_URL  = `${BASE_URL}/health`; // change to your health-check endpoint

// ─── Circuit Breaker Config ──────────────────────────────────────────────────
const FAILURE_THRESHOLD  = 5;      // consecutive failures before opening circuit
const SUCCESS_THRESHOLD  = 2;      // consecutive successes to close circuit from half-open
const RECOVERY_TIMEOUT   = 30_000; // ms to wait before trying half-open
const HEARTBEAT_INTERVAL = 5_000;  // ms between pings

// Circuit states:
//   closed    → normal — all requests pass through
//   open      → tripped — all requests blocked, show maintenance UI
//   half_open → probing — one test request allowed; close on success, re-open on fail

let _heartbeatTimer = null;
let _recoveryTimer  = null;

// ─── Thunks ─────────────────────────────────────────────────────────────────

export const pingServer = createAsyncThunk(
  '{{lowerName}}/ping',
  async (_, { getState, dispatch, rejectWithValue }) => {
    const { circuitState } = getState().{{lowerName}};

    // In half_open: one probe allowed; if open: skip ping (recovery timer handles it)
    if (circuitState === 'open') {
      return rejectWithValue({ skipped: true });
    }

    try {
      const response = await axios.get(HEALTH_URL, { timeout: 5000 });
      return { status: response.status, latencyMs: Date.now() };
    } catch (error) {
      return rejectWithValue({
        skipped: false,
        message: error.response?.data?.message || error.message,
        statusCode: error.response?.status,
      });
    }
  }
);

// Start periodic heartbeat — call once in app entry point
export const startHeartbeat = () => (dispatch) => {
  if (_heartbeatTimer) clearInterval(_heartbeatTimer);
  dispatch(pingServer()); // immediate first ping
  _heartbeatTimer = setInterval(() => dispatch(pingServer()), HEARTBEAT_INTERVAL);
};

export const stopHeartbeat = () => () => {
  if (_heartbeatTimer) { clearInterval(_heartbeatTimer); _heartbeatTimer = null; }
  if (_recoveryTimer)  { clearTimeout(_recoveryTimer);  _recoveryTimer  = null; }
};

// Manually probe after circuit opened (also called by recovery timer)
export const probeRecovery = () => (dispatch) => {
  dispatch(set{{Name}}CircuitState('half_open'));
  dispatch(pingServer());
};

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    circuitState: 'closed',    // 'closed' | 'open' | 'half_open'
    consecutiveFailures: 0,
    consecutiveSuccesses: 0,
    lastPingAt: null,          // ISO timestamp of last ping
    lastSuccessAt: null,
    latencyMs: null,           // last successful ping latency
    serverStatus: 'unknown',   // 'healthy' | 'degraded' | 'down' | 'unknown'
    pingError: null,
  },
  reducers: {
    set{{Name}}CircuitState: (state, action) => {
      state.circuitState = action.payload;
    },
    // Use this to guard API calls from other slices
    // Example: if (getState().{{lowerName}}.circuitState === 'open') return;
  },
  extraReducers: (builder) => {
    builder
      .addCase(pingServer.fulfilled, (state, action) => {
        const now = new Date().toISOString();
        state.lastPingAt     = now;
        state.lastSuccessAt  = now;
        state.latencyMs      = Date.now() - new Date(now).getTime();
        state.pingError      = null;
        state.consecutiveFailures = 0;
        state.consecutiveSuccesses += 1;

        if (state.circuitState === 'half_open') {
          // Enough successes — close the circuit (server recovered)
          if (state.consecutiveSuccesses >= SUCCESS_THRESHOLD) {
            state.circuitState = 'closed';
            state.serverStatus = 'healthy';
          }
        } else {
          state.serverStatus = 'healthy';
        }
      })

      .addCase(pingServer.rejected, (state, action) => {
        if (action.payload?.skipped) return; // circuit was open — skip counting

        state.lastPingAt = new Date().toISOString();
        state.consecutiveSuccesses = 0;
        state.consecutiveFailures += 1;
        state.pingError = action.payload?.message || 'Ping failed';

        if (state.circuitState === 'half_open') {
          // Probe failed — re-open circuit and schedule another recovery probe
          state.circuitState = 'open';
          state.serverStatus = 'down';
          if (_recoveryTimer) clearTimeout(_recoveryTimer);
          // Note: dispatch not available here; component/effect should call probeRecovery
        } else if (
          state.circuitState === 'closed' &&
          state.consecutiveFailures >= FAILURE_THRESHOLD
        ) {
          // Trip the circuit breaker
          state.circuitState = 'open';
          state.serverStatus = 'down';
        } else {
          state.serverStatus = state.consecutiveFailures >= 2 ? 'degraded' : 'healthy';
        }
      });
  },
});

export const { set{{Name}}CircuitState } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Quick-start:
//
// 1. Start heartbeat in main.jsx (once):
//      import { startHeartbeat, probeRecovery } from '…/{{lowerName}}Slice';
//      store.dispatch(startHeartbeat());
//
// 2. Guard API calls in other slices:
//      const { circuitState } = getState().{{lowerName}};
//      if (circuitState === 'open') return rejectWithValue('Server unavailable');
//
// 3. Auto-probe recovery when circuit opens (in App.jsx):
//      useEffect(() => {
//        if (circuitState === 'open') {
//          const timer = setTimeout(() => dispatch(probeRecovery()), 30_000);
//          return () => clearTimeout(timer);
//        }
//      }, [circuitState]);
//
// 4. Show maintenance banner:
//      const { circuitState, serverStatus, latencyMs } = useSelector(s => s.{{lowerName}});
//      {circuitState === 'open' && <Banner>Server ခေတ္တ ပြုပြင်နေပါသည်</Banner>}
//      {circuitState === 'half_open' && <Banner type="warning">ပြန်ချိတ်ဆက်နေသည်…</Banner>}
//      {circuitState === 'closed' && <span>🟢 {latencyMs}ms</span>}
//
// Config (customize at top of file):
//   FAILURE_THRESHOLD  = 5      consecutive fails  → open circuit
//   SUCCESS_THRESHOLD  = 2      consecutive passes → close circuit (from half_open)
//   RECOVERY_TIMEOUT   = 30_000 ms → wait before probing
//   HEARTBEAT_INTERVAL = 5_000  ms → ping frequency
//   HEALTH_URL         = BASE_URL + '/health'  → your health endpoint
