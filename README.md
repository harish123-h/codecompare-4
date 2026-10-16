# CodeCompare

CodeCompare is a React/TypeScript workspace for comparing C, Python 3 and Java implementations. It includes debounced AI translation, Docker-backed code execution, terminal stdin/stdout over Socket.IO, local guest projects, optional Supabase persistence/auth, concepts, export and responsive layout.

## Requirements
- Node.js 20+
- Docker Desktop or Docker Engine (for the isolated runner)
- Optional: Supabase project and one LLM provider API key

## Local setup
1. Copy `.env.example` to `.env` and set the provider key. For database auth, set both Supabase URL/key pairs.
2. Install dependencies: `npm install`
3. Build the runner image: `docker build -f apps/server/Dockerfile.runner -t codecompare-runner:local apps/server`
4. Start the app: `npm run dev`
5. Open http://localhost:5173. API health: http://localhost:4000/api/health

If you have no LLM key, the translation endpoint returns a clear configuration error; the editor, concepts, guest storage and runner can still be used. If Docker is not running, execution returns a clear runner error instead of running untrusted code on the host.

## Supabase
Run `supabase/schema.sql` in the Supabase SQL editor. The browser uses the publishable/anon key; server project routes verify the caller's JWT and rely on RLS. Never put the service-role key in `VITE_*` variables. Enable Email and Google providers in Supabase Auth settings if desired. Configure the callback URL for your deployed frontend.

## Deployment
- Frontend: deploy `apps/web` to Vercel, set `VITE_API_URL`, `VITE_SOCKET_URL`, `VITE_SUPABASE_URL`, and `VITE_SUPABASE_ANON_KEY`. Set the Vercel root directory to `apps/web` and build command to `npm run build`.
- Backend: deploy `apps/server` to a Docker-capable host such as a dedicated VM or container host. Set all server environment variables and `WEB_ORIGIN` to the frontend URL. The runner requires Docker access; mounting the Docker socket into a general shared web service is highly privileged. Prefer a dedicated runner host/service with strict access controls. Some Render/Railway plans do not permit nested Docker or privileged socket access; in that case deploy a separate runner service or replace the runner adapter with a managed execution provider.
- For production, use HTTPS/WSS, restrict CORS, configure provider quotas, and use a dedicated execution worker. Do not expose the Docker socket publicly.

## Socket.IO protocol
Client emits `run:start` with `{language, code, stdin?}`. Server replies `run:started` with `{runId}`, streams `run:stdout` / `run:stderr` with `{runId, chunk}`, accepts `run:stdin` with `{runId, data}`, and stops on `run:stop` with `{runId}`. Completion emits `run:exit` with `{runId, exitCode, durationMs}`; failures emit `run:error` with `{runId, message}`. Each socket owns its run IDs.

## Security notes and limitations
Docker runs with no network, non-root UID, read-only root filesystem, memory/CPU/PID limits, dropped capabilities and a hard timeout. Docker daemon access is itself highly privileged; isolate it on a dedicated host. Source is size-limited. Translation is best-effort and generated code must be reviewed. Output comparison is byte-normalized text comparison, not semantic equivalence. PDF export is a text listing. Supabase cloud credentials and provider keys are required for those integrations. This project is a runnable baseline, not a substitute for a security audit before public multi-tenant deployment.