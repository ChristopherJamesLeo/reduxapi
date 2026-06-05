import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import axios from 'axios';

const API_URL = '{{apiUrl}}/{{lowerName}}';

// ─── AES-256-GCM Encryption (Web Crypto API — zero dependencies) ─────────────
//
// Set your encryption key in .env:
//   REACT_APP_STORE_KEY=your-strong-secret-key
//
// WARNING: Never commit the key. Change the default before production.

const PASSPHRASE = typeof process !== 'undefined'
  ? (process.env.REACT_APP_STORE_KEY || '{{lowerName}}-dev-key-change-in-prod')
  : '{{lowerName}}-dev-key-change-in-prod';

const STORAGE_SALT = '{{lowerName}}_aes_salt_v1'; // change to rotate all stored data
const IV_LENGTH    = 12; // bytes — AES-GCM standard
const ITERATIONS   = 100_000;

const _enc = new TextEncoder();
const _dec = new TextDecoder();

const deriveKey = async () => {
  const raw = await crypto.subtle.importKey(
    'raw', _enc.encode(PASSPHRASE), 'PBKDF2', false, ['deriveKey']
  );
  return crypto.subtle.deriveKey(
    { name: 'PBKDF2', salt: _enc.encode(STORAGE_SALT), iterations: ITERATIONS, hash: 'SHA-256' },
    raw,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt']
  );
};

const encryptData = async (data) => {
  const key = await deriveKey();
  const iv  = crypto.getRandomValues(new Uint8Array(IV_LENGTH));
  const enc = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    _enc.encode(JSON.stringify(data))
  );
  const buf = new Uint8Array(IV_LENGTH + enc.byteLength);
  buf.set(iv);
  buf.set(new Uint8Array(enc), IV_LENGTH);
  return btoa(String.fromCharCode(...buf)); // base64 ciphertext
};

const decryptData = async (ciphertext) => {
  const key  = await deriveKey();
  const buf  = Uint8Array.from(atob(ciphertext), c => c.charCodeAt(0));
  const iv   = buf.slice(0, IV_LENGTH);
  const data = buf.slice(IV_LENGTH);
  const dec  = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, data);
  return JSON.parse(_dec.decode(dec));
};

// ─── Thunks ─────────────────────────────────────────────────────────────────

// Fetch from API → encrypt → store ciphertext in Redux + sessionStorage
export const load{{Name}} = createAsyncThunk(
  '{{lowerName}}/load',
  async (params = {}, { rejectWithValue }) => {
    try {
      const response = await axios.get(API_URL, { params });
      const raw = response.data.data ?? response.data;
      const ciphertext = await encryptData(raw);
      // Also persist to sessionStorage (cleared on tab close)
      sessionStorage.setItem('{{lowerName}}_enc', ciphertext);
      return ciphertext;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// Decrypt stored ciphertext → put plaintext in state.data (memory only)
export const unlock{{Name}} = createAsyncThunk(
  '{{lowerName}}/unlock',
  async (_, { getState, rejectWithValue }) => {
    try {
      const cipher = getState().{{lowerName}}.encryptedData
        || sessionStorage.getItem('{{lowerName}}_enc');
      if (!cipher) return rejectWithValue('No encrypted data found');
      return await decryptData(cipher);
    } catch {
      return rejectWithValue('Decryption failed — invalid key or corrupted data');
    }
  }
);

// Save sensitive form data → encrypt → PATCH/POST
export const save{{Name}} = createAsyncThunk(
  '{{lowerName}}/save',
  async ({ id, data }, { rejectWithValue }) => {
    try {
      const url = id ? `${API_URL}/${id}` : API_URL;
      const method = id ? 'patch' : 'post';
      const response = await axios[method](url, data);
      const saved = response.data.data ?? response.data;
      const ciphertext = await encryptData(saved);
      sessionStorage.setItem('{{lowerName}}_enc', ciphertext);
      return ciphertext;
    } catch (error) {
      return rejectWithValue(error.response?.data?.message || error.message);
    }
  }
);

// ─── Slice ───────────────────────────────────────────────────────────────────

const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    encryptedData: sessionStorage.getItem('{{lowerName}}_enc') || null, // persists in tab
    data: null,       // decrypted — in-memory only, never touches localStorage
    locked: true,     // false once unlock{{Name}}() succeeds
    loading: false,
    error: null,
  },
  reducers: {
    // Wipe decrypted data from memory (call on logout or sensitive screen exit)
    lock{{Name}}: (state) => {
      state.data = null;
      state.locked = true;
    },
    // Wipe everything including the encrypted copy
    purge{{Name}}: (state) => {
      state.encryptedData = null;
      state.data = null;
      state.locked = true;
      sessionStorage.removeItem('{{lowerName}}_enc');
    },
  },
  extraReducers: (builder) => {
    builder
      // Load (fetch + encrypt + store ciphertext)
      .addCase(load{{Name}}.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(load{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.encryptedData = action.payload;
        state.locked = true; // data is encrypted — still locked until unlock() called
      })
      .addCase(load{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      // Unlock (decrypt ciphertext → data in memory)
      .addCase(unlock{{Name}}.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(unlock{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.data = action.payload;
        state.locked = false;
      })
      .addCase(unlock{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      })

      // Save (mutate + re-encrypt)
      .addCase(save{{Name}}.pending, (state) => { state.loading = true; state.error = null; })
      .addCase(save{{Name}}.fulfilled, (state, action) => {
        state.loading = false;
        state.encryptedData = action.payload;
        state.locked = true; // re-lock after save
        state.data = null;
      })
      .addCase(save{{Name}}.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload;
      });
  },
});

export const { lock{{Name}}, purge{{Name}} } = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Quick-start:
//
// 1. Set key in .env:
//      REACT_APP_STORE_KEY=my-super-secret-256bit-key
//
// 2. Load + encrypt on mount:
//      dispatch(load{{Name}}());
//
// 3. Decrypt for display (e.g. when user enters PIN / opens sensitive section):
//      dispatch(unlock{{Name}}());
//      const { data, locked } = useSelector(s => s.{{lowerName}});
//      if (!locked) return <div>{data.creditCard}</div>;
//
// 4. Lock on exit:
//      dispatch(lock{{Name}}());   // wipes data from memory, keeps ciphertext
//      dispatch(purge{{Name}}());  // wipes everything incl. sessionStorage
//
// Security notes:
//   • data (decrypted)     → lives only in Redux memory, never written to disk
//   • encryptedData        → AES-256-GCM ciphertext stored in sessionStorage
//   • sessionStorage       → cleared automatically when the browser tab closes
//   • REACT_APP_STORE_KEY  → bundle-time constant; use a backend-issued key for
//                            maximum security in production
