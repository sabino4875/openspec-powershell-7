# Instruções — Artefato `design` (Condicional / Opcional)

## Quando criar vs. pular

Este artefato é **condicional (`optional: true`)**:

- **Crie `design.md` apenas se** a mudança envolver decisões arquiteturais, alterações de contratos de API/interfaces públicas, mudanças de schema de dados/persistência, integração entre múltiplos módulos ou camadas, novas dependências ou trade-offs técnicos relevantes.
- **Pode ser pulado deliberadamente** em mudanças triviais, ajustes localizados em um único componente sem decisão arquitetural ou mudanças puramente documentais. Ao pular, registre explicitamente ao usuário o motivo pelo qual `design.md` não é necessário.

## Diretrizes ao redigir

1. Leia `proposal.md` e os delta specs em `specs/` a partir do disco antes de redigir.
2. Respeite estritamente a linguagem de programação, a stack tecnológica, as camadas arquiteturais e os padrões de projeto definidos pelo usuário em `openspec/config.yaml` e na base de código existente:
   - Siga a organização de módulos, camadas e dependências já adotada pelo projeto.
   - Nunca introduza linguagens, frameworks, bancos de dados ou dependências externas não autorizados pelo usuário.
3. Aplique os guardrails obrigatórios de segurança e qualidade definidos pelo projeto (ex.: consultas parametrizadas, validação de entrada, compilação/lint sem erros ou warnings, preservação de contratos públicos e proibição de segredos versionados).
4. Inclua estratégia concreta de testes automatizados (utilizando o framework de testes definido pelo projeto) e verificação manual.
