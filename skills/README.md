# Skills Index

> Navegable index of the skills in this workspace. Use this to find the right skill folder quickly. Each skill lives in its own directory (`skills/<name>/SKILL.md`) and is auto-discovered by OpenCode and Antigravity.

## How skills are discovered

- **OpenCode** discovers `SKILL.md` files recursively, so nested category subfolders would work — but Antigravity does **not**.
- **Antigravity** reads only one level deep (`skills/<name>/SKILL.md`): nested sub-skills (e.g. the 48 `design-it/*` styles) are **not** listed as individual skills there. That is why the layout stays flat and `design-it` acts as a router. Do not reorganize skills into category subfolders.
- Skills with `disable-model-invocation: true` (currently 10: `ask-matt`, `cyber-audit`, `grill-with-docs`, `plan-phases-create`, `plan-phases-implement`, `setup-matt-pocock-skills`, `to-spec`, `to-tickets`, `triage`, `wayfinder`) are hidden from the model's skill inventory and are only invoked via slash command (`/plan-phases-create`, etc.).

Total: **116 skills** grouped into 17 categories. Design sub-styles (48) live under [`design-it`](design-it/SKILL.md) and are routed from there.

## 🗺️ Planning & Wayfinding  (13)

- **`ask-matt`** - Ask which skill or flow fits your situation. A router over the skills in this repo.
- **`create-work-breakdown-structure`** - Create a Work Breakdown Structure (WBS) and WBS Dictionary from project charter deliverables. Covers hierarchical decomposition, WBS coding, effort estimation, dependency identification, and critical path candidates.
- **`estimate-costs`** - Estimate the monetary cost of a WBS using a rate card. Takes a WBS Dictionary (effort in person-days per work package, with Responsible role) and produces a Cost Breakdown Structure (CBS) with per-package cost, rollups by WBS branch, contingency ranges, and totals. Use after create-work-breakdown-structure, when a project has effort estimates and you need a bottom-up budget, or when pricing out a quote for a client.
- **`grill-with-docs`** - A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go.
- **`grilling`** - Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
- **`plan-phases-create`** - Create a phased implementation plan for a large task. Interviews the user, explores the codebase, defines vertical-slice phases with public contracts, and writes the plan file only after user approval. Use when a task is too big for a single session or needs clear phases before implementing.
- **`plan-phases-implement`** - Implement exactly ONE phase of a plan created by /plan-phases-create, then stop. Never commits or pushes automatically. Use when a plan file exists in .agents/plans and you are asked to implement the next pending phase.
- **`research`** - Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
- **`setup-matt-pocock-skills`** - Configure this repo for the engineering skills — set up its issue tracker, triage label vocabulary, and domain doc layout. Run once before first use of the other engineering skills.
- **`to-spec`** - Turn the current conversation into a spec and publish it to the project issue tracker — no interview, just synthesis of what you've already discussed.
- **`to-tickets`** - Break a plan, spec, or the current conversation into a set of tracer-bullet tickets, each declaring its blocking edges, published to the configured tracker — edges as text in one file per ticket locally, or native blocking links on a real tracker.
- **`triage`** - Move issues and external PRs through a state machine of triage roles — categorise, verify, grill if needed, and write agent-ready briefs.
- **`wayfinder`** - Plan a huge chunk of work — more than one agent session can hold — as a shared map of decision tickets on your issue tracker, and resolve them one at a time until the way to the destination is clear.

## 🎨 Design & UX  (10)

- **`accessibility-compliance-accessibility-audit`** - You are an accessibility expert specializing in WCAG compliance, inclusive design, and assistive technology compatibility. Conduct audits, identify barriers, and provide remediation guidance.
- **`baseline-ui`** - Quickly deslop UI code by fixing spacing, hierarchy, typography, and small layout issues. Use when the interface needs a fast cleanup or polish pass.
- **`design-it`** - Routes frontend design tasks to 48 specific UI styles. Triggers for websites, app screens, or UI components requesting a specific aesthetic.
- **`design-system`** - Mechanical implementation invariants for frontend design: token architecture, typography hierarchy, loading order, FOUT prevention, chrome stability, motion timing, color semantics. Use with design when building components, pages, or design systems. (Aesthetic direction lives in the design-it skill.)
- **`fixing-accessibility`** - Audit and fix HTML accessibility issues including ARIA labels, keyboard navigation, focus management, color contrast, and form errors. Use when adding interactive controls, forms, dialogs, or reviewing WCAG compliance.
- **`high-end-visual-design`** - Use when designing expensive agency-grade interfaces with premium fonts, spatial rhythm, soft depth, and fluid microinteractions.
- **`industrial-brutalist-ui`** - Use when creating raw industrial or tactical telemetry UIs with rigid grids, stark typography, CRT effects, and high-density data.
- **`onboarding-ux`** - Onboarding and First Experience Design: progressive disclosure, empty-to-populated transitions, first-use tutorials, reducing friction. Use when designing first-time user experiences, onboarding flows, or reducing time-to-value.
- **`ux-design`** - User-Centered Design: Nielsen heuristics, task flows, information architecture, usability evaluation. Use when designing interfaces, evaluating usability, or applying UX principles beyond visual aesthetics.
- **`ux-writing`** - UX Writing and Microcopy: labels, error messages, empty states, tooltips, onboarding copy, tone of voice. Use when writing user-facing text in interfaces to ensure clarity, consistency, and accessibility.

## 🟦 Angular Frontend  (9)

- **`angular`** - Modern Angular (v17-v21) development: components, services, dependency injection, routing, forms, and Standalone Components. Use for general Angular coding, SSR/hydration, or migrating apps to modern patterns.
- **`angular-22`** - Angular 22+ modern architecture: Zoneless apps, Signals-first state, Control Flow, LinkedSignal, and Resource API. Use when the app targets Angular 22+ or uses cutting-edge reactivity and async resources.
- **`angular-best-practices`** - Angular performance optimization and best practices guide. Use when writing, reviewing, or refactoring Angular code for optimal performance, bundle size, and rendering efficiency.
- **`angular-ui-patterns`** - Modern Angular UI patterns for loading states, error handling, and data display. Use when building UI components, handling async data, or managing component states.
- **`markstream-angular`** - Integrate the alpha markstream-angular renderer into Angular 20+ applications with standalone components, signals, safe HTML defaults, and optional peer features.
- **`mobile-ux-patterns`** - Mobile UX patterns: touch targets, thumb zones, gestures, bottom navigation, swipe actions, mobile forms, responsive design. Use when building mobile-first web apps, PWAs, or Angular responsive layouts for phones and tablets.
- **`pwa`** - Progressive Web App implementation with Angular: service workers, manifest.json, Workbox, offline-first caching, installability (beforeinstallprompt), App Shell pattern. Use when adding PWA capabilities to an Angular application.
- **`real-time-web-stack`** - Real-time web stack: WebSocket (STOMP), Server-Sent Events (SseEmitter), and polling in Spring Boot + Angular 22. Covers reconnection strategies, heartbeats, Signal integration, and choosing between transport protocols.
- **`web-push-notifications`** - Web Push Notifications: VAPID keys, Push API, service worker handlers, permission UX, subscription persistence in Spring Boot, web-push library, FCM Android, iOS 16.4+. Use when adding push notifications to an Angular PWA.

## 🟨 React / JavaScript / TypeScript  (8)

- **`frontend-architecture`** - A portable, framework-agnostic architecture style for any React or React Native frontend. Organizes apps into feature modules with page/screen directories, a strict server-state vs UI-state split, barrel-only cross-module imports, co-located styles, and clear component-promotion rules.
- **`frontend-developer`** - Build React components, implement responsive layouts, and handle client-side state management. Masters React 19, Next.js 15, and modern frontend architecture.
- **`frontend-security-coder`** - Expert in secure frontend coding practices specializing in XSS prevention, output sanitization, and client-side security patterns.
- **`nextjs-best-practices`** - Next.js App Router principles. Server Components, data fetching, routing patterns.
- **`javascript-pro`** - Master modern JavaScript with ES6+, async patterns, and Node.js APIs. Handles promises, event loops, and browser/Node compatibility.
- **`javascript-typescript-typescript-scaffold`** - You are a TypeScript project architecture expert specializing in scaffolding production-ready Node.js and frontend applications. Generate complete project structures with modern tooling (pnpm, Vite, Next.js, tsup, Vitest).
- **`typescript-pro`** - Master TypeScript with advanced types, generics, and strict type safety. Handles complex type systems, decorators, and enterprise-grade patterns.
- **`i18n-localization`** - Internationalization and localization patterns. Detecting hardcoded strings, managing translations, locale files, RTL support.

## ☕ Java / Spring Boot  (3)

- **`java-lts`** - Java 21 & 25 LTS language features and idioms: Record Patterns, Pattern Matching for switch, Sequenced Collections, Scoped Values, ZGC, and Loom virtual threads. Use for modern Java code style and JVM performance.
- **`java-pro`** - Build Java applications with Spring Boot 3.x/4.x, GraalVM native images, virtual threads, and cloud-native patterns. Use when developing Spring-based services, REST APIs, or enterprise Java backends.
- **`spring-boot`** - Enterprise Spring Boot 4.x / 3.5 LTS architecture, Virtual Threads (Project Loom), Spring AI, Declarative HTTP Clients, and Security best practices.

## ⚙️ Backend (Node / Python / Go)  (6)

- **`backend-architect`** - Backend architecture at the system level: microservices, distributed systems, event-driven design, and scalability. Use when designing overall backend structure, service boundaries, or integrations — not for writing endpoint code.
- **`backend-dev-guidelines`** - Write production-grade backend code: routes, controllers, services, repositories, Express middleware, and Prisma database access. Use when implementing or refactoring concrete endpoint and data-access layers.
- **`backend-security-coder`** - Expert in secure backend coding practices specializing in input validation, authentication, and API security. Use PROACTIVELY for backend security implementations or security code reviews.
- **`bullmq-specialist`** - BullMQ expert for Redis-backed job queues, background processing,
- **`fastapi-pro`** - Build high-performance async APIs with FastAPI, SQLAlchemy 2.0, and Pydantic V2. Master microservices, WebSockets, and modern Python async patterns.
- **`grpc-golang`** - Build production-ready gRPC services in Go with mTLS, streaming, and observability. Use when designing Protobuf contracts with Buf or implementing secure service-to-service transport.

## 🔗 API & Integration  (8)

- **`api-design-principles`** - Design REST and GraphQL APIs from scratch: resource modeling, endpoints, verbs, status codes, naming, and API contracts. Use when creating a new API's design or interface.
- **`api-patterns`** - Decide between REST, GraphQL, and tRPC for a project, then pick response formats, versioning strategy, and pagination. Use when comparing API technologies or standardizing conventions.
- **`api-security-best-practices`** - Implement secure API design patterns including authentication, authorization, input validation, rate limiting, and protection against common API vulnerabilities
- **`api-security-testing`** - API security testing workflow for REST and GraphQL APIs covering authentication, authorization, rate limiting, input validation, and security best practices.
- **`auth-implementation-patterns`** - Build secure, scalable authentication and authorization systems using industry-standard patterns and modern best practices.
- **`graphql-architect`** - Master modern GraphQL with federation, performance optimization, and enterprise security. Build scalable schemas, implement advanced caching, and design real-time systems.
- **`mercadopago`** - Integration patterns for MercadoPago LATAM (Checkout Pro, Checkout API, Pix, Subscriptions, Webhook Security, Node/Java SDKs).
- **`webhooks`** - Webhook design and implementation: request/response contracts, idempotency, retries with exponential backoff, HMAC signature verification, replay protection. Use when building webhook receivers or senders in Spring Boot or any backend.

## 🏛️ Architecture Patterns  (4)

- **`cqrs-implementation`** - Implement Command Query Responsibility Segregation for scalable architectures. Use when separating read and write models, optimizing query performance, or building event-sourced systems.
- **`ddd-tactical-patterns`** - Apply DDD tactical patterns in code using entities, value objects, aggregates, repositories, and domain events with explicit invariants.
- **`domain-driven-design`** - Plan and route Domain-Driven Design work from strategic modeling to tactical implementation and evented architecture patterns.
- **`event-sourcing-architect`** - Expert in event sourcing, CQRS, and event-driven architecture patterns. Masters event store design, projection building, saga orchestration, and eventual consistency patterns. Use PROACTIVELY for event-sourced systems, audit trail requirements, or complex domain modeling with temporal queries.

## 🗄️ Database  (7)

- **`claimable-postgres`** - Provision instant temporary Postgres databases via Claimable Postgres by Neon (neon.new) with no login, signup, or credit card. Supports REST API, CLI, and SDK. Use when users ask for a quick Postgres environment, a throwaway DATABASE_URL for prototyping/tests, or "just give me a DB for quick testing".
- **`database-admin`** - Operate and administer databases in production: provisioning, backups, replication, monitoring, and automation for cloud databases. Use for DB operations, incidents, and reliability.
- **`database-architect`** - Architect the data layer from the ground up: technology selection, schema modeling, and scalable database architecture. Use when starting a new project''s persistence or choosing between database engines.
- **`database-design`** - Database design decisions: schema design, indexing strategy, ORM selection, and serverless database trade-offs. Use when modeling tables, choosing indexes, or picking an ORM for a feature.
- **`database-migrations-sql-migrations`** - SQL database migrations with zero-downtime strategies for PostgreSQL, MySQL, and SQL Server. Focus on data integrity and rollback plans.
- **`database-optimizer`** - Tune database performance: slow queries, index optimization, EXPLAIN analysis, and scalability bottlenecks. Use when a database is slow, queries regress, or the data layer needs optimization.
- **`drizzle-orm-expert`** - Expert in Drizzle ORM for TypeScript — schema design, relational queries, migrations, and serverless database integration. Use when building type-safe database layers with Drizzle.

## 🤖 AI / LLM / Agents  (13)

- **`ai-engineer`** - Build production-ready LLM applications, advanced RAG systems, and intelligent agents. Implements vector search, multimodal AI, agent orchestration, and enterprise AI integrations.
- **`agent-creator`** - Create custom AI subagents with proper plugin structure, persona generation, and companion routing skills.
- **`agent-memory`** - Use the agentMemory library (webzler/agentMemory): persistent, searchable knowledge management for AI agents. Use when integrating, configuring, or extending this specific agentMemory package.
- **`agent-memory-mcp`** - Expose agent memory through MCP: architecture, patterns, and decisions for connecting AI agents to persistent memory via the memory MCP server. Use when wiring memory into agents through MCP tools.
- **`agent-memory-systems`** - Design and architect AI agent memory systems: context windows, short-term and long-term memory, vector stores, and cognitive architectures. Use when planning how an agent should persist, retrieve, and organize knowledge.
- **`agent-orchestration-improve-agent`** - Systematic improvement of existing agents through performance analysis, prompt engineering, and continuous iteration.
- **`agent-orchestrator`** - Meta-skill that orchestrates all agents in the ecosystem: automatic skill scanning, capability matching, multi-skill workflow coordination, and registry management.
- **`autonomous-agents`** - Design, build, and orchestrate autonomous AI agents that decompose goals, plan, use tools, and self-correct. Use when implementing agent loops, tool-calling, multi-agent systems, or agent reliability.
- **`langchain-architecture`** - Master the LangChain framework for building sophisticated LLM applications with agents, chains, memory, and tool integration.
- **`langgraph`** - Expert in LangGraph - the production-grade framework for building
- **`llm-app-patterns`** - Production-ready patterns for building LLM applications: RAG, agents, prompt design, tool use, streaming, and evaluation, inspired by [Dify](https://github.com/langgenius/dify). Use when architecting LLM features like chatbots, copilots, or retrieval pipelines.
- **`llm-structured-output`** - Get reliable JSON, enums, and typed objects from LLMs using response_format, tool_use, and schema-constrained decoding across OpenAI, Anthropic, and Google APIs. risk: safe source: community date_added: "2026-03-12
- **`context7-mcp`** - This skill should be used when the user asks about libraries, frameworks, API references, or needs code examples. Activates for setup questions, code generation involving libraries, or mentions of specific frameworks like React, Vue, Next.js, Prisma, Supabase, etc.

## 🧩 MCP Development  (2)

- **`mcp-builder`** - Design MCP (Model Context Protocol) servers that let LLMs interact with external services through well-crafted tools. Use when architecting the tool surface and behavior of an MCP server.
- **`mcp-tool-developer`** - Build full-stack MCP (Model Context Protocol) servers from scratch in TypeScript or Python: tool implementation, testing, deployment, and registry publishing. Use when implementing or shipping an MCP server.

## ☁️ DevOps & Cloud  (12)

- **`aws-cdk-development`** - AWS Cloud Development Kit (CDK) expert for building cloud infrastructure with TypeScript/Python. Use when creating CDK stacks, defining CDK constructs, implementing infrastructure as code, or when the user mentions CDK, CloudFormation, IaC, cdk synth, cdk deploy, or wants to define AWS infrastructure with Infrastructure as Code.
- **`aws-serverless`** - Specialized skill for building production-ready serverless
- **`gcp-cloud-run`** - Specialized skill for building production-ready serverless
- **`docker-expert`** - You are an advanced Docker containerization expert with comprehensive, practical knowledge of container optimization, security hardening, multi-stage builds, orchestration patterns, and production deployment strategies based on current industry best practices.
- **`container-security-hardening`** - Harden Docker/container images and runtime deployments with secure base images, non-root users, CVE scanning, SBOM/signing, seccomp/AppArmor, and Kubernetes pod security controls. Use for Dockerfile security reviews, container CVEs, image scanning, distroless images, or production hardening. category: security risk: safe source: community date_added: "2026-05-30
- **`k8s-manifest-generator`** - Step-by-step guidance for creating production-ready Kubernetes manifests including Deployments, Services, ConfigMaps, Secrets, and PersistentVolumeClaims.
- **`kubernetes-architect`** - Expert Kubernetes architect specializing in cloud-native infrastructure, advanced GitOps workflows (ArgoCD/Flux), and enterprise container orchestration.
- **`devcontainer-setup`** - Creates devcontainers with Claude Code, language-specific tooling (Python/Node/Rust/Go), and persistent volumes. Use when adding devcontainer support to a project, setting up isolated development environments, or configuring sandboxed Claude Code workspaces.
- **`ci-cd-and-automation`** - Automates CI/CD pipeline setup. Use when setting up or modifying build and deployment pipelines. Use when you need to automate quality gates, configure test runners in CI, or establish deployment strategies.
- **`github-actions-advanced`** - Design, debug, and harden GitHub Actions CI/CD workflows, including reusable workflows, matrix builds, self-hosted runners, OIDC authentication, caching, environments, secrets, and release automation. category: devops risk: safe source: community date_added: "2026-05-30
- **`observability-monitoring-monitor-setup`** - You are a monitoring and observability expert specializing in implementing comprehensive monitoring solutions. Set up metrics collection, distributed tracing, log aggregation, and create insightful dashboards and alerts.
- **`prometheus-configuration`** - Complete guide to Prometheus setup, metric collection, scrape configuration, and recording rules.

## 🐚 Shell & Linux  (3)

- **`bash-linux`** - Bash/Linux terminal patterns. Critical commands, piping, error handling, scripting. Use when working on macOS or Linux systems.
- **`bash-pro`** - Master of defensive Bash scripting for production automation, CI/CD
- **`linux-shell-scripting`** - Provide production-ready shell script templates for common Linux system administration tasks including backups, monitoring, user management, log analysis, and automation. These scripts serve as building blocks for security operations and penetration testing environments.

## 🔀 Git & GitHub  (3)

- **`git-advanced-workflows`** - Master advanced Git techniques to maintain clean history, collaborate effectively, and recover from any situation with confidence.
- **`git-pr-workflows-git-workflow`** - Orchestrate review, tests, commits, branch pushes, and pull-request creation with parallel agents. Use when completed changes must move through validation into a PR or guarded merge.
- **`github-automation`** - Operate GitHub issues, pull requests, branches, checks, workflows, and permissions through Rube MCP. Use when GitHub work must be queried or changed programmatically with repository-policy safeguards.

## 🧪 Testing  (4)

- **`cypress-skill`** - Generates production-grade Cypress E2E and component tests in JavaScript or TypeScript. Supports local execution and TestMu AI cloud. Use when the user asks to write Cypress tests, set up Cypress, test with cy commands, or mentions "Cypress", "cy.visit", "cy.get", "cy.intercept".
- **`jest-skill`** - Generates Jest unit and integration tests in JavaScript or TypeScript. Covers mocking, snapshots, async testing, and React component testing. Use when user mentions "Jest", "describe/it/expect", "jest.mock", "toMatchSnapshot". Triggers on: "Jest", "expect().toBe()", "jest.mock", "test()".
- **`junit-5-skill`** - Generates production-grade JUnit 5 unit and integration tests in Java. Covers assertions, parameterized tests, lifecycle hooks, mocking with Mockito, and nested tests. Use when user mentions "JUnit", "JUnit 5", "@Test", "assertEquals", "Assertions", "Java unit test". Triggers on: "@Test", "Mockito", "parameterized tests".
- **`e2e-testing`** - End-to-end testing workflow with Playwright for browser automation, visual regression, cross-browser testing, and CI/CD integration.

## ⚖️ Code Quality & Engineering  (8)

- **`clean-code`** - This skill embodies the principles of \"Clean Code\" by Robert C. Martin (Uncle Bob). Use it to transform \"code that works\" into \"code that is clean.\
- **`code-review-excellence`** - Improve code-review process and culture: constructive feedback, systematic analysis, and collaborative review practices. Use when establishing review workflows, mentoring reviewers, or planning review strategies.
- **`code-reviewer`** - Perform rigorous code reviews of diffs and pull requests: correctness, security, performance, and readability. Use when reviewing a PR, a diff, or specific code for issues before merge.
- **`code-simplification`** - Simplifies code for clarity. Use when refactoring code for clarity without changing behavior. Use when code works but is harder to read, maintain, or extend than it should be. Use when reviewing code that has accumulated unnecessary complexity.
- **`debugging-code`** - Hands-on interactive debugging: set breakpoints, step through execution, inspect live variables, and trace call stacks. Use when you need to debug a running program with a debugger, not just reason about it.
- **`debugging-strategies`** - Apply systematic debugging methodology: reproduce, isolate, bisect, and root-cause problems with proven strategies and tools. Use when approaching a stubborn bug methodically, before or alongside hands-on debugging.
- **`error-handling-patterns`** - Build resilient applications with robust error handling strategies that gracefully handle failures and provide excellent debugging experiences.
- **`performance-optimization`** - Optimizes application performance. Use when performance requirements exist, when you suspect performance regressions, or when Core Web Vitals or load times need improvement. Use when profiling reveals bottlenecks that need fixing.

## 🛡️ Security  (3)

- **`audit-skills`** - Expert security auditor for AI Skills and Bundles. Performs non-intrusive static analysis to identify malicious patterns, data leaks, system stability risks, and obfuscated payloads across Windows, macOS, Linux/Unix, and Mobile (Android/iOS).
- **`cyber-audit`** - Run read-only exposure checks for security advisories and write a structured local audit report.
- **`gdpr-data-handling`** - Practical implementation guide for GDPR-compliant data processing, consent management, and privacy controls.
