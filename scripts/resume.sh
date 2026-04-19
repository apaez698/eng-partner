#!/bin/bash

# ─────────────────────────────────────────
# eng-partner — retomar sesión interrumpida
# Uso: ./resume.sh [path/session.md] [path/repo]
# ─────────────────────────────────────────

SESSION=$1
REPO=$2
AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/agents"
PROFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)/profiles"
CLAUDE_DIR="$HOME/.claude"

MODEL_RESUMER="claude-sonnet-4-6"
MODEL_ANALYST="claude-opus-4-6"

if [ -z "$SESSION" ]; then
  echo "Uso: ./resume.sh [path/session.md] [path/repo]"
  echo ""
  echo "Sesiones disponibles en vault:"
  ls -lt "$(cd "$(dirname "$0")/.." && pwd)/vault"/*.md 2>/dev/null | head -10
  exit 1
fi

if [ ! -f "$SESSION" ]; then
  echo "❌ Archivo de sesión no encontrado: $SESSION"
  exit 1
fi

if [ -n "$REPO" ] && [ ! -d "$REPO" ]; then
  echo "❌ El directorio '$REPO' no existe"
  exit 1
fi

[ -n "$REPO" ] && cd "$REPO" && echo "📁 Repo: $REPO"

separator() { echo ""; echo "══════════════════════════════════════"; echo ""; }
SESSION_CONTENT=$(cat "$SESSION")

# ─── Retomar sesión ───────────────────────
separator
echo "🔄 Retomando sesión... [$MODEL_RESUMER]"
separator

cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
cat "$AGENTS_DIR/Resumer.md" >> "$CLAUDE_DIR/CLAUDE.md"

IMPLEMENTATION=$(echo "@resumer carga la siguiente sesión, identifica qué está pendiente y continúa implementando todo lo que falta sin pedir confirmación. Al final genera el reporte completo de lo implementado.

$SESSION_CONTENT" | claude --model $MODEL_RESUMER --dangerously-skip-permissions --print 2>&1 | tee /dev/tty)

# ─── Analyst — reporte final ─────────────
separator
echo "📊 Generando reporte final... [$MODEL_ANALYST]"
separator

cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
cat "$AGENTS_DIR/Analyst.md" >> "$CLAUDE_DIR/CLAUDE.md"

echo "@analyst revisa:

Sesión retomada:
$SESSION_CONTENT

Código implementado en esta sesión:
$IMPLEMENTATION" | claude --model $MODEL_ANALYST --dangerously-skip-permissions --print 2>&1 | tee /dev/tty

# ─── Restaurar global ────────────────────
cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
for f in "$AGENTS_DIR"/*.md; do
  printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
  cat "$f" >> "$CLAUDE_DIR/CLAUDE.md"
done

separator
echo "✅ Sesión completada"
echo "Revisa el output, prueba manualmente y haz el PR cuando estés listo."