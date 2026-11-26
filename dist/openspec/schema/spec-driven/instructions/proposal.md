# Instruções — Artefato `proposal`

## Objetivo

Definir **por que** a mudança existe e **o que** ela entrega em termos de escopo, impactos e critérios de aceitação, antes de detalhar requisitos, design ou tarefas.

## Passos obrigatórios antes de redigir

1. Leia `openspec/config.yaml` (campos `context` e `rules.proposal`), mantendo-os apenas como restrições — **nunca** copie esses blocos para dentro de `proposal.md`.
2. Inspecione de forma read-only os arquivos, configurações, rotas/endpoints, features e documentos relevantes em `docs/projects/` e `openspec/specs/` para fundamentar o escopo no estado real do código.
3. Identifique claramente se a mudança afeta `servico/`, `aplicativo/` ou ambos, e liste os documentos em `docs/projects/<projeto>/` impactados.
4. Separe claramente comportamento observado no código de premissas e adições propostas; se detectar conflito com specs existentes em `openspec/specs/`, registre e pergunte ao usuário em vez de decidir silenciosamente.
5. Liste todas as `<capability-path>` novas, modificadas ou aposentadas (ou justifique por que `skip_specs: true` se aplica em `.openspec.yaml`).

## Critérios de qualidade

- Não incluir detalhes de implementação linha a linha (isso pertence a `design.md` e `tasks.md`).
- Garantir que o escopo negativo (`Fora de escopo`) evite ambiguidades.
- Verificar a compatibilidade com o contrato REST Afixbase (`ReceiveData/SendData` em Base64) sempre que ambos os projetos ou a API pública forem tocados.
