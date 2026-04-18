#!/bin/bash

AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/agents"
PROFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)/profiles"
CLAUDE_DIR="$HOME/.claude"
AGENT=$1

if [ -z "$AGENT" ]; then
  echo "Uso: ./use-agent.sh [all|taskdefiner|arch|reader|reviewer|inspector|builder|doc]"
  echo ""
  echo "  all         → todos los agentes"
  echo "  taskdefiner → define tareas desde requerimientos"
  echo "  arch        → analiza y simplifica arquitectura"
  echo "  reader      → entiende código ajeno rápido"
  echo "  reviewer    → valida código antes del PR"
  echo "  inspector   → diagnostica problemas en producción"
  echo "  builder     → propone e implementa cambios"
  echo "  doc         → documenta decisiones técnicas"
  exit 1
fi

load_agent() {
  cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
  printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
  cat "$AGENTS_DIR/$1" >> "$CLAUDE_DIR/CLAUDE.md"
  echo "✅ $2 activo"
  echo "Para usar: cd /tu/proyecto && claude"
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
  *) echo "❌ Agente desconocido: $AGENT" && exit 1 ;;
esac