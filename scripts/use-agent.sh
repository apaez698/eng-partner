#!/bin/bash

AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/agents"
PROFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)/profiles"
CLAUDE_DIR="$HOME/.claude"
AGENT=$1

if [ -z "$AGENT" ]; then
  echo "Uso: ./use-agent.sh [all|taskdefiner|arch|reader|reviewer|inspector|builder|doc]"
  exit 1
fi

load_agent() {
  cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
  printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
  cat "$AGENTS_DIR/$1" >> "$CLAUDE_DIR/CLAUDE.md"
  echo "✅ $2 activo"
}

case $AGENT in
  all)
    cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
    for f in "$AGENTS_DIR"/*.md; do
      printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
      cat "$f" >> "$CLAUDE_DIR/CLAUDE.md"
    done
    echo "✅ Todos los agentes activos"
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

echo "Para usar: cd /tu/proyecto && claude"
