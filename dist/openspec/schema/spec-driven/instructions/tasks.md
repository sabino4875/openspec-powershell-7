# Instruções — Artefato `tasks`

## Objetivo

Traduzir a proposta, os delta specs e o design (quando houver) em um plano de execução concreto, sequencial e verificável, compatível com o fluxo do `GEMINI.md` §1.1.

## Regras obrigatórias

1. Leia `proposal.md`, os arquivos em `specs/` e `design.md` (se existir) diretamente do disco antes de escrever `tasks.md`.
2. Organize as tarefas em **etapas numeradas** (`## Etapa 1 — ...`, `## Etapa 2 — ...`), pensadas para serem executadas **estritamente uma por vez**, com commit local, pausa e confirmação explícita do usuário entre etapas.
3. Evite tarefas genéricas como "explorar o código" ou "planejar implementação" — toda investigação necessária deve ter ocorrido durante a criação da proposta/specs/design.
4. Use checkboxes `- [ ] X.Y <descrição objetiva>` (o script `openspec.ps1` contabiliza `- [ ]` e `- [x]`/`- [X]`).
5. **Não marque `- [x]` antecipadamente** e nunca marque uma tarefa como concluída se o comportamento especificado estiver apenas parcial ou adiado.
6. Inclua obrigatoriamente na etapa final (ou nas etapas pertinentes):
   - Build/análise (`dotnet build -c Release` no `servico/`; `flutter analyze` no `aplicativo/`).
   - Testes automatizados (`dotnet test -c Release` com xUnit v3 e mocks sem I/O real; `flutter test` no `aplicativo/`).
   - Atualização da documentação as-is em `docs/projects/<projeto>/documentation/` (e `analysis/` se aplicável) no mesmo commit da mudança.
   - Validação manual com o usuário, sync dos delta specs e geração de `docs/pr/` e `docs/tasks/` (via `azure-devops-gestao`).
