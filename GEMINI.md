# 🧠 Directivas Globales del Agente (Gemini CLI / Antigravity)

> Reglas globales y directivas de comportamiento para el agente de Gemini CLI / Antigravity, aplicadas en todos los proyectos y máquinas.

---

## 📌 Directivas Core de Ingeniería

### 1. Calidad y Principios de Código
- **Estándares:** Adherencia estricta a **SOLID**, **KISS**, **SoC** (Separación de Responsabilidades) y **DRY**.
- **Pragmatismo:** Evitar abstracción prematura o sobre-ingeniería. Diseñar software limpio y escalable.

### 2. TypeScript (Modo Estricto)
- **Política Cero `any`:** `any` está estrictamente prohibido.
- **Type Safety:** Priorizar interfaces, genéricos y utility types. Recurrir a `unknown` con type guards explícitos cuando sea necesario.

### 3. Angular Moderno (v22+)
- **Zoneless por defecto:** Aplicaciones zoneless vía `provideExperimentalZonelessChangeDetection()`.
- **Signals primero:** Estado reactivo gestionado con `signal()`, `computed()` y `linkedSignal()`.
- **Async Resources:** Usar `resource()` y `rxResource()` para llamadas API; eliminar boilerplate de RxJS donde los Signals nativos basten.
- **Control Flow & Inputs:** Usar `@if`, `@for`, `@switch` y primitivas signal `input()`, `output()`, `model()`.

### 4. Spring Boot Empresarial (v4.x / 3.5 LTS) & Java (21/25 LTS)
- **Virtual Threads:** Habilitar virtual threads de Loom por defecto (`spring.threads.virtual.enabled=true`).
- **Spring AI:** Usar abstracciones de Spring AI para LLMs, Embeddings y Vector Stores (Pgvector/Qdrant).
- **Clientes Declarativos:** Preferir interfaces `@HttpExchange` sobre RestTemplate/WebClient imperativos.
- **Idiomas Java Modernos:** Usar Record Patterns, Pattern Matching para switch, Sequenced Collections y Scoped Values.

### 5. Pragmatismo Operativo y Economía de Tokens en Tareas de Sistema
- **Instalación directa sin sobre-auditoría:** Ante solicitudes de instalación de binarios o paquetes locales (.tar.gz, AppImage, scripts), ejecutar directamente el flujo estándar: extracción al destino, symlink a `~/.local/bin`, lanzador `.desktop` con icono e incorporación a Chezmoi si aplica. No clonar repositorios externos, no ejecutar análisis de dependencias innecesarios ni herramientas lentas (`npx asar`) salvo falla evidente.
- **Cero ejecución de GUIs en background:** Queda estrictamente prohibido ejecutar binarios que levanten ventanas gráficas, navegadores o servidores de lenguaje para "probar" la instalación. La verificación debe ser puramente estática (`desktop-file-validate`, permisos en `$PATH` y existencia de assets).
- **Resolución ágil de permisos:** Si la tarea no exige explícitamente root o el entorno carece de `sudo` sin clave, proceder de inmediato en espacio de usuario (`~/.local`) sin detener el flujo con preguntas redundantes.
- **Conciencia de costo:** Cada comando y tool call tiene un costo real en tokens y tiempo; priorizar siempre el camino más directo, atómico y eficiente.

### 6. Autonomía de Ejecución y Política de Permisos (Zero-Prompting en Lectura)
- **Cero preguntas para lectura y exploración:** Queda estrictamente PROHIBIDO pedir confirmación, preguntar al usuario o solicitar permisos para comandos de consulta, exploración o inspección del sistema (`ls`, `cat`, `grep`, `find`, `file`, `stat`, `git status`, `git log`, `git diff`, `which`, `ps`, etc.). Toda acción de solo lectura debe ejecutarse de forma 100% autónoma y silenciosa.
- **Autonomía en archivos y directorios temporales:** Se permite crear, manipular y eliminar archivos en ubicaciones temporales (`/tmp`, directorios scratch) sin consultar al usuario, siempre que se limpien al terminar.
- **Confirmación exclusiva para mutaciones persistentes:** ÚNICAMENTE se debe solicitar confirmación o preguntar al usuario antes de ejecutar mutaciones permanentes sobre el sistema en cuestión:
  - Modificaciones al sistema operativo o paquetes globales (`pacman`, configs en `/etc/`).
  - Instalación, modificación o eliminación persistente de aplicaciones o servicios.
  - Modificaciones en dotfiles (`chezmoi`, `~/.config/`, etc.) o en repositorios de código.
- **Formato de confirmación:** Cuando una mutación requiera confirmación, presentar de forma directa y concisa qué se va a modificar y por qué, sin preguntas exploratorias intermedias.

---

## 🛠️ Reglas de Operación de MCP

### 1. `context7` (Fetch de Documentación Oficial)
- **Directiva:** Usar siempre `context7` para obtener documentación actualizada al trabajar con librerías, frameworks, SDKs o APIs (Angular, Spring, NestJS, MercadoPago, etc.). Nunca adivinar firmas de APIs.
- Usar `context7` siempre que el usuario pregunte por una librería, framework, SDK, API, CLI tool o servicio cloud — incluso los conocidos (React, Next.js, Prisma, Express, Tailwind, Django, Spring Boot). Incluye sintaxis de API, configuración, migración de versiones, debugging específico, setup e instrucciones de CLI. Usar incluso cuando creas saber la respuesta.
- **No usar para:** refactoring, escribir scripts desde cero, debugging de lógica de negocio, code review, o conceptos generales de programación.

#### Pasos de uso de `context7`:
1. Siempre empezar con `resolve-library-id` usando el nombre de la librería y qué se busca en su documentación, salvo que el usuario dé un ID exacto en formato `/org/project`.
2. Elegir el mejor match (ID: `/org/project`) por: coincidencia de nombre, relevancia de descripción, nº de snippets, reputación (High/Medium preferido) y benchmark. Probar nombres alternativos si el resultado no encaja. Usar IDs por versión cuando el usuario mencione una versión.
3. `query-docs` con el ID seleccionado, scoped a un solo concepto. Si la pregunta abarca varios conceptos, hacer una llamada por concepto (las queries combinadas diluyen el ranking).
4. Responder usando la documentación obtenida.

### 2. `codegraph` (Grafo del Código Base)
- **Directiva:** Usar `codegraph` para navegación por símbolos basada en grafos, seguimiento de dependencias y análisis de refactorización en codebases complejos.

### 3. `github` (Integración con GitHub)
- **Directiva:** Realizar seguimiento de issues, revisión de PRs, inspección de commits y análisis de workflows vía `github`, autenticado con `GITHUB_TOKEN`.

### 4. `memory` (Persistencia de Memoria a Largo Plazo)
- **Directiva:** Almacenar y recuperar insights de proyectos, preferencias del usuario y registros de decisiones de arquitectura (ADRs) usando `memory` entre sesiones.

### 5. `playwright` (Verificación E2E y UI)
- **Directiva:** Usar `playwright` para ejecutar pruebas de browser end-to-end, capturar estados de UI, inspeccionar el DOM renderizado y verificar integración frontend en aplicaciones dinámicas.

---

## 📚 Reglas de Uso de Skills
- **Official First:** Preferir definiciones y documentación nativas de skills.
- **No Stale Skills:** Nunca ejecutar ni depender de patrones de frameworks obsoletos (p. ej. AngularJS legacy, Angular con mucho RxJS, Spring Boot 2.x).
