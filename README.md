# james-redux-cli

A CLI tool that generates Redux Toolkit API slices and automatically wires them into your React store.

## Installation

```bash
npm install james-redux-cli
```

## Requirements

Install peer dependencies in your React project:

```bash
npm install @reduxjs/toolkit react-redux axios
```

## Usage

```bash
reduxapi make:api <name> [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-t, --type <type>` | Template type (see below) | `crud` |
| `-u, --url <url>` | API base URL | `https://your-api-url.com` |

### Template Types

| Type | Description |
|------|-------------|
| `crud` | Full CRUD (fetch, create, update, delete) |
| `create` | Create-only slice |
| `token` | Full CRUD with Bearer token authentication |
| `auth` | Login, register, logout with localStorage |

## Examples

**Basic CRUD slice:**
```bash
reduxapi make:api Product
```
Generates `slices/productSlice.js` with `fetchProducts`, `createProduct`, `updateProduct`, `deleteProduct`.

**Bearer token CRUD:**
```bash
reduxapi make:api Order -t token -u https://api.example.com/orders
```
Reads `token` from `state.auth.token` and attaches `Authorization: Bearer <token>` to every request.

**Auth slice:**
```bash
reduxapi make:api auth -t auth -u https://api.example.com
```
Generates `authSlice.js` with `login`, `register`, `logout` thunks and persists token to `localStorage`.

**Create-only slice:**
```bash
reduxapi make:api ContactForm -t create -u https://api.example.com/contact
```

## How It Works

1. Generates a slice file inside `node_modules/james-redux-cli/slices/`.
2. Automatically adds the import and reducer entry to `src/store/store.js` in your project (creates the file if it doesn't exist).

### Example — importing in your React components

```js
import { useDispatch, useSelector } from 'react-redux';
import { fetchProducts, createProduct, reset ProductStatus } from 'james-redux-cli/slices/productSlice';

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
import { login, logout, clearAuthError } from 'james-redux-cli/slices/authSlice';

const dispatch = useDispatch();
const { user, isAuthenticated, loading, error } = useSelector(state => state.auth);

dispatch(login({ email: 'user@example.com', password: 'secret' }));
dispatch(logout());
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

All generated slices (except `auth`) share the same state shape:

```js
{
  data: [],       // fetched records
  loading: false,
  error: null,
  success: false, // true after create / update / delete
}
```

The `auth` slice:

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
