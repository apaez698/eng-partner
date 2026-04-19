#!/bin/bash

# ─────────────────────────────────────────
# eng-partner — pipeline encadenado
# Uso: ./flow.sh ./mi-repo "descripción del ticket"
# ─────────────────────────────────────────

REPO=$1
TASK=$2
AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/agents"
PROFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)/profiles"
CLAUDE_DIR="$HOME/.claude"
VAULT_DIR="$(cd "$(dirname "$0")/.." && pwd)/vault"
LOG_FILE="$VAULT_DIR/session-$(date +%Y%m%d-%H%M).md"

MODEL_READER="claude-sonnet-4-6"
MODEL_TASKDEFINER="claude-sonnet-4-6"
MODEL_BUILDER="claude-sonnet-4-6"
MODEL_ANALYST="claude-opus-4-6"

if [ -z "$REPO" ] || [ -z "$TASK" ]; then
  echo "Uso: ./flow.sh [path/repo] [descripción del ticket]"
  echo ""
  echo "Ejemplo:"
  echo "  ./flow.sh ~/proyectos/payment-approval 'validar referencias duplicadas'"
  exit 1
fi

if [ ! -d "$REPO" ]; then
  echo "❌ El directorio '$REPO' no existe"
  exit 1
fi

cd "$REPO"
mkdir -p "$VAULT_DIR"

log() { echo "$1" | tee -a "$LOG_FILE"; }
separator() { echo ""; echo "══════════════════════════════════════"; echo ""; }

log "# Sesión: $TASK"
log "**Fecha**: $(date '+%Y-%m-%d %H:%M')"
log "**Repo**: $REPO"
log ""

# ─── PASO 1: CodeReader — contexto ───────
separator
echo "🔍 Paso 1 — Leyendo el repo... [$MODEL_READER]"
separator

cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
cat "$AGENTS_DIR/CodeReader.md" >> "$CLAUDE_DIR/CLAUDE.md"

CONTEXT=$(echo "@reader analiza . enfocándote en los archivos relevantes para: $TASK" | claude --model $MODEL_READER --dangerously-skip-permissions --print 2>&1 | tee /dev/tty)

log "## Contexto del repo"
log "$CONTEXT"

# ─── PASO 2: TaskDefiner — tareas ────────
separator
echo "📋 Paso 2 — Definiendo tareas... [$MODEL_TASKDEFINER]"
separator

cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
cat "$AGENTS_DIR/TaskDefiner.md" >> "$CLAUDE_DIR/CLAUDE.md"

TASKS=$(echo "@agente contexto:
$CONTEXT

para: $TASK" | claude --model $MODEL_TASKDEFINER --dangerously-skip-permissions --print 2>&1 | tee /dev/tty)

log "## Tareas definidas"
log "$TASKS"

separator
echo "¿Qué tareas quieres implementar?"
echo "Ejemplos: '1 y 3' | 'todas' | 'solo 2' | 'salir'"
echo ""
read -r -p "→ " SELECTED

[ "$SELECTED" = "salir" ] && echo "" && echo "Sesión guardada en: $LOG_FILE" && exit 0
log "**Tareas seleccionadas**: $SELECTED"

# ─── PASO 3: Builder — propuesta ─────────
separator
echo "🔨 Paso 3 — Generando propuesta... [$MODEL_BUILDER]"
separator

cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
cat "$AGENTS_DIR/Builder.md" >> "$CLAUDE_DIR/CLAUDE.md"

PROPOSAL=$(echo "@builder propone los cambios para implementar las siguientes tareas.

Ticket: $TASK
Tareas seleccionadas: $SELECTED
Contexto del repo:
$CONTEXT
Tareas definidas:
$TASKS

Propón los cambios como unidades independientes y espera aprobación." | claude --model $MODEL_BUILDER --dangerously-skip-permissions --print 2>&1 | tee /dev/tty)

log "## Propuesta de implementación"
log "$PROPOSAL"

separator
echo "¿Qué cambios apruebas para implementar?"
echo "Ejemplos: '1 y 2' | 'todos' | 'solo 1' | 'salir'"
echo ""
read -r -p "→ " APPROVED

[ "$APPROVED" = "salir" ] && echo "" && echo "Sesión guardada en: $LOG_FILE" && exit 0
log "**Cambios aprobados**: $APPROVED"

# ─── PASO 4: Builder — implementación ────
separator
echo "⚙️  Paso 4 — Implementando cambios: $APPROVED... [$MODEL_BUILDER]"
separator

IMPLEMENTATION=$(echo "@builder implementa ÚNICAMENTE los cambios aprobados: $APPROVED

Ticket: $TASK
Propuesta de referencia:
$PROPOSAL

Genera el código final completo listo para copiar, archivo por archivo." | claude --model $MODEL_BUILDER --dangerously-skip-permissions --print 2>&1 | tee /dev/tty)

log "## Código implementado"
log "$IMPLEMENTATION"

# ─── PASO 5: Analyst — reporte final ─────
separator
echo "📊 Paso 5 — Generando reporte final... [$MODEL_ANALYST]"
separator

cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
cat "$AGENTS_DIR/Analyst.md" >> "$CLAUDE_DIR/CLAUDE.md"

ANALYSIS=$(echo "@analyst revisa:

Ticket: $TASK
Código implementado:
$IMPLEMENTATION" | claude --model $MODEL_ANALYST --dangerously-skip-permissions --print 2>&1 | tee /dev/tty)

log "## Reporte final"
log "$ANALYSIS"

# ─── Restaurar global ────────────────────
cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
for f in "$AGENTS_DIR"/*.md; do
  printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
  cat "$f" >> "$CLAUDE_DIR/CLAUDE.md"
done

separator
echo "✅ Pipeline completo — 5 pasos ejecutados"
echo "📄 Sesión guardada en: $LOG_FILE"
echo ""
echo "¿Sesión interrumpida? Retoma con:"
echo "  bash ./scripts/resume.sh $LOG_FILE $REPO"