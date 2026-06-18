# @christopherjamesleo/reduxapi-helper

A CLI tool that generates Redux Toolkit API slices and automatically wires them into your React store.

## Installation

```bash
npm install @christopherjamesleo/reduxapi-helper
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
npx reduxapi make:<type> <name> -u <url>

# One-time use without installing
npx @christopherjamesleo/reduxapi-helper make:<type> <name> -u <url>
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
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
| `focusrevalidation` | Stale-On-Focus — silently refetches stale data whenever the user returns to the tab or unlocks their phone screen |
| `circuitbreaker` | Advanced Circuit Breaker — trips after consecutive API failures, blocks all requests, shows maintenance UI, auto-probes recovery |
| `gracefuldegradation` | Graceful Degradation — falls back to localStorage cache when the server is down; app stays usable in read-only mode |
| `sessionidle` | Session Idle Timeout — auto-logout after 5 min of inactivity, 60-second countdown warning, clears all sensitive state |
| `mfa` | Multi-Factor Authentication — 2-step login (password → OTP), TOTP/SMS/email support, 60s countdown, lockout after 3 wrong attempts, QR setup flow |
| `predictivescroll` | Predictive infinite scroll — combines cursor pagination with look-ahead prefetch, batched `?ids=` requests, AbortController dedupe, network-aware (data-saver) guard, and an LRU+TTL detail cache |


## Slice Templates

### `crud` — Full CRUD

```bash
npx reduxapi make:crud Product -u https://api.example.com
```
Generates `productSlice.js` with `fetchProducts`, `createProduct`, `updateProduct`, `deleteProduct`.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchProducts, createProduct, resetProductStatus } from './store/productSlice';

const dispatch = useDispatch();
const { data, loading, error, success } = useSelector(state => state.product);

// Fetch all
dispatch(fetchProducts());

// Create
dispatch(createProduct({ name: 'New Product', price: 99 }));

// Reset success/error flags
dispatch(resetProductStatus());
```

**State shape:**

```js
{
  data: [],
  loading: false,
  error: null,
  success: false,
}
```

Also exposes `links` and `meta` for the paginated fetch:
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

**Backend example (Laravel / Node.js):**

`reduxapi` only generates the frontend Redux slice — your backend must expose matching REST routes. The `crud` template (`npx reduxapi make:crud Product -u https://api.example.com`) expects:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/product` | List all (or `?page=N` for pagination) |
| POST | `/product` | Create |
| PUT | `/product/:id` | Update |
| DELETE | `/product/:id` | Delete |

**Laravel — `routes/api.php`**
```php
use App\Http\Controllers\ProductController;

Route::get('/product', [ProductController::class, 'index']);
Route::post('/product', [ProductController::class, 'store']);
Route::put('/product/{id}', [ProductController::class, 'update']);
Route::delete('/product/{id}', [ProductController::class, 'destroy']);
```

**Laravel — `app/Http/Controllers/ProductController.php`**
```php
namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        if ($request->has('page')) {
            return Product::paginate(10); // matches fetchPaginatedProducts
        }
        return Product::all(); // matches fetchProducts
    }

    public function store(Request $request)
    {
        $product = Product::create($request->all());
        return response()->json(['data' => $product], 201);
    }

    public function update(Request $request, $id)
    {
        $product = Product::findOrFail($id);
        $product->update($request->all());
        return response()->json(['data' => $product]);
    }

    public function destroy($id)
    {
        Product::destroy($id);
        return response()->json(null, 204);
    }
}
```

**Node.js — `routes/product.js`**
```js
const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');

router.get('/', productController.index);
router.post('/', productController.store);
router.put('/:id', productController.update);
router.delete('/:id', productController.destroy);

module.exports = router;
```

**Node.js — `controllers/productController.js`**
```js
const Product = require('../models/Product');

exports.index = async (req, res) => {
  if (req.query.page) {
    const page = parseInt(req.query.page) || 1;
    const limit = 10;
    const data = await Product.find().skip((page - 1) * limit).limit(limit);
    const total = await Product.countDocuments();
    return res.json({
      data,
      meta: { current_page: page, total },
      links: null,
    }); // matches fetchPaginatedProducts
  }
  const data = await Product.find();
  res.json(data); // matches fetchProducts
};

exports.store = async (req, res) => {
  const product = await Product.create(req.body);
  res.status(201).json({ data: product });
};

exports.update = async (req, res) => {
  const product = await Product.findByIdAndUpdate(req.params.id, req.body, { new: true });
  res.json({ data: product });
};

exports.destroy = async (req, res) => {
  await Product.findByIdAndDelete(req.params.id);
  res.status(204).send();
};
```

The response shapes above (`{ data, meta, links }` for pagination, `{ data }` for create/update) match what `crudSlice.js.t` expects out of the box — adjust other templates' backends to match their own thunk expectations (e.g. `token` expects `Authorization: Bearer`, `auth` expects `/login`, `/register`, `/logout`, etc.).

---

### `create` — Create-only slice

```bash
npx reduxapi make:create ContactForm -u https://api.example.com/contact
```

**Frontend usage:** same pattern as `crud`'s `createProduct` call — `dispatch(createContactForm({ ... }))`.

**State shape:**
```js
{
  data: [],
  loading: false,
  error: null,
  success: false,
}
```

**Backend example (Laravel / Node.js):**

Single `POST` endpoint, same response shape as `crud`'s create action.

```php
// routes/api.php
Route::post('/contact-form', [ContactFormController::class, 'store']);

// ContactFormController.php
public function store(Request $request) {
    $item = ContactForm::create($request->all());
    return response()->json(['data' => $item], 201);
}
```
```js
// Express
router.post('/', contactFormController.store);

exports.store = async (req, res) => {
  const item = await ContactForm.create(req.body);
  res.status(201).json({ data: item });
};
```

---

### `token` — Bearer token CRUD

```bash
npx reduxapi make:token Order -u https://api.example.com/orders
```
Reads `token` from `state.auth.token` and attaches `Authorization: Bearer <token>` to every request.

**Frontend usage:** same dispatch pattern as `crud` (`fetchOrders`, `createOrder`, `updateOrder`, `deleteOrder`) — every request automatically includes `Authorization: Bearer <token>` read from `state.auth.token`.

**State shape:**

```js
{
  data: [],
  loading: false,
  error: null,
  success: false,
}
```

**Backend example (Laravel / Node.js):**

Same routes as `crud`, but every request must be authenticated via `Authorization: Bearer <token>`.

```php
// routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/orders', [OrderController::class, 'index']);
    Route::post('/orders', [OrderController::class, 'store']);
    Route::put('/orders/{id}', [OrderController::class, 'update']);
    Route::delete('/orders/{id}', [OrderController::class, 'destroy']);
});
```
```js
// Express
router.use(requireBearerAuth); // verifies Authorization: Bearer <token>
router.get('/', orderController.index);
router.post('/', orderController.store);
router.put('/:id', orderController.update);
router.delete('/:id', orderController.destroy);
```

---

### `auth` — Login, register, logout

```bash
npx reduxapi make:auth all -u https://api.example.com
```
Generates `loginSlice.js`, `registerSlice.js`, `logoutSlice.js` and persists token to `localStorage`.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import { login, logout, clearAuthError } from './store/authSlice';

const dispatch = useDispatch();
const { user, isAuthenticated, loading, error } = useSelector(state => state.auth);

dispatch(login({ email: 'user@example.com', password: 'secret' }));
dispatch(logout());
```

**State shape:**

```js
{
  user: null,
  token: null,
  isAuthenticated: false,
  loading: false,
  error: null,
}
```

**Backend example (Laravel / Node.js):**

```php
// routes/api.php
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/logout', [AuthController::class, 'logout']);

// AuthController.php
public function login(Request $request) {
    // validate credentials...
    return response()->json(['user' => $user, 'token' => $token]);
}
```
```js
// Express
router.post('/login', authController.login);
router.post('/register', authController.register);
router.post('/logout', authController.logout);

exports.login = async (req, res) => {
  // validate credentials...
  res.json({ user, token });
};
```

---

### `customheader` — Custom headers CRUD

```bash
npx reduxapi make:customheader Order -u https://api.example.com
```
Generates a slice with a `getHeaders()` helper function. Edit it to add any headers you need.

**Frontend usage:**

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
} from './store/orderSlice';

const dispatch = useDispatch();
const { data, links, meta, loading, error, success } = useSelector(state => state.order);

dispatch(fetchOrders());
dispatch(fetchPaginatedOrders(1));
dispatch(fetchPaginatedOrders(meta.current_page + 1));

dispatch(createOrder({ item: 'Book', qty: 2 }));
dispatch(updateOrder({ id: 1, updateData: { qty: 5 } }));
dispatch(deleteOrder(1));
dispatch(resetOrderStatus());
```

**State shape:**

```js
{
  data: [],
  loading: false,
  error: null,
  success: false,
}
```

Also exposes `links` and `meta` for the paginated fetch:
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

**Backend example (Laravel / Node.js):**

Same CRUD routes as `crud`, but the server must accept (and may validate) the custom headers your `getHeaders()` sends (e.g. `Authorization`, `X-App-Version`, `Accept-Language`).

```php
// routes/api.php — same routes as crud
// Middleware can inspect $request->header('X-App-Version') if needed
```
```js
// Express
router.get('/', (req, res, next) => {
  console.log(req.headers['x-app-version']); // read custom header
  next();
}, orderController.index);
```

---

### `secretkey` — Two-step secret key CRUD

```bash
npx reduxapi make:secretkey Room -u https://api.yourhotel.com/v1
```
Every request automatically fetches a fresh secret key from `GET /get-secret-key` first, then sends the real request with `X-Custom-Secret-Key` in the header.

**Frontend usage:**

This template uses a **two-step request pattern**:

```
Step 1 →  GET /get-secret-key                        → receives { secret_key: "abc123" }
Step 2 →  GET /room  (+ X-Custom-Secret-Key: abc123) → receives real data
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
} from './store/roomSlice';

const dispatch = useDispatch();
const { data, links, meta, loading, error, success } = useSelector(state => state.room);

dispatch(fetchRooms());
dispatch(fetchPaginatedRooms(1));
dispatch(fetchPaginatedRooms(meta.current_page + 1)); // next page

dispatch(createRoom({ room_no: '201', room_type: 'SUITE', price_per_night: '300 AED' }));
dispatch(updateRoom({ id: 1, updateData: { price_per_night: '350 AED' } }));
dispatch(deleteRoom(1));
dispatch(resetRoomStatus());
```

To change the secret key endpoint or header name, edit these two lines in the generated slice:

```js
const SECRET_KEY_URL = `${BASE_URL}/get-secret-key`; // ← your health endpoint

const secureHeaders = (secretKey) => ({
  'X-Custom-Secret-Key': secretKey,                   // ← your header name
  'Accept': 'application/json',
});
```

**State shape:** same as `crud`/`customheader` — `data`, `links`, `meta`, `loading`, `error`, `success`.

**Backend example (Laravel / Node.js):**

```php
// routes/api.php
Route::get('/get-secret-key', [SecretKeyController::class, 'issue']);
Route::middleware('verify.secret.key')->group(function () {
    Route::get('/room', [RoomController::class, 'index']);
    Route::post('/room', [RoomController::class, 'store']);
});

// SecretKeyController.php
public function issue() {
    return response()->json(['secret_key' => Str::random(32)]);
}
// Middleware checks $request->header('X-Custom-Secret-Key') against a store/cache
```
```js
// Express
router.get('/get-secret-key', (req, res) => res.json({ secret_key: issueKey() }));
router.use(verifySecretKeyHeader); // checks req.headers['x-custom-secret-key']
router.get('/room', roomController.index);
```

---

### `infinite` — Infinite scroll

```bash
npx reduxapi make:infinite Post -u https://api.example.com
```
Appends pages to `state.data` on each load-more call. Tracks `hasMore` and `nextCursor` automatically.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchPosts, resetPosts } from './store/postSlice';

const dispatch = useDispatch();
const { data, hasMore, nextCursor, loading, loadingMore } = useSelector(state => state.post);

// Initial load
dispatch(fetchPosts());

// Load next page
if (hasMore) dispatch(fetchPosts({ cursor: nextCursor }));

// Reset and reload (e.g. pull-to-refresh)
dispatch(resetPosts());
dispatch(fetchPosts());
```

**State shape:**

```js
{
  data: [],           // accumulated items across all pages
  nextCursor: null,   // cursor for the next page (null = first page)
  hasMore: true,      // false when all pages are fetched
  loading: false,     // true only on initial load
  loadingMore: false, // true when appending the next page
  error: null,
}
```

**Backend example (Laravel / Node.js):**

`GET /post?cursor=<cursor>` must return the next page plus a cursor and a flag/marker for whether more pages exist.

```php
// PostController.php
public function index(Request $request) {
    $posts = Post::where('id', '<', $request->query('cursor', PHP_INT_MAX))
        ->orderByDesc('id')->limit(20)->get();
    return response()->json([
        'data' => $posts,
        'nextCursor' => $posts->last()?->id,
        'hasMore' => $posts->count() === 20,
    ]);
}
```
```js
// Express
exports.index = async (req, res) => {
  const cursor = req.query.cursor || null;
  const posts = await Post.find(cursor ? { _id: { $lt: cursor } } : {}).sort({ _id: -1 }).limit(20);
  res.json({ data: posts, nextCursor: posts.at(-1)?._id ?? null, hasMore: posts.length === 20 });
};
```

---

### `search` — Search / filter slice

```bash
npx reduxapi make:search Product -u https://api.example.com
```
Passes any filter object as query params. Includes `setFilters` and `clearFilters` reducers.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import { searchProducts, setProductFilters, clearProductFilters } from './store/productSlice';

const dispatch = useDispatch();
const { data, filters, meta, loading } = useSelector(state => state.product);

dispatch(searchProducts({ q: 'laptop', category: 'electronics', page: 1 }));

dispatch(setProductFilters({ status: 'active' }));
dispatch(searchProducts(filters));

dispatch(clearProductFilters());
```

**State shape:**

```js
{
  data: [],     // search results
  meta: null,   // pagination meta if returned by API
  filters: {},  // active filters saved via setFilters
  loading: false,
  error: null,
}
```

**Backend example (Laravel / Node.js):**

`GET /product` accepts arbitrary query params (filters) and returns matching results plus optional pagination meta.

```php
// ProductController.php
public function index(Request $request) {
    $query = Product::query();
    foreach ($request->query() as $key => $value) {
        if (in_array($key, ['q','category','status'])) $query->where($key, 'like', "%$value%");
    }
    return response()->json(['data' => $query->paginate(20)]);
}
```
```js
// Express
exports.index = async (req, res) => {
  const filter = {};
  if (req.query.category) filter.category = req.query.category;
  const data = await Product.find(filter);
  res.json({ data });
};
```

---

### `upload` — File upload slice

```bash
npx reduxapi make:upload Avatar -u https://api.example.com
```
Accepts plain objects containing `File` values and converts them to `FormData` automatically.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import { uploadAvatar, updateUploadAvatar, resetAvatarUpload } from './store/avatarSlice';

const dispatch = useDispatch();
const { data, loading, progress, success, error } = useSelector(state => state.avatar);

// Create — mix of plain fields and File objects
dispatch(uploadAvatar({ title: 'Profile Photo', file: event.target.files[0] }));

// Update (uses POST + _method: PUT for Laravel compatibility)
dispatch(updateUploadAvatar({ id: 1, data: { title: 'New Photo', file: newFile } }));

if (success) dispatch(resetAvatarUpload());
```

**State shape:**

```js
{
  data: null,
  progress: 0,  // 0 → 100 (set to 100 on success)
  loading: false,
  error: null,
  success: false,
}
```

**Backend example (Laravel / Node.js):**

Requests arrive as `multipart/form-data`. Update uses `POST` + `_method: PUT` (Laravel form-method spoofing).

```php
// routes/api.php
Route::post('/avatar', [AvatarController::class, 'store']);
Route::post('/avatar/{id}', [AvatarController::class, 'update']); // handles _method=PUT

// AvatarController.php
public function store(Request $request) {
    $path = $request->file('file')->store('avatars');
    return response()->json(['data' => Avatar::create(['title' => $request->title, 'path' => $path])]);
}
```
```js
// Express (using multer)
router.post('/', upload.single('file'), avatarController.store);

exports.store = async (req, res) => {
  const avatar = await Avatar.create({ title: req.body.title, path: req.file.path });
  res.json({ data: avatar });
};
```

---

### `polling` — Background polling

```bash
npx reduxapi make:polling Notification -u https://api.example.com
```
Provides `startPollingNotification(5000)` and `stopPollingNotification()` thunk helpers.

**Frontend usage:**

```js
import { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { startPollingNotification, stopPollingNotification } from './store/notificationSlice';

const dispatch = useDispatch();
const { data, lastUpdated, loading } = useSelector(state => state.notification);

useEffect(() => {
  dispatch(startPollingNotification(10000)); // poll every 10 s
  return () => dispatch(stopPollingNotification());
}, []);
```

**State shape:**

```js
{
  data: null,
  isPolling: false,
  lastUpdated: null, // ISO timestamp of the last successful fetch
  loading: false,
  error: null,
}
```

**Backend example (Laravel / Node.js):**

Standard `GET` endpoint, polled repeatedly by the client at a fixed interval — no special headers, just keep it fast/cacheable.

```php
Route::get('/notification', [NotificationController::class, 'index']);
```
```js
router.get('/', notificationController.index); // returns latest notifications array
```

---

### `analytics` — Dashboard / analytics slice

```bash
npx reduxapi make:analytics Report -u https://api.example.com
```
Three separate thunks — `fetchReportSummary`, `fetchReportChart`, `fetchReportMetrics` — each with its own loading flag.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchReportSummary,
  fetchReportChart,
  fetchReportMetrics,
  clearReportData,
} from './store/reportSlice';

const dispatch = useDispatch();
const { summary, chart, metrics, loadingSummary, loadingChart, loadingMetrics } =
  useSelector(state => state.report);

dispatch(fetchReportSummary({ period: 'month' }));
dispatch(fetchReportChart({ metric: 'revenue', range: '30d', interval: 'day' }));
dispatch(fetchReportMetrics({ group: 'region' }));

dispatch(clearReportData()); // clear on unmount
```

**State shape:**

```js
{
  summary: null,
  chart: [],
  metrics: [],
  loadingSummary: false,
  loadingChart: false,
  loadingMetrics: false,
  error: null,
}
```

**Backend example (Laravel / Node.js):**

Three separate `GET` endpoints, one per thunk: `/report/summary`, `/report/chart`, `/report/metrics`.

```php
Route::get('/report/summary', [ReportController::class, 'summary']);
Route::get('/report/chart', [ReportController::class, 'chart']);
Route::get('/report/metrics', [ReportController::class, 'metrics']);
```
```js
router.get('/summary', reportController.summary);
router.get('/chart', reportController.chart);     // accepts ?metric=&range=&interval=
router.get('/metrics', reportController.metrics); // accepts ?group=
```

---

### `optimistic` — Optimistic UI slice

```bash
npx reduxapi make:optimistic Task -u https://api.example.com
```
Updates the list immediately via `optimisticAddTask` / `optimisticUpdateTask` / `optimisticRemoveTask`, then confirms or rolls back when the API responds.

**Frontend usage:**

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
} from './store/taskSlice';

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
// UI removes item instantly; if the API fails, error is set
```

**State shape:**

```js
{
  data: [],       // list with optimistic items (_optimistic: true until confirmed)
  loading: false,
  error: null,
  success: false,
}
```

**Backend example (Laravel / Node.js):**

Standard REST endpoint, same shape as the `crud` example above — no special headers or response format required.

---

### `cache` — Stale-While-Revalidate cache slice

```bash
npx reduxapi make:cache Room -u https://api.example.com
```
Returns Redux-cached data instantly, then silently re-fetches in background. Shows stale data while fresh data loads — zero perceived latency.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchRooms, revalidateRooms, invalidateRoomCache } from './store/roomSlice';

const dispatch = useDispatch();
const { data, loading, revalidating, lastFetched } = useSelector(s => s.room);

// First visit — hits API, caches result for 5 minutes
dispatch(fetchRooms());

// Second visit within 5 min — returns Redux cache instantly, no API call
dispatch(fetchRooms());

// Custom TTL (10 min)
dispatch(fetchRooms({ ttl: 10 * 60 * 1000 }));

// Force a fresh fetch regardless of TTL
dispatch(fetchRooms({ force: true }));

// Silent background refresh (stale data still visible to user)
dispatch(revalidateRooms());

// Expire the cache (next fetch will always hit the API)
dispatch(invalidateRoomCache());

// UI hints:
// loading      → show full-page spinner (first load only)
// revalidating → show a subtle "Refreshing…" badge
```

**State shape:**

```js
{
  data: [],
  lastFetched: null,    // Unix ms timestamp of last successful API call
  loading: false,       // true only on first load (empty cache)
  revalidating: false,  // true during silent background refresh
  error: null,
}
```

**Backend example (Laravel / Node.js):**

Standard `GET /room` endpoint — caching/TTL logic is purely client-side in Redux, no special backend contract needed.

```php
Route::get('/room', [RoomController::class, 'index']);
```
```js
router.get('/', roomController.index);
```

---

### `debounce` — Debounce / Throttle slice

```bash
npx reduxapi make:debounce Hotel -u https://api.example.com
```
Built-in `debouncedHotelSearch(dispatch, params)` (500 ms) and `throttledHotelSubmit(dispatch, data)` (2 s) helpers — no extra libraries needed.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  debouncedHotelSearch,
  throttledHotelSubmit,
  searchHotels,
  clearHotelResults,
} from './store/hotelSlice';

const dispatch = useDispatch();
const { data, loading, submitting, success } = useSelector(s => s.hotel);

// Fires 500 ms after the user stops typing
<input onChange={(e) => debouncedHotelSearch(dispatch, { q: e.target.value })} />

// One API call per 2 seconds even if the button is clicked repeatedly
<button onClick={() => throttledHotelSubmit(dispatch, formData)}>Book Now</button>

// Direct call (no debounce)
dispatch(searchHotels({ city: 'Dubai', stars: 5 }));
dispatch(clearHotelResults());
```

**State shape:**

```js
{
  data: [],
  result: null,
  loading: false,    // search in-flight
  submitting: false, // form submit in-flight
  error: null,
  success: false,
}
```

**Backend example (Laravel / Node.js):**

Standard REST endpoint, same shape as the `crud` example above — debounce/throttle is purely client-side, no special headers or response format required.

---

### `retry` — Auto-retry slice

```bash
npx reduxapi make:retry Payment -u https://api.example.com
```
Every thunk silently retries up to 3 times (2 s → 4 s → 6 s) on network errors or 5xx. Only surfaces the error to the UI after all retries are exhausted.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchPayments, createPayment } from './store/paymentSlice';

const dispatch = useDispatch();
const { data, loading, error } = useSelector(s => s.payment);

// Auto-retries up to 3 times on network errors or 5xx
dispatch(fetchPayments());
dispatch(createPayment({ amount: 500, currency: 'AED' }));

// error is only set after ALL retry attempts fail
// 4xx errors (400, 401, 422…) are NOT retried — they surface immediately
```

**State shape:**

```js
{
  data: [],
  loading: false,
  error: null,   // only set after all retry attempts are exhausted
  success: false,
}
```

**Backend example (Laravel / Node.js):**

Standard REST endpoint, same shape as the `crud` example above — retry logic on 5xx/network errors is purely client-side. Make sure your backend returns proper 5xx status codes on real failures so the retry logic can detect them.

---

### `rollback` — Snapshot rollback slice

```bash
npx reduxapi make:rollback Bookmark -u https://api.example.com
```
Takes a deep snapshot before every optimistic mutation. On any API failure, state is fully restored to exactly what it was — no manual undo logic needed.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  optimisticUpdateBookmark,
  updateBookmark,
  optimisticRemoveBookmark,
  deleteBookmark,
  optimisticAddBookmark,
  createBookmark,
} from './store/bookmarkSlice';

// Toggle (optimistic) — auto-reverts if API returns 401/500
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

**State shape:**

```js
{
  data: [],
  _snapshot: null, // deep copy saved before each mutation; null when clean
  loading: false,
  error: null,
  success: false,
}
```

**Backend example (Laravel / Node.js):**

Standard REST endpoint, same shape as the `crud` example above — no special headers or response format required; the rollback behavior lives entirely in the Redux slice.

---

### `tokenrefresh` — Auto JWT refresh slice

```bash
npx reduxapi make:tokenrefresh Auth -u https://api.example.com
```
Generates an `apiClient` (axios instance) + `setupApiInterceptors(store)`. On 401, silently refreshes the token and retries the original request. Concurrent requests are queued and replayed automatically.

**Frontend usage:**

**Step 1 — Generate the slice:**
```bash
npx reduxapi make:tokenrefresh Auth -u https://api.example.com
```

**Step 2 — Wire up interceptors in `main.jsx` (once, after store is created):**
```jsx
import { store } from './store/store';
import { setupApiInterceptors } from './store/authSlice';

setupApiInterceptors(store); // add this before ReactDOM.createRoot

ReactDOM.createRoot(document.getElementById('root')).render(
  <Provider store={store}><App /></Provider>
);
```

**Step 3 — Use `apiClient` in other slices instead of plain `axios`:**
```js
import { apiClient } from './store/authSlice';

// Token is attached automatically; expired token is silently refreshed
const response = await apiClient.get('/rooms');
const response = await apiClient.post('/bookings', data);
```

**Step 4 — Auth actions in components:**
```js
import { loginAuth, logoutAuth } from './store/authSlice';

const { user, isAuthenticated, loading, error } = useSelector(s => s.auth);

dispatch(loginAuth({ email: 'user@example.com', password: 'secret' }));
dispatch(logoutAuth());
```

**State shape:**

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

**Backend example (Laravel / Node.js):**

Needs `/login` (returns access + refresh tokens) and `/auth/refresh` (exchanges a refresh token for a new access token). All other endpoints expect `Authorization: Bearer <accessToken>` and should return 401 on expiry so the interceptor can refresh and retry.

```php
Route::post('/login', [AuthController::class, 'login']);
Route::post('/auth/refresh', [AuthController::class, 'refresh']);

// login() returns: ['user' => ..., 'accessToken' => ..., 'refreshToken' => ...]
// refresh() returns: ['accessToken' => ...]
```
```js
router.post('/login', authController.login);     // -> { user, accessToken, refreshToken }
router.post('/auth/refresh', authController.refresh); // -> { accessToken }
// Other routes: middleware verifies Authorization: Bearer <accessToken>, returns 401 if expired
```

---

### `offline` — Offline sync slice

```bash
npx reduxapi make:offline Booking -u https://api.example.com
```
Queues all mutations (create/update/delete) to localStorage when offline. Auto-syncs when network returns. Items show `_queued: true` in the UI until confirmed.

**Frontend usage:**

```js
import { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchBookings,
  createBooking,
  updateBooking,
  deleteBooking,
  startBookingNetworkListener,
} from './store/bookingSlice';

// main.jsx — start listener once
store.dispatch(startBookingNetworkListener());

// Component
const { data, queue, isOnline, syncing, syncFailed } = useSelector(s => s.booking);

// Use exactly like a normal slice — offline handling is invisible
dispatch(createBooking({ room_id: 1, check_in: '2025-01-01' }));
dispatch(updateBooking({ id: 1, updateData: { status: 'confirmed' } }));
dispatch(deleteBooking(1));

// UI hints:
// isOnline         → show / hide "Offline Mode 🔴" banner
// queue.length > 0 → show "3 changes pending sync" badge
// item._queued     → show "Pending…" status per row
// syncing          → show sync spinner
// syncFailed       → show "Some changes failed to sync" alert
```

**State shape:**

```js
{
  data: [],
  queue: [],       // [{ queueId, method, data?, resourceId?, timestamp }]
  isOnline: true,  // mirrors navigator.onLine
  syncing: false,  // true while queue is being flushed
  syncFailed: [],  // items that failed even after reconnect
  loading: false,
  error: null,
  success: false,
}
```

**Backend example (Laravel / Node.js):**

Standard CRUD routes, identical to `crud` — the offline queue/sync logic is entirely client-side; queued mutations are simply replayed as normal POST/PUT/DELETE calls once back online.

```php
// Same routes as crud
Route::apiResource('bookings', BookingController::class);
```
```js
router.post('/', bookingController.store);
router.put('/:id', bookingController.update);
router.delete('/:id', bookingController.destroy);
```

---

### `prefetch` — Optimistic pre-fetch slice

```bash
npx reduxapi make:prefetch Room -u https://api.example.com
```
Call `dispatch(prefetchRoom(id))` on `onMouseEnter` or `IntersectionObserver`. When the user navigates to the detail page, data is already in cache — 0 ms loading time.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchRooms, prefetchRoom, prefetchRoomList, fetchRoomById } from './store/roomSlice';

const dispatch = useDispatch();
const { list, current, prefetchCache, loadingById } = useSelector(s => s.room);

// Load list — also warms cache from list data
dispatch(fetchRooms());

// Warm cache on row hover
<tr onMouseEnter={() => dispatch(prefetchRoom(room.id))}>

// Warm all currently-visible rows at once (Intersection Observer)
dispatch(prefetchRoomList(visibleIds));

// Navigate to detail — instant if prefetched (0 ms), loader if not
dispatch(fetchRoomById(id));
// loadingById is false when hitting cache → no spinner shown
```

**State shape:**

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

**Backend example (Laravel / Node.js):**

Standard list + by-id endpoints: `GET /room` and `GET /room/:id` — prefetching is just calling the by-id endpoint early, no special backend contract needed.

```php
Route::get('/room', [RoomController::class, 'index']);
Route::get('/room/{id}', [RoomController::class, 'show']);
```
```js
router.get('/', roomController.index);
router.get('/:id', roomController.show);
```

---

### `batch` — Batching slice

```bash
npx reduxapi make:batch User -u https://api.example.com
```
Three components each call `dispatch(requestUser(id))` within 50 ms — only one request fires: `GET /user?ids=1,2,3`. Backend must accept a comma-separated `ids` param.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import { requestUser, fetchUserByIds } from './store/userSlice';

const dispatch = useDispatch();
const { itemCache } = useSelector(s => s.user);

// In three different components (same render cycle):
// Component A:  dispatch(requestUser(1));
// Component B:  dispatch(requestUser(2));
// Component C:  dispatch(requestUser(3));
// → Fires ONE request after 50 ms: GET /user?ids=1,2,3

const user = itemCache[id]; // read from cache after batch resolves

// Manual batch (known IDs):
dispatch(fetchUserByIds([1, 2, 3]));

// Backend must handle: GET /user?ids=1,2,3  →  [{ id:1,… }, { id:2,… }, { id:3,… }]
```

**State shape:**

```js
{
  list: [],
  itemCache: {},        // { [id]: item } — populated by every batch / list fetch
  loading: false,
  batchLoading: false,  // true while a batched request is in-flight
  error: null,
}
```

**Backend example (Laravel / Node.js):**

`GET /user?ids=1,2,3` must return an array of matching items.

```php
// UserController.php
public function index(Request $request) {
    if ($request->has('ids')) {
        $ids = explode(',', $request->query('ids'));
        return response()->json(User::whereIn('id', $ids)->get());
    }
    return response()->json(User::all());
}
```
```js
exports.index = async (req, res) => {
  if (req.query.ids) {
    const ids = req.query.ids.split(',');
    return res.json(await User.find({ _id: { $in: ids } }));
  }
  res.json(await User.find());
};
```

---

### `dedupe` — Deduplication slice

```bash
npx reduxapi make:dedupe Settings -u https://api.example.com
```
Sidebar, Header, and Footer all call `dispatch(fetchSettings())` on mount — only one API call is made. All three components receive the same response once it resolves.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchSettingss, fetchSettingsById } from './store/settingsSlice';

// All three components mount simultaneously and dispatch the same action
// ComponentA: dispatch(fetchSettingss());  ─┐
// ComponentB: dispatch(fetchSettingss());  ─┤→  ONE axios.get('/settings')
// ComponentC: dispatch(fetchSettingss());  ─┘   all three re-render once

// Per-ID dedup
dispatch(fetchSettingsById(5)); // Component 1
dispatch(fetchSettingsById(5)); // Component 2 — waits on same Promise, no second API call
```

**State shape:**

```js
{
  list: [],
  items: {},  // { [id]: item } — single-item results indexed by id
  loading: false,
  error: null,
}
```

**Backend example (Laravel / Node.js):**

Standard REST endpoints, same shape as `crud` — deduplication of in-flight requests is purely client-side; the backend just needs normal `GET /settings` and `GET /settings/:id` routes.

```php
Route::get('/settings', [SettingsController::class, 'index']);
Route::get('/settings/{id}', [SettingsController::class, 'show']);
```
```js
router.get('/', settingsController.index);
router.get('/:id', settingsController.show);
```

---

### `websocket` — WebSocket / SSE slice

```bash
npx reduxapi make:websocket Room -u https://api.example.com
```
Connects a WebSocket (or SSE) stream. Incoming events (`room.created`, `room.updated`, `room.deleted`) are routed directly into Redux state — no polling, no refresh button needed.

**Frontend usage:**

```js
import { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchRooms,
  connectRoomSocket,
  disconnectRoomSocket,
  sendToRoomSocket,
  connectRoomSSE,
  disconnectRoomSSE,
} from './store/roomSlice';

const dispatch = useDispatch();
const { data, socketStatus } = useSelector(s => s.room);

useEffect(() => {
  dispatch(fetchRooms());        // HTTP: load current list
  dispatch(connectRoomSocket()); // WS: receive real-time updates

  return () => dispatch(disconnectRoomSocket());
}, []);

// Send a message to the server (e.g. subscribe to a channel)
dispatch(sendToRoomSocket({ type: 'subscribe', channel: 'room_updates' }));

// UI hints:
// socketStatus === 'connected'    → 🟢 Live
// socketStatus === 'disconnected' → 🔴 Reconnecting…
// socketStatus === 'error'        → ⚠️ Connection error

// SSE alternative (read-only — no sendToSocket needed):
dispatch(connectRoomSSE()); // connects to GET /room/stream

// Expected backend event format:
// { "type": "room.created", "data": { ...room } }
// { "type": "room.updated", "data": { ...room } }
// { "type": "room.deleted", "data": { "id": 1 } }
```

**State shape:**

```js
{
  data: [],
  socketStatus: 'idle', // 'idle' | 'connected' | 'disconnected' | 'error'
  socketError: null,
  lastEvent: null,      // most recent raw event — useful for debugging
  loading: false,
  error: null,
}
```

**Backend example (Laravel / Node.js):**

Needs the normal `GET /room` REST list, plus a WebSocket endpoint at `ws(s)://.../ws/room` (or SSE fallback at `GET /room/stream`) that pushes `{ type, data }` events.

```php
// Laravel: use Laravel Reverb / Pusher broadcasting, or a custom WS server.
// Broadcast event shape:
broadcast(new RoomEvent('room.updated', $room));
// -> { "type": "room.updated", "data": { ...room } }
```
```js
// Node.js (ws library)
wss.on('connection', (socket) => {
  socket.send(JSON.stringify({ type: 'room.created', data: newRoom }));
});

// SSE fallback
router.get('/room/stream', (req, res) => {
  res.set({ 'Content-Type': 'text/event-stream' });
  res.write(`data: ${JSON.stringify({ type: 'room.updated', data: room })}\n\n`);
});
```

---

### `stream` — Data streaming slice

```bash
npx reduxapi make:stream Chat -u https://api.example.com
```
Supports both `EventSource` (SSE GET) and `fetch`-based streaming (POST body). Appends tokens one-by-one into `state.streamText` — ideal for LLM/ChatGPT-style output.

**Frontend usage:**

```js
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchChatStream,
  startChatSSEStream,
  stopChatSSEStream,
  resetChatStream,
} from './store/chatSlice';

const dispatch = useDispatch();
const { streamText, streaming, done, error } = useSelector(s => s.chat);

// POST with body, stream tokens back (ChatGPT-style)
const promise = dispatch(fetchChatStream({ prompt: 'Hello', model: 'gpt-4' }));
promise.abort(); // cancel mid-stream

// SSE (read-only push from server)
dispatch(startChatSSEStream({ topic: 'live-scores' }));
dispatch(stopChatSSEStream()); // cleanup

dispatch(resetChatStream()); // reset output for new conversation

// JSX:
// <p>{streamText}{streaming && <span className="cursor">▍</span>}</p>
// <button onClick={() => promise.abort()} disabled={!streaming}>Stop</button>
```

**State shape:**

```js
{
  chunks: [],        // raw received chunks
  streamText: '',    // concatenated text — bind directly to UI
  streaming: false,  // true while stream is open
  done: false,       // true once [DONE] signal received
  error: null,
}
```

**Backend example (Laravel / Node.js):**

`POST /chat/stream` (body request) and `GET /chat/stream` (SSE) must respond with `Content-Type: text/event-stream`, sending chunks as `data: <token>\n\n` and a final `data: [DONE]\n\n`.

```php
// Laravel — use a streamed response
return response()->stream(function () {
    foreach ($tokens as $t) {
        echo "data: {$t}\n\n";
        ob_flush(); flush();
    }
    echo "data: [DONE]\n\n";
}, 200, ['Content-Type' => 'text/event-stream']);
```
```js
// Express
router.post('/chat/stream', (req, res) => {
  res.set({ 'Content-Type': 'text/event-stream' });
  tokens.forEach(t => res.write(`data: ${t}\n\n`));
  res.write('data: [DONE]\n\n');
  res.end();
});
```

---

### `abort` — Abort / cancellation slice

```bash
npx reduxapi make:abort Report -u https://api.example.com
```
Every thunk receives RTK's `signal` and passes it to axios. Call `promise.abort()` in `useEffect` cleanup to cancel in-flight requests on unmount — prevents memory leaks and race conditions.

**Frontend usage:**

```js
import { useEffect, useRef } from 'react';
import { useDispatch } from 'react-redux';
import { fetchReports, fetchReportById } from './store/reportSlice';

// Pattern 1 — auto-cancel on unmount (most common)
useEffect(() => {
  const req = dispatch(fetchReports());
  return () => req.abort();
}, []);

// Pattern 2 — cancel previous before new search (search-as-you-type)
const lastReq = useRef(null);
const onSearch = (q) => {
  lastReq.current?.abort();
  lastReq.current = dispatch(fetchReports({ q }));
};

// Pattern 3 — cancel on tab switch
const req = useRef(null);
req.current = dispatch(fetchReportById(id));
// on tab change: req.current.abort();

// state.aborted === true  → silent cancel, do NOT show error UI
// state.error !== null    → only when aborted is false
```

**State shape:**

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

**Backend example (Laravel / Node.js):**

Standard REST endpoint, same shape as the `crud` example above — request cancellation is handled entirely client-side via `AbortController`/RTK's `signal`; the server simply stops processing if the client disconnects.

---

### `encrypt` — Encrypted state slice

```bash
npx reduxapi make:encrypt Profile -u https://api.example.com
```
Fetched data is AES-256-GCM encrypted before entering Redux state. Plaintext lives only in memory after calling `unlockProfile()`. `purgeProfile()` wipes everything including sessionStorage.

**Frontend usage:**

```js
// .env
// REACT_APP_STORE_KEY=my-256bit-secret-key

import { useDispatch, useSelector } from 'react-redux';
import { loadProfile, unlockProfile, saveProfile, lockProfile, purgeProfile }
  from './store/profileSlice';

const dispatch = useDispatch();
const { data, locked, loading, encryptedData } = useSelector(s => s.profile);

// Fetch from API, encrypt, store ciphertext
dispatch(loadProfile());

// Decrypt into memory when user opens a sensitive section
dispatch(unlockProfile());
if (!locked) console.log(data.creditCard); // plaintext available in Redux memory

// Save changes — re-encrypts on success
dispatch(saveProfile({ id: 1, data: { name: 'James' } }));

// Lock on exit — wipes plaintext, keeps ciphertext
dispatch(lockProfile());

// Full wipe on logout — removes sessionStorage too
dispatch(purgeProfile());
```

**State shape:**

```js
{
  encryptedData: null, // AES-256-GCM base64 ciphertext (persisted in sessionStorage)
  data: null,          // decrypted plaintext — in-memory only, never written to disk
  locked: true,        // false only after unlockXxx() succeeds
  loading: false,
  error: null,
}
```

**Backend example (Laravel / Node.js):**

Standard `GET`/`POST` endpoint returning plain JSON — encryption happens entirely client-side after the response is received, so the backend contract is identical to `crud`.

```php
Route::get('/profile', [ProfileController::class, 'index']);
```
```js
router.get('/', profileController.index); // plain JSON, encrypted on the client
```

---

### `heartbeat` — Heartbeat + Circuit Breaker slice

```bash
npx reduxapi make:heartbeat System -u https://api.example.com
```
Pings `GET /health` every 5 s. After 5 consecutive failures the circuit opens — all API calls can check `circuitState === 'open'` to bail early. Auto-probes recovery after 30 s.

**Frontend usage:**

```js
// main.jsx — start once after store creation
import { startHeartbeat } from './store/systemSlice';
store.dispatch(startHeartbeat());

// App.jsx — maintenance UI + recovery probe
import { probeRecovery } from './store/systemSlice';

const { circuitState, serverStatus, latencyMs, consecutiveFailures } =
  useSelector(s => s.system);

// Schedule a recovery probe 30 s after the circuit opens
useEffect(() => {
  if (circuitState === 'open') {
    const t = setTimeout(() => dispatch(probeRecovery()), 30_000);
    return () => clearTimeout(t);
  }
}, [circuitState]);

// Guard API calls in other slices:
// const { circuitState } = getState().system;
// if (circuitState === 'open') return rejectWithValue('Server unavailable');

// JSX:
// {circuitState === 'open'      && <Banner>⚠️ Server is under maintenance</Banner>}
// {circuitState === 'half_open' && <Banner>🔄 Reconnecting…</Banner>}
// {circuitState === 'closed'    && <span>🟢 {latencyMs}ms</span>}
```

**State shape:**

```js
{
  circuitState: 'closed',  // 'closed' | 'open' | 'half_open'
  consecutiveFailures: 0,
  consecutiveSuccesses: 0,
  lastPingAt: null,         // ISO timestamp
  lastSuccessAt: null,
  latencyMs: null,          // last successful ping round-trip ms
  serverStatus: 'unknown',  // 'healthy' | 'degraded' | 'down' | 'unknown'
  pingError: null,
}
```

**Backend example (Laravel / Node.js):**

`GET /health` must respond quickly (used to measure `latencyMs`) and simply return 200 OK when healthy.

```php
Route::get('/health', fn () => response()->json(['status' => 'ok']));
```
```js
router.get('/health', (req, res) => res.json({ status: 'ok' }));
```

To change the endpoint, edit `HEALTH_URL = BASE_URL + '/health'` in the generated slice.

---

### `focusrevalidation` — Focus Revalidation (Stale-On-Focus) slice

```bash
npx reduxapi make:focusrevalidation Post -u https://api.example.com
```
Silently refetches stale data in the background whenever the user switches back to the tab or unlocks their phone screen. Uses `revalidating` state to show a subtle refresh indicator without blocking the UI.

**Frontend usage:**

```js
// main.jsx — register listeners once
import { startPostFocusRevalidation } from './store/postSlice';
store.dispatch(startPostFocusRevalidation());

// Component
const { data, loading, revalidating, lastFetchedAt } = useSelector(s => s.post);
useEffect(() => { dispatch(fetchPosts()); }, []);

// UI hints:
// loading      → full-page spinner (first load)
// revalidating → small corner spinner (silent background refresh)
// {revalidating && <SmallSpinner />}
// {`Last updated: ${new Date(lastFetchedAt).toLocaleTimeString()}`}
```

**State shape:**

```js
{
  data: [],
  loading: false,
  revalidating: false, // true during silent background refetch — don't show full spinner
  error: null,
  lastFetchedAt: null, // epoch ms — used to decide whether data is stale
}
```

**Backend example (Laravel / Node.js):**

Standard REST endpoint, same shape as the `crud` example above — no special headers or response format required; revalidation is triggered client-side on window/tab focus.

---

### `circuitbreaker` — Advanced Circuit Breaker slice

```bash
npx reduxapi make:circuitbreaker Order -u https://api.example.com
```
Similar to `heartbeat` but also counts failures from real API calls, not just health pings. Tracks `blockedCount` to show how many requests were blocked while the circuit was open.

**Frontend usage:**

```js
// main.jsx
import { startOrderCircuitBreaker } from './store/orderSlice';
store.dispatch(startOrderCircuitBreaker());

// App.jsx — schedule recovery probe when circuit opens
const { circuitState, serverStatus, latencyMs, blockedCount } = useSelector(s => s.order);
useEffect(() => {
  if (circuitState === 'open') dispatch(scheduleOrderRecovery());
}, [circuitState]);

// JSX:
// {circuitState === 'open'      && <Banner>⚠️ Server is under maintenance</Banner>}
// {circuitState === 'half_open' && <Banner>🔄 Reconnecting…</Banner>}
// {circuitState === 'closed'    && <span>🟢 {latencyMs}ms</span>}
// {serverStatus === 'degraded'  && <Badge>⚡ Server responding slowly</Badge>}
// {`Blocked requests: ${blockedCount}`}
```

**State shape:**

```js
{
  data: [],
  loading: false,
  error: null,
  success: false,
  circuitState: 'closed',   // 'closed' | 'open' | 'half_open'
  consecutiveFailures: 0,
  consecutiveSuccesses: 0,
  serverStatus: 'unknown',  // 'healthy' | 'degraded' | 'down' | 'unknown'
  lastPingAt: null,
  latencyMs: null,
  blockedCount: 0,          // requests blocked while circuit was open
}
```

**Backend example (Laravel / Node.js):**

Needs both `GET /health` (for the periodic ping) and the normal CRUD endpoints for `Order` — failures on either feed into the circuit breaker's failure count.

```php
Route::get('/health', fn () => response()->json(['status' => 'ok']));
Route::apiResource('orders', OrderController::class);
```
```js
router.get('/health', (req, res) => res.json({ status: 'ok' }));
router.get('/orders', orderController.index);
```

---

### `gracefuldegradation` — Graceful Degradation (Offline/Fail Fallback) slice

```bash
npx reduxapi make:gracefuldegradation Product -u https://api.example.com
```
Serves cached data from localStorage when the server is unreachable. Blocks write operations in degraded mode to prevent data loss. Automatically refreshes when the network comes back.

**Frontend usage:**

```js
// main.jsx
import { startProductDegradationListener } from './store/productSlice';
store.dispatch(startProductDegradationListener());

// Component
const { data, loading, degraded, fromCache, cachedAt, cacheAvailable, error } =
  useSelector(s => s.product);

// UI hints:
// {degraded && fromCache && (
//   <Banner>📦 Offline — showing cached data from {new Date(cachedAt).toLocaleString()}</Banner>
// )}
// {degraded && !cacheAvailable && (
//   <ErrorPage>⚠️ Server unreachable and no cached data available</ErrorPage>
// )}
// Disable write actions in degraded mode:
// <button disabled={degraded}>Create</button>
```

**State shape:**

```js
{
  data: [],
  loading: false,
  error: null,
  success: false,
  degraded: false,        // true = offline or server unreachable
  fromCache: false,       // true = current data served from localStorage cache
  cachedAt: null,         // ISO timestamp of cache
  cacheAvailable: false,  // false = no cache exists (blank-screen risk)
}
```

**Backend example (Laravel / Node.js):**

Standard CRUD routes, same as `crud` — degradation/fallback-to-cache logic is entirely client-side, triggered when requests time out or fail.

```php
Route::apiResource('products', ProductController::class);
```
```js
router.get('/', productController.index);
router.post('/', productController.store);
```

---

### `sessionidle` — Session Idle Timeout slice

```bash
npx reduxapi make:sessionidle Session -u https://api.example.com
```
Auto-logout after 5 minutes of inactivity. Shows a 60-second warning modal before logging out. Clears session tokens and sensitive state on logout.

**Frontend usage:**

```js
// After successful login — mark session active and start watching
import { setSessionSessionActive, startSessionIdleWatcher } from './store/sessionSlice';
dispatch(setSessionSessionActive(true));
store.dispatch(startSessionIdleWatcher());

// On manual logout — stop watcher first
dispatch(stopSessionIdleWatcher());
dispatch(logoutSession());

// Component — show warning countdown
const { showingWarning, loggedOutReason } = useSelector(s => s.session);

// {showingWarning && (
//   <Modal>
//     <p>⏳ You will be logged out in 60 seconds due to inactivity</p>
//     <button onClick={() => dispatch(resetSessionIdleTimer())}>Stay logged in</button>
//     <button onClick={() => dispatch(logoutSession())}>Log out now</button>
//   </Modal>
// )}
// {loggedOutReason === 'idle' && (
//   <Alert>You were automatically logged out due to inactivity</Alert>
// )}
```

**State shape:**

```js
{
  sessionActive: false,    // true after login, false after logout
  showingWarning: false,   // true during the 60 s countdown before auto-logout
  loggedOutReason: null,   // 'idle' | 'manual' | null
  logoutLoading: false,
  error: null,
  loginAt: null,           // ISO timestamp of session start
  lastActivityAt: null,    // ISO timestamp of most recent user activity
}
```

**Backend example (Laravel / Node.js):**

Only needs a `POST /logout` endpoint, called automatically (and silently) when the idle timer fires or the user manually logs out.

```php
Route::post('/logout', [AuthController::class, 'logout']);
```
```js
router.post('/logout', authController.logout); // invalidate session/token server-side
```

---

### `mfa` — MFA (Multi-Factor Authentication) slice

```bash
npx reduxapi make:mfa Mfa -u https://api.example.com
```
Two-step login flow: password → OTP verification. Supports TOTP (Google Authenticator), SMS, and email OTP. Includes a 60-second countdown timer, 5-minute lockout after 3 failed attempts, and a full QR code setup flow for TOTP enrollment.

**Frontend usage:**

```js
// ── Step 1: Primary login ──────────────────────────────────────────────────
dispatch(primaryMfaLogin({ username, password }));
// → state.step = 'pending_otp'  (MFA required — navigate to OTP screen)
// → state.step = 'verified'     (MFA not enabled — proceed directly to app)

// ── Step 2: OTP screen ─────────────────────────────────────────────────────
const { step, mfaMethod, otpCountdown, failedAttempts, lockedUntil, verifying } =
  useSelector(s => s.mfa);

// Start countdown when OTP screen mounts
useEffect(() => {
  if (step === 'pending_otp') dispatch(startMfaOtpCountdown());
}, [step]);

// Verify OTP
dispatch(verifyMfaOtp({ otp: '123456', sessionToken: state.mfa.sessionToken }));
// → state.step = 'verified', state.accessToken set

// Resend OTP (SMS / email)
dispatch(resendMfaOtp(state.mfa.sessionToken));
dispatch(startMfaOtpCountdown()); // restart countdown

// JSX hints:
// <input maxLength={6} placeholder="6-digit code" />
// {otpCountdown > 0
//   ? <span>Code expires in {otpCountdown}s</span>
//   : <button onClick={handleResend} disabled={resending}>Resend code</button>}
// {lockedUntil && Date.now() < lockedUntil && (
//   <Alert>Too many incorrect attempts — try again in 5 minutes</Alert>
// )}
// {mfaMethod === 'totp' && <p>Enter the code from your Authenticator app</p>}
// {mfaMethod === 'sms'  && <p>Enter the code sent to your phone</p>}

// ── TOTP Setup (Settings page) ─────────────────────────────────────────────
dispatch(setupMfaTotp());
// → state.totpQrUri   — render with a QR code library (e.g. qrcode.react)
// → state.totpSecret  — display for manual entry
// → state.backupCodes — show once and prompt user to save them

// <QRCode value={totpQrUri} />
// <p>Manual key: {totpSecret}</p>
// <p>Backup codes: {backupCodes.join(', ')}</p>

// After user scans QR and submits a verification code
dispatch(confirmMfaTotpSetup({ otp: '123456', secret: state.mfa.totpSecret }));
// → state.mfaEnabled = true, step = 'setup_confirmed'
dispatch(clearMfaTokens()); // wipe QR URI and secret from state

// ── Disable MFA ────────────────────────────────────────────────────────────
dispatch(disableMfaMfa({ password: currentPassword }));
// → state.mfaEnabled = false
```

**State shape:**

```js
{
  step: 'idle',          // 'idle' | 'pending_otp' | 'verified' | 'setup' | 'setup_confirmed'
  sessionToken: null,    // short-lived token from step-1 login, passed to OTP verify
  mfaMethod: null,       // 'totp' | 'sms' | 'email'
  mfaEnabled: false,     // whether the user has MFA active on their account

  otpCountdown: 0,       // seconds until resend is allowed (counts down from 60)

  failedAttempts: 0,     // wrong OTP attempts in the current session
  lockedUntil: null,     // epoch ms — null = not locked; check Date.now() < lockedUntil

  totpSecret: null,      // TOTP raw secret — clear after setup is confirmed
  totpQrUri: null,       // otpauth:// URI — pass to a QR code renderer
  backupCodes: [],       // one-time backup codes — show once then dispatch clearMfaTokens()

  accessToken: null,     // set after successful MFA verification
  user: null,

  loading: false,
  verifying: false,      // OTP verification in progress
  resending: false,      // OTP resend in progress
  setupLoading: false,   // TOTP setup / confirm in progress
  error: null,
  success: false,
}
```

**Backend example (Laravel / Node.js):**

Needs `/auth/login`, `/auth/mfa/verify`, `/auth/mfa/resend`, `/auth/mfa/setup`, `/auth/mfa/setup/confirm`, and `/auth/mfa/disable`.

```php
Route::post('/auth/login', [MfaController::class, 'login']);          // -> { step, sessionToken? }
Route::post('/auth/mfa/verify', [MfaController::class, 'verify']);    // -> { accessToken, user }
Route::post('/auth/mfa/resend', [MfaController::class, 'resend']);
Route::post('/auth/mfa/setup', [MfaController::class, 'setup']);      // -> { totpQrUri, totpSecret, backupCodes }
Route::post('/auth/mfa/setup/confirm', [MfaController::class, 'confirmSetup']);
Route::post('/auth/mfa/disable', [MfaController::class, 'disable']);
```
```js
router.post('/auth/login', mfaController.login);
router.post('/auth/mfa/verify', mfaController.verify);   // -> { accessToken, user }
router.post('/auth/mfa/resend', mfaController.resend);
router.post('/auth/mfa/setup', mfaController.setup);      // -> { totpQrUri, totpSecret, backupCodes }
router.post('/auth/mfa/setup/confirm', mfaController.confirmSetup);
router.post('/auth/mfa/disable', mfaController.disable);
```

### `predictivescroll` — Predictive infinite scroll

```bash
npx reduxapi make:predictivescroll Post -u https://api.example.com
```

Combines cursor-based infinite scroll with look-ahead prefetching: rows near the viewport are queued and fetched as one batched `?ids=1,2,3` request, in-flight requests for the same id-set are deduped/aborted, slow connections or data-saver mode skip prefetching entirely, the detail cache is capped (LRU) and time-limited (TTL) so memory never grows unbounded, and a **Scroll Velocity Gatekeeper** pauses prefetching outright while the user is flinging the list.

**Scroll Velocity Gatekeeper:**

```
speed = (distance scrolled) / (time elapsed)   // px / ms, sampled on every scroll event
if (speed > 2.5) → prefetchPaused = true       // pause — don't warm rows the user is blowing past
if (speed < 1.5) → prefetchPaused = false      // resume — only once it's genuinely slowed down
```

There's no point prefetching a row the user scrolls past in 20ms, and doing so anyway just stacks wasted requests on top of an already-fast scroll.

**The Ping-Pong Pause problem (hysteresis):** real scrolling isn't a steady speed — thumb flicks and stop-start drags hover right around any single cutoff, so a one-threshold gate flips `prefetchPaused` true/false dozens of times a second as speed bounces 2.4 → 2.6 → 2.4 → 2.6. Every flip dispatches an action and re-renders every subscribed component — the UI stutters from its own state churn, not from data. The fix is **two thresholds instead of one**: pause above `2.5`, but only resume below `1.5`. Once paused, speed has to drop meaningfully — not just dip 0.1 under the pause line — before prefetching resumes, which closes the gap the jitter lives in. The numeric `scrollVelocity` readout (for a debug HUD) is dispatched on its own 100ms throttle, completely separate from the pause/resume decision, so cosmetic updates never interfere with the gating logic.

**Frontend usage:**

```js
import { useEffect, useRef } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
  fetchPosts,
  startScrollVelocityGatePost,
  queuePrefetchPost,
  fetchPostById,
  resetPosts,
} from './store/postSlice';

const dispatch = useDispatch();
const { data, hasMore, nextCursor, loading, loadingMore, loadingIds, detailCache, prefetchPaused } =
  useSelector((s) => s.post);

// Initial load
useEffect(() => { dispatch(fetchPosts()); }, []);

// Start the scroll-velocity gate ONCE — pauses prefetching automatically
// while the user is flinging, re-opens once they slow down
useEffect(() => {
  const stop = dispatch(startScrollVelocityGatePost());
  return stop; // removes the scroll listener on unmount
}, []);

// Load next page (e.g. on scroll-to-bottom sentinel)
if (hasMore) dispatch(fetchPosts({ cursor: nextCursor }));

// Warm the cache when a row nears the viewport — auto-batches within 50ms,
// auto-skips on slow/data-saver connections, no manual debounce needed
const observerRef = useRef(
  new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        dispatch(queuePrefetchPost(entry.target.dataset.id));
      }
    });
  })
);
// <li ref={(el) => el && observerRef.current.observe(el)} data-id={post.id}>

// Navigate to detail page — 0ms if the row was already prefetched
dispatch(fetchPostById(id));

// Read the cache directly to render instantly, skip dispatch + spinner entirely
const cached = detailCache[id];

// Pull-to-refresh
dispatch(resetPosts());
dispatch(fetchPosts());

// UI hints:
// loadingIds.includes(id) → only true on an actual cache miss, never for warm rows
// loadingMore             → show a small "loading more…" footer, not a full spinner
// prefetchPaused          → true while flinging — optionally show a tiny "⏸ prefetch paused" hint
```

**State shape:**

```js
{
  data: [],            // accumulated infinite-scroll items
  nextCursor: null,
  hasMore: true,
  loading: false,
  loadingMore: false,

  detailCache: {},     // { [id]: item } — capped at 50 entries (LRU), 5 min TTL
  cacheOrder: [],       // LRU order, oldest first — internal, don't read directly
  fetchedAt: {},        // { [id]: epoch ms } — used for TTL staleness checks
  loadingIds: [],       // ids currently being prefetched/fetched

  scrollVelocity: 0,     // px/ms, updated on every scroll event
  prefetchPaused: false, // hysteresis-gated: true above 2.5px/ms, false again only below 1.5px/ms

  error: null,
}
```

**Backend example (Laravel / Node.js):**

Needs the same cursor-paginated list endpoint as `infinite`, PLUS a batch endpoint that accepts a comma-separated `ids` param (same contract as `batch`) for prefetch:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/post?cursor=...&limit=20` | Infinite-scroll page |
| GET | `/post?ids=1,2,3` | Batched prefetch — returns those rows in one call |
| GET | `/post/:id` | Single-item fetch (cache miss fallback) |

```php
// routes/api.php
Route::get('/post', [PostController::class, 'index']); // handles cursor OR ids
Route::get('/post/{id}', [PostController::class, 'show']);

// app/Http/Controllers/PostController.php
public function index(Request $request)
{
    if ($request->has('ids')) {
        $ids = explode(',', $request->query('ids'));
        return ['data' => Post::whereIn('id', $ids)->get()];
    }

    $limit = $request->query('limit', 20);
    $query = Post::orderBy('id')->limit($limit);
    if ($cursor = $request->query('cursor')) {
        $query->where('id', '>', $cursor);
    }
    $items = $query->get();

    return [
        'data' => $items,
        'next_cursor' => $items->isNotEmpty() ? $items->last()->id : null,
    ];
}

public function show($id)
{
    return ['data' => Post::findOrFail($id)];
}
```

```js
// routes/post.js
router.get('/', postController.index); // handles cursor OR ids
router.get('/:id', postController.show);

// controllers/postController.js
exports.index = async (req, res) => {
  if (req.query.ids) {
    const ids = req.query.ids.split(',');
    const data = await Post.find({ _id: { $in: ids } });
    return res.json({ data });
  }

  const limit = parseInt(req.query.limit) || 20;
  const filter = req.query.cursor ? { _id: { $gt: req.query.cursor } } : {};
  const items = await Post.find(filter).sort({ _id: 1 }).limit(limit);

  res.json({
    data: items,
    next_cursor: items.length ? items[items.length - 1]._id : null,
  });
};

exports.show = async (req, res) => {
  const post = await Post.findById(req.params.id);
  res.json({ data: post });
};
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


## License

ISC
