import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL       = '{{apiUrl}}';
const IDLE_TIMEOUT  = 5 * 60 * 1000; // 5 minutes of no activity → auto logout
const WARNING_BEFORE = 60_000;        // show warning 60s before logout
const ACTIVITY_EVENTS = ['mousemove', 'keydown', 'mousedown', 'touchstart', 'scroll', 'click'];

let _idleTimer    = null;
let _warnTimer    = null;

// ─── Thunks ─────────────────────────────────────────────────────────────────

export const logout{{Name}} = createAsyncThunk(
  '{{lowerName}}/logout',
  async (_, { rejectWithValue }) => {
    try {
      await axios.post(`${API_URL}/logout`);
      return true;
    } catch (error) {
      // Even if the server call fails, clear local session
      return true;
    }
  }
);

// ─── Timer helpers (called from thunk-action / component) ────────────────────

const clearTimers = () => {
  if (_idleTimer) { clearTimeout(_idleTimer); _idleTimer = null; }
  if (_warnTimer) { clearTimeout(_warnTimer); _warnTimer = null; }
};

// Start (or reset) idle timers — dispatched on every activity event
export const reset{{Name}}IdleTimer = () => (dispatch, getState) => {
  const { sessionActive } = getState().{{lowerName}};
  if (!sessionActive) return; // already logged out

  clearTimers();
  dispatch(set{{Name}}Warning(false));

  // Warning countdown starts IDLE_TIMEOUT - WARNING_BEFORE ms after last activity
  _warnTimer = setTimeout(() => {
    dispatch(set{{Name}}Warning(true));
  }, IDLE_TIMEOUT - WARNING_BEFORE);

  // Auto-logout after full idle timeout
  _idleTimer = setTimeout(() => {
    dispatch(logout{{Name}}());
  }, IDLE_TIMEOUT);
};

// Register activity listeners — call once in app entry point after login
export const start{{Name}}IdleWatcher = () => (dispatch) => {
  const onActivity = () => dispatch(reset{{Name}}IdleTimer());

  ACTIVITY_EVENTS.forEach(evt => window.addEventListener(evt, onActivity, { passive: true }));

  dispatch(reset{{Name}}IdleTimer()); // start the first timer immediately

  return () => {
    ACTIVITY_EVENTS.forEach(evt => window.removeEventListener(evt, onActivity));
    clearTimers();
  };
};

// Stop watching (call on manual logout or session end)
export const stop{{Name}}IdleWatcher = () => () => clearTimers();

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    sessionActive: false,   // true after successful login
    showingWarning: false,  // true during the last WARNING_BEFORE ms countdown
    loggedOutReason: null,  // 'idle' | 'manual' | null
    logoutLoading: false,
    error: null,

    // Optional: track session metadata
    loginAt: null,          // ISO timestamp of session start
    lastActivityAt: null,   // ISO timestamp of most recent user activity
  },
  reducers: {
    set{{Name}}SessionActive: (state, action) => {
      state.sessionActive   = action.payload;
      state.loggedOutReason = null;
      state.showingWarning  = false;
      if (action.payload) state.loginAt = new Date().toISOString();
    },
    set{{Name}}Warning: (state, action) => {
      state.showingWarning = action.payload;
    },
    record{{Name}}Activity: (state) => {
      state.lastActivityAt = new Date().toISOString();
      state.showingWarning = false;
    },
    reset{{Name}}Status: (state) => {
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(logout{{Name}}.pending, (state) => {
        state.logoutLoading = true;
      })
      .addCase(logout{{Name}}.fulfilled, (state) => {
        state.logoutLoading   = false;
        state.sessionActive   = false;
        state.showingWarning  = false;
        state.loggedOutReason = 'idle';
        state.loginAt         = null;
        clearTimers();
        // Clear sensitive local data
        try {
          sessionStorage.clear();
          localStorage.removeItem('{{lowerName}}_token');
        } catch {}
      })
      .addCase(logout{{Name}}.rejected, (state, action) => {
        // Still end the session locally even on server error
        state.logoutLoading   = false;
        state.sessionActive   = false;
        state.loggedOutReason = 'idle';
        clearTimers();
      });
  },
});

export const {
  set{{Name}}SessionActive,
  set{{Name}}Warning,
  record{{Name}}Activity,
  reset{{Name}}Status,
} = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Quick-start:
//
// 1. After successful login — mark session active and start watching:
//      dispatch(set{{Name}}SessionActive(true));
//      store.dispatch(start{{Name}}IdleWatcher());
//
// 2. On manual logout — stop watcher first:
//      dispatch(stop{{Name}}IdleWatcher());
//      dispatch(logout{{Name}}());
//      dispatch(set{{Name}}SessionActive(false));
//
// 3. Show idle warning modal (60s countdown before auto-logout):
//      const { showingWarning, sessionActive } = useSelector(s => s.{{lowerName}});
//      {showingWarning && (
//        <Modal>
//          <p>⏳ You will be logged out in 60 seconds due to inactivity</p>
//          <button onClick={() => dispatch(reset{{Name}}IdleTimer())}>Stay logged in</button>
//          <button onClick={() => dispatch(logout{{Name}}())}>Log out now</button>
//        </Modal>
//      )}
//
// 4. Show "Logged out due to inactivity" message on login page:
//      const { loggedOutReason } = useSelector(s => s.{{lowerName}});
//      {loggedOutReason === 'idle' && (
//        <Alert>You were automatically logged out due to inactivity</Alert>
//      )}
//
// Config (top of file):
//   IDLE_TIMEOUT   = 5 * 60 * 1000   ms of inactivity → auto logout (default 5 min)
//   WARNING_BEFORE = 60_000           ms before logout to show warning modal
//   ACTIVITY_EVENTS                   browser events that reset the timer
