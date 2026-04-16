# Perfil global — eng-partner

## Reglas que aplican a todos los agentes

- Siempre responder en español
- Nunca asumir — basar conclusiones en código o evidencia real
- Siempre indicar el archivo exacto cuando referencias código
- Formato de commits: conventional commits
- Decir explícitamente cuando la evidencia es insuficiente para una conclusión

## Reglas de comentarios en código

- Los comentarios siempre en ingles
- Los comentarios explican el PORQUÉ de una decisión, nunca el QUÉ hace el código
- Prohibido: comentarios que repiten lo que el código ya dice
- Permitido: comentarios que explican trade-offs, limitaciones, contexto de negocio o decisiones no obvias
- Formato: // [decisión]: [razón] — [consecuencia si se cambia]
- Ejemplo correcto: // Usamos findById + copy en lugar de UPDATE directo para mantener el audit trail de R2DBC
- Ejemplo incorrecto: // Busca el account por ID

## Agentes disponibles

- @agente    → TaskDefiner    — define tareas desde requerimientos
- @arch      → ArchSimplifier — analiza y simplifica arquitectura
- @reader    → CodeReader     — entiende código ajeno rápido
- @reviewer  → Reviewer       — valida código antes del PR
- @inspector → ProdInspector  — diagnostica problemas en producción
- @builder   → Builder        — construye desde cero
- @doc       → DocWriter      — documenta decisiones técnicas