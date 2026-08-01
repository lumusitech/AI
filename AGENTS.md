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

### 4. `memory` (Long-Term Memory Persistence)
- **Directive:** Store and recall project insights, user preferences, and architectural decision records (ADRs) using `memory` MCP across chat sessions.

### 5. `playwright` (E2E & UI Browser Verification)
- **Directive:** Use `playwright` MCP to execute end-to-end browser tests, capture UI states, inspect rendered DOM elements, and verify frontend integration in dynamic applications.

---

## 📚 Skill Usage & Fresher Rules
- **Official First:** Prefer native skill definitions and documentation.
- **No Stale Skills:** Never execute or rely on deprecated framework patterns (e.g., legacy AngularJS, RxJS-heavy Angular, Spring Boot 2.x).
