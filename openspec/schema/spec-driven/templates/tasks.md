# Tarefas: <título da mudança>

> **Ciclo obrigatório (`GEMINI.md` §1.1 e §1.7):** execute **somente uma etapa por vez**. Ao concluir a etapa atual, peça permissão explícita antes de qualquer comando, faça o commit local correspondente, pare e aguarde confirmação do usuário antes de avançar para a próxima etapa.

## Etapa 1 — <Título da etapa 1>

- [ ] 1.1 <Ação específica e verificável>
- [ ] 1.2 <Ação específica e verificável>

## Etapa 2 — <Título da etapa 2>

- [ ] 2.1 <Ação específica e verificável>
- [ ] 2.2 <Ação específica e verificável>

## Etapa 3 — Verificação, documentação e fechamento

- [ ] 3.1 Executar build e análise estática (`dotnet build -c Release` ou `flutter analyze`) sem erros nem warnings
- [ ] 3.2 Executar testes automatizados (`dotnet test -c Release` com mocks / sem I/O real, ou `flutter test`) sem falhas
- [ ] 3.3 Atualizar a documentação as-is em `docs/projects/<projeto>/documentation/` (e `analysis/` se aplicável) no mesmo commit do código
- [ ] 3.4 Validar testes manuais com o usuário e sincronizar delta specs para `openspec/specs/`
- [ ] 3.5 Gerar PR em `docs/pr/<nome-da-mudanca>.md` e detalhamento Azure DevOps em `docs/tasks/<nome-da-mudanca>-tasks.md`
