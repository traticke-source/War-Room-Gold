# WAR ROOM

An intelligence-command-center interface for structured decision analysis. The current MVP is a fully functional static prototype with local persistence: create a brief, weight priorities, watch parallel council analysis, read a Chairman verdict, stress-test it in the simulator, and archive it.

## Run locally

Open `index.html` in a modern browser. No build tool is required in this environment.

## Production integration plan

The UI is deliberately provider-neutral. For production, place AI calls in server-side routes, validate every model response against the structured schema in `docs/architecture.md`, persist user-owned data in Supabase with RLS, and replace `localStorage` in `app.js` with authenticated API calls.

## Environment

Copy `.env.example` to `.env.local` when deploying the integrated version. Never expose secrets to the browser.
