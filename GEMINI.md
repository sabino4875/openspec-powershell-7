# GEMINI.md Template

## Rules (Mandatórias — Precedência Máxima)

1. **Solicitação Obrigatória de Permissão para Execução de Comandos**:
   - O agente **SEMPRE** deve solicitar permissão ao usuário para a execução de um comando no terminal (utilizando `BypassSandbox: true` na ferramenta `run_command` para acionar o prompt de aprovação do usuário).
   - Nunca encadear criação ou edição de arquivos em paralelo com um comando de terminal cujo sucesso seja pré-requisito da etapa.
   - Respeitar rigorosamente as políticas e restrições declaradas em `.agents/permissions.json` e `.agents/settings.json`.
2. **Parada Imediata em Caso de Falha (Fail-Fast / Tolerância Zero)**:
   - Se **qualquer** comando, build, teste ou ação falhar (**na 1ª falha**, inclusive falha de permissão, erro de Git ou código de saída diferente de zero), **PARE IMEDIATAMENTE** o processo.
   - **De forma alguma continue** para o próximo passo, não tente contornar silenciosamente e não agende tarefas em segundo plano (`schedule`/timers) em loop.
   - Apresente a falha claramente ao usuário e **solicite uma ação/orientação** antes de prosseguir.

## Gotchas

- **PowerShell no Windows**: a política de execução bloqueia scripts `.ps1` (ex.: o shim `bun.ps1` do pnpm). Ao executar qualquer script `.ps1` pela ferramenta `bash`, padronize com `powershell -NoProfile -ExecutionPolicy Bypass -File <script>` (ou `-Command` para comando único). `-NoProfile` ignora o profile do usuário; `-ExecutionPolicy Bypass` vale apenas para a invocação, sem alterar a política do sistema. Não salve scripts de teste no diretório temp (a execução falha) — crie-os em `docs/scripts/` (crie a pasta caso ainda não exista).
