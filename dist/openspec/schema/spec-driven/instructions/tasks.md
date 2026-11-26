# Instruções — Artefato `tasks`

## Objetivo

Traduzir a proposta, os delta specs e o design (quando houver) em um plano de execução concreto, sequencial e verificável, compatível com o fluxo do `GEMINI.md`.

## Regras obrigatórias

1. Leia `proposal.md`, os arquivos em `specs/` e `design.md` (se existir) diretamente do disco antes de escrever `tasks.md`.
2. Organize as tarefas em **etapas numeradas** (`## Etapa 1 — ...`, `## Etapa 2 — ...`), pensadas para serem executadas **estritamente uma por vez**, com commit local, pausa e confirmação explícita do usuário entre etapas.
3. Evite tarefas genéricas como "explorar o código" ou "planejar implementação" — toda investigação necessária deve ter ocorrido durante a criação da proposta/specs/design.
4. Use checkboxes `- [ ] X.Y <descrição objetiva>` (o script `openspec.ps1` contabiliza `- [ ]` e `- [x]`/`- [X]`).
5. **Não marque `- [x]` antecipadamente** e nunca marque uma tarefa como concluída se o comportamento especificado estiver apenas parcial ou adiado.
6. Inclua obrigatoriamente na etapa final (ou nas etapas pertinentes), utilizando as ferramentas da stack definida pelo usuário em `openspec/config.yaml`:
   - Compilação, build e/ou análise estática (linter/typecheck) sem erros.
   - Execução dos testes automatizados da stack do projeto sem falhas.
   - Atualização da documentação técnica do projeto impactada pela mudança.
   - Validação manual com o usuário e sincronização dos delta specs para `openspec/specs/`.
