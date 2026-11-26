---
name: openspec-sync-specs
description: Sincronizar delta specs de uma mudança OpenSpec para as especificações principais em openspec/specs/. Use para atualizar as specs principais sem arquivar a mudança. Também acionada por "openspec sync" ou "opsx sync".
license: MIT
compatibility: Requer PowerShell 7 (pwsh) e docs/scripts/openspec.ps1.
metadata:
  author: openspec-powershell-7
  version: "2.0"
  mode: "pwsh7-no-cli"
---

Sincronizar delta specs de uma mudança OpenSpec para as especificações principais (`openspec/specs/`).

Esta é uma operação **dirigida pelo agente**: você lê os delta specs e aplica um **merge inteligente** nas specs principais, preservando conteúdo existente que não foi alterado.

**Permissão prévia (`GEMINI.md`):** peça permissão explícita ao usuário no chat listando literalmente cada comando `pwsh` antes de executá-lo.

`<capability-path>` é o diretório relativo dentro de `specs/` (ex.: `autenticacao` ou `dominio/relatorios`). Preserve exatamente o mesmo `<capability-path>` entre delta spec e spec principal.

## Passos

1. **Selecionar a mudança**
   - Use o nome informado ou inferido do contexto; se ambíguo, liste as mudanças ativas (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" list --json
     ```
     destacando as que possuem `hasDeltaSpecs: true`.
   - Sempre anuncie: `Usando mudança: <nome>`.

2. **Resolver contexto e localizar delta specs**
   - Execute (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" status --change "<nome>" --json
     ```
   - Use exclusivamente `artifactPaths.specs.existingOutputPaths` como lista de delta specs e `planningHome.specsDir` (`openspec/specs`) como raiz das specs principais.
   - Se `existingOutputPaths` estiver vazio (ou `meta.skip_specs: true`), informe que não há delta specs para sincronizar e pare.
   - Se um chamador (como `openspec-archive-change`) ou o usuário forneceu um subconjunto explícito de caminhos de `existingOutputPaths`, sincronize **somente** esse subconjunto (nunca amplie de volta para toda a lista; se algum caminho nomeado não estiver em `existingOutputPaths`, pare e reporte).

3. **Obter snapshot de regras de specs**
   - Se chamado inline por `openspec-archive-change` com snapshot já obtido de `instructions specs`, reutilize-o sem repetir o comando.
   - Caso contrário, execute uma vez (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" instructions specs --change "<nome>" --json
     ```
   - Se o comando falhar ou retornar JSON inválido, pare antes de editar qualquer spec principal. Aplique `rules` apenas à forma/conteúdo das specs escritas (sem copiar o texto das regras para os arquivos).

4. **Aplicar merge inteligente para cada delta spec**
   Para cada delta spec selecionado:
   a. Leia o delta spec completo do disco.
   b. Leia a spec principal correspondente em `<planningHome.specsDir>/<capability-path>/spec.md` (se existir).

   - **Caso 1 — Spec principal NÃO existe ainda (nova capability):**
     - Somente `## ADDED Requirements` pode criar uma nova spec principal.
     - Se o delta contiver `## MODIFIED Requirements` ou `## RENAMED Requirements`, **bloqueie** a capability e informe que não existe requisito prévio para modificar/renomear (nunca invente requisitos).
     - Se o delta contiver apenas `## REMOVED Requirements`:
       - Se `.openspec.yaml` declarar `retire_capabilities: true`, considere já aposentada (avise e não recrie o arquivo).
       - Caso contrário, bloqueie o sync e informe que não há spec principal para remover.
     - Se houver `## ADDED Requirements` (e nenhum bloqueio): crie `<planningHome.specsDir>/<capability-path>/spec.md` seguindo o formato canônico abaixo, copiando o `## Purpose` do delta (ou inserindo placeholder TBD com aviso se estiver ausente) e todos os requisitos de `ADDED`. Se houver `REMOVED` junto, ignore-os com aviso.

   - **Caso 2 — Spec principal JÁ existe:**
     - **Título (`# ...`) e `## Purpose` existentes:** preserve-os **completamente intactos** (ignore `## Purpose` do delta, apenas avise se houver).
     - **`## ADDED Requirements`:** adicione requisitos novos sob `## Requirements`; se o requisito já existir, atualize-o de forma compatível.
     - **`## MODIFIED Requirements`:** localize o requisito e aplique as mudanças de descrição e cenários, preservando cenários e conteúdos não alterados mencionados no delta (todo `MODIFIED` completo deve manter os cenários sobreviventes).
     - **`## REMOVED Requirements`:** remova o bloco inteiro do requisito.
       - **Aposentadoria da capability:** só delete o arquivo `spec.md` (e a pasta vazia dentro de `openspec/specs/`, validando que o caminho permanece dentro de `openspec/specs/`) se **todas** as condições valerem: (1) nenhum requisito sobrar após esta remoção; (2) a spec ainda tinha `## Purpose` válido e requisitos antes desta execução; (3) `.openspec.yaml` declara `retire_capabilities: true`; (4) não há seções extras incompatíveis. Caso contrário, pare e informe o bloqueio — **nunca** deixe uma seção `## Requirements` vazia.
     - **`## RENAMED Requirements`:** localize o requisito `FROM` e renomeie para `TO`.
     - Preserve a ordem e todo o conteúdo existente não citado no delta.

5. **Validar as specs principais atualizadas**
   - Execute (após permissão):
     ```powershell
     pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" validate --specs --json
     ```
   - Só declare sucesso se `valid: true` (`exit code 0`). Se houver erros, reporte-os claramente para correção.

6. **Exibir resumo**
   - Capabilities criadas, atualizadas ou aposentadas (nomeando arquivos e requisitos afetados).
   - Eventual nova spec que tenha ficado com `Purpose` TBD pendente de preenchimento.
   - Lembrar que a mudança continua ativa até ser arquivada (`/opsx-archive`).

## Referência de formato canônico

**Delta Spec (entrada em `openspec/changes/<nome>/specs/<cap>/spec.md`):**
- Título `# Spec Delta: <cap>`
- `## Purpose` (apenas para nova capability)
- Seções válidas: `## ADDED Requirements`, `## MODIFIED Requirements`, `## REMOVED Requirements`, `## RENAMED Requirements` (`- FROM: \`### Requirement: ...\`` / `- TO: \`### Requirement: ...\``)

**Spec Principal (saída em `openspec/specs/<cap>/spec.md`):**
- Título `# <cap> Specification`
- `## Purpose` não vazio
- `## Requirements` contendo blocos `### Requirement: <nome>` (`SHALL`/`MUST`) e `#### Scenario: <nome>` (`- **GIVEN**`/`- **WHEN**`/`- **THEN**`)
- **NUNCA** pode conter cabeçalhos de delta (`## ADDED/MODIFIED/REMOVED/RENAMED Requirements`).

## Guardrails

- Leia sempre o delta spec e a spec principal antes de editar.
- Nunca copie um delta spec bruto para `openspec/specs/`; faça merge mantendo o formato canônico.
- Operação deve ser idempotente: rodar o sync novamente deve produzir o mesmo resultado.
- Nunca deixe `## Requirements` vazio em uma spec principal.
