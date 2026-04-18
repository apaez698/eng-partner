cat > ~/Documents/AI/eng-partner/scripts/install.sh << 'EOF'
#!/bin/bash
set -e

AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/agents"
PROFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)/profiles"
CLAUDE_DIR="$HOME/.claude"

echo "🤖 eng-partner — instalador"
echo ""
echo "  1. Todos los agentes (recomendado)"
echo "  2. Solo TaskDefiner"
echo "  3. Solo ArchSimplifier"
echo "  4. Solo CodeReader"
echo "  5. Solo Reviewer"
echo "  6. Solo ProdInspector"
echo "  7. Solo Builder"
echo "  8. Solo DocWriter"
echo ""
read -p "¿Qué instalar? (1-8, default: 1): " choice
choice=${choice:-1}

mkdir -p "$CLAUDE_DIR"

load_agent() {
  cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
  printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
  cat "$AGENTS_DIR/$1" >> "$CLAUDE_DIR/CLAUDE.md"
  echo "✅ $2 instalado"
}

case $choice in
  1)
    cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
    for f in "$AGENTS_DIR"/*.md; do
      printf "\n---\n" >> "$CLAUDE_DIR/CLAUDE.md"
      cat "$f" >> "$CLAUDE_DIR/CLAUDE.md"
    done
    echo "✅ Todos los agentes instalados"
    ;;
  2) load_agent "TaskDefiner.md" "TaskDefiner" ;;
  3) load_agent "ArchSimplifier.md" "ArchSimplifier" ;;
  4) load_agent "CodeReader.md" "CodeReader" ;;
  5) load_agent "Reviewer.md" "Reviewer" ;;
  6) load_agent "ProdInspector.md" "ProdInspector" ;;
  7) load_agent "Builder.md" "Builder" ;;
  8) load_agent "DocWriter.md" "DocWriter" ;;
  *) echo "❌ Opción inválida" && exit 1 ;;
esac

echo ""
echo "Para usar: cd /tu/proyecto && claude"
EOF

chmod +x ~/Documents/AI/eng-partner/scripts/install.sh