---
name: openspec-update-change
description: Atualizar uma mudança OpenSpec revisando seus artefatos de planejamento existentes e mantendo coerência entre eles. Use quando decisões mudarem ou após editar artefatos. Também acionada por "openspec update change" ou "opsx update". Nunca edita código.
license: MIT
compatibility: Requer PowerShell 7 (pwsh) e docs/scripts/openspec.ps1.
metadata:
  author: afixinv-local
  version: "2.0"
  mode: "pwsh7-no-cli"
---

Revisar artefatos de planejamento existentes de uma mudança OpenSpec e mantê-los coerentes entre si. **Nunca edite código de implementação** neste fluxo.

**Permissão prévia (`GEMINI.md` §1.7):** peça permissão explícita ao usuário no chat listando literalmente cada comando `pwsh` antes de executá-lo.

Este fluxo revisa artefatos já existentes; ele **não** cria artefatos principais faltantes (`proposal`, `design`, `tasks`) nem toca em artefatos marcados como `skipped`.

## Passos

1. **Selecionar a mudança**
   - Se o nome foi informado ou puder ser inferido do contexto, use-o.
   - Caso contrário, liste as mudanças ativas ordenadas por `lastModified` (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" list --json
     ```
   - Apresente as opções (nome, progresso `completedTasks/totalTasks` e `lastModified`), marcando a mais recente como `(Recomendada)`.
   - Sempre anuncie: `Usando mudança: <nome>`.

2. **Inspecionar o estado atual da mudança**
   - Execute (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" status --change "<nome>" --json
     ```
   - Utilize `schemaName`, `changeRoot`, `artifacts` e `artifactPaths.<id>.existingOutputPaths` do JSON.
   - Edite apenas os arquivos concretos em `existingOutputPaths` (nunca tente escrever em padrão glob como `specs/**/*.md`).

3. **Entender o escopo da atualização**
   - Se o usuário pediu uma alteração específica ("o design agora usa X"), use-a como ponto de partida.
   - Se pediu apenas para revisar/alinhar ("atualize" / "mantenha coerente"), faça uma revisão cruzada de todos os artefatos existentes buscando contradições, lacunas ou duplicação.
   - **Heurística Atualizar vs. Começar do Zero:** se a mudança alterar fundamentalmente a intenção original da proposta, pergunte por um novo nome distinto e recomende criar uma nova mudança com `docs/scripts/openspec.ps1 new "<novo-nome>"`.

4. **Ler e reconciliar na conversa (sem escrever ainda)**
   - Leia do disco todos os artefatos existentes da mudança e `openspec/config.yaml`.
   - Rascunhe na conversa as alterações necessárias e verifique impacto em **todas as direções** (`proposal` ↔ `specs` ↔ `design` ↔ `tasks`): alterar `tasks.md` ou `design.md` pode exigir revisão em `specs/` ou `proposal.md`.
   - **Artefato faltante:** se um artefato tiver `existingOutputPaths` vazio e `status: "ready"` ou `"blocked"`, apenas informe o usuário e aponte como obtê-lo via `instructions "<artifact-id>" --change "<nome>" --json`, sem criá-lo aqui. Deixe artefatos `skipped` intactos.
   - **Exceção para glob `specs/**/*.md` parcialmente populado:** se a reconciliação exigir um novo arquivo de capability dentro de `specs/` quando já houver outros delta specs (`existingOutputPaths` não vazio e `skipped` falso):
     1. Consulte `instructions specs --change "<nome>" --json` (após permissão).
     2. Escolha um caminho concreto `<changeRoot>/specs/<capability-path>/spec.md` dentro de `changeRoot` que ainda não exista.
     3. Inclua a criação desse arquivo na proposta de revisão para aprovação no passo 5.

5. **Confirmar e aplicar um artefato por vez**
   - Apresente claramente cada revisão proposta e o motivo.
   - **Escreva somente após confirmação explícita do usuário** para cada artefato (se o usuário rejeitar alguma revisão, deixe aquele arquivo intocado).
   - Para reescritas substanciais, consulte antes o template e as regras com `instructions "<artifact-id>" --change "<nome>" --json`.
   - Se algum delta spec em `specs/` tiver sido alterado ou criado, execute a validação ao final (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" validate --change "<nome>" --json
     ```

6. **Indicar o próximo passo (sem executar)**
   - Se faltarem artefatos de planejamento: informe qual é o próximo segundo `status`.
   - Se a mudança já tinha tarefas concluídas em código e o plano mudou: recomende `/opsx-apply` para levar as revisões ao código.
   - Se tudo estiver completo e implementado: recomende `/opsx-archive`.

## Guardrails

- Somente artefatos de planejamento — **nunca** edite código de implementação.
- Edite apenas arquivos concretos em `existingOutputPaths` (ou novo delta spec confirmado sob `specs/` já populado).
- Confirme cada revisão com o usuário antes de gravar no disco.
- Não copie `context` ou `rules` de `openspec/config.yaml` para os artefatos.
