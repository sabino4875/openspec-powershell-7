# Instruções — Arquivamento (`archive`)

## Fluxo de verificação antes de mover a mudança

1. **Verificar completude de artefatos:** confirme via `openspec.ps1 status` que todos os artefatos obrigatórios estão presentes (ou devidamente pulados, como `skip_specs: true` ou `design.md` condicional). Se faltar algum artefato obrigatório, informe e peça confirmação explícita antes de continuar.
2. **Verificar completude de tarefas:** confirme via `openspec.ps1 tasks` (ou `list`) que todas as tarefas em `tasks.md` estão marcadas como `[x]`. Caso haja tarefas pendentes, exiba o aviso com a contagem exata e peça confirmação do usuário antes de arquivar.
3. **Avaliar e sincronizar delta specs:**
   - Se existirem arquivos em `specs/**/*.md` dentro da mudança, compare-os com `openspec/specs/<capability-path>/spec.md`.
   - Caso haja deltas pendentes e o usuário opte por sincronizar, execute o fluxo `openspec-sync-specs` (merge inteligente preservando conteúdo não alterado, `## Purpose` existente e cabeçalhos canônicos).
   - Nunca crie/mantenha uma spec principal com `## Requirements` vazio (para aposentar capability, exija `retire_capabilities: true` em `.openspec.yaml` e remova `spec.md` e diretório vazio).
   - Valide as specs principais via `openspec.ps1 validate --specs` **antes** de mover a pasta da mudança.
4. **Mover para o arquivo (`archive`):**
   - Destino em `openspec/changes/archive/<target-name>`: use o próprio `<name>` se já começar com `YYYY-MM-DD-`, ou `YYYY-MM-DD-<name>` caso contrário (nunca empilhar duas datas).
   - Se o diretório de destino já existir, falhe com erro claro sem sobrescrever.
   - Preserve `.openspec.yaml` dentro da pasta arquivada (move junto com o diretório).
5. **Permissão prévia:** lembre-se de solicitar permissão no chat antes de executar o comando `pwsh` de validação/arquivamento ou comandos `git` (`GEMINI.md` §1.7).
