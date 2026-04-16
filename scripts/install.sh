cat > scripts/install.sh << 'EOF'
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

install_all() {
  cat "$PROFILES_DIR/global.md" > "$CLAUDE_DIR/CLAUDE.md"
  for f in "$AGENTS_DIR"/*.md; do
    echo -e "\n---" >> "$CLAUDE_DIR/CLAUDE.md"
    cat "$f" >> "$CLAUDE_DIR/CLAUDE.md"
  done
  echo "✅ Todos los agentes instalados en ~/.claude/CLAUDE.md"
}

case $choice in
  1) install_all ;;
  2) cat "$PROFILES_DIR/global.md" "$AGENTS_DIR/TaskDefinerV3.md" > "$CLAUDE_DIR/CLAUDE.md" && echo "✅ TaskDefiner instalado" ;;
  3) cat "$PROFILES_DIR/global.md" "$AGENTS_DIR/ArchSimplifierV1.md" > "$CLAUDE_DIR/CLAUDE.md" && echo "✅ ArchSimplifier instalado" ;;
  4) cat "$PROFILES_DIR/global.md" "$AGENTS_DIR/CodeReader.md" > "$CLAUDE_DIR/CLAUDE.md" && echo "✅ CodeReader instalado" ;;
  5) cat "$PROFILES_DIR/global.md" "$AGENTS_DIR/Reviewer.md" > "$CLAUDE_DIR/CLAUDE.md" && echo "✅ Reviewer instalado" ;;
  6) cat "$PROFILES_DIR/global.md" "$AGENTS_DIR/ProdInspector.md" > "$CLAUDE_DIR/CLAUDE.md" && echo "✅ ProdInspector instalado" ;;
  7) cat "$PROFILES_DIR/global.md" "$AGENTS_DIR/Builder.md" > "$CLAUDE_DIR/CLAUDE.md" && echo "✅ Builder instalado" ;;
  8) cat "$PROFILES_DIR/global.md" "$AGENTS_DIR/DocWriter.md" > "$CLAUDE_DIR/CLAUDE.md" && echo "✅ DocWriter instalado" ;;
  *) echo "❌ Opción inválida" && exit 1 ;;
esac

echo ""
echo "Para usar: cd /tu/proyecto && claude"
EOF

chmod +x scripts/install.sh