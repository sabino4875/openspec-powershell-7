# Instruções — Execução (`apply`)

## Regras de execução no projeto

1. **Ler todo o contexto antes de editar código:** leia `proposal.md`, todos os arquivos de `specs/`, `design.md` (se existir) e `tasks.md` diretamente do disco, além de `openspec/config.yaml`.
2. **Uma etapa por vez (`GEMINI.md`):** execute **apenas** a etapa atual de `tasks.md`. Nunca execute duas etapas consecutivas sem confirmação explícita do usuário entre elas.
3. **Permissão prévia obrigatória para comandos (`GEMINI.md`):** peça permissão no chat listando literalmente cada comando (`pwsh`, `git` e comandos de build/teste da stack definida pelo usuário) antes de executá-lo.
4. **Execução síncrona em PowerShell 7 (`GEMINI.md`):** qualquer comando de script OpenSpec deve usar `pwsh -NoProfile -ExecutionPolicy Bypass -File "<script>.ps1"` ou `-Command "<comando>"`, sem background tasks/daemons.
5. **Respeito à linguagem e arquitetura do usuário:** siga rigorosamente a linguagem de programação, arquitetura, camadas, padrões de código e ferramentas definidos em `openspec/config.yaml` e na base de código do projeto.
6. **Escopo mínimo e fiel à spec:**
   - Se a tarefa estiver ambígua, pause e pergunte antes de implementar.
   - Se a implementação revelar divergência de design ou necessidade de escopo fora do especificado, pause e proponha atualização dos artefatos (`openspec-update-change`) — nunca reduza ou ignore silenciosamente um requisito.
7. **Atualização imediata de progresso:** só altere `- [ ]` para `- [x]` na linha exata de `tasks.md` quando o requisito/tarefa estiver integralmente implementado e verificado.
8. **Fechamento de cada etapa:** faça o commit local da etapa (após permissão), pare, relate claramente o que foi feito e aguarde confirmação explícita antes da próxima etapa.
9. **Fail-Fast / Tolerância Zero (`GEMINI.md`):** se qualquer comando, build, análise ou teste falhar, pare imediatamente, reporte os erros completos e aguarde orientação do usuário.
