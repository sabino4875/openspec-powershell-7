---
name: openspec-archive-change
description: Finalizar e arquivar uma mudança OpenSpec concluída, verificando artefatos, tarefas e sincronização de delta specs. Também acionada por "openspec archive" ou "opsx archive".
license: MIT
compatibility: Requer PowerShell 7 (pwsh) e docs/scripts/openspec.ps1.
metadata:
  author: openspec-powershell-7
  version: "2.0"
  mode: "pwsh7-no-cli"
---

Finalizar e arquivar uma mudança OpenSpec concluída movendo-a para `openspec/changes/archive/YYYY-MM-DD-<nome>/`.

**Permissão prévia (`GEMINI.md`):** peça permissão explícita ao usuário no chat listando literalmente cada comando `pwsh` antes de executá-lo.

## Passos

1. **Selecionar a mudança e carregar instruções**
   - Use o nome informado ou inferido do contexto; se ambíguo, liste apenas mudanças ativas (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" list --json
     ```
   - Sempre anuncie: `Usando mudança: <nome>`.
   - Carregue as instruções de arquivamento (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" instructions archive --change "<nome>" --json
     ```
     (Considere `context` como restrição, sem copiá-lo para outputs ou resumos.)

2. **Verificar completude de artefatos**
   - Execute (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" status --change "<nome>" --json
     ```
   - Se houver artefatos obrigatórios (`optional: false`) com status diferente de `done` e `skipped`:
     - Liste os artefatos incompletos em aviso claro.
     - Peça confirmação explícita do usuário para prosseguir mesmo assim.

3. **Verificar completude de tarefas**
   - Execute (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" tasks --change "<nome>" --json
     ```
   - Se `incompleteTasks > 0`:
     - Exiba a contagem (`incompleteTasks` pendentes de `totalTasks`).
     - Peça confirmação explícita do usuário para prosseguir mesmo com tarefas abertas.

4. **Avaliar e sincronizar delta specs (se existirem)**
   - Use exclusivamente `artifactPaths.specs.existingOutputPaths` do JSON de `status`. Se estiver vazio, pule para o passo 5 informando "Sem delta specs".
   - Caso existam delta specs, compare cada um com `<planningHome.specsDir>/<capability-path>/spec.md`:
     - Identifique capabilities novas (`ADDED`), atualizações (`ADDED`/`MODIFIED`/`RENAMED`/`REMOVED`), aposentadorias (`retire_capabilities: true`) e eventuais capabilities bloqueadas (`MODIFIED`/`RENAMED` para spec principal inexistente, ou `REMOVED`-only sem `retire_capabilities: true`).
     - Mostre um resumo combinado ao usuário e apresente as opções:
       - Se alguma capability estiver bloqueada para sync: `"Arquivar sem sincronizar"` ou `"Cancelar"`.
       - Se houver mudanças pendentes de sync: `"Sincronizar agora (recomendado)"`, `"Arquivar sem sincronizar"` ou `"Cancelar"`.
       - Se já estiverem sincronizadas: `"Arquivar agora"`, `"Sincronizar novamente"` ou `"Cancelar"`.
   - Se o usuário escolher sincronizar:
     1. Busque o snapshot de regras (após permissão):
        ```powershell
        pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" instructions specs --change "<nome>" --json
        ```
        (Se falhar ou retornar JSON inválido, pare imediatamente sem mover a mudança.)
     2. Execute o fluxo de `openspec-sync-specs` **inline na thread principal** (nunca em background) reutilizando esse snapshot.
     3. Se o sync reportar qualquer bloqueio ou falha de verificação/validação (`validate --specs --json`), **pare imediatamente** — não mova a pasta da mudança.
     4. Recompare cada capability de `existingOutputPaths` contra `openspec/specs/` para confirmar que não restam deltas pendentes.

5. **Executar o arquivamento**
   - Peça permissão e execute:
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" archive --change "<nome>"
     ```
     (Adicione `--force` **somente** se o usuário confirmou explicitamente nos passos 2 ou 3 arquivar com artefatos ou tarefas pendentes.)
   - O script:
     - Usa `<nome>` se já iniciar com `YYYY-MM-DD-`, ou `YYYY-MM-DD-<nome>` caso contrário (sem duplicar data).
     - Falha com erro claro se o destino já existir em `openspec/changes/archive/`.
     - Move a pasta preservando `.openspec.yaml`.

6. **Exibir resumo final**
   - Nome da mudança e schema utilizado.
   - Caminho final em `openspec/changes/archive/...`.
   - Status das specs (`Sincronizadas e validadas`, `Sem delta specs` ou `Sync ignorado pelo usuário`).
   - Avisos (se arquivada com artefatos ou tarefas incompletas).

## Guardrails

- Nunca mova a pasta da mudança enquanto um sync estiver em andamento ou com falha na validação (`validate --specs`).
- Não bloqueie permanentemente por avisos de tarefas/artefatos incompletos: alerte e exija confirmação explícita antes de usar `--force`.
- Preserve `.openspec.yaml` dentro da pasta arquivada.
- Peça permissão prévia antes de qualquer comando (`GEMINI.md`).
