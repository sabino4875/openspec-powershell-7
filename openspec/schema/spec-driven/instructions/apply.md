# Instruções — Execução (`apply`)

## Regras de execução no monorepo Afixinv

1. **Ler todo o contexto antes de editar código:** leia `proposal.md`, todos os arquivos de `specs/`, `design.md` (se existir) e `tasks.md` diretamente do disco, além de `openspec/config.yaml`.
2. **Uma etapa por vez (`GEMINI.md` §1.1):** execute **apenas** a etapa atual de `tasks.md`. Nunca execute duas etapas consecutivas sem confirmação explícita do usuário entre elas.
3. **Permissão prévia obrigatória para comandos (`GEMINI.md` §1.7):** peça permissão no chat listando literalmente cada comando (`pwsh`, `git`, `dotnet`, `flutter`, `dart`) antes de executá-lo.
4. **Execução síncrona em PowerShell 7 (`GEMINI.md` §1.3 e §1.6):** qualquer comando de script deve usar `pwsh -NoProfile -ExecutionPolicy Bypass -File "<script>.ps1"` ou `-Command "<comando>"`, sem background tasks/daemons e sem Windows PowerShell 5.1.
5. **Escopo mínimo e fiel à spec:**
   - Se a tarefa estiver ambígua, pause e pergunte antes de implementar.
   - Se a implementação revelar divergência de design ou necessidade de escopo fora do especificado, pause e proponha atualização dos artefatos (`openspec-update-change`) — nunca reduza ou ignore silenciosamente um requisito.
6. **Atualização imediata de progresso:** só altere `- [ ]` para `- [x]` na linha exata de `tasks.md` quando o requisito/tarefa estiver integralmente implementado e verificado.
7. **Fechamento de cada etapa:** faça o commit local da etapa (após permissão), pare, relate claramente o que foi feito e aguarde confirmação explícita antes da próxima etapa.
8. **Circuit Breaker:** se qualquer build, análise ou teste falhar 2 vezes seguidas, pare imediatamente, reporte os erros completos e aguarde orientação.
