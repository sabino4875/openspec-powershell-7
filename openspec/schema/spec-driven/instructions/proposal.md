# Instruções — Artefato `proposal`

## Objetivo

Definir **por que** a mudança existe e **o que** ela entrega em termos de escopo, impactos e critérios de aceitação, antes de detalhar requisitos, design ou tarefas.

## Passos obrigatórios antes de redigir

1. Leia `openspec/config.yaml` (campos `context` e `rules.proposal`), mantendo a linguagem, a stack e a arquitetura definidas pelo usuário apenas como restrições — **nunca** copie esses blocos para dentro de `proposal.md`.
2. Inspecione de forma read-only os arquivos de código, configurações, contratos/interfaces, features e documentos relevantes do repositório e `openspec/specs/` para fundamentar o escopo no estado real do projeto.
3. Identifique claramente quais módulos, serviços, camadas ou pacotes definidos na arquitetura do usuário são afetados e liste a documentação técnica do projeto impactada.
4. Separe claramente comportamento observado no código de premissas e adições propostas; se detectar conflito com specs existentes em `openspec/specs/`, registre e pergunte ao usuário em vez de decidir silenciosamente.
5. Liste todas as `<capability-path>` novas, modificadas ou aposentadas (ou justifique por que `skip_specs: true` se aplica em `.openspec.yaml`).

## Critérios de qualidade

- Não incluir detalhes de implementação linha a linha (isso pertence a `design.md` e `tasks.md`).
- Garantir que o escopo negativo (`Fora de escopo`) evite ambiguidades.
- Verificar a compatibilidade com os contratos de API, interfaces públicas, schemas de dados e padrões arquiteturais definidos pelo usuário sempre que integrações ou contratos públicos forem tocados.
