# @james/reduxapi-helper-cli

A CLI tool that generates Redux Toolkit API slices and automatically wires them into your React store.

## Installation

```bash
npm install @james/reduxapi-helper-cli
```

## Requirements

Install peer dependencies in your React project:

```bash
npm install @reduxjs/toolkit react-redux axios
```

## Link with npm

```bash
npm link
```

## Usage

After installing locally, use the `reduxapi` binary:

```bash
# After npm install (local project)
npx reduxapi make:api <name> [options]

# One-time use without installing
npx @james/reduxapi-helper-cli make:api <name> [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-t, --type <type>` | Template type (see below) | `crud` |
| `-u, --url <url>` | API base URL | `https://your-api-url.com` |

### Template Types

| Type | Description |
|------|-------------|
| `crud` | Full CRUD (fetch, create, update, delete) with pagination support |
| `create` | Create-only slice |
| `token` | Full CRUD with Bearer token from localStorage |
| `auth` | Login, register, logout with localStorage |
| `customheader` | Full CRUD with custom headers (Bearer token + any extra headers) |
| `secretkey` | Full CRUD with two-step auth — fetches a secret key first, then uses it as a custom header |
| `infinite` | Fetch with cursor-based load-more / append support for infinite scrolling |
| `search` | Read-only fetch optimized for complex queries and dynamic filter combinations |
| `upload` | Create / Update with automatic `FormData` conversion for files and media |
| `polling` | Automatic background re-fetching at a set interval for real-time feel |
| `analytics` | Read-only slice structured for dashboard summary cards, charts, and metric lists |
| `optimistic` | Instant UI update before the API responds, with automatic rollback on failure |
| `cache` | Stale-While-Revalidate caching — shows cached data instantly, refreshes silently in background |
| `debounce` | Built-in debounce (search inputs) and throttle (submit buttons) to prevent API spam |
| `retry` | Auto-retry on network errors and 5xx failures with exponential back-off (up to 3 attempts) |
| `rollback` | Snapshot-based optimistic mutations — any failed API call fully restores previous state |
| `tokenrefresh` | Auto JWT refresh on 401, request queue, and retry — users never see a session-expired error |
| `offline` | Queue mutations when offline, persist to localStorage, auto-sync when network returns |
| `prefetch` | Pre-fetch item detail on hover / scroll-near so the detail page opens with zero loading time |
| `batch` | Consolidate concurrent ID-based requests into a single `?ids=1,2,3` API call within a 50 ms window |
| `dedupe` | Deduplicate in-flight requests — N simultaneous identical calls share one Promise and one API hit |
| `websocket` | Real-time Redux state via WebSocket or SSE with reconnection, event routing, and HTTP fallback |
| `stream` | SSE / Fetch streaming — appends server chunks into Redux state token-by-token (ChatGPT-style) |
| `abort` | AbortController wired into every thunk — cancel in-flight requests on unmount or navigation |
| `encrypt` | AES-256-GCM encryption via Web Crypto API — sensitive data never touches Redux unencrypted |
| `heartbeat` | Periodic server ping + Circuit Breaker — auto-blocks requests and shows maintenance UI when server is down |

## Examples

**Basic CRUD slice:**
```bash
npx reduxapi make:api Product
```
Generates `slices/productSlice.js` with `fetchProducts`, `createProduct`, `updateProduct`, `deleteProduct`.

**Bearer token CRUD:**
```bash
npx reduxapi make:api Order -t token -u https://api.example.com/orders
```
Reads `token` from `state.auth.token` and attaches `Authorization: Bearer <token>` to every request.

**Auth slice:**
```bash
npx reduxapi make:api auth -t auth -u https://api.example.com
```
Generates `authSlice.js` with `login`, `register`, `logout` thunks and persists token to `localStorage`.

**Create-only slice:**
```bash
npx reduxapi make:api ContactForm -t create -u https://api.example.com/contact
```

**Custom header CRUD:**
```bash
npx reduxapi make:api Order -t customheader -u https://api.example.com
```
Generates a slice with a `getHeaders()` helper function. Edit it to add any headers you need.

**Two-step secret key CRUD:**
```bash
npx reduxapi make:api Room -t secretkey -u https://api.yourhotel.com/v1
```
Every request automatically fetches a fresh secret key from `GET /get-secret-key` first, then sends the real request with `X-Custom-Secret-Key` in the header.

**Infinite scroll slice:**
```bash
npx reduxapi make:api Post -t infinite -u https://api.example.com
```
Appends pages to `state.data` on each load-more call. Tracks `hasMore` and `nextCursor` automatically.

**Search / filter slice:**
```bash
npx reduxapi make:api Product -t search -u https://api.example.com
```
Passes any filter object as query params. Includes `setFilters` and `clearFilters` reducers.

**File upload slice:**
```bash
npx reduxapi make:api Avatar -t upload -u https://api.example.com
```
Accepts plain objects containing `File` values and converts them to `FormData` automatically.

**Polling slice:**
```bash
npx reduxapi make:api Notification -t polling -u https://api.example.com
```
Provides `startPollingNotification(5000)` and `stopPollingNotification()` thunk helpers.

**Analytics / dashboard slice:**
```bash
npx reduxapi make:api Report -t analytics -u https://api.example.com
```
Three separate thunks — `fetchReportSummary`, `fetchReportChart`, `fetchReportMetrics` — each with its own loading flag.

**Optimistic UI slice:**
```bash
npx reduxapi make:api Task -t optimistic -u https://api.example.com
```
Updates the list immediately via `optimisticAddTask` / `optimisticUpdateTask` / `optimisticRemoveTask`, then confirms or rolls back when the API responds.

**Cache + Stale-While-Revalidate slice:**
```bash
npx reduxapi make:api Room -t cache -u https://api.example.com
```
Returns Redux-cached data instantly, then silently re-fetches in background. Shows stale data while fresh data loads — zero perceived latency.

**Debounce / Throttle slice:**
```bash
npx reduxapi make:api Hotel -t debounce -u https://api.example.com
```
Built-in `debouncedHotelSearch(dispatch, params)` (500 ms) and `throttledHotelSubmit(dispatch, data)` (2 s) helpers — no extra libraries needed.

**Auto-retry slice:**
```bash
npx reduxapi make:api Payment -t retry -u https://api.example.com
```
Every thunk silently retries up to 3 times (2 s → 4 s → 6 s) on network errors or 5xx. Only surfaces the error to the UI after all retries are exhausted.

**Snapshot rollback slice:**
```bash
npx reduxapi make:api Bookmark -t rollback -u https://api.example.com
```
Takes a deep snapshot before every optimistic mutation. On any API failure, state is fully restored to exactly what it was — no manual undo logic needed.

**Auto token-refresh slice:**
```bash
npx reduxapi make:api Auth -t tokenrefresh -u https://api.example.com
```
Generates an `apiClient` (axios instance) + `setupApiInterceptors(store)`. On 401, silently refreshes the token and retries the original request. Concurrent requests are queued and replayed automatically.

**Offline sync slice:**
```bash
npx reduxapi make:api Booking -t offline -u https://api.example.com
```
Queues all mutations (create/update/delete) to localStorage when offline. Auto-syncs when network returns. Items show `_queued: true` in the UI until confirmed.

**Optimistic pre-fetch slice:**
```bash
npx reduxapi make:api Room -t prefetch -u https://api.example.com
```
Call `dispatch(prefetchRoom(id))` on `onMouseEnter` or `IntersectionObserver`. When the user actually navigates to the detail page, data is already in cache — 0 ms loading time.

**Batching slice:**
```bash
npx reduxapi make:api User -t batch -u https://api.example.com
```
Three components each call `dispatch(requestUser(id))` within 50 ms — only one request fires: `GET /user?ids=1,2,3`. Backend must accept a comma-separated `ids` param.

**Deduplication slice:**
```bash
npx reduxapi make:api Settings -t dedupe -u https://api.example.com
```
Sidebar, Header, and Footer all call `dispatch(fetchSettings())` on mount — only one API call is made. All three components receive the same response once it resolves.

**WebSocket / SSE slice:**
```bash
npx reduxapi make:api Room -t websocket -u https://api.example.com
```
Connects a WebSocket (or SSE) stream. Incoming events (`room.created`, `room.updated`, `room.deleted`) are routed directly into Redux state — no polling, no refresh button needed.

**Data streaming slice:**
```bash
npx reduxapi make:api Chat -t stream -u https://api.example.com
```
Supports both `EventSource` (SSE GET) and `fetch`-based streaming (POST body). Appends tokens one-by-one into `state.streamText` — ideal for LLM/ChatGPT-style output.

**Abort / cancellation slice:**
```bash
npx reduxapi make:api Report -t abort -u https://api.example.com
```
Every thunk receives RTK's `signal` and passes it to axios. Call `promise.abort()` in `useEffect` cleanup to cancel in-flight requests on unmount — prevents memory leaks and race conditions.

**Encrypted state slice:**
```bash
npx reduxapi make:api Profile -t encrypt -u https://api.example.com
```
Fetched data is AES-256-GCM encrypted before entering Redux state. Plaintext lives only in memory after calling `unlockProfile()`. `purgeProfile()` wipes everything including sessionStorage.

**Heartbeat + Circuit Breaker slice:**
```bash
npx reduxapi make:api System -t heartbeat -u https://api.example.com
```
Pings `GET /health` every 5 s. After 5 consecutive failures the circuit opens — all API calls can check `circuitState === 'open'` to bail early. Auto-probes recovery after 30 s.

## How It Works

1. Generates a slice file inside `node_modules/@james/reduxapi-helper-cli/slices/`.
2. Automatically adds the import and reducer entry to `src/store/store.js` in your project (creates the file if it doesn't exist).

### Example — importing in your React components

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchProducts, createProduct, resetProductStatus } from '@james/reduxapi-helper-cli/slices/productSlice';

const dispatch = useDispatch();
const { data, loading, error, success } = useSelector(state => state.product);

// Fetch all
dispatch(fetchProducts());

// Create
dispatch(createProduct({ name: 'New Product', price: 99 }));

// Reset success/error flags
dispatch(resetProductStatus());
```

### Auth slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import { login, logout, clearAuthError } from '@james/reduxapi-helper-cli/slices/authSlice';

const dispatch = useDispatch();
const { user, isAuthenticated, loading, error } = useSelector(state => state.auth);

dispatch(login({ email: 'user@example.com', password: 'secret' }));
dispatch(logout());
```

### Secret key slice usage

This template uses a **two-step request pattern**:

```
Step 1 →  GET /get-secret-key          → receives { secret_key: "abc123" }
Step 2 →  GET /room  (+ X-Custom-Secret-Key: abc123)  → receives real data
```

Every thunk (`fetch`, `fetchPaginated`, `create`, `update`, `delete`) repeats both steps automatically so the key is always fresh.

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchRooms,
  fetchPaginatedRooms,
  createRoom,
  updateRoom,
  deleteRoom,
  resetRoomStatus,
} from '@james/reduxapi-helper-cli/slices/roomSlice';

const dispatch = useDispatch();
const { data, links, meta, loading, error, success } = useSelector(state => state.room);

// Fetch all
dispatch(fetchRooms());

// Fetch with pagination
dispatch(fetchPaginatedRooms(1));
dispatch(fetchPaginatedRooms(meta.current_page + 1)); // next page

// CRUD
dispatch(createRoom({ room_no: '201', room_type: 'SUITE', price_per_night: '300 AED' }));
dispatch(updateRoom({ id: 1, updateData: { price_per_night: '350 AED' } }));
dispatch(deleteRoom(1));
dispatch(resetRoomStatus());
```

To change the secret key endpoint or header name, edit these two lines in the generated slice:

```js
const SECRET_KEY_URL = `${BASE_URL}/get-secret-key`;  // ← endpoint ပြောင်း

const secureHeaders = (secretKey) => ({
  'X-Custom-Secret-Key': secretKey,                    // ← header name ပြောင်း
  'Accept': 'application/json',
});
```

### Custom header slice usage

The generated slice contains a `getHeaders()` function at the top — edit it to add whatever headers your API requires:

```js
// Inside the generated slice file
const getHeaders = () => ({
  Authorization: `Bearer ${localStorage.getItem('token')}`,
  'X-App-Version': '2.0',
  'Accept-Language': 'en',
});
```

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchOrders,
  fetchPaginatedOrders,
  createOrder,
  updateOrder,
  deleteOrder,
  resetOrderStatus,
} from '@james/reduxapi-helper-cli/slices/orderSlice';

const dispatch = useDispatch();
const { data, links, meta, loading, error, success } = useSelector(state => state.order);

// Fetch all (no pagination)
dispatch(fetchOrders());

// Fetch with pagination
dispatch(fetchPaginatedOrders(1));
dispatch(fetchPaginatedOrders(meta.current_page + 1)); // next page

// CRUD
dispatch(createOrder({ item: 'Book', qty: 2 }));
dispatch(updateOrder({ id: 1, updateData: { qty: 5 } }));
dispatch(deleteOrder(1));
dispatch(resetOrderStatus());
```

### Infinite scroll slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchPosts, resetPosts } from '@james/reduxapi-helper-cli/slices/postSlice';

const dispatch = useDispatch();
const { data, hasMore, nextCursor, loading, loadingMore } = useSelector(state => state.post);

// Initial load
dispatch(fetchPosts());

// Load next page
if (hasMore) dispatch(fetchPosts({ cursor: nextCursor }));

// Reset and reload (e.g. on pull-to-refresh)
dispatch(resetPosts());
dispatch(fetchPosts());
```

### Search / filter slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import { searchProducts, setProductFilters, clearProductFilters } from '@james/reduxapi-helper-cli/slices/productSlice';

const dispatch = useDispatch();
const { data, filters, meta, loading } = useSelector(state => state.product);

// Search with params
dispatch(searchProducts({ q: 'laptop', category: 'electronics', page: 1 }));

// Save active filters to state, then search
dispatch(setProductFilters({ status: 'active' }));
dispatch(searchProducts(filters));

// Clear everything
dispatch(clearProductFilters());
```

### File upload slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import { uploadAvatar, updateUploadAvatar, resetAvatarUpload } from '@james/reduxapi-helper-cli/slices/avatarSlice';

const dispatch = useDispatch();
const { data, loading, progress, success, error } = useSelector(state => state.avatar);

// Create — mix of plain fields and File objects
dispatch(uploadAvatar({ title: 'Profile Photo', file: event.target.files[0] }));

// Update (uses POST + _method: PUT for Laravel compatibility)
dispatch(updateUploadAvatar({ id: 1, data: { title: 'New Photo', file: newFile } }));

// Reset after success
if (success) dispatch(resetAvatarUpload());
```

### Polling slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import { startPollingNotification, stopPollingNotification } from '@james/reduxapi-helper-cli/slices/notificationSlice';

const dispatch = useDispatch();
const { data, lastUpdated, loading } = useSelector(state => state.notification);

// Start polling every 5 seconds
dispatch(startPollingNotification(5000));

// Stop when component unmounts
useEffect(() => {
  dispatch(startPollingNotification(10000));
  return () => dispatch(stopPollingNotification());
}, []);
```

### Analytics / dashboard slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchReportSummary,
  fetchReportChart,
  fetchReportMetrics,
  clearReportData,
} from '@james/reduxapi-helper-cli/slices/reportSlice';

const dispatch = useDispatch();
const { summary, chart, metrics, loadingSummary, loadingChart, loadingMetrics } = useSelector(state => state.report);

// KPI cards
dispatch(fetchReportSummary({ period: 'month' }));

// Line / bar chart data
dispatch(fetchReportChart({ metric: 'revenue', range: '30d', interval: 'day' }));

// Metric breakdown table
dispatch(fetchReportMetrics({ group: 'region' }));

// Clear dashboard on unmount
dispatch(clearReportData());
```

### Cache + Stale-While-Revalidate slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchRooms,
  revalidateRooms,
  invalidateRoomCache,
} from '@james/reduxapi-helper-cli/slices/roomSlice';

const dispatch = useDispatch();
const { data, loading, revalidating, lastFetched } = useSelector(s => s.room);

// First visit: hits API, caches result for 5 minutes
dispatch(fetchRooms());

// Second visit within 5 min: returns Redux cache instantly, no API call
dispatch(fetchRooms());

// Custom TTL (10 min)
dispatch(fetchRooms({ ttl: 10 * 60 * 1000 }));

// Force a fresh fetch regardless of TTL
dispatch(fetchRooms({ force: true }));

// Silent background refresh (stale data still visible to user)
dispatch(revalidateRooms());

// Expire the cache (next fetch will always hit the API)
dispatch(invalidateRoomCache());

// UI hints
// loading      → show full-page spinner (first load only)
// revalidating → show a subtle "Refreshing…" badge (stale data still shown)
```

### Debounce / Throttle slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  debouncedHotelSearch,
  throttledHotelSubmit,
  searchHotels,
  clearHotelResults,
} from '@james/reduxapi-helper-cli/slices/hotelSlice';

const dispatch = useDispatch();
const { data, loading, submitting, success } = useSelector(s => s.hotel);

// Debounced — fires 500 ms after the user stops typing
<input onChange={(e) => debouncedHotelSearch(dispatch, { q: e.target.value })} />

// Throttled — one API call per 2 seconds even if button is clicked 10 times
<button onClick={() => throttledHotelSubmit(dispatch, formData)}>Book Now</button>

// Direct call (no debounce)
dispatch(searchHotels({ city: 'Dubai', stars: 5 }));

// Clear results
dispatch(clearHotelResults());

// state.loading    → search spinner
// state.submitting → disable button while submit is in-flight
```

### Auto-retry slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchPayments, createPayment } from '@james/reduxapi-helper-cli/slices/paymentSlice';

const dispatch = useDispatch();
const { data, loading, error } = useSelector(s => s.payment);

// Each call auto-retries up to 3 times on network errors or 5xx
dispatch(fetchPayments());
dispatch(createPayment({ amount: 500, currency: 'AED' }));

// error is only set after ALL retry attempts fail
// 4xx errors (400, 401, 422…) are NOT retried — they surface immediately
```

### Snapshot rollback slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  optimisticUpdateBookmark,
  updateBookmark,
  optimisticRemoveBookmark,
  deleteBookmark,
  optimisticAddBookmark,
  createBookmark,
} from '@james/reduxapi-helper-cli/slices/bookmarkSlice';

const dispatch = useDispatch();

// Toggle bookmark (optimistic) — auto-reverts if API returns 401/500
dispatch(optimisticUpdateBookmark({ id: 1, saved: true }));
dispatch(updateBookmark({ id: 1, updateData: { saved: true } }));

// Delete (optimistic) — item reappears if API fails
dispatch(optimisticRemoveBookmark(id));
dispatch(deleteBookmark(id));

// Create (optimistic) — temp item removed if API fails
const tempId = Date.now();
dispatch(optimisticAddBookmark({ _tempId: tempId, title: 'My Hotel' }));
dispatch(createBookmark({ _tempId: tempId, title: 'My Hotel' }));
```

### Auto token-refresh slice usage

**Step 1 — Generate the slice:**
```bash
npx reduxapi make:api Auth -t tokenrefresh -u https://api.example.com
```

**Step 2 — Wire up interceptors in `main.jsx` (once, after store is created):**
```jsx
import { store } from './store/store';
import { setupApiInterceptors } from '@james/reduxapi-helper-cli/slices/authSlice';

setupApiInterceptors(store); // ← add this line before ReactDOM.createRoot

ReactDOM.createRoot(document.getElementById('root')).render(
  <Provider store={store}><App /></Provider>
);
```

**Step 3 — Use `apiClient` in other slices instead of plain `axios`:**
```js
import { apiClient } from '@james/reduxapi-helper-cli/slices/authSlice';

// Token is attached automatically; expired token is silently refreshed
const response = await apiClient.get('/rooms');
const response = await apiClient.post('/bookings', data);
```

**Step 4 — Auth actions in components:**
```js
import { loginAuth, logoutAuth, clearAuthError } from '@james/reduxapi-helper-cli/slices/authSlice';

const { user, isAuthenticated, loading, error } = useSelector(s => s.auth);

dispatch(loginAuth({ email: 'user@example.com', password: 'secret' }));
dispatch(logoutAuth());
```

### Offline sync slice usage

```js
import { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchBookings,
  createBooking,
  updateBooking,
  deleteBooking,
  start BookingNetworkListener,
} from '@james/reduxapi-helper-cli/slices/bookingSlice';

// main.jsx — start listener once
store.dispatch(startBookingNetworkListener());

// Component
const { data, queue, isOnline, syncing, syncFailed } = useSelector(s => s.booking);

// Use exactly like a normal slice — offline handling is invisible
dispatch(createBooking({ room_id: 1, check_in: '2025-01-01' }));
dispatch(updateBooking({ id: 1, updateData: { status: 'confirmed' } }));
dispatch(deleteBooking(1));

// UI hints
// isOnline         → show/hide "Offline Mode 🔴" banner
// queue.length > 0 → show "3 changes pending sync" badge
// item._queued     → show "Pending…" status per row
// syncing          → show sync spinner
// syncFailed       → show "Some changes failed to sync" alert
```

### Optimistic pre-fetch slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchRooms, prefetchRoom, prefetchRoomList, fetchRoomById } from '@james/reduxapi-helper-cli/slices/roomSlice';

const dispatch = useDispatch();
const { list, current, prefetchCache, loadingById } = useSelector(s => s.room);

// Load list — also warms cache from list data
dispatch(fetchRooms());

// Warm cache on row hover (React)
<tr onMouseEnter={() => dispatch(prefetchRoom(room.id))}>

// Warm all currently-visible rows at once (Intersection Observer)
dispatch(prefetchRoomList(visibleIds));

// Navigate to detail — instant if prefetched (0ms), loader if not
dispatch(fetchRoomById(id));

// loadingById is false when hitting cache → no spinner shown
```

### Batching slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import { requestUser, fetchUserByIds } from '@james/reduxapi-helper-cli/slices/userSlice';

const dispatch = useDispatch();
const { itemCache } = useSelector(s => s.user);

// In three different components (same render cycle):
// Component A:  dispatch(requestUser(1));
// Component B:  dispatch(requestUser(2));
// Component C:  dispatch(requestUser(3));
// → Fires ONE request after 50ms: GET /user?ids=1,2,3

// Read item from cache after batch resolves:
const user = itemCache[id];

// Manual batch (known IDs):
dispatch(fetchUserByIds([1, 2, 3]));

// Backend must handle: GET /user?ids=1,2,3  →  [{ id:1,… }, { id:2,… }, { id:3,… }]
```

### Deduplication slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchSettingss } from '@james/reduxapi-helper-cli/slices/settingsSlice';

// All three components mount at the same time and dispatch the same action
// ComponentA: dispatch(fetchSettingss());  ─┐
// ComponentB: dispatch(fetchSettingss());  ─┤→  ONE axios.get('/settings')
// ComponentC: dispatch(fetchSettingss());  ─┘   all three components re-render once

// Per-ID dedup
import { fetchSettingsById } from '…';
dispatch(fetchSettingsById(5)); // Component 1
dispatch(fetchSettingsById(5)); // Component 2 — waits on same Promise, no second API call
```

### WebSocket / SSE slice usage

```js
import { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchRooms,
  connectRoomSocket,
  disconnectRoomSocket,
  sendToRoomSocket,
  connectRoomSSE,       // SSE alternative
  disconnectRoomSSE,
} from '@james/reduxapi-helper-cli/slices/roomSlice';

const dispatch = useDispatch();
const { data, socketStatus } = useSelector(s => s.room);

useEffect(() => {
  dispatch(fetchRooms());         // HTTP: load current list
  dispatch(connectRoomSocket());  // WS:   receive real-time updates

  return () => dispatch(disconnectRoomSocket()); // cleanup on unmount
}, []);

// Send message to server (subscribe to a channel)
dispatch(sendToRoomSocket({ type: 'subscribe', channel: 'room_updates' }));

// UI hints
// socketStatus === 'connected'    → show 🟢 Live indicator
// socketStatus === 'disconnected' → show 🔴 Reconnecting…
// socketStatus === 'error'        → show ⚠️ Connection error

// SSE (simpler, read-only — no sendToSocket needed):
dispatch(connectRoomSSE());   // connects to GET /room/stream

// Backend event format:
// { "type": "room.created", "data": { ...room } }
// { "type": "room.updated", "data": { ...room } }
// { "type": "room.deleted", "data": { "id": 1 } }
```

### Data streaming slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  fetch ChatStream,         // POST + ReadableStream
  startChatSSEStream,      // GET + EventSource
  stopChatSSEStream,
  resetChatStream,
} from '@james/reduxapi-helper-cli/slices/chatSlice';

const dispatch = useDispatch();
const { streamText, streaming, done, error } = useSelector(s => s.chat);

// ChatGPT-style: POST with body, stream tokens back
const promise = dispatch(fetchChatStream({ prompt: 'Hello', model: 'gpt-4' }));
// Cancel mid-stream (e.g. user clicks "Stop"):
promise.abort();

// SSE (read-only push from server):
dispatch(startChatSSEStream({ topic: 'live-scores' }));
// cleanup:
dispatch(stopChatSSEStream());

// Reset output (new conversation):
dispatch(resetChatStream());

// In JSX:
// <p>{streamText}{streaming && <span className="cursor">▍</span>}</p>
// <button onClick={() => promise.abort()} disabled={!streaming}>Stop</button>
```

### Abort / cancellation slice usage

```js
import { useEffect, useRef } from 'react';
import { useDispatch } from 'react-redux';
import { fetchReports, fetchReportById } from '@james/reduxapi-helper-cli/slices/reportSlice';

const dispatch = useDispatch();

// Pattern 1 — auto-cancel on unmount (most common):
useEffect(() => {
  const req = dispatch(fetchReports());
  return () => req.abort(); // cancelled when component leaves screen
}, []);

// Pattern 2 — cancel previous before new search (search-as-you-type):
const lastReq = useRef(null);
const onSearch = (q) => {
  lastReq.current?.abort();                  // kill previous request
  lastReq.current = dispatch(fetchReports({ q }));
};

// Pattern 3 — cancel on tab switch:
const req = useRef(null);
req.current = dispatch(fetchReportById(id));
// on tab change → req.current.abort();

// state.aborted === true  → don't show error (silent cancel)
// state.error !== null    → only when aborted is false
```

### Encrypted state slice usage

```js
// .env
// REACT_APP_STORE_KEY=my-256bit-secret-key

import { useDispatch, useSelector } from 'react-redux';
import { loadProfile, unlockProfile, saveProfile, lockProfile, purgeProfile }
  from '@james/reduxapi-helper-cli/slices/profileSlice';

const dispatch = useDispatch();
const { data, locked, loading, encryptedData } = useSelector(s => s.profile);

// On mount — fetch from API, encrypt, store ciphertext
dispatch(loadProfile());

// When user opens sensitive section — decrypt into memory
dispatch(unlockProfile());
// data is now available as plaintext in Redux memory
if (!locked) console.log(data.creditCard);

// Save changes — re-encrypts on success
dispatch(saveProfile({ id: 1, data: { name: 'James' } }));

// Lock on exit (wipes plaintext from memory, keeps ciphertext)
dispatch(lockProfile());

// Full wipe on logout (removes sessionStorage too)
dispatch(purgeProfile());
```

### Heartbeat + Circuit Breaker slice usage

```js
// main.jsx — start once after store creation
import { startHeartbeat } from '@james/reduxapi-helper-cli/slices/systemSlice';
store.dispatch(startHeartbeat());

// App.jsx — show maintenance UI + schedule recovery probe
import { useDispatch, useSelector } from 'react-redux';
import { probeRecovery } from '@james/reduxapi-helper-cli/slices/systemSlice';

const { circuitState, serverStatus, latencyMs, consecutiveFailures } =
  useSelector(s => s.system);

// Auto-probe recovery 30s after circuit opens
useEffect(() => {
  if (circuitState === 'open') {
    const t = setTimeout(() => dispatch(probeRecovery()), 30_000);
    return () => clearTimeout(t);
  }
}, [circuitState]);

// In other slices — guard API calls:
// const { circuitState } = getState().system;
// if (circuitState === 'open') return rejectWithValue('Server unavailable');

// JSX:
// {circuitState === 'open'      && <Banner>⚠️ Server ခေတ္တ ပြုပြင်နေပါသည်</Banner>}
// {circuitState === 'half_open' && <Banner>🔄 ပြန်ချိတ်ဆက်နေသည်…</Banner>}
// {circuitState === 'closed'    && <span>🟢 {latencyMs}ms</span>}
```

### Optimistic UI slice usage

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchTasks,
  createTask,
  updateTask,
  deleteTask,
  optimisticAddTask,
  optimisticUpdateTask,
  optimisticRemoveTask,
} from '@james/reduxapi-helper-cli/slices/taskSlice';

const dispatch = useDispatch();
const { data, loading, error } = useSelector(state => state.task);

// Optimistic create
const tempId = Date.now();
dispatch(optimisticAddTask({ _tempId: tempId, title: 'Buy milk', done: false }));
dispatch(createTask({ _tempId: tempId, title: 'Buy milk', done: false }));

// Optimistic update
dispatch(optimisticUpdateTask({ id: 1, title: 'Buy oat milk', done: true }));
dispatch(updateTask({ id: 1, updateData: { title: 'Buy oat milk', done: true } }));

// Optimistic delete
dispatch(optimisticRemoveTask(1));
dispatch(deleteTask(1));
// → UI removes item instantly; if API fails, error is set and item stays removed (re-fetch to restore)
```

## Store Setup

The CLI writes imports and reducers into `src/store/store.js` automatically. To connect the store to your app:

```jsx
// src/main.jsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import { Provider } from 'react-redux';
import { store } from './store/store';
import App from './App';

ReactDOM.createRoot(document.getElementById('root')).render(
  <Provider store={store}>
    <App />
  </Provider>
);
```

## State Shape

**`crud`, `token`, `create` slices:**
```js
{
  data: [],       // fetched records
  loading: false,
  error: null,
  success: false,
}
```

**`crud` and `customheader` slices** also expose `links` and `meta` when using the paginated fetch:
```js
{
  data: [],
  links: { first, last, prev, next },
  meta: { current_page, last_page, per_page, total, ... },
  loading: false,
  error: null,
  success: false,
}
```

**`auth` slice:**
```js
{
  user: null,
  token: null,
  isAuthenticated: false,
  loading: false,
  error: null,
}
```

**`infinite` slice:**
```js
{
  data: [],          // accumulated items across all pages
  nextCursor: null,  // cursor for the next page (null = first page)
  hasMore: true,     // false when all pages are fetched
  loading: false,    // true only on the initial load
  loadingMore: false,// true when appending the next page
  error: null,
}
```

**`search` slice:**
```js
{
  data: [],     // search results
  meta: null,   // pagination meta if returned by API
  filters: {},  // active filters saved via setFilters
  loading: false,
  error: null,
}
```

**`upload` slice:**
```js
{
  data: null,      // response from the API after upload
  progress: 0,     // 0 → 100 (set to 100 on success)
  loading: false,
  error: null,
  success: false,
}
```

**`polling` slice:**
```js
{
  data: null,          // latest fetched data
  isPolling: false,
  lastUpdated: null,   // ISO timestamp of the last successful fetch
  loading: false,
  error: null,
}
```

**`analytics` slice:**
```js
{
  summary: null,        // KPI / card data
  chart: [],            // time-series or grouped chart data
  metrics: [],          // metric breakdown rows
  loadingSummary: false,
  loadingChart: false,
  loadingMetrics: false,
  error: null,
}
```

**`optimistic` slice:**
```js
{
  data: [],       // list with optimistic items (_optimistic: true until confirmed)
  loading: false,
  error: null,    // set if API call fails after optimistic update
  success: false,
}
```

**`cache` slice:**
```js
{
  data: [],            // cached items
  lastFetched: null,   // Unix ms timestamp of last successful API call
  loading: false,      // true only on first load (empty cache)
  revalidating: false, // true during silent background refresh
  error: null,
}
```

**`debounce` slice:**
```js
{
  data: [],         // search results
  result: null,     // last submit response
  loading: false,   // search in-flight
  submitting: false,// form submit in-flight
  error: null,
  success: false,
}
```

**`retry` slice:**
```js
{
  data: [],
  loading: false,
  error: null,     // only set after all retry attempts are exhausted
  success: false,
}
```

**`rollback` slice:**
```js
{
  data: [],          // current list (may contain _optimistic: true items)
  _snapshot: null,   // deep copy saved before each mutation; null when clean
  loading: false,
  error: null,
  success: false,
}
```

**`tokenrefresh` slice:**
```js
{
  user: null,
  accessToken: null,
  refreshToken: null,
  isAuthenticated: false,
  loading: false,
  error: null,
}
```

**`offline` slice:**
```js
{
  data: [],
  queue: [],         // [{ queueId, method, data?, resourceId?, timestamp }]
  isOnline: true,    // mirrors navigator.onLine
  syncing: false,    // true while queue is being flushed
  syncFailed: [],    // items that failed even after reconnect
  loading: false,
  error: null,
  success: false,
}
```

**`prefetch` slice:**
```js
{
  list: [],
  current: null,       // currently displayed item
  prefetchCache: {},   // { [id]: item } — warmed by hover / scroll
  loading: false,
  loadingById: false,  // true ONLY on cache miss
  error: null,
}
```

**`batch` slice:**
```js
{
  list: [],
  itemCache: {},       // { [id]: item } — populated by every batch/list fetch
  loading: false,
  batchLoading: false, // true while a batched request is in-flight
  error: null,
}
```

**`dedupe` slice:**
```js
{
  list: [],
  items: {},     // { [id]: item } — single-item results indexed by id
  loading: false,
  error: null,
}
```

**`websocket` slice:**
```js
{
  data: [],
  socketStatus: 'idle', // 'idle' | 'connected' | 'disconnected' | 'error'
  socketError: null,
  lastEvent: null,       // most recent raw event — useful for debugging
  loading: false,
  error: null,
}
```

**`stream` slice:**
```js
{
  chunks: [],        // raw received chunks (strings or objects)
  streamText: '',    // concatenated text — bind directly to UI
  streaming: false,  // true while stream is open
  done: false,       // true once [DONE] signal received
  error: null,
}
```

**`abort` slice:**
```js
{
  data: [],
  current: null,
  loading: false,
  aborted: false,  // true on intentional cancel — do NOT show error UI
  error: null,
  success: false,
}
```

**`encrypt` slice:**
```js
{
  encryptedData: null, // AES-256-GCM base64 ciphertext (persisted in sessionStorage)
  data: null,          // decrypted plaintext — in-memory only, never written to disk
  locked: true,        // false only after unlockXxx() succeeds
  loading: false,
  error: null,
}
```

**`heartbeat` slice:**
```js
{
  circuitState: 'closed', // 'closed' | 'open' | 'half_open'
  consecutiveFailures: 0,
  consecutiveSuccesses: 0,
  lastPingAt: null,        // ISO timestamp
  lastSuccessAt: null,
  latencyMs: null,         // last successful ping round-trip ms
  serverStatus: 'unknown', // 'healthy' | 'degraded' | 'down' | 'unknown'
  pingError: null,
}
```

## License

ISC
