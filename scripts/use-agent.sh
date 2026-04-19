#!/bin/bash

AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/agents"
PROFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)/profiles"
CLAUDE_DIR="$HOME/.claude"
AGENT=$1

declare -A AGENT_MODELS
AGENT_MODELS[taskdefiner]="claude-sonnet-4-6"
AGENT_MODELS[arch]="claude-opus-4-6"
AGENT_MODELS[reader]="claude-sonnet-4-6"
AGENT_MODELS[reviewer]="claude-sonnet-4-6"
AGENT_MODELS[inspector]="claude-opus-4-6"
AGENT_MODELS[builder]="claude-sonnet-4-6"
AGENT_MODELS[doc]="claude-sonnet-4-6"
AGENT_MODELS[analyst]="claude-opus-4-6"
AGENT_MODELS[resumer]="claude-sonnet-4-6"

if [ -z "$AGENT" ]; then
  echo "Uso: ./use-agent.sh [all|taskdefiner|arch|reader|reviewer|inspector|builder|doc|resumer]"
  echo ""
  echo "  all         → todos los agentes"
  echo "  taskdefiner → define tareas desde requerimientos       [sonnet-4-6]"
  echo "  arch        → analiza y simplifica arquitectura        [opus-4-6]"
  echo "  reader      → entiende código ajeno rápido             [sonnet-4-6]"
  echo "  reviewer    → valida código antes del PR               [sonnet-4-6]"
  echo "  inspector   → diagnostica problemas en producción      [opus-4-6]"
  echo "  builder     → propone e implementa cambios             [sonnet-4-6]"
  echo "  doc         → documenta decisiones técnicas            [sonnet-4-6]"
  echo "  analyst     → pruebas, patrones y big wins             [opus-4-6]"
  echo "  resumer     → retoma sesiones interrumpidas del vault  [sonnet-4-6]"
  exit 1
fi

load_agent() {
  local file=$1
  local name=$2
  local model=${AGENT_MODELS[$AGENT]}
  cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
  printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
  cat "$AGENTS_DIR/$file" >> "$CLAUDE_DIR/CLAUDE.md"
  echo "✅ $name activo — modelo: $model"
  echo "Para usar: cd /tu/proyecto && claude --model $model"
}

case $AGENT in
  all)
    cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
    for f in "$AGENTS_DIR"/*.md; do
      printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
      cat "$f" >> "$CLAUDE_DIR/CLAUDE.md"
    done
    echo "✅ Todos los agentes activos"
    echo "Para usar: cd /tu/proyecto && claude"
    ;;
  taskdefiner) load_agent "TaskDefiner.md" "TaskDefiner" ;;
  arch)        load_agent "ArchSimplifier.md" "ArchSimplifier" ;;
  reader)      load_agent "CodeReader.md" "CodeReader" ;;
  reviewer)    load_agent "Reviewer.md" "Reviewer" ;;
  inspector)   load_agent "ProdInspector.md" "ProdInspector" ;;
  builder)     load_agent "Builder.md" "Builder" ;;
  doc)         load_agent "DocWriter.md" "DocWriter" ;;
  analyst)     load_agent "Analyst.md" "Analyst" ;;
  resumer)     load_agent "Resumer.md" "Resumer" ;;
  *) echo "❌ Agente desconocido: $AGENT" && exit 1 ;;
esac