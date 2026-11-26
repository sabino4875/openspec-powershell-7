---
name: openspec-propose
description: Propor uma nova mudança OpenSpec gerando todos os artefatos de planejamento (proposal, specs, design opcional e tasks). Use quando o usuário pedir para propor ou especificar algo novo. Também acionada por "openspec propose" ou "opsx propose".
license: MIT
compatibility: Requer PowerShell 7 (pwsh) e docs/scripts/openspec.ps1.
metadata:
  author: openspec-powershell-7
  version: "2.0"
  mode: "pwsh7-no-cli"
---

Propor uma nova mudança OpenSpec — cria o diretório da mudança e gera os artefatos de planejamento definidos em `openspec/schema/spec-driven/`.

**Limite de planejamento (Planning boundary):** este fluxo cria **apenas artefatos de planejamento**. A solicitação que acionou esta skill autoriza somente o planejamento, mesmo que o pedido também mencione implementar ou corrigir algo. **Não edite código de implementação** e não inicie o fluxo `apply` nesta mesma resposta. Ao concluir todos os artefatos, pare e aguarde um novo pedido explícito do usuário para iniciar a implementação.

**Permissão prévia (`GEMINI.md`):** peça permissão explícita ao usuário no chat listando literalmente cada comando `pwsh` antes de executá-lo, sempre fora do sandbox e de forma síncrona (`GEMINI.md`).

## Padrão de execução

Todos os comandos utilizam o script local em PowerShell 7:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" <subcomando> [opções]
```

**Artefatos do schema padrão (`spec-driven`):**
- `proposal.md` (o quê e por quê)
- `specs/<capability-path>/spec.md` (delta specs — não a spec principal)
- `design.md` (como — **condicional/opcional**)
- `tasks.md` (etapas de implementação)

`<capability-path>` é o diretório relativo dentro de `specs/` (ex.: `autenticacao` ou `dominio/relatorios`). Preserve exatamente o caminho de capabilities já existentes em `openspec/specs/`.

## Passos

1. **Entender a solicitação e esclarecer ambiguidades**
   - Se o usuário não descreveu claramente o que deseja construir ou corrigir, pergunte antes de prosseguir.
   - Derive um nome em `kebab-case` (ex.: `add-export-csv`).
   - Se houver ambiguidade material de escopo, comportamento observável, compatibilidade de contratos/interfaces definidos pelo projeto ou critérios de aceitação, pergunte ao usuário antes de criar a mudança. Para detalhes menores, registre premissas razoáveis nos artefatos.

2. **Verificar raiz e carregar contexto do projeto**
   - Execute (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" context --json
     ```
   - Se retornar `error: "no_openspec_root"` (`root: null`), **pare imediatamente** sem criar `openspec/` como efeito colateral e informe o usuário.
   - Leia `openspec/config.yaml` do disco e aplique a linguagem, stack, arquitetura, `context` e `rules` definidos pelo usuário como restrições internas — **nunca** copie esses blocos para dentro dos artefatos.

3. **Criar o diretório da mudança**
   - Nunca crie `openspec/changes/<nome>` manualmente sem `.openspec.yaml`.
   - Execute (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" new "<nome>"
     ```
     (Use `--skip-specs` somente quando aplicável e justificado; caso o nome já exista, pergunte se o usuário deseja continuar a mudança existente ou escolher outro nome.)

4. **Consultar a ordem de artefatos**
   - Execute (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" status --change "<nome>" --json
     ```
   - Use `changeRoot`, `applyRequires`, `artifacts` e `artifactPaths` retornados no JSON.

5. **Gerar todos os artefatos necessários em ordem de dependência**
   Para cada artefato com `status: "ready"`:
   a. Obtenha template, regras e instruções (após permissão):
      ```powershell
      pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" instructions "<artifact-id>" --change "<nome>" --json
      ```
   b. Re-leia do disco os arquivos listados em `dependencies`.
   c. **Inspecione o projeto antes de redigir:** leia de forma somente leitura código, testes, configurações e documentação do repositório e `openspec/specs/` relevantes. Diferencie comportamento observado de premissas e aponte conflitos com specs existentes ao usuário.
   d. **Escolha o caminho concreto:**
      - Para `specs`, escolha `<changeRoot>/specs/<capability-path>/spec.md` e confirme que o caminho resolvido permanece dentro de `changeRoot`.
      - Para os demais artefatos, use `resolvedOutputPath`.
   e. **Avalie condição de pulo:**
      - Se `skipped: true` (por `skip_specs: true`), **não** crie o artefato.
      - Se `optional: true` (`design.md`), você pode pular deliberadamente quando não houver decisões arquiteturais, mudanças de contrato/schema ou trade-offs relevantes; informe o usuário e não reconsidere o pulo.
   f. Escreva o artefato seguindo estritamente `template`, `instruction`, `context` e `rules` definidos pelo usuário (sem copiar `context`/`rules` no conteúdo) e verifique que o arquivo existe no disco.
   g. Re-execute `status --change "<nome>" --json` após cada criação até que todos os artefatos requeridos por `applyRequires` e suas dependências transitivas estejam `done`, `skipped` ou deliberadamente pulados.

6. **Validar os delta specs gerados**
   - Execute (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" validate --change "<nome>" --json
     ```
   - Corrija eventuais erros reportados antes de encerrar.

7. **Apresentar resumo final**
   - Nome e localização da mudança (`changeRoot`).
   - Lista dos artefatos criados (com breve resumo) e eventual artefato opcional pulado com justificativa.
   - Indicar que os artefatos estão prontos para revisão e que, quando o usuário quiser implementar, pode acionar `/opsx-apply` ou pedir para aplicar a mudança.

## Guardrails

- Apenas planejamento: nunca edite código de implementação nem comece `apply` nesta rodada.
- Sempre re-leia dependências do disco antes de criar o próximo artefato.
- Nunca copie blocos de `context` ou `rules` para os artefatos gerados.
- Verifique cada arquivo criado e valide com `validate --change "<nome>" --json` antes de concluir.
