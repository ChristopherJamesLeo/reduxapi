import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

const HTTP_URL = '{{apiUrl}}/{{lowerName}}';

// ─── SSE via EventSource (read-only push stream) ─────────────────────────────
let _eventSource = null;

export const start{{Name}}SSEStream = (params = {}) => (dispatch) => {
  if (_eventSource) { _eventSource.close(); }
  dispatch(reset{{Name}}Stream());

  const qs = new URLSearchParams(params).toString();
  const url = `${HTTP_URL}/stream${qs ? '?' + qs : ''}`;
  _eventSource = new EventSource(url);

  _eventSource.onmessage = (event) => {
    if (event.data === '[DONE]') {
      dispatch(set{{Name}}StreamDone());
      _eventSource.close();
      _eventSource = null;
      return;
    }
    try {
      const chunk = JSON.parse(event.data);
      // Handle ChatGPT-style: { choices: [{ delta: { content: "..." } }] }
      const text = chunk.choices?.[0]?.delta?.content
        ?? chunk.content
        ?? chunk.text
        ?? chunk;
      dispatch(append{{Name}}Chunk(text));
    } catch {
      dispatch(append{{Name}}Chunk(event.data)); // plain-text token
    }
  };

  _eventSource.addEventListener('error', () => {
    dispatch(set{{Name}}StreamError('SSE connection failed'));
    _eventSource?.close();
    _eventSource = null;
  });
};

export const stop{{Name}}SSEStream = () => () => {
  _eventSource?.close();
  _eventSource = null;
};

// ─── Fetch-based Streaming (POST body + ReadableStream) ──────────────────────
// Supports OpenAI-compatible streaming, Laravel Streamed Responses, etc.
export const fetch{{Name}}Stream = createAsyncThunk(
  '{{lowerName}}/fetchStream',
  async (params = {}, { dispatch, signal, rejectWithValue }) => {
    dispatch(reset{{Name}}Stream());

    try {
      const response = await fetch(`${HTTP_URL}/stream`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Accept: 'text/event-stream' },
        body: JSON.stringify(params),
        signal,
      });

      if (!response.ok) {
        const err = await response.json().catch(() => ({}));
        return rejectWithValue(err.message || `HTTP ${response.status}`);
      }

      const reader  = response.body.getReader();
      const decoder = new TextDecoder();

      // eslint-disable-next-line no-constant-condition
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const raw = decoder.decode(value, { stream: true });

        // Parse SSE lines: "data: {...}\n\n"
        for (const line of raw.split('\n')) {
          const trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;
          const payload = trimmed.slice(5).trim();
          if (payload === '[DONE]') { dispatch(set{{Name}}StreamDone()); return null; }

          try {
            const chunk = JSON.parse(payload);
            const text  = chunk.choices?.[0]?.delta?.content
              ?? chunk.content ?? chunk.text ?? chunk;
            dispatch(append{{Name}}Chunk(text));
          } catch {
            dispatch(append{{Name}}Chunk(payload));
          }
        }
      }

      dispatch(set{{Name}}StreamDone());
      return null;
    } catch (error) {
      if (error.name === 'AbortError') return rejectWithValue('Stream aborted');
      return rejectWithValue(error.message);
    }
  }
);

// ─── Slice ───────────────────────────────────────────────────────────────────
const {{lowerName}}Slice = createSlice({
  name: '{{lowerName}}',
  initialState: {
    chunks: [],        // raw received chunks (objects or strings)
    streamText: '',    // concatenated text — use this for chat/LLM output
    streaming: false,  // true while stream is open
    done: false,       // true once [DONE] received
    error: null,
  },
  reducers: {
    append{{Name}}Chunk: (state, action) => {
      const chunk = action.payload;
      state.chunks.push(chunk);
      state.streaming = true;
      if (typeof chunk === 'string') state.streamText += chunk;
      else if (typeof chunk === 'object' && chunk !== null) {
        state.streamText += chunk.content ?? chunk.text ?? '';
      }
    },
    set{{Name}}StreamDone: (state) => {
      state.streaming = false;
      state.done = true;
    },
    set{{Name}}StreamError: (state, action) => {
      state.streaming = false;
      state.error = action.payload;
    },
    reset{{Name}}Stream: (state) => {
      state.chunks = [];
      state.streamText = '';
      state.streaming = false;
      state.done = false;
      state.error = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetch{{Name}}Stream.pending, (state) => {
        state.streaming = true;
        state.error = null;
      })
      .addCase(fetch{{Name}}Stream.rejected, (state, action) => {
        state.streaming = false;
        state.error = action.payload;
      });
    // fulfilled is handled inside the thunk via inline dispatches
  },
});

export const {
  append{{Name}}Chunk,
  set{{Name}}StreamDone,
  set{{Name}}StreamError,
  reset{{Name}}Stream,
} = {{lowerName}}Slice.actions;
export default {{lowerName}}Slice.reducer;

// Quick-start (ChatGPT-style token output):
//
// SSE (EventSource — GET, server pushes):
//   dispatch(start{{Name}}SSEStream({ prompt: 'Hello' }));
//   dispatch(stop{{Name}}SSEStream());
//
// Fetch stream (POST body — more control):
//   const promise = dispatch(fetch{{Name}}Stream({ prompt: 'Hello', model: 'gpt-4' }));
//   // cancel mid-stream:
//   promise.abort();
//
// In component:
//   const { streamText, streaming, done } = useSelector(s => s.{{lowerName}});
//   <p>{streamText}{streaming && <span className="cursor">▍</span>}</p>
//
// State hints:
//   streaming  → show blinking cursor / "Stop Generating" button
//   done       → show copy / regenerate button
//   chunks     → iterate for structured data (e.g. JSON-patch streaming)
//   streamText → show for plain-text / LLM output
