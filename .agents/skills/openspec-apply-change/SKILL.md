---
name: openspec-apply-change
description: Implementar tarefas de uma mudança OpenSpec etapa por etapa. Use quando o usuário quiser iniciar ou continuar a implementação de uma mudança. Também acionada por "openspec apply", "opsx apply" ou "openspec implement".
license: MIT
compatibility: Requer PowerShell 7 (pwsh) e docs/scripts/openspec.ps1.
metadata:
  author: openspec-powershell-7
  version: "2.0"
  mode: "pwsh7-no-cli"
---

Implementar tarefas de uma mudança OpenSpec seguindo o ciclo etapa por etapa do projeto.

**Governança obrigatória (`GEMINI.md`):**
- Execute **SOMENTE uma etapa por vez** de `tasks.md`. Ao concluir a etapa atual, faça o commit local correspondente, pare, relate o que foi feito e aguarde confirmação explícita do usuário antes da próxima etapa.
- Peça **permissão prévia no chat** listando literalmente cada comando de terminal (`pwsh`, `git` ou ferramentas de build/teste da stack definida pelo usuário) antes de executá-lo.
- Execute comandos sempre de forma síncrona na thread principal, um por vez, fora do sandbox quando exigido (`GEMINI.md`).
- **Fail-Fast / Tolerância Zero (`GEMINI.md`):** se qualquer comando, build ou teste falhar, pare imediatamente, reporte os erros completos e aguarde orientação do usuário.

## Passos

1. **Selecionar a mudança**
   - Se o usuário informou o nome da mudança, use-o.
   - Caso contrário, verifique o contexto da conversa ou liste as mudanças ativas (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" list --json
     ```
   - Se houver exatamente 1 mudança ativa, selecione-a; se houver mais de uma e estiver ambíguo, peça ao usuário escolher.
   - Sempre anuncie: `Usando mudança: <nome>` (e como trocar, ex.: `/opsx-apply <outro-nome>`).

2. **Consultar status e instruções de aplicação**
   - Execute (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" status --change "<nome>" --json
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" instructions apply --change "<nome>" --json
     ```
   - Avalie o campo `state` retornado por `instructions apply`:
     - **`blocked`**: exiba `missingArtifacts` e pause a implementação. Oriente completar os artefatos faltantes antes de codificar.
     - **`all_done`**: informe que todas as tarefas rastreadas em `tasks.md` já estão concluídas e sugira revisão, testes manuais e arquivamento (`/opsx-archive`).
     - **`ready`**: prossiga para o passo 3.

3. **Ler todo o contexto do disco**
   - Leia todos os arquivos listados em `contextFiles` (`proposal.md`, delta specs em `specs/`, `design.md` se existir, `tasks.md`) e `openspec/config.yaml`.
   - Nunca copie o texto de `context` nem das instruções de schema para dentro dos arquivos de código ou artefatos.

4. **Exibir progresso e identificar a etapa atual**
   - Mostre o progresso atual (`N/M tarefas concluídas`) e identifique a **primeira etapa com tarefas pendentes** em `tasks.md`.

5. **Implementar SOMENTE a etapa atual**
   Para cada tarefa pendente pertencente à etapa atual:
   - Anuncie qual tarefa está sendo executada (`X.Y`).
   - Realize as alterações mínimas e focadas no código/documentação conforme `proposal.md`, `specs/` e `design.md`.
   - Respeite rigorosamente a linguagem de programação, arquitetura, camadas, convenções de código, ferramentas de teste e guardrails de segurança definidos pelo usuário em `openspec/config.yaml` e `GEMINI.md` (incluindo atualização da documentação técnica do projeto quando comportamento, API ou schema mudarem).
   - Antes de marcar a tarefa como concluída, confirme que o texto na linha `line` de `sourcePath` corresponde exatamente à tarefa e só altere `- [ ]` para `- [x]` quando o comportamento especificado estiver **100% implementado** (nunca parcialmente).
   - Verifique o progresso atualizado (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" tasks --change "<nome>" --json
     ```

   **Pause imediatamente se:**
   - Uma tarefa estiver ambígua → pergunte ao usuário antes de editar.
   - A implementação revelar falha no design ou necessidade de alterar requisitos → sugira `/opsx-update` e pause.
   - A tarefa exigir escopo extra não previsto ou tentar simplificar/omitir comportamento especificado → exponha ao usuário e aguarde decisão.
   - Houver qualquer erro de build, teste ou comando (`GEMINI.md`).

6. **Fechar a etapa atual**
   - Execute os builds, linters e testes aplicáveis à etapa conforme a stack definida pelo usuário (após permissão explícita).
   - Peça permissão explícita para o commit local da etapa atual.
   - Relate com clareza o que foi alterado, os resultados dos comandos executados e o progresso atualizado (`N/M tarefas concluídas`).
   - **PARE e aguarde confirmação explícita do usuário** antes de iniciar a próxima etapa.
   - Ao concluir a **última** etapa, lembre também da validação manual, do sync de specs (`/opsx-sync`) e do arquivamento (`/opsx-archive`).

## Guardrails

- Nunca execute duas etapas seguidas de `tasks.md` sem confirmação entre elas.
- Nunca marque `- [x]` para trabalho parcial, adiado ou não verificado.
- Use `contextFiles`, `sourcePath` e `line` retornados por `docs/scripts/openspec.ps1`.
- Peça permissão prévia antes de qualquer comando (`GEMINI.md`).
