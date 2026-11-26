# Design: <título da mudança>

## Contexto

Resumo técnico do estado atual (arquitetura, classes/componentes, fluxos, restrições relevantes do monorepo).

## Objetivos e não-objetivos

- **Objetivos:**
  - `<objetivo técnico>`
- **Não-objetivos:**
  - `<o que não será alterado>`

## Decisões técnicas

### Decisão 1: <título da decisão>
- **Escolha:** `<opção adotada>`
- **Alternativas consideradas:** `<alternativa A>`, `<alternativa B>`
- **Justificativa:** `<por que esta escolha respeita camadas, stack e restrições do projeto>`

## Arquitetura e componentes afetados

<!-- Respeitar camadas: servico/ (EndPoints -> CrossCutting -> Application -> Domain -> InfraEstructure) ou aplicativo/ (data/domain/presentation por feature). -->

- `<componente / arquivo>`: `<papel na mudança>`

## Contratos, dados e segurança

- **Contrato REST / Envelope Base64 (`ReceiveData/SendData`):** `<detalhes ou "Sem alterações">`
- **Persistência (`Dapper` / `SQL Server` / `sqflite`):** `<consultas parametrizadas, schemas, tabelas afetadas>`
- **Validação e autenticação/autorização:** `<FluentValidation, JWT, ApiKey, permissões>`
- **Guardrails aplicáveis:** `<ex.: sem interpolação de ORDER BY/OFFSET; offline-first preservado; sem segredos commitados>`

## Riscos, trade-offs e mitigação

- `<risco / trade-off>`: `<estratégia de mitigação>`

## Estratégia de verificação e testes

- **Testes automatizados:** `<xUnit v3 em servico/ sem I/O real; flutter test + flutter analyze em aplicativo/>`
- **Testes manuais / validações:** `<cenários a confirmar com o usuário>`
