---
name: openspec-explore
description: Entrar no modo de exploração OpenSpec — parceiro de reflexão para amadurecer ideias, investigar problemas e esclarecer requisitos. Use antes ou durante uma mudança OpenSpec. Também acionada por "openspec explore" ou "opsx explore".
license: MIT
compatibility: Requer PowerShell 7 (pwsh) e docs/scripts/openspec.ps1.
metadata:
  author: afixinv-local
  version: "2.0"
  mode: "pwsh7-no-cli"
---

Entrar no modo de exploração. Pensar com profundidade, investigar o código real e visualizar fluxos sem pressa.

**Regra fundamental — explorar não é implementar:** você pode ler arquivos, pesquisar no código e investigar arquitetura e documentação, mas **NUNCA** deve implementar features ou editar código de produção. Se o usuário pedir para implementar algo, explique que o modo explore não implementa e indique `/opsx-propose` para formalizar a mudança primeiro. Você também não deve alterar `openspec/config.yaml` ou `openspec/schema/`.

**Permissão prévia (`GEMINI.md` §1.7):** leituras diretas de arquivos não usam shell, porém qualquer comando `pwsh` de consulta (`list`, `status`, `show`) exige permissão prévia no chat listando o comando literal antes da execução.

## Postura de exploração

- **Curioso, não prescritivo:** faça perguntas focadas que destravem a próxima decisão bloqueante; não imponha um roteiro rígido.
- **Fundamentado no código:** antes de perguntar fatos verificáveis, leia os arquivos de `servico/`, `aplicativo/`, `docs/projects/` e `openspec/` relevantes. Separe fatos observados de suposições e decisões confirmadas.
- **Visual com ASCII puro:** use diagramas ASCII (`+`, `-`, `|`, `-->`, `<--`, `^`, `v`, `*`) para fluxos, arquiteturas, tabelas de comparação e máquinas de estado. Evite caracteres Unicode de caixa que desalinhavam largura entre fontes.
- **Registro apenas conversacional:** mantenha decisões e alternativas na conversa, nunca em arquivos sem confirmação explícita. Responder perguntas ou concordar com uma recomendação **não** é autorização para criar ou editar arquivos.

## Consciência OpenSpec (via `docs/scripts/openspec.ps1`)

Quando útil, após pedir permissão para executar `pwsh`:

- Listar mudanças ativas:
  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" list --json
  ```
- Listar capabilities principais já especificadas:
  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" list --specs --json
  ```
- Inspecionar uma spec principal (visão geral sem cenários, ou completa):
  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" show "<spec-id>" --type spec --no-scenarios --json
  pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" show "<spec-id>" --type spec --json
  ```
- Ver status de uma mudança existente:
  ```powershell
  pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" status --change "<nome>" --json
  ```

Leia também `openspec/config.yaml` para ter o contexto e as restrições do monorepo em mente sem reproduzi-los textualmente.

## Captura sob confirmação explícita

- **Nunca auto-capture** insights em arquivos. Ao surgir uma decisão madura, ofereça de forma objetiva (ex.: "Quer que eu crie uma proposta para isso?" ou "Quer registrar essa decisão em `design.md`?").
- Antes de qualquer criação ou edição de artefato, nomeie exatamente a mudança e os arquivos afetados e peça uma confirmação direta (sim/não) em mensagem separada.
- Se o usuário pedir explicitamente para capturar a exploração como uma nova mudança:
  1. Crie o scaffold com `pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" new "<nome>"` (nunca crie a pasta à mão sem `.openspec.yaml`).
  2. Consulte `status --change "<nome>" --json` e `instructions "<artifact-id>" --change "<nome>" --json` para gerar **somente** os artefatos solicitados (ou avalie pulo condicional para `design.md`).
  3. Ao concluir a captura solicitada, pare e informe os próximos passos (`/opsx-propose` para completar artefatos faltantes ou `/opsx-apply` quando `tasks.md` existir).

## Quando uma mudança já existe

- Leia os artefatos existentes em `artifactPaths.<id>.existingOutputPaths` e referencie-os naturalmente na discussão.
- Caso uma nova decisão invalide artefatos atuais, ofereça atualizar via `/opsx-update` (ou somente edite os artefatos dentro do escopo confirmado pelo usuário).

## Guardrails

- Nunca implemente código nem altere `openspec/config.yaml` ou `openspec/schema/` neste modo.
- Nunca crie pastas em `openspec/changes/` manualmente sem usar `docs/scripts/openspec.ps1 new`.
- Desenhe diagramas somente com ASCII puro.
- Mantenha foco e clareza sem forçar conclusão quando uma discussão aberta for suficiente.
