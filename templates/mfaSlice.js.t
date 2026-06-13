import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL       = '{{apiUrl}}';
const OTP_LENGTH    = 6;      // digits expected from user
const OTP_EXPIRES   = 60;     // seconds before OTP code expires / resend allowed
const MAX_ATTEMPTS  = 3;      // wrong OTP attempts before lockout
const LOCKOUT_SEC   = 300;    // 5 minutes lockout after max attempts

let _countdownTimer = null;
let _lockoutTimer   = null;

// ─── Thunks ─────────────────────────────────────────────────────────────────

// Step 1: Primary login — returns a sessionToken if MFA is required
export const primary{{Name}}Login = createAsyncThunk(
  '{{lowerName}}/primaryLogin',
  async ({ username, password }, { rejectWithValue }) => {
    try {
      const response = await axios.post(`${API_URL}/auth/login`, { username, password });
      // Server should return: { mfaRequired: true, sessionToken: '…', method: 'totp'|'sms'|'email' }
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Step 2: Submit OTP code
export const verify{{Name}}Otp = createAsyncThunk(
  '{{lowerName}}/verifyOtp',
  async ({ otp, sessionToken }, { getState, rejectWithValue }) => {
    const { lockedUntil } = getState().{{lowerName}};
    if (lockedUntil && Date.now() < lockedUntil) {
      const remaining = Math.ceil((lockedUntil - Date.now()) / 1000);
      return rejectWithValue(`အကောင့် ယာယီ ပိတ်ဆို့ထားသည်။ ${remaining}s ကျော်မှ ထပ်ကြိုးစားပါ`);
    }
    if (!otp || otp.length !== OTP_LENGTH) {
      return rejectWithValue(`OTP ${OTP_LENGTH} လုံး ထည့်သွင်းပါ`);
    }

    try {
      const response = await axios.post(`${API_URL}/auth/mfa/verify`, {
        otp,
        sessionToken,
      });
      // Server should return: { accessToken, refreshToken, user }
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Resend / regenerate OTP (SMS or email)
export const resend{{Name}}Otp = createAsyncThunk(
  '{{lowerName}}/resendOtp',
  async (sessionToken, { getState, rejectWithValue }) => {
    const { otpCountdown } = getState().{{lowerName}};
    if (otpCountdown > 0) {
      return rejectWithValue(`${otpCountdown}s ကျော်မှ ထပ်တောင်းနိုင်သည်`);
    }
    try {
      const response = await axios.post(`${API_URL}/auth/mfa/resend`, { sessionToken });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Setup TOTP — returns a QR code URI for authenticator apps
export const setup{{Name}}Totp = createAsyncThunk(
  '{{lowerName}}/setupTotp',
  async (_, { rejectWithValue }) => {
    try {
      const response = await axios.post(`${API_URL}/auth/mfa/setup`);
      // Server returns: { secret, qrUri, backupCodes }
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Confirm TOTP setup — user scans QR, then submits a code to prove it works
export const confirm{{Name}}TotpSetup = createAsyncThunk(
  '{{lowerName}}/confirmTotpSetup',
  async ({ otp, secret }, { rejectWithValue }) => {
    try {
      const response = await axios.post(`${API_URL}/auth/mfa/setup/confirm`, { otp, secret });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Disable MFA (requires password re-confirmation)
export const disable{{Name}}Mfa = createAsyncThunk(
  '{{lowerName}}/disableMfa',
  async ({ password }, { rejectWithValue }) => {
    try {
      const response = await axios.post(`${API_URL}/auth/mfa/disable`, { password });
      return response.data;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// ─── Countdown helpers ───────────────────────────────────────────────────────

// Start 60s OTP expiry countdown — call after sendingOtp succeeds
export const start{{Name}}OtpCountdown = () => (dispatch) => {
  if (_countdownTimer) clearInterval(_countdownTimer);
  dispatch(set{{Name}}OtpCountdown(OTP_EXPIRES));

  _countdownTimer = setInterval(() => {
    dispatch(tick{{Name}}OtpCountdown());
  }, 1000);
};

export const stop{{Name}}OtpCountdown = () => () => {
  if (_countdownTimer) { clearInterval(_countdownTimer); _countdownTimer = null; }
};

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    // MFA flow state
    step: 'idle',             // 'idle' | 'pending_otp' | 'verified' | 'setup' | 'setup_confirmed'
    sessionToken: null,       // short-lived token from step-1 login, passed to OTP verify
    mfaMethod: null,          // 'totp' | 'sms' | 'email'
    mfaEnabled: false,        // whether user has MFA enabled on their account

    // OTP countdown
    otpCountdown: 0,          // seconds remaining before resend is allowed

    // Attempt tracking / lockout
    failedAttempts: 0,
    lockedUntil: null,        // epoch ms — null means not locked

    // TOTP setup
    totpSecret: null,         // raw secret (show to user for manual entry)
    totpQrUri: null,          // otpauth:// URI → render as QR code
    backupCodes: [],          // one-time backup codes — show once, then hide

    // Auth result (set after successful MFA)
    accessToken: null,
    user: null,

    // Loading / error
    loading: false,
    verifying: false,
    resending: false,
    setupLoading: false,
    error: null,
    success: false,
  },
  reducers: {
    set{{Name}}OtpCountdown: (state, action) => {
      state.otpCountdown = action.payload;
    },
    tick{{Name}}OtpCountdown: (state) => {
      if (state.otpCountdown > 0) state.otpCountdown -= 1;
      if (state.otpCountdown === 0 && _countdownTimer) {
        clearInterval(_countdownTimer);
        _countdownTimer = null;
      }
    },
    reset{{Name}}Mfa: (state) => {
      state.step          = 'idle';
      state.sessionToken  = null;
      state.failedAttempts = 0;
      state.otpCountdown  = 0;
      state.error         = null;
      state.success       = false;
      if (_countdownTimer) { clearInterval(_countdownTimer); _countdownTimer = null; }
    },
    clear{{Name}}Tokens: (state) => {
      state.totpSecret  = null;
      state.totpQrUri   = null;
      state.backupCodes = [];
    },
    reset{{Name}}Status: (state) => {
      state.error   = null;
      state.success = false;
    },
  },
  extraReducers: (builder) => {
    builder
      // ── Step 1: Primary login ─────────────────────────────────────────────
      .addCase(primary{{Name}}Login.pending, (state) => {
        state.loading = true;
        state.error   = null;
      })
      .addCase(primary{{Name}}Login.fulfilled, (state, action) => {
        state.loading = false;
        if (action.payload.mfaRequired) {
          state.step         = 'pending_otp';
          state.sessionToken = action.payload.sessionToken;
          state.mfaMethod    = action.payload.method ?? 'totp';
        } else {
          // MFA not required for this account — treat as direct login
          state.step        = 'verified';
          state.accessToken = action.payload.accessToken;
          state.user        = action.payload.user;
          state.success     = true;
        }
      })
      .addCase(primary{{Name}}Login.rejected, (state, action) => {
        state.loading = false;
        state.error   = action.payload;
      })

      // ── Step 2: OTP verify ────────────────────────────────────────────────
      .addCase(verify{{Name}}Otp.pending, (state) => {
        state.verifying = true;
        state.error     = null;
      })
      .addCase(verify{{Name}}Otp.fulfilled, (state, action) => {
        state.verifying      = false;
        state.step           = 'verified';
        state.accessToken    = action.payload.accessToken;
        state.user           = action.payload.user;
        state.failedAttempts = 0;
        state.lockedUntil    = null;
        state.sessionToken   = null; // consumed
        state.success        = true;
        if (_countdownTimer) { clearInterval(_countdownTimer); _countdownTimer = null; }
      })
      .addCase(verify{{Name}}Otp.rejected, (state, action) => {
        state.verifying   = false;
        state.error       = action.payload;
        state.failedAttempts += 1;

        if (state.failedAttempts >= MAX_ATTEMPTS) {
          state.lockedUntil    = Date.now() + LOCKOUT_SEC * 1000;
          state.failedAttempts = 0;
          if (_lockoutTimer) clearTimeout(_lockoutTimer);
          _lockoutTimer = setTimeout(() => {
            // Note: components should dispatch clearLockout or re-check lockedUntil
          }, LOCKOUT_SEC * 1000);
        }
      })

      // ── Resend OTP ────────────────────────────────────────────────────────
      .addCase(resend{{Name}}Otp.pending, (state) => {
        state.resending = true;
        state.error     = null;
      })
      .addCase(resend{{Name}}Otp.fulfilled, (state) => {
        state.resending  = false;
        state.otpCountdown = OTP_EXPIRES; // countdown resets
      })
      .addCase(resend{{Name}}Otp.rejected, (state, action) => {
        state.resending = false;
        state.error     = action.payload;
      })

      // ── TOTP Setup ────────────────────────────────────────────────────────
      .addCase(setup{{Name}}Totp.pending, (state) => {
        state.setupLoading = true;
        state.error        = null;
        state.step         = 'setup';
      })
      .addCase(setup{{Name}}Totp.fulfilled, (state, action) => {
        state.setupLoading = false;
        state.totpSecret   = action.payload.secret;
        state.totpQrUri    = action.payload.qrUri;
        state.backupCodes  = action.payload.backupCodes ?? [];
      })
      .addCase(setup{{Name}}Totp.rejected, (state, action) => {
        state.setupLoading = false;
        state.error        = action.payload;
        state.step         = 'idle';
      })

      // ── Confirm TOTP setup ────────────────────────────────────────────────
      .addCase(confirm{{Name}}TotpSetup.pending, (state) => {
        state.setupLoading = true;
        state.error        = null;
      })
      .addCase(confirm{{Name}}TotpSetup.fulfilled, (state) => {
        state.setupLoading = false;
        state.mfaEnabled   = true;
        state.step         = 'setup_confirmed';
        state.totpSecret   = null; // clear — no longer needed
        state.success      = true;
      })
      .addCase(confirm{{Name}}TotpSetup.rejected, (state, action) => {
        state.setupLoading = false;
        state.error        = action.payload;
      })

      // ── Disable MFA ───────────────────────────────────────────────────────
      .addCase(disable{{Name}}Mfa.pending, (state) => {
        state.loading = true;
        state.error   = null;
      })
      .addCase(disable{{Name}}Mfa.fulfilled, (state) => {
        state.loading    = false;
        state.mfaEnabled = false;
        state.step       = 'idle';
        state.success    = true;
      })
      .addCase(disable{{Name}}Mfa.rejected, (state, action) => {
        state.loading = false;
        state.error   = action.payload;
      });
  },
});

export const {
  set{{Name}}OtpCountdown,
  tick{{Name}}OtpCountdown,
  reset{{Name}}Mfa,
  clear{{Name}}Tokens,
  reset{{Name}}Status,
} = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Quick-start:
//
// ── Login flow (2-step) ──────────────────────────────────────────────────────
//
// Step 1 — primary credential check:
//   dispatch(primaryMfaLogin({ username, password }));
//   → if mfaRequired: state.step = 'pending_otp', navigate to OTP screen
//   → if not required: state.step = 'verified', proceed normally
//
// Step 2 — OTP entry screen:
//   const { step, mfaMethod, otpCountdown, failedAttempts, lockedUntil, verifying } =
//     useSelector(s => s.mfa);
//
//   useEffect(() => {
//     if (step === 'pending_otp') dispatch(startMfaOtpCountdown());
//   }, [step]);
//
//   const handleVerify = () =>
//     dispatch(verifyMfaOtp({ otp, sessionToken: state.mfa.sessionToken }));
//
//   const handleResend = () => {
//     dispatch(resendMfaOtp(state.mfa.sessionToken));
//     dispatch(startMfaOtpCountdown());
//   };
//
//   JSX:
//   <input maxLength={6} placeholder="6-digit code" ... />
//
//   {otpCountdown > 0
//     ? <span>OTP သက်တမ်း: {otpCountdown}s</span>
//     : <button onClick={handleResend}>OTP ထပ်တောင်းရန်</button>}
//
//   {lockedUntil && Date.now() < lockedUntil && (
//     <Alert>အကြိမ် {MAX_ATTEMPTS} ကြိမ် မမှန်ပါ။ ယာယီ ပိတ်ဆို့ထားသည်</Alert>
//   )}
//
// ── TOTP Setup flow ──────────────────────────────────────────────────────────
//
//   dispatch(setupMfaTotp());
//   // → state.totpQrUri — render with any QR library: <QRCode value={totpQrUri} />
//   // → state.totpSecret — show for manual entry
//   // → state.backupCodes — display once, user must save them
//
//   dispatch(confirmMfaTotpSetup({ otp: userEnteredCode, secret: state.mfa.totpSecret }));
//   // → state.mfaEnabled = true, step = 'setup_confirmed'
//
//   // After showing backup codes, clear sensitive setup data:
//   dispatch(clearMfaTokens());
//
// ── Disable MFA ──────────────────────────────────────────────────────────────
//
//   dispatch(disableMfaMfa({ password: currentPassword }));
//   // → state.mfaEnabled = false
//
// Config (top of file):
//   OTP_LENGTH    = 6        digits expected
//   OTP_EXPIRES   = 60       seconds before resend is allowed
//   MAX_ATTEMPTS  = 3        wrong OTP attempts before lockout
//   LOCKOUT_SEC   = 300      seconds locked after max attempts (5 min)
