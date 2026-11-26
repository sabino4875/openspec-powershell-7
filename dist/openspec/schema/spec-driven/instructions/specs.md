# Instruções — Artefato `specs` (Delta Specs)

## Onde criar os arquivos

- Caminho: `openspec/changes/<nome-da-mudanca>/specs/<capability-path>/spec.md` (ex.: `specs/autenticacao/spec.md` ou `specs/servico/relatorios/spec.md`).
- Se a capability já existir em `openspec/specs/<capability-path>/spec.md`, preserve exatamente o mesmo `<capability-path>`.
- Se `skip_specs: true` estiver definido em `.openspec.yaml`, este artefato **não deve** ser criado.

## Estrutura obrigatória de um Delta Spec

1. Use apenas as seções aplicáveis entre:
   - `## ADDED Requirements`
   - `## MODIFIED Requirements`
   - `## REMOVED Requirements`
   - `## RENAMED Requirements`
2. Use `## Purpose` apenas quando estiver introduzindo uma **nova** capability (ele será copiado para a spec principal durante o sync). Em capabilities existentes, o `## Purpose` da spec principal permanece intacto.
3. Todo requisito novo ou modificado deve usar cabeçalho `### Requirement: <nome>` com linguagem normativa (`SHALL` ou `MUST`) e pelo menos um cenário `#### Scenario: <nome>` estruturado em `- **GIVEN**`, `- **WHEN**`, `- **THEN**`.
4. **Regra do `MODIFIED` completo:** ao modificar um requisito existente, inclua o bloco inteiro do requisito — descrição e **todos** os cenários que sobrevivem da spec principal, além dos cenários novos ou alterados. Nunca omita cenários preservados dentro de um `MODIFIED`.
5. **Regra de aposentadoria (`retire_capabilities: true`):** para remover todos os requisitos de uma capability existente e removê-la da spec principal no sync, liste-os em `## REMOVED Requirements` e declare `retire_capabilities: true` no `.openspec.yaml` da mudança.
6. Em `## RENAMED Requirements`, utilize estritamente o formato:
   - `- FROM: \`### Requirement: <nome-antigo>\``
   - `- TO: \`### Requirement: <nome-novo>\``

## Referência da spec principal (pós-sync)

Após o sync, a spec principal em `openspec/specs/<capability-path>/spec.md` segue `templates/spec-main.md` (`# <capability> Specification`, `## Purpose`, `## Requirements`) e **nunca** deve conter cabeçalhos de delta (`## ADDED/MODIFIED/REMOVED/RENAMED Requirements`).
