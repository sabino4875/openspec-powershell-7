#Requires -Version 7.0
<#
.SYNOPSIS
  Suíte de testes automatizados para docs/scripts/openspec.ps1.
.DESCRIPTION
  Executa cenários ponta a ponta em uma sandbox isolada sob docs/logs/_openspec-test-sandbox
  (removida ao final no bloco finally), validando todos os subcomandos do openspec.ps1.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$scriptPath = Join-Path $repoRoot 'docs/scripts/openspec.ps1'
$logsDir = Join-Path $repoRoot 'docs/logs'
$logsExistedBefore = Test-Path -LiteralPath $logsDir
$sandbox = Join-Path $logsDir '_openspec-test-sandbox'

$passed = 0
$failed = 0

function Invoke-OpenSpec {
  param([string[]]$ArgsList)
  $allArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath) + $ArgsList + @('--root', $sandbox)
  $raw = & pwsh @allArgs 2>&1
  $code = $LASTEXITCODE
  $text = ($raw | Out-String).Trim()
  $obj = $null
  try {
    $obj = $text | ConvertFrom-Json
  } catch {
    throw "Saída não é JSON válido (exit $code): $text"
  }
  return [PSCustomObject]@{
    ExitCode = $code
    Data     = $obj
    Raw      = $text
  }
}

function Assert-True {
  param(
    [bool]$Condition,
    [string]$Message
  )
  if ($Condition) {
    $script:passed++
    Write-Output "PASS: $Message"
  } else {
    $script:failed++
    Write-Output "FAIL: $Message"
  }
}

try {
  if (Test-Path -LiteralPath $sandbox) {
    Remove-Item -LiteralPath $sandbox -Recurse -Force
  }
  $null = New-Item -ItemType Directory -Path (Join-Path $sandbox 'openspec/specs') -Force
  $null = New-Item -ItemType Directory -Path (Join-Path $sandbox 'openspec/changes/archive') -Force
  Copy-Item -LiteralPath (Join-Path $repoRoot 'openspec/config.yaml') -Destination (Join-Path $sandbox 'openspec/config.yaml')
  Copy-Item -LiteralPath (Join-Path $repoRoot 'openspec/schema') -Destination (Join-Path $sandbox 'openspec/schema') -Recurse

  # 1. context
  $res = Invoke-OpenSpec -ArgsList @('context', '--json')
  Assert-True ($res.ExitCode -eq 0 -and $res.Data.schema -eq 'spec-driven' -and $res.Data.hasContext -eq $true) 'context retorna schema spec-driven e hasContext=true'

  # 2. new (sucesso, rejeição de nome inválido e duplicado)
  $resNew = Invoke-OpenSpec -ArgsList @('new', 'test-change')
  Assert-True ($resNew.ExitCode -eq 0 -and $resNew.Data.created -eq $true -and (Test-Path -LiteralPath $resNew.Data.metaPath)) 'new test-change cria pasta e .openspec.yaml'

  $resBad = Invoke-OpenSpec -ArgsList @('new', 'Bad_Name')
  Assert-True ($resBad.ExitCode -ne 0 -and $resBad.Data.error -eq 'invalid_name') 'new rejeita nome fora do padrão kebab-case'

  $resDup = Invoke-OpenSpec -ArgsList @('new', 'test-change')
  Assert-True ($resDup.ExitCode -ne 0 -and $resDup.Data.error -eq 'change_exists') 'new rejeita mudança duplicada'

  # 3. status inicial -> após proposal + specs (design opcional não bloqueia tasks)
  $resSt1 = Invoke-OpenSpec -ArgsList @('status', '--change', 'test-change', '--json')
  $stProp1 = ($resSt1.Data.artifacts | Where-Object { $_.id -eq 'proposal' }).status
  $stSpecs1 = ($resSt1.Data.artifacts | Where-Object { $_.id -eq 'specs' }).status
  Assert-True ($stProp1 -eq 'ready' -and $stSpecs1 -eq 'blocked') 'status inicial: proposal=ready e specs=blocked'

  $changeRoot = $resSt1.Data.changeRoot
  Set-Content -LiteralPath (Join-Path $changeRoot 'proposal.md') -Value "# Proposta: Teste`n" -Encoding UTF8
  $deltaDir = Join-Path $changeRoot 'specs/auth'
  $null = New-Item -ItemType Directory -Path $deltaDir -Force
  $deltaPath = Join-Path $deltaDir 'spec.md'
  @(
    '# Spec Delta: auth'
    ''
    '## Purpose'
    'Autenticação de teste.'
    ''
    '## ADDED Requirements'
    ''
    '### Requirement: Login básico'
    'The system SHALL autenticar usuário válido.'
    ''
    '#### Scenario: Sucesso'
    '- **GIVEN** credenciais válidas'
    '- **WHEN** usuário envia login'
    '- **THEN** sistema retorna token'
  ) | Set-Content -LiteralPath $deltaPath -Encoding UTF8

  $resSt2 = Invoke-OpenSpec -ArgsList @('status', '--change', 'test-change', '--json')
  $stDesign2 = ($resSt2.Data.artifacts | Where-Object { $_.id -eq 'design' }).status
  $stTasks2 = ($resSt2.Data.artifacts | Where-Object { $_.id -eq 'tasks' }).status
  Assert-True ($stDesign2 -eq 'ready' -and $stTasks2 -eq 'ready') 'status após proposal+specs: design=ready e tasks=ready (design opcional)'

  # 4. instructions & tasks
  $resInstrProp = Invoke-OpenSpec -ArgsList @('instructions', 'proposal', '--change', 'test-change', '--json')
  Assert-True ($resInstrProp.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($resInstrProp.Data.template) -and $resInstrProp.Data.rules.Count -ge 1) 'instructions proposal retorna template e rules'

  $resApplyBlocked = Invoke-OpenSpec -ArgsList @('instructions', 'apply', '--change', 'test-change', '--json')
  Assert-True ($resApplyBlocked.Data.state -eq 'blocked') 'instructions apply retorna blocked antes de tasks.md'

  $tasksPath = Join-Path $changeRoot 'tasks.md'
  @(
    '# Tarefas'
    ''
    '```markdown'
    '- [ ] checkbox em bloco de código deve ser ignorado'
    '```'
    ''
    '- [x] 1.1 Primeira tarefa'
    '- [ ] 1.2 Segunda tarefa'
  ) | Set-Content -LiteralPath $tasksPath -Encoding UTF8

  $resTasks = Invoke-OpenSpec -ArgsList @('tasks', '--change', 'test-change', '--json')
  Assert-True ($resTasks.Data.totalTasks -eq 2 -and $resTasks.Data.completedTasks -eq 1 -and $resTasks.Data.tasks[1].line -eq 8) 'tasks ignora code fence e retorna linha exata (8)'

  $resApplyReady = Invoke-OpenSpec -ArgsList @('instructions', 'apply', '--change', 'test-change', '--json')
  Assert-True ($resApplyReady.Data.state -eq 'ready' -and $resApplyReady.Data.progress.remaining -eq 1) 'instructions apply retorna ready com 1 tarefa pendente'

  # 5. validate --change (válido vs inválido)
  $resValOk = Invoke-OpenSpec -ArgsList @('validate', '--change', 'test-change', '--json')
  Assert-True ($resValOk.ExitCode -eq 0 -and $resValOk.Data.valid -eq $true) 'validate --change aprova delta válido'

  Set-Content -LiteralPath $deltaPath -Value "# Spec Delta: auth`n`n## ADDED Requirements`n`n### Requirement: Sem cenário`nO sistema faz algo.`n" -Encoding UTF8
  $resValBad = Invoke-OpenSpec -ArgsList @('validate', '--change', 'test-change', '--json')
  Assert-True ($resValBad.ExitCode -ne 0 -and $resValBad.Data.valid -eq $false -and $resValBad.Data.errors.Count -ge 2) 'validate --change rejeita delta sem SHALL/MUST e sem Scenario'

  # 6. validate --specs (spec principal canônica vs spec com header de delta)
  $mainSpecDir = Join-Path $sandbox 'openspec/specs/auth'
  $null = New-Item -ItemType Directory -Path $mainSpecDir -Force
  $mainSpecPath = Join-Path $mainSpecDir 'spec.md'
  @(
    '# auth Specification'
    ''
    '## Purpose'
    'Autenticação.'
    ''
    '## Requirements'
    ''
    '### Requirement: Login'
    'The system SHALL validar token.'
    ''
    '#### Scenario: Token válido'
    '- **WHEN** token válido'
    '- **THEN** autoriza'
  ) | Set-Content -LiteralPath $mainSpecPath -Encoding UTF8

  $resSpecOk = Invoke-OpenSpec -ArgsList @('validate', '--specs', '--json')
  Assert-True ($resSpecOk.ExitCode -eq 0 -and $resSpecOk.Data.valid -eq $true) 'validate --specs aprova spec principal canônica'

  Add-Content -LiteralPath $mainSpecPath -Value "`n## ADDED Requirements`n"
  $resSpecBad = Invoke-OpenSpec -ArgsList @('validate', '--specs', '--json')
  Assert-True ($resSpecBad.ExitCode -ne 0 -and $resSpecBad.Data.valid -eq $false) 'validate --specs rejeita spec principal contendo cabeçalho de delta'

  # 7. archive (bloqueado quando incompleto -> sucesso quando 2/2 concluídas + sem duplicar data)
  $resArchBlocked = Invoke-OpenSpec -ArgsList @('archive', '--change', 'test-change')
  Assert-True ($resArchBlocked.ExitCode -ne 0 -and $resArchBlocked.Data.code -eq 'incomplete_change') 'archive bloqueia mudança com tarefa aberta sem --force'

  (Get-Content -LiteralPath $tasksPath -Raw) -replace '- \[ \] 1\.2', '- [x] 1.2' | Set-Content -LiteralPath $tasksPath -Encoding UTF8
  $resApplyDone = Invoke-OpenSpec -ArgsList @('instructions', 'apply', '--change', 'test-change', '--json')
  Assert-True ($resApplyDone.Data.state -eq 'all_done') 'instructions apply retorna all_done com 2/2 tarefas concluídas'

  $resArchOk = Invoke-OpenSpec -ArgsList @('archive', '--change', 'test-change')
  $expectedPrefix = (Get-Date).ToString('yyyy-MM-dd') + '-test-change'
  Assert-True ($resArchOk.ExitCode -eq 0 -and $resArchOk.Data.archived -eq $true -and $resArchOk.Data.targetName -eq $expectedPrefix -and (Test-Path -LiteralPath (Join-Path $resArchOk.Data.archivedPath '.openspec.yaml'))) 'archive move pasta com data e preserva .openspec.yaml'

  $null = Invoke-OpenSpec -ArgsList @('new', '2026-01-01-dated-change')
  $resDatedArch = Invoke-OpenSpec -ArgsList @('archive', '--change', '2026-01-01-dated-change', '--force')
  Assert-True ($resDatedArch.ExitCode -eq 0 -and $resDatedArch.Data.targetName -eq '2026-01-01-dated-change') 'archive não duplica prefixo YYYY-MM-DD- existente'
}
finally {
  if (Test-Path -LiteralPath $sandbox) {
    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
  }
  if (-not $logsExistedBefore -and (Test-Path -LiteralPath $logsDir)) {
    $remaining = @(Get-ChildItem -LiteralPath $logsDir -Force -ErrorAction SilentlyContinue)
    if ($remaining.Count -eq 0) {
      Remove-Item -LiteralPath $logsDir -Force -ErrorAction SilentlyContinue
    }
  }
}

Write-Output ""
Write-Output "Resumo: $passed passaram, $failed falharam."
if ($failed -gt 0) { exit 1 }
exit 0
