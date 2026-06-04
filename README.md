# redux-api-helper

A CLI tool that generates Redux Toolkit API slices and automatically wires them into your React store.

## Installation

```bash
npm install redux-api-helper
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

```bash
npx reduxapi make:api <name> [options]
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

## How It Works

1. Generates a slice file inside `node_modules/redux-api-helper/slices/`.
2. Automatically adds the import and reducer entry to `src/store/store.js` in your project (creates the file if it doesn't exist).

### Example — importing in your React components

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchProducts, createProduct, resetProductStatus } from 'redux-api-helper/slices/productSlice';

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
import { login, logout, clearAuthError } from 'redux-api-helper/slices/authSlice';

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
} from 'redux-api-helper/slices/roomSlice';

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
} from 'redux-api-helper/slices/orderSlice';

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

## License

ISC
