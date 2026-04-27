import os
import subprocess
from anthropic import Anthropic

client = Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

TARGET_REPO = r"D:\finhabits\projects\finhabits"

# Costo aproximado claude-sonnet-4-6 (USD por millón de tokens)
COST_INPUT_PER_M  = 3.00
COST_OUTPUT_PER_M = 15.00

# Máximo de mensajes a mantener en historial (user+assistant, sin contar system)
# Cada par turno ≈ ~2 entradas. 10 = últimos 5 turnos.
MAX_HISTORY = 10

SYSTEM = """
Eres un agente mentor técnico senior con acceso a herramientas git.
Tu misión es ayudar al desarrollador a entender profundamente el código del repositorio
para que pueda contribuir y extenderlo con confianza.

Cuando el usuario te pida entender código, una rama, un módulo o una feature, SIEMPRE:

1. USA git para obtener contexto real antes de responder.
   - Empieza con `git log --oneline -15` para orientarte.
   - Luego explora archivos relevantes con `git show <ref>:<path>` o `git ls-tree`.
   - Usa `git diff` para ver qué cambió si el usuario menciona una rama o commit.

2. EXPLICA en capas:
   a) ¿Qué hace este código? (propósito de negocio en 2-3 líneas)
   b) ¿Cómo está estructurado? (módulos, capas, patrones de diseño detectados)
   c) ¿Qué tecnologías y librerías usa y por qué existen en este contexto?
   d) Mapa mental: los 3-5 conceptos clave que el desarrollador DEBE dominar para trabajar aquí.

3. MAPAS MENTALES: cuando los menciones, estructúralos así:
   - Concepto central → qué es → por qué importa en este repo → recurso sugerido para aprenderlo.

4. SEÑALA dependencias y flujo de datos: cómo los módulos se conectan entre sí.

Reglas:
- No inventes hechos. Usa las herramientas git para obtener contexto real del código.
- Si falta contexto responde [NEED_HUMAN_INPUT]
- Si estás inseguro responde [LOW_CONFIDENCE]
- Si la pregunta es ambigua responde [MULTIPLE_POSSIBLE_INTERPRETATIONS]
- Si todo está claro responde [READY] y procede directamente.

Sé claro y directo. Usa listas y secciones cortas. No escribas parrafos largos.
"""

# Solo subcomandos de lectura para evitar modificaciones accidentales al repo
ALLOWED_GIT_COMMANDS = {
    "log", "show", "diff", "branch", "status", "cat-file",
    "ls-tree", "rev-parse", "blame", "grep", "shortlog",
    "describe", "tag", "stash",
}

TOOLS = [
    {
        "name": "git_run",
        "description": (
            "Ejecuta un comando git de solo lectura para inspeccionar el repositorio. "
            "Útil para ver historial, contenido de archivos en commits/ramas específicas, diffs, etc. "
            "Ejemplos: ['log', '--oneline', '-10'], ['show', 'main:src/app.py'], "
            "['diff', 'feat/login..main', '--', 'auth.py']"
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "args": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "Argumentos del comando git sin incluir 'git' al inicio.",
                }
            },
            "required": ["args"],
        },
    }
]


def run_git(args: list) -> str:
    if not args:
        return "Error: se requieren argumentos."
    subcommand = args[0]
    if subcommand not in ALLOWED_GIT_COMMANDS:
        return f"Error: subcomando '{subcommand}' no permitido. Permitidos: {sorted(ALLOWED_GIT_COMMANDS)}"
    try:
        result = subprocess.run(
            ["git"] + args,
            capture_output=True,
            text=True,
            timeout=15,
            cwd=TARGET_REPO,
        )
        output = result.stdout or result.stderr
        return output[:3000] if output else "(sin salida)"
    except subprocess.TimeoutExpired:
        return "Error: el comando git tardó demasiado."
    except Exception as e:
        return f"Error: {e}"


# Acumuladores de sesión
_session_input_tokens  = 0
_session_output_tokens = 0


def trim_history(messages: list) -> list:
    """Mantiene solo los últimos MAX_HISTORY mensajes para limitar tokens de entrada."""
    if len(messages) > MAX_HISTORY:
        return messages[-MAX_HISTORY:]
    return messages


def print_usage(usage) -> None:
    global _session_input_tokens, _session_output_tokens
    _session_input_tokens  += usage.input_tokens
    _session_output_tokens += usage.output_tokens
    turn_cost    = (usage.input_tokens / 1_000_000 * COST_INPUT_PER_M
                    + usage.output_tokens / 1_000_000 * COST_OUTPUT_PER_M)
    session_cost = (_session_input_tokens / 1_000_000 * COST_INPUT_PER_M
                    + _session_output_tokens / 1_000_000 * COST_OUTPUT_PER_M)
    print(f"  [tokens] in={usage.input_tokens} out={usage.output_tokens} "
          f"| turno≈${turn_cost:.4f} | sesión≈${session_cost:.4f}")


def run_agent_turn(messages: list) -> str:
    """Ejecuta un turno del agente incluyendo el loop de tool use."""
    while True:
        response = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=8096,
            system=SYSTEM,
            tools=TOOLS,
            messages=trim_history(messages),
        )

        print_usage(response.usage)
        messages.append({"role": "assistant", "content": response.content})

        if response.stop_reason == "tool_use":
            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    cmd_str = "git " + " ".join(block.input.get("args", []))
                    print(f"  [tool] {cmd_str}")
                    result = run_git(block.input.get("args", []))
                    tool_results.append(
                        {
                            "type": "tool_result",
                            "tool_use_id": block.id,
                            "content": result,
                        }
                    )
            messages.append({"role": "user", "content": tool_results})
            continue  # siguiente iteración con resultados de herramientas

        # stop_reason == "end_turn": extraer texto final
        text_parts = [b.text for b in response.content if hasattr(b, "text")]
        return "\n".join(text_parts)


def main():
    messages = []
    print("Agente técnico con acceso git. Escribe 'salir' para terminar.\n")

    while True:
        try:
            user_input = input("Tú: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nHasta luego.")
            break

        if user_input.lower() in ("salir", "exit", "quit"):
            print("Hasta luego.")
            break
        if not user_input:
            continue

        messages.append({"role": "user", "content": user_input})
        reply = run_agent_turn(messages)
        print(f"\nAgente: {reply}\n")


if __name__ == "__main__":
    main()