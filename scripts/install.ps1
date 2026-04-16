cat > scripts/install.ps1 << 'EOF'
# eng-partner — instalador Windows (PowerShell)

$AgentsDir = Join-Path $PSScriptRoot "..\agents"
$ProfilesDir = Join-Path $PSScriptRoot "..\profiles"
$ClaudeDir = Join-Path $HOME ".claude"

Write-Host "🤖 eng-partner — instalador"
Write-Host ""
Write-Host "  1. Todos los agentes (recomendado)"
Write-Host "  2. Solo TaskDefiner"
Write-Host "  3. Solo ArchSimplifier"
Write-Host "  4. Solo CodeReader"
Write-Host "  5. Solo Reviewer"
Write-Host "  6. Solo ProdInspector"
Write-Host "  7. Solo Builder"
Write-Host "  8. Solo DocWriter"
Write-Host ""
$choice = Read-Host "¿Qué instalar? (1-8, default: 1)"
if (-not $choice) { $choice = "1" }

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
$output = Join-Path $ClaudeDir "CLAUDE.md"

function Install-All {
  Get-Content "$ProfilesDir\global.md" | Set-Content $output
  Get-ChildItem "$AgentsDir\*.md" | ForEach-Object {
    "`n---" | Add-Content $output
    Get-Content $_.FullName | Add-Content $output
  }
  Write-Host "✅ Todos los agentes instalados en ~/.claude/CLAUDE.md"
}

switch ($choice) {
  "1" { Install-All }
  "2" { (Get-Content "$ProfilesDir\global.md", "$AgentsDir\TaskDefinerV3.md") | Set-Content $output; Write-Host "✅ TaskDefiner instalado" }
  "3" { (Get-Content "$ProfilesDir\global.md", "$AgentsDir\ArchSimplifierV1.md") | Set-Content $output; Write-Host "✅ ArchSimplifier instalado" }
  "4" { (Get-Content "$ProfilesDir\global.md", "$AgentsDir\CodeReader.md") | Set-Content $output; Write-Host "✅ CodeReader instalado" }
  "5" { (Get-Content "$ProfilesDir\global.md", "$AgentsDir\Reviewer.md") | Set-Content $output; Write-Host "✅ Reviewer instalado" }
  "6" { (Get-Content "$ProfilesDir\global.md", "$AgentsDir\ProdInspector.md") | Set-Content $output; Write-Host "✅ ProdInspector instalado" }
  "7" { (Get-Content "$ProfilesDir\global.md", "$AgentsDir\Builder.md") | Set-Content $output; Write-Host "✅ Builder instalado" }
  "8" { (Get-Content "$ProfilesDir\global.md", "$AgentsDir\DocWriter.md") | Set-Content $output; Write-Host "✅ DocWriter instalado" }
  default { Write-Host "❌ Opción inválida"; exit 1 }
}

Write-Host ""
Write-Host "Para usar: cd /tu/proyecto && claude"
EOF