# Instruções — Artefato `design` (Condicional / Opcional)

## Quando criar vs. pular

Este artefato é **condicional (`optional: true`)**:

- **Crie `design.md` apenas se** a mudança envolver decisões arquiteturais, alterações de contrato REST/envelope Base64, mudanças de schema/tabelas (SQL Server ou `sqflite`), integração entre múltiplos módulos/camadas, novos pacotes/dependências ou trade-offs técnicos relevantes.
- **Pode ser pulado deliberadamente** em mudanças triviais, ajustes localizados em 1 componente sem decisão arquitetural ou mudanças puramente documentais. Ao pular, registre explicitamente ao usuário o motivo pelo qual `design.md` não é necessário.

## Diretrizes ao redigir

1. Leia `proposal.md` e os delta specs em `specs/` a partir do disco antes de redigir.
2. Respeite as camadas e a stack permitida em `openspec/config.yaml`:
   - `servico/`: `EndPoints -> CrossCutting -> Application -> Domain -> InfraEstructure` (.NET 10 / C# / Dapper / FluentValidation / xUnit v3).
   - `aplicativo/`: `data / domain / presentation` por feature (Flutter / Dart / `flutter_bloc` / `get_it` / `sqflite` offline-first).
   - Nunca introduzir Node.js, pnpm, Python, Docker ou Windows PowerShell 5.1.
3. Aplique os guardrails obrigatórios de segurança e qualidade (SQL parametrizado sem interpolar `ORDER BY`/`OFFSET`, `TreatWarningsAsErrors`, sem ampliar CORS, sem reativar `JwtMiddleware`, sem novas permissões Android sem aprovação, sem segredos versionados).
4. Inclua estratégia concreta de testes automatizados e verificação manual.
