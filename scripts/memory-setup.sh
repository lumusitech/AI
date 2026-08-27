#!/usr/bin/env bash
# ==============================================================================
# Memory Setup — per-user local memory database for the MCP memory server.
# ==============================================================================
# Detects the GitHub/user identity, picks a local (never committed) location for
# the knowledge-graph file, writes MEMORY_FILE_PATH into ~/.agent/.env, ensures
# the shell loads that .env, and optionally migrates a legacy repo-tracked
# memory.jsonl into the new per-user location.
#
# Usage:
#   bash scripts/memory-setup.sh              # interactive (defaults on non-TTY)
#   bash scripts/memory-setup.sh --non-interactive   # use defaults, never prompt
# ==============================================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${REPO_DIR}/.env"
INTERACTIVE=0
if [ "${1:-}" = "--non-interactive" ]; then
  INTERACTIVE=0
elif [ -t 0 ] && [ -t 1 ]; then
  INTERACTIVE=1
fi

prompt() {
  # prompt <message> <default> ; echoes the chosen value
  local msg="$1" default="$2" answer
  if [ "${INTERACTIVE}" -ne 1 ]; then
    echo "${default}"
    return 0
  fi
  read -r -p "${msg} [${default}]: " answer
  echo "${answer:-${default}}"
}

confirm() {
  # confirm <message> <default_yes y/n> ; returns 0 if yes
  local msg="$1" default="$2" answer
  if [ "${INTERACTIVE}" -ne 1 ]; then
    case "${default}" in
      y|Y) return 0 ;;
      *) return 1 ;;
    esac
  fi
  read -r -p "${msg} (y/n) [${default}]: " answer
  case "${answer:-${default}}" in
    y|Y) return 0 ;;
    *) return 1 ;;
  esac
}

sanitize_name() {
  # sanitize a user id into a safe [a-z0-9-] slug
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//;s/-*$//'
}

# Portable in-place sed: GNU `sed -i` and BSD `sed -i ''` differ (macOS treats
# `sed -i -E` as `-i` with backup extension "-E", disabling extended regex and
# breaking `\1` backreferences). A temp file + mv is safe on both.
sed_inplace() {
  local expr="$1" file="$2" tmp
  tmp="${file}.tmp.$$"
  sed -E "${expr}" "${file}" > "${tmp}"
  mv "${tmp}" "${file}"
}

# --- 1. Detect user ----------------------------------------------------------
detect_user() {
  if command -v gh >/dev/null 2>&1; then
    local login
    if login="$(gh api user -q .login 2>/dev/null)"; then
      [ -n "${login}" ] && { echo "${login}"; return 0; }
    fi
  fi
  local name
  if name="$(git config --get user.name 2>/dev/null)"; then
    [ -n "${name}" ] && { echo "${name}"; return 0; }
  fi
  whoami
}

USER_SLUG="$(sanitize_name "$(detect_user)")"
if [ -z "${USER_SLUG}" ]; then
  echo "❌ No se pudo detectar el usuario del sistema." >&2
  exit 1
fi
echo "👤 Usuario detectado: ${USER_SLUG}"

# --- 2. Pick memory location ------------------------------------------------
DEFAULT_MEM_FILE="${HOME}/.local/share/opencode/memory/${USER_SLUG}.jsonl"

if [ -n "${MEMORY_FILE_PATH:-}" ]; then
  # Respect an already-set value (from environment or existing .env)
  MEM_FILE="${MEMORY_FILE_PATH}"
  echo "ℹ️  Usando MEMORY_FILE_PATH existente: ${MEM_FILE}"
else
  MEM_FILE="$(prompt "¿Ubicación de la memoria local de '${USER_SLUG}'?" "${DEFAULT_MEM_FILE}")"
  # expand leading ~ if provided
  case "${MEM_FILE}" in
    "~/"*) MEM_FILE="${HOME}/${MEM_FILE#\~/}" ;;
  esac
fi

MEM_DIR="$(dirname "${MEM_FILE}")"
mkdir -p "${MEM_DIR}"

# --- 3. Write MEMORY_FILE_PATH into ~/.agent/.env ---------------------------
set_env_value() {
  local file="$1" key="$2" value="$3"
  if [ ! -f "${file}" ]; then
    touch "${file}"
  fi
  if grep -qE "^[[:space:]]*${key}=" "${file}"; then
    sed_inplace "s|^([[:space:]]*${key}=).*|\1${value}|" "${file}"
  else
    printf '%s=%s\n' "${key}" "${value}" >> "${file}"
  fi
}

set_env_value "${ENV_FILE}" "MEMORY_FILE_PATH" "${MEM_FILE}"
echo "✅ MEMORY_FILE_PATH=${MEM_FILE} escrito en ${ENV_FILE}"

# --- 4. Ensure the shell loads ~/.agent/.env --------------------------------
detect_shell_rc() {
  local shell_name rc
  shell_name="$(basename "${SHELL:-${SHELL_NAME:-}}")"
  case "${shell_name}" in
    zsh)   rc="${HOME}/.zshrc" ;;
    bash)  rc="${HOME}/.bashrc" ;;
    fish)  rc="${HOME}/.config/fish/config.fish" ;;
    *)     echo ""; return 0 ;;
  esac
  echo "${rc}"
}

RC_FILE="$(detect_shell_rc)"
MARKER="# >>> lumusitech agent env >>>"
if [ -n "${RC_FILE}" ]; then
  mkdir -p "$(dirname "${RC_FILE}")"
  if [ -f "${RC_FILE}" ]; then
    # Remove legacy unmarked loader blocks (pre-marker versions) so a single
    # marked copy remains — the repo is the source of truth.
    sed_inplace '/^# Load ~\/\.agent\/\.env credentials \(GITHUB_TOKEN, etc\.\)/,/^fi[[:space:]]*$/d' "${RC_FILE}"
  fi
  if [ -f "${RC_FILE}" ] && grep -qF "${MARKER}" "${RC_FILE}" 2>/dev/null; then
    echo "✅ ${RC_FILE} ya carga ~/.agent/.env"
  else
    if [ -f "${RC_FILE}" ]; then
      # Any other unmarked loader variant: remove it before appending ours.
      sed_inplace '/^# Load ~\/\.agent\/\.env credentials/,/^fi[[:space:]]*$/d' "${RC_FILE}"
    fi
    cat >> "${RC_FILE}" <<'BLOCK'

# >>> lumusitech agent env >>>
# Load ~/.agent/.env credentials (GITHUB_TOKEN, MEMORY_FILE_PATH, etc.) for opencode MCP servers
if [ -f "$HOME/.agent/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$HOME/.agent/.env"
    set +a
fi
# <<< lumusitech agent env <<<
BLOCK
    echo "✅ Bloque de carga añadido a ${RC_FILE} (recarga tu shell para aplicarlo)"
  fi
else
  echo "⚠️  Shell no reconocido (SHELL=${SHELL:-desconocida}). Configura el source de ~/.agent/.env manualmente."
fi

# --- 5. Seed + migrate legacy memory.jsonl ----------------------------------
if [ -s "${MEM_FILE}" ]; then
  echo "✅ Base de memoria per-usuario ya existe: ${MEM_FILE} ($(wc -l < "${MEM_FILE}") líneas)"
elif [ -f "${REPO_DIR}/memory.jsonl" ]; then
  if confirm "¿Migrar el memory.jsonl legacy del repo a ${MEM_FILE}?" y; then
    cp "${REPO_DIR}/memory.jsonl" "${MEM_FILE}"
    echo "✅ Migrado memory.jsonl legacy → ${MEM_FILE} ($(wc -l < "${MEM_FILE}") líneas)"
    if confirm "¿Eliminar el memory.jsonl del repo (para no commitear memorias)?" y; then
      rm -f "${REPO_DIR}/memory.jsonl"
      echo "✅ Eliminado ${REPO_DIR}/memory.jsonl"
    fi
  else
    : > "${MEM_FILE}"
    echo "ℹ️  Base vacía creada en ${MEM_FILE} (no se migró el legacy)"
  fi
else
  : > "${MEM_FILE}"
  echo "✅ Base de memoria creada: ${MEM_FILE}"
fi

echo ""
echo "🎉 Memoria per-usuario lista:"
echo "   • Archivo:   ${MEM_FILE}"
echo "   • Variable:  MEMORY_FILE_PATH (en ${ENV_FILE})"
echo "   • Shell rc:  ${RC_FILE:-no configurado}"
echo "   • Próximo paso: reinicia opencode para que el MCP memory use la nueva ruta."
