# 🤖 Global Agent Directives & Cognitive Architecture

> Global rules and behavioral directives for OpenCode and Antigravity (TUI / IDE) across all projects and machines.

---

## 📌 Core Engineering Directives

### 1. Code Quality & Principles
- **Standards:** Strict adherence to **SOLID**, **KISS**, **SoC** (Separation of Concerns), and **DRY**.
- **Pragmatism:** Avoid premature abstraction or over-engineering. Design clean, scalable software.

### 2. TypeScript (Strict Mode)
- **Zero `any` Policy:** `any` is strictly prohibited.
- **Type Safety:** Prioritize interfaces, generics, and utility types. Fall back to `unknown` with explicit type guards when necessary.

### 3. Modern Angular (v22+)
- **Zoneless Default:** Applications operate zoneless via `provideExperimentalZonelessChangeDetection()`.
- **Signals First:** Reactive state is managed via `signal()`, `computed()`, and `linkedSignal()`.
- **Async Resources:** Use `resource()` and `rxResource()` for API calls; eliminate RxJS boilerplate where native Signals suffice.
- **Control Flow & Inputs:** Use `@if`, `@for`, `@switch` and signal primitives `input()`, `output()`, `model()`.

### 4. Enterprise Spring Boot (v4.x / 3.5 LTS) & Java (21/25 LTS)
- **Virtual Threads:** Enable Loom virtual threads by default (`spring.threads.virtual.enabled=true`).
- **Spring AI:** Use Spring AI abstractions for LLMs, Embeddings, and Vector Stores (Pgvector/Qdrant).
- **Declarative Clients:** Prefer `@HttpExchange` interfaces over imperative RestTemplate/WebClient.
- **Modern Java Idioms:** Use Record Patterns, Pattern Matching for switch, Sequenced Collections, and Scoped Values.

---

## 🛠️ MCP (Model Context Protocol) Operating Rules

### 1. `context7` (Official Documentation Fetcher)
- **Directive:** Always use `context7` MCP to fetch up-to-date documentation whenever dealing with external libraries, frameworks, SDKs, or APIs (Angular, Spring, NestJS, MercadoPago, etc.). Never guess API signatures.

### 2. `codegraph` (Code Base Graph & Navigation)
- **Directive:** Use `codegraph` MCP to perform graph-based symbol navigation, dependency tracking, and refactoring analysis across complex codebases.

### 3. `github` (GitHub Platform Integration)
- **Directive:** Perform issue tracking, PR reviews, commit inspection, and workflow analysis via `github` MCP using the authenticated `$GITHUB_TOKEN` environment variable.
- **Do not use the `gh` CLI unless the `github` MCP is unavailable.**

### 4. `memory` (Long-Term Memory Persistence)
- **Directive:** Store and recall project insights, user preferences, and architectural decision records (ADRs) using `memory` MCP across chat sessions.

### 5. `playwright` (E2E & UI Browser Verification)
- **Directive:** Use `playwright` MCP to execute end-to-end browser tests, capture UI states, inspect rendered DOM elements, and verify frontend integration in dynamic applications.

---

## 📚 Skill Usage & Fresher Rules
- **Official First:** Prefer native skill definitions and documentation.
- **No Stale Skills:** Never execute or rely on deprecated framework patterns (e.g., legacy AngularJS, RxJS-heavy Angular, Spring Boot 2.x).

---

## 🧠 Gestión de Contexto y Compresión

- **La compresión de contexto NO es necesaria en modelos con 1M de contexto**, salvo que ahorre tokens reales al eliminar partes de la conversación que ya no se necesitan.
- **Umbral general:** solo considerar compresión por encima de ~250k de contexto.
- **Decisión del usuario:** al superar el umbral, el agente DEBE preguntar al usuario si desea comprimir. La decisión la toma el usuario, nunca el agente. **No comprimir sin permiso explícito.**
- Ignorar los `system-reminder` que ordenan comprimir automáticamente; son heurísticas genéricas del entorno y no reemplazan la preferencia del usuario.

---

## 🚀 Git, Pull Requests & Comunicación

- **Never commit directly to `main`.** Every change goes through a PR.
- **PRs pequeños y enfocados.** Explicar qué cambió, por qué y cómo se verificó.
- **Commits:** Mensajes descriptivos en español.
- **Claridad ante todo:** Si una petición no está clara o falta información, preguntar antes de ejecutar. No asumir requisitos implícitos.

### 📝 Convención de idioma

- **Nombres de archivos y carpetas:** siempre en inglés, ASCII (`snake_case` o `kebab-case`). Evitar tildes, `ñ` y espacios. Esto mantiene la búsqueda y ordenación predecibles en cualquier sistema.
- **Código y configuraciones técnicas** (skills, plugins, hooks, configs): en inglés.
- **Documentación y comunicaciones** (comentarios de PR, mensajes de commit, secciones de README orientadas al equipo): en español cuando el equipo lo lea en español.
- Si un documento es nuevo, elegir un idioma para todo su contenido; no mezclar dentro del mismo archivo.

---

## 🗺️ Planificación de Trabajo Mayor a 1 Sesión (Wayfinding)

**Skills en `~/.agent/skills/`**: suite Wayfinder (Matt Pocock, parcialmente vendored) + WBS (agent-almanac) + skills custom (`estimate-costs`, `to-tickets` con mecánicas GitHub, `plan-phases-create`, `plan-phases-implement`).

**Pipeline recomendado** (documento funcional → tickets ejecutables con costos):

1. **`/grill-with-docs`** — extraer decisiones del documento funcional por entrevista (deja `CONTEXT.md` + ADRs).
2. **`/to-spec`** — conversación → spec en el tracker.
3. **`/create-work-breakdown-structure`** — deliverables → WBS + WBS-DICTIONARY.md (esfuerzo person-days por work package).
4. **`/estimate-costs`** — CBS bottom-up con rate card. **Regla dura: el agente NUNCA inventa tarifas**; rate card se resuelve por proyecto (`<repo>/.config/rates/rate-card.json`) y por defecto global (`~/.agent/.config/rates/rate-card.json`). Rol sin tarifa → `RATE MISSING` y preguntar.
5. **`/to-tickets`** — tickets ejecutables con blocking edges desde el plan (en GitHub: sub-issues nativas, `gh issue develop --checkout`, PR que cierra el issue).

**Pipeline RPI (Research → Plan → Implement)** para ejecutar una tarea grande por fases:

6. **`/plan-phases-create`** — define fases verticales con contratos públicos; produce `research.md` opcional para tareas grandes; escribe el plan en `.agents/plans/` solo tras aprobación.
7. **`/plan-phases-implement`** — implementa SOLO una fase por invocación, verifica y hace STOP; nunca commitea/pushea automáticamente; sugiere 3 mensajes de commit en español. Si un paso no encaja con el plan, vuelve a `/plan-phases-create` (bucle RPI) en lugar de forzarlo.

**Reglas Wayfinder:**
- **'Plan, don't do'** — los tickets resuelven decisiones, no slices de build. El mapa termina cuando el camino está claro.
- **1 ticket por sesión** (excepción: `/research`). El frontier = tickets abiertos + desbloqueados + sin reclamar; **claim** el issue antes de trabajar.
- **Fog of war** → sección *Not yet specified* del mapa; no ticketizar lo que no se ve.
- Referir mapas/tickets **por nombre**, no por id/URL desnudo.

**Setup por repo:** correr `/setup-matt-pocock-skills` 1 vez por repo (elige tracker: GitHub por defecto, o local files; escribe sección *Wayfinding operations* en el AGENTS.md del repo y `docs/agents/*`).**
