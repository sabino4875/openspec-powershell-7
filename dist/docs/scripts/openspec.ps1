#Requires -Version 7.0
<#
.SYNOPSIS
  CLI local do OpenSpec em PowerShell 7 (substitui o pacote npm @fission-ai/openspec).
.DESCRIPTION
  Gerencia o ciclo OpenSpec (context, list, new, status, instructions, tasks, show,
  validate, archive) diretamente sobre openspec/ e openspec/schema/spec-driven/,
  sem Node.js, npm ou pnpm.
.EXAMPLE
  pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" context --json
.GITHUB REFERENCE
 https://github.com/Fission-AI/OpenSpec/
#>
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Write-JsonOutput {
  param(
    [Parameter(Mandatory = $true)]$Data,
    [int]$ExitCode = 0
  )
  $json = $Data | ConvertTo-Json -Depth 12
  Write-Output $json
  exit $ExitCode
}

function Write-ErrorJson {
  param(
    [string]$Code,
    [string]$Message,
    [hashtable]$Extra = @{},
    [int]$ExitCode = 1
  )
  $payload = [ordered]@{
    error   = $Code
    code    = $Code
    message = $Message
  }
  foreach ($k in $Extra.Keys) {
    $payload[$k] = $Extra[$k]
  }
  Write-JsonOutput -Data $payload -ExitCode $ExitCode
}

function Parse-CliArgs {
  param([string[]]$RawArgs)
  $positional = [System.Collections.Generic.List[string]]::new()
  $flags = @{}
  $i = 0
  while ($i -lt $RawArgs.Count) {
    $arg = $RawArgs[$i]
    if ($arg -eq '-h' -or $arg -eq '--help' -or $arg -eq '-Help') {
      $flags['help'] = $true
      $i++
      continue
    }
    if ($arg.StartsWith('--')) {
      $key = $arg.Substring(2)
      $valueFlags = @('change', 'schema', 'type', 'root')
      if ($valueFlags -contains $key) {
        if (($i + 1) -ge $RawArgs.Count) {
          Write-ErrorJson -Code 'invalid_arguments' -Message "A flag --$key exige um valor."
        }
        $flags[$key] = $RawArgs[$i + 1]
        $i += 2
      } else {
        $flags[$key] = $true
        $i++
      }
      continue
    }
    $positional.Add($arg)
    $i++
  }
  return [PSCustomObject]@{
    Positional = [string[]]$positional.ToArray()
    Flags      = $flags
  }
}

function Assert-PathInsideBase {
  param(
    [Parameter(Mandatory = $true)][string]$CandidatePath,
    [Parameter(Mandatory = $true)][string]$BaseDir
  )
  $fullBase = [System.IO.Path]::GetFullPath($BaseDir).TrimEnd('\', '/')
  $fullCandidate = [System.IO.Path]::GetFullPath($CandidatePath)
  $prefix = $fullBase + [System.IO.Path]::DirectorySeparatorChar
  if ($fullCandidate -ne $fullBase -and -not $fullCandidate.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-ErrorJson -Code 'path_traversal' -Message "Caminho fora do escopo permitido: $CandidatePath"
  }
  return $fullCandidate
}

function Resolve-OpenSpecRoot {
  param([string]$ExplicitRoot)
  if (-not [string]::IsNullOrWhiteSpace($ExplicitRoot)) {
    $full = [System.IO.Path]::GetFullPath($ExplicitRoot)
    $openspecDir = Join-Path $full 'openspec'
    if (Test-Path -LiteralPath $openspecDir -PathType Container) {
      return [PSCustomObject]@{
        RootPath    = $full
        OpenspecDir = $openspecDir
        ConfigPath  = (Join-Path $openspecDir 'config.yaml')
      }
    }
    return $null
  }

  $current = (Get-Location).Path
  while (-not [string]::IsNullOrWhiteSpace($current)) {
    $openspecDir = Join-Path $current 'openspec'
    if (Test-Path -LiteralPath $openspecDir -PathType Container) {
      return [PSCustomObject]@{
        RootPath    = $current
        OpenspecDir = $openspecDir
        ConfigPath  = (Join-Path $openspecDir 'config.yaml')
      }
    }
    $parent = Split-Path -Path $current -Parent
    if ($parent -eq $current) { break }
    $current = $parent
  }
  return $null
}

function Read-OpenSpecConfig {
  param([string]$ConfigPath)
  $result = [ordered]@{
    schema  = 'spec-driven'
    context = ''
    rules   = @{}
  }
  if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    return [PSCustomObject]$result
  }

  $lines = Get-Content -LiteralPath $ConfigPath -Encoding UTF8
  $mode = 'root'
  $currentRuleKey = $null
  $contextLines = [System.Collections.Generic.List[string]]::new()

  foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if ($mode -eq 'context') {
      if ($line -match '^\s{2}(.*)$') {
        $contextLines.Add($Matches[1])
        continue
      } elseif ($trimmed -eq '') {
        $contextLines.Add('')
        continue
      } else {
        $mode = 'root'
      }
    }

    if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }

    if ($line -match '^schema:\s*(.+)$') {
      $result.schema = $Matches[1].Trim().Trim('"', "'")
      $mode = 'root'
      continue
    }
    if ($line -match '^context:\s*\|') {
      $mode = 'context'
      continue
    }
    if ($line -match '^rules:\s*$') {
      $mode = 'rules'
      $currentRuleKey = $null
      continue
    }
    if ($mode -eq 'rules') {
      if ($line -match '^\s{2}([a-zA-Z0-9_-]+):\s*$') {
        $currentRuleKey = $Matches[1]
        if (-not $result.rules.ContainsKey($currentRuleKey)) {
          $result.rules[$currentRuleKey] = [System.Collections.Generic.List[string]]::new()
        }
        continue
      }
      if ($null -ne $currentRuleKey -and $line -match '^\s{4}-\s+(.+)$') {
        $result.rules[$currentRuleKey].Add($Matches[1].Trim())
        continue
      }
      if ($line -match '^\S') {
        $mode = 'root'
      }
    }
  }

  $result.context = ($contextLines -join "`n").TrimEnd()
  $normalizedRules = @{}
  foreach ($k in $result.rules.Keys) {
    $normalizedRules[$k] = [string[]]$result.rules[$k].ToArray()
  }
  $result.rules = $normalizedRules
  return [PSCustomObject]$result
}

function Read-SchemaDefinition {
  param(
    [Parameter(Mandatory = $true)][string]$OpenspecDir,
    [Parameter(Mandatory = $true)][string]$SchemaName
  )
  $schemaDir = Assert-PathInsideBase -CandidatePath (Join-Path $OpenspecDir (Join-Path 'schema' $SchemaName)) -BaseDir $OpenspecDir
  $schemaFile = Join-Path $schemaDir 'schema.yaml'
  if (-not (Test-Path -LiteralPath $schemaFile -PathType Leaf)) {
    Write-ErrorJson -Code 'schema_not_found' -Message "Schema '$SchemaName' não encontrado em $schemaFile"
  }

  $lines = @(Get-Content -LiteralPath $schemaFile -Encoding UTF8)
  $schema = [ordered]@{
    name                 = $SchemaName
    version              = 1
    description          = ''
    change_meta_template = 'change-meta.yaml'
    schemaDir            = $schemaDir
    apply                = [ordered]@{
      requires    = [System.Collections.Generic.List[string]]::new()
      tracks      = 'tasks.md'
      instruction = 'instructions/apply.md'
    }
    archive              = [ordered]@{
      instruction = 'instructions/archive.md'
    }
    artifacts            = [System.Collections.Generic.List[object]]::new()
  }

  $section = 'root'
  $subSection = ''
  $currentArtifact = $null

  foreach ($line in $lines) {
    $trimmed = $line.Trim()
    if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }

    if ($line -match '^(name|version|description|change_meta_template):\s*(.+)$') {
      $key = $Matches[1]
      $val = $Matches[2].Trim().Trim('"', "'")
      if ($key -eq 'version') { $schema[$key] = [int]$val } else { $schema[$key] = $val }
      $section = 'root'
      continue
    }
    if ($line -match '^apply:\s*$') { $section = 'apply'; $subSection = ''; continue }
    if ($line -match '^archive:\s*$') { $section = 'archive'; $subSection = ''; continue }
    if ($line -match '^artifacts:\s*$') { $section = 'artifacts'; $subSection = ''; continue }

    if ($section -eq 'apply') {
      if ($line -match '^\s{2}requires:\s*$') { $subSection = 'requires'; continue }
      if ($subSection -eq 'requires' -and $line -match '^\s{4}-\s+(.+)$') {
        $schema.apply.requires.Add($Matches[1].Trim())
        continue
      }
      if ($line -match '^\s{2}(tracks|instruction):\s*(.+)$') {
        $subSection = ''
        $schema.apply[$Matches[1]] = $Matches[2].Trim()
        continue
      }
    }

    if ($section -eq 'archive') {
      if ($line -match '^\s{2}instruction:\s*(.+)$') {
        $schema.archive.instruction = $Matches[1].Trim()
        continue
      }
    }

    if ($section -eq 'artifacts') {
      if ($line -match '^\s{2}-\s+id:\s*(.+)$') {
        $currentArtifact = [ordered]@{
          id           = $Matches[1].Trim()
          generates    = ''
          is_glob      = $false
          optional     = $false
          skippable_by = $null
          template     = ''
          instruction  = ''
          requires     = [System.Collections.Generic.List[string]]::new()
        }
        $schema.artifacts.Add($currentArtifact)
        $subSection = ''
        continue
      }
      if ($null -ne $currentArtifact) {
        if ($line -match '^\s{4}requires:\s*\[\s*\]\s*$') {
          $subSection = ''
          continue
        }
        if ($line -match '^\s{4}requires:\s*$') {
          $subSection = 'requires'
          continue
        }
        if ($subSection -eq 'requires' -and $line -match '^\s{6}-\s+(.+)$') {
          $currentArtifact.requires.Add($Matches[1].Trim())
          continue
        }
        if ($line -match '^\s{4}([a-z_]+):\s*(.+)$') {
          $subSection = ''
          $k = $Matches[1]
          $v = $Matches[2].Trim().Trim('"', "'")
          if ($k -eq 'is_glob' -or $k -eq 'optional') {
            $currentArtifact[$k] = ($v -eq 'true')
          } else {
            $currentArtifact[$k] = $v
          }
          continue
        }
      }
    }
  }

  $schema.apply.requires = [string[]]$schema.apply.requires.ToArray()
  foreach ($art in $schema.artifacts) {
    $art.requires = [string[]]$art.requires.ToArray()
  }
  $schema.artifacts = [object[]]$schema.artifacts.ToArray()
  return [PSCustomObject]$schema
}

function Read-ChangeMeta {
  param([string]$ChangeRoot)
  $metaPath = Join-Path $ChangeRoot '.openspec.yaml'
  $meta = [ordered]@{
    schema              = 'spec-driven'
    created             = ''
    skip_specs          = $false
    retire_capabilities = $false
    skip_design         = $false
  }
  if (-not (Test-Path -LiteralPath $metaPath -PathType Leaf)) {
    return [PSCustomObject]$meta
  }
  foreach ($line in (Get-Content -LiteralPath $metaPath -Encoding UTF8)) {
    $t = $line.Trim()
    if ($t -eq '' -or $t.StartsWith('#')) { continue }
    if ($t -match '^([a-z_]+):\s*(.+)$') {
      $k = $Matches[1]
      $v = $Matches[2].Trim().Trim('"', "'")
      if ($v -eq 'true') { $meta[$k] = $true }
      elseif ($v -eq 'false') { $meta[$k] = $false }
      else { $meta[$k] = $v }
    }
  }
  return [PSCustomObject]$meta
}

function Parse-TasksFile {
  param([string]$TasksPath)
  $items = [System.Collections.Generic.List[hashtable]]::new()
  if (-not (Test-Path -LiteralPath $TasksPath -PathType Leaf)) {
    return [PSCustomObject]@{
      exists         = $false
      totalTasks     = 0
      completedTasks = 0
      incompleteTasks = 0
      tasks          = [object[]]@()
    }
  }

  $lines = @(Get-Content -LiteralPath $TasksPath -Encoding UTF8)
  $inFence = $false
  for ($idx = 0; $idx -lt $lines.Count; $idx++) {
    $line = $lines[$idx]
    if ($line.TrimStart() -match '^```') {
      $inFence = -not $inFence
      continue
    }
    if ($inFence) { continue }

    if ($line -match '^\s*[-*]\s+\[([ xX])\]\s+(.+)$') {
      $done = ($Matches[1] -eq 'x' -or $Matches[1] -eq 'X')
      $items.Add([ordered]@{
        line       = ($idx + 1)
        completed  = $done
        text       = $Matches[2].Trim()
        sourcePath = $TasksPath
      })
    }
  }

  $total = $items.Count
  $completed = @($items | Where-Object { $_.completed }).Count
  return [PSCustomObject]@{
    exists          = $true
    totalTasks      = $total
    completedTasks  = $completed
    incompleteTasks = ($total - $completed)
    tasks           = [object[]]$items.ToArray()
  }
}

function Get-ArtifactFiles {
  param(
    [string]$ChangeRoot,
    $Artifact
  )
  if ($Artifact.is_glob) {
    $specsDir = Join-Path $ChangeRoot 'specs'
    if (-not (Test-Path -LiteralPath $specsDir -PathType Container)) {
      return
    }
    Get-ChildItem -LiteralPath $specsDir -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue |
      Sort-Object FullName |
      ForEach-Object { $_.FullName }
  } else {
    $target = Join-Path $ChangeRoot $Artifact.generates
    if (Test-Path -LiteralPath $target -PathType Leaf) {
      $target
    }
  }
}

function Get-ChangeStatusData {
  param(
    [PSCustomObject]$RootInfo,
    [PSCustomObject]$Config,
    [string]$ChangeName
  )
  if ([string]::IsNullOrWhiteSpace($ChangeName)) {
    Write-ErrorJson -Code 'missing_change' -Message 'Nome da mudança é obrigatório (--change <nome>).'
  }
  $changesDir = Join-Path $RootInfo.OpenspecDir 'changes'
  $changeRoot = Assert-PathInsideBase -CandidatePath (Join-Path $changesDir $ChangeName) -BaseDir $changesDir
  if (-not (Test-Path -LiteralPath $changeRoot -PathType Container)) {
    Write-ErrorJson -Code 'change_not_found' -Message "Mudança '$ChangeName' não encontrada em $changeRoot"
  }

  $meta = Read-ChangeMeta -ChangeRoot $changeRoot
  $schemaName = if ($meta.schema) { $meta.schema } else { $Config.schema }
  $schema = Read-SchemaDefinition -OpenspecDir $RootInfo.OpenspecDir -SchemaName $schemaName

  $artifactPaths = [ordered]@{}
  $existingMap = @{}
  $skippedMap = @{}

  foreach ($art in $schema.artifacts) {
    $files = [string[]]@(Get-ArtifactFiles -ChangeRoot $changeRoot -Artifact $art | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $isSkipped = $false
    if ($art.skippable_by -and ($meta.PSObject.Properties.Name -contains $art.skippable_by)) {
      $isSkipped = [bool]$meta.($art.skippable_by)
    }
    $skipProp = "skip_$($art.id)"
    if ($art.optional -and ($meta.PSObject.Properties.Name -contains $skipProp) -and [bool]$meta.$skipProp) {
      $isSkipped = $true
    }
    $existingMap[$art.id] = $files
    $skippedMap[$art.id] = $isSkipped

    $resolved = Join-Path $changeRoot $art.generates
    $artifactPaths[$art.id] = [ordered]@{
      outputPath          = $art.generates
      resolvedOutputPath  = $resolved
      isGlob              = [bool]$art.is_glob
      existingOutputPaths = [string[]]@($files)
    }
  }

  $artifactStatuses = [System.Collections.Generic.List[object]]::new()
  $statusLookup = @{}
  $artifactDefLookup = @{}
  foreach ($art in $schema.artifacts) { $artifactDefLookup[$art.id] = $art }

  foreach ($art in $schema.artifacts) {
    $files = @($existingMap[$art.id])
    $isSkipped = $skippedMap[$art.id]
    $st = 'blocked'
    if ($isSkipped) {
      $st = 'skipped'
    } elseif ($files.Count -gt 0) {
      $st = 'done'
    } else {
      $allDepsOk = $true
      foreach ($depId in $art.requires) {
        $depStatus = $statusLookup[$depId]
        $depIsOptional = [bool]$artifactDefLookup[$depId].optional
        if ($depStatus -eq 'done' -or $depStatus -eq 'skipped') {
          continue
        }
        if ($depIsOptional) {
          # Dependência opcional (ex.: design) só libera quando seus próprios pré-requisitos estão satisfeitos
          $depDef = $artifactDefLookup[$depId]
          $depOwnOk = $true
          foreach ($subDep in $depDef.requires) {
            if ($statusLookup[$subDep] -notin @('done', 'skipped')) {
              $depOwnOk = $false
              break
            }
          }
          if ($depOwnOk) { continue }
        }
        $allDepsOk = $false
        break
      }
      if ($allDepsOk) { $st = 'ready' }
    }
    $statusLookup[$art.id] = $st
    $artifactStatuses.Add([ordered]@{
      id                  = $art.id
      status              = $st
      optional            = [bool]$art.optional
      isGlob              = [bool]$art.is_glob
      requires            = [string[]]$art.requires
      existingOutputPaths = [string[]]@($files)
    })
  }

  $isPlanningComplete = $true
  foreach ($stItem in $artifactStatuses) {
    if (-not $stItem.optional -and $stItem.status -notin @('done', 'skipped')) {
      $isPlanningComplete = $false
      break
    }
  }

  return [PSCustomObject]@{
    changeName         = $ChangeName
    schemaName         = $schema.name
    planningHome       = [ordered]@{
      root        = $RootInfo.RootPath
      openspecDir = $RootInfo.OpenspecDir
      changesDir  = $changesDir
      specsDir    = (Join-Path $RootInfo.OpenspecDir 'specs')
    }
    changeRoot         = $changeRoot
    applyRequires      = [string[]]$schema.apply.requires
    isPlanningComplete = $isPlanningComplete
    isComplete         = $isPlanningComplete
    meta               = $meta
    artifacts          = [object[]]$artifactStatuses.ToArray()
    artifactPaths      = $artifactPaths
    schema             = $schema
  }
}

function Test-SpecMarkdown {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][ValidateSet('main', 'delta')][string]$Kind,
    [bool]$SkipSpecs = $false
  )
  $errors = [System.Collections.Generic.List[string]]::new()
  $warnings = [System.Collections.Generic.List[string]]::new()
  $lines = @(Get-Content -LiteralPath $FilePath -Encoding UTF8)

  $inFence = $false
  $hasH1 = $false
  $hasPurpose = $false
  $purposeBody = [System.Collections.Generic.List[string]]::new()
  $hasRequirementsHeader = $false
  $deltaHeaders = [System.Collections.Generic.List[string]]::new()

  $currentSection = ''
  $currentReqName = $null
  $currentReqSection = ''
  $currentReqHasNormative = $false
  $currentReqScenarioCount = 0

  $renamedFromCount = 0
  $renamedToCount = 0

  $flushReq = {
    if ($null -ne $currentReqName) {
      if ($Kind -eq 'main' -or $currentReqSection -in @('ADDED', 'MODIFIED')) {
        if (-not $currentReqHasNormative) {
          $errors.Add("${FilePath}: Requisito '$currentReqName' deve conter linguagem normativa (SHALL ou MUST).")
        }
        if ($currentReqScenarioCount -lt 1) {
          $errors.Add("${FilePath}: Requisito '$currentReqName' deve possuir ao menos um '#### Scenario:'.")
        }
      }
    }
  }

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $trimmed = $line.Trim()
    if ($trimmed.StartsWith('```')) {
      $inFence = -not $inFence
      continue
    }
    if ($inFence) { continue }

    if ($trimmed -match '^#\s+.+') { $hasH1 = $true }

    if ($trimmed -match '^##\s+(ADDED|MODIFIED|REMOVED|RENAMED)\s+Requirements\s*$') {
      & $flushReq
      $currentReqName = $null
      $sec = $Matches[1]
      $deltaHeaders.Add($sec)
      $currentSection = $sec
      continue
    }

    if ($trimmed -eq '## Purpose') {
      & $flushReq
      $currentReqName = $null
      $hasPurpose = $true
      $currentSection = 'Purpose'
      continue
    }

    if ($trimmed -eq '## Requirements') {
      & $flushReq
      $currentReqName = $null
      $hasRequirementsHeader = $true
      $currentSection = 'Requirements'
      continue
    }

    if ($trimmed -match '^##\s+') {
      & $flushReq
      $currentReqName = $null
      $currentSection = 'Other'
      continue
    }

    if ($trimmed -match '^###\s+Requirement:\s*(.+)$') {
      & $flushReq
      $currentReqName = $Matches[1].Trim()
      $currentReqSection = $currentSection
      $currentReqHasNormative = $false
      $currentReqScenarioCount = 0
      continue
    }

    if ($trimmed -match '^####\s+Scenario:\s*(.+)$') {
      if ($null -ne $currentReqName) {
        $currentReqScenarioCount++
      }
      continue
    }

    if ($currentSection -eq 'Purpose' -and $trimmed -ne '' -and -not $trimmed.StartsWith('<!--')) {
      $purposeBody.Add($trimmed)
    }

    if ($null -ne $currentReqName -and ($trimmed -match '\b(SHALL|MUST)\b')) {
      $currentReqHasNormative = $true
    }

    if ($currentSection -eq 'RENAMED') {
      if ($trimmed -match '^-\s*FROM:\s*`###\s+Requirement:\s*.+`') { $renamedFromCount++ }
      if ($trimmed -match '^-\s*TO:\s*`###\s+Requirement:\s*.+`') { $renamedToCount++ }
    }
  }
  & $flushReq

  if (-not $hasH1) {
    $errors.Add("${FilePath}: Título H1 ('# ...') ausente.")
  }

  if ($Kind -eq 'main') {
    if ($deltaHeaders.Count -gt 0) {
      $errors.Add("${FilePath}: Spec principal não pode conter cabeçalhos de delta ($($deltaHeaders -join ', ')).")
    }
    if (-not $hasPurpose -or $purposeBody.Count -eq 0) {
      $errors.Add("${FilePath}: Spec principal deve conter seção '## Purpose' não vazia.")
    }
    if (-not $hasRequirementsHeader) {
      $errors.Add("${FilePath}: Spec principal deve conter seção '## Requirements'.")
    }
    $reqCount = @($lines | Where-Object { $_ -match '^###\s+Requirement:' }).Count
    if ($reqCount -lt 1) {
      $errors.Add("${FilePath}: Spec principal deve conter ao menos um '### Requirement:'.")
    }
  } else {
    if ($SkipSpecs) {
      $errors.Add("${FilePath}: Delta spec presente, porém .openspec.yaml declara skip_specs: true.")
    }
    if ($deltaHeaders.Count -eq 0) {
      $errors.Add("${FilePath}: Delta spec deve conter ao menos uma seção ADDED, MODIFIED, REMOVED ou RENAMED Requirements.")
    }
    if ($renamedFromCount -ne $renamedToCount) {
      $errors.Add("${FilePath}: Seção RENAMED Requirements possui pares FROM/TO desbalanceados ($renamedFromCount FROM vs $renamedToCount TO).")
    }
  }

  return [PSCustomObject]@{
    errors   = [string[]]$errors.ToArray()
    warnings = [string[]]$warnings.ToArray()
  }
}

# --- Execução principal ---
$parsed = Parse-CliArgs -RawArgs $CliArgs
$pos = $parsed.Positional
$flags = $parsed.Flags

if ($flags.ContainsKey('help') -or $pos.Count -eq 0) {
  Write-Output @"
Uso: pwsh -NoProfile -ExecutionPolicy Bypass -File "docs/scripts/openspec.ps1" <comando> [opções]

Comandos:
  context                           Exibe raiz OpenSpec, schema e contexto configurado
  list [--specs]                    Lista mudanças ativas ou specs principais (--specs)
  new [change] <nome> [--schema s] [--skip-specs]
                                    Cria nova mudança em openspec/changes/<nome>
  status --change <nome>            Mostra estado dos artefatos e dependências
  instructions <alvo> --change <nome>
                                    Retorna template, regras e instruções (artefato|apply|archive)
  tasks --change <nome>             Lista tarefas e linhas de tasks.md
  show <id> [--type spec|change] [--no-scenarios]
                                    Exibe conteúdo de uma spec principal ou mudança
  validate [--specs | --change <nome>]
                                    Valida estrutura e regras de specs principais ou delta specs
  archive --change <nome> [--force] Move mudança para openspec/changes/archive/YYYY-MM-DD-<nome>
"@
  exit 0
}

$explicitRoot = if ($flags.ContainsKey('root')) { [string]$flags['root'] } else { '' }
$rootInfo = Resolve-OpenSpecRoot -ExplicitRoot $explicitRoot
if ($null -eq $rootInfo) {
  Write-ErrorJson -Code 'no_openspec_root' -Message 'Nenhum diretório openspec/ encontrado a partir do diretório atual.' -Extra @{ root = $null } -ExitCode 1
}

$config = Read-OpenSpecConfig -ConfigPath $rootInfo.ConfigPath
$cmd = $pos[0].ToLowerInvariant()

switch ($cmd) {
  'context' {
    $payload = [ordered]@{
      root          = [ordered]@{
        path        = $rootInfo.RootPath
        openspecDir = $rootInfo.OpenspecDir
        configPath  = $rootInfo.ConfigPath
      }
      schema        = $config.schema
      hasContext    = (-not [string]::IsNullOrWhiteSpace($config.context))
      contextLength = ([System.Text.Encoding]::UTF8.GetByteCount($config.context))
      rulesKeys     = [string[]]@($config.rules.Keys | Sort-Object)
    }
    Write-JsonOutput -Data $payload
  }

  'list' {
    if ($flags.ContainsKey('specs')) {
      $specsDir = Join-Path $rootInfo.OpenspecDir 'specs'
      $specsList = [System.Collections.Generic.List[hashtable]]::new()
      if (Test-Path -LiteralPath $specsDir -PathType Container) {
        $specFiles = Get-ChildItem -LiteralPath $specsDir -Filter 'spec.md' -Recurse -File -ErrorAction SilentlyContinue | Sort-Object FullName
        foreach ($sf in $specFiles) {
          $rel = $sf.Directory.FullName.Substring($specsDir.Length).TrimStart('\', '/').Replace('\', '/')
          $contentLines = Get-Content -LiteralPath $sf.FullName -Encoding UTF8
          $reqCount = @($contentLines | Where-Object { $_ -match '^###\s+Requirement:' }).Count
          $scenCount = @($contentLines | Where-Object { $_ -match '^####\s+Scenario:' }).Count
          $specsList.Add([ordered]@{
            id               = $rel
            path             = $sf.FullName
            requirementCount = $reqCount
            scenarioCount    = $scenCount
          })
        }
      }
      Write-JsonOutput -Data ([ordered]@{
        root  = [ordered]@{ path = $rootInfo.RootPath }
        specs = [object[]]$specsList.ToArray()
      })
    } else {
      $changesDir = Join-Path $rootInfo.OpenspecDir 'changes'
      $changesList = [System.Collections.Generic.List[hashtable]]::new()
      if (Test-Path -LiteralPath $changesDir -PathType Container) {
        $dirs = Get-ChildItem -LiteralPath $changesDir -Directory -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -ne 'archive' }
        foreach ($d in $dirs) {
          $meta = Read-ChangeMeta -ChangeRoot $d.FullName
          $tasksPath = Join-Path $d.FullName 'tasks.md'
          $taskInfo = Parse-TasksFile -TasksPath $tasksPath
          $deltaSpecsDir = Join-Path $d.FullName 'specs'
          $hasDelta = $false
          if (Test-Path -LiteralPath $deltaSpecsDir -PathType Container) {
            $hasDelta = (@(Get-ChildItem -LiteralPath $deltaSpecsDir -Filter '*.md' -Recurse -File -ErrorAction SilentlyContinue).Count -gt 0)
          }
          $latestWrite = $d.LastWriteTimeUtc
          $allFiles = Get-ChildItem -LiteralPath $d.FullName -Recurse -File -Force -ErrorAction SilentlyContinue
          foreach ($af in $allFiles) {
            if ($af.LastWriteTimeUtc -gt $latestWrite) { $latestWrite = $af.LastWriteTimeUtc }
          }
          $changesList.Add([ordered]@{
            name            = $d.Name
            schema          = $meta.schema
            path            = $d.FullName
            created         = $meta.created
            lastModified    = $latestWrite.ToString('o')
            totalTasks      = $taskInfo.totalTasks
            completedTasks  = $taskInfo.completedTasks
            incompleteTasks = $taskInfo.incompleteTasks
            hasDeltaSpecs   = $hasDelta
          })
        }
      }
      $sorted = @($changesList | Sort-Object -Property lastModified -Descending)
      Write-JsonOutput -Data ([ordered]@{
        root    = [ordered]@{ path = $rootInfo.RootPath }
        changes = [object[]]$sorted
      })
    }
  }

  'new' {
    $changeName = ''
    if ($pos.Count -ge 3 -and $pos[1].ToLowerInvariant() -eq 'change') {
      $changeName = $pos[2]
    } elseif ($pos.Count -ge 2) {
      $changeName = $pos[1]
    }
    if ([string]::IsNullOrWhiteSpace($changeName)) {
      Write-ErrorJson -Code 'missing_name' -Message 'Informe o nome da mudança em kebab-case: openspec.ps1 new <nome>'
    }
    if ($changeName -eq 'archive' -or $changeName -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
      Write-ErrorJson -Code 'invalid_name' -Message "Nome inválido '$changeName'. Use kebab-case (ex.: add-user-auth) e evite 'archive'."
    }

    $schemaName = if ($flags.ContainsKey('schema')) { [string]$flags['schema'] } else { $config.schema }
    $null = Read-SchemaDefinition -OpenspecDir $rootInfo.OpenspecDir -SchemaName $schemaName

    $changesDir = Join-Path $rootInfo.OpenspecDir 'changes'
    $changeRoot = Assert-PathInsideBase -CandidatePath (Join-Path $changesDir $changeName) -BaseDir $changesDir
    if (Test-Path -LiteralPath $changeRoot) {
      Write-ErrorJson -Code 'change_exists' -Message "A mudança '$changeName' já existe em $changeRoot"
    }

    $null = New-Item -ItemType Directory -Path $changeRoot -Force
    $skipSpecsVal = if ($flags.ContainsKey('skip-specs')) { 'true' } else { 'false' }
    $today = (Get-Date).ToString('yyyy-MM-dd')
    $metaContent = @(
      "schema: $schemaName"
      "created: $today"
      "skip_specs: $skipSpecsVal"
      "retire_capabilities: false"
    ) -join "`n"
    $metaPath = Join-Path $changeRoot '.openspec.yaml'
    Set-Content -LiteralPath $metaPath -Value $metaContent -Encoding UTF8

    Write-JsonOutput -Data ([ordered]@{
      created    = $true
      name       = $changeName
      schema     = $schemaName
      skipSpecs  = ($skipSpecsVal -eq 'true')
      changeRoot = $changeRoot
      metaPath   = $metaPath
    })
  }

  'status' {
    $changeName = if ($flags.ContainsKey('change')) { [string]$flags['change'] } elseif ($pos.Count -ge 2) { $pos[1] } else { '' }
    $st = Get-ChangeStatusData -RootInfo $rootInfo -Config $config -ChangeName $changeName
    $st.PSObject.Properties.Remove('schema')
    Write-JsonOutput -Data $st
  }

  'instructions' {
    if ($pos.Count -lt 2) {
      Write-ErrorJson -Code 'missing_target' -Message 'Informe o alvo: instructions <artefato|apply|archive> --change <nome>'
    }
    $target = $pos[1].ToLowerInvariant()
    $changeName = if ($flags.ContainsKey('change')) { [string]$flags['change'] } elseif ($pos.Count -ge 3) { $pos[2] } else { '' }
    $st = Get-ChangeStatusData -RootInfo $rootInfo -Config $config -ChangeName $changeName
    $schema = $st.schema

    if ($target -eq 'apply') {
      $missing = [System.Collections.Generic.List[string]]::new()
      foreach ($art in $st.artifacts) {
        if (-not $art.optional -and $art.status -notin @('done', 'skipped')) {
          $missing.Add($art.id)
        }
      }
      $tracksPath = Join-Path $st.changeRoot $schema.apply.tracks
      $taskInfo = Parse-TasksFile -TasksPath $tracksPath

      $state = 'ready'
      if ($missing.Count -gt 0 -or -not $taskInfo.exists) {
        $state = 'blocked'
      } elseif ($taskInfo.totalTasks -gt 0 -and $taskInfo.incompleteTasks -eq 0) {
        $state = 'all_done'
      }

      $contextFiles = [ordered]@{}
      foreach ($artId in $st.artifactPaths.Keys) {
        $contextFiles[$artId] = [string[]]$st.artifactPaths[$artId].existingOutputPaths
      }

      $instrPath = Assert-PathInsideBase -CandidatePath (Join-Path $schema.schemaDir $schema.apply.instruction) -BaseDir $schema.schemaDir
      $instrText = if (Test-Path -LiteralPath $instrPath -PathType Leaf) { Get-Content -LiteralPath $instrPath -Raw -Encoding UTF8 } else { '' }

      Write-JsonOutput -Data ([ordered]@{
        changeName       = $st.changeName
        schemaName       = $st.schemaName
        state            = $state
        missingArtifacts = [string[]]$missing.ToArray()
        contextFiles     = $contextFiles
        progress         = [ordered]@{
          total     = $taskInfo.totalTasks
          completed = $taskInfo.completedTasks
          remaining = $taskInfo.incompleteTasks
        }
        tasks            = [object[]]$taskInfo.tasks
        instruction      = $instrText.Trim()
        context          = $config.context
      })
    }

    if ($target -eq 'archive') {
      $instrPath = Assert-PathInsideBase -CandidatePath (Join-Path $schema.schemaDir $schema.archive.instruction) -BaseDir $schema.schemaDir
      $instrText = if (Test-Path -LiteralPath $instrPath -PathType Leaf) { Get-Content -LiteralPath $instrPath -Raw -Encoding UTF8 } else { '' }
      Write-JsonOutput -Data ([ordered]@{
        changeName  = $st.changeName
        schemaName  = $st.schemaName
        instruction = $instrText.Trim()
        context     = $config.context
      })
    }

    $artDef = $schema.artifacts | Where-Object { $_.id -eq $target } | Select-Object -First 1
    if ($null -eq $artDef) {
      Write-ErrorJson -Code 'artifact_not_found' -Message "Artefato '$target' não pertence ao schema '$($schema.name)'."
    }
    $artStatus = $st.artifacts | Where-Object { $_.id -eq $target } | Select-Object -First 1

    $tplPath = Assert-PathInsideBase -CandidatePath (Join-Path $schema.schemaDir $artDef.template) -BaseDir $schema.schemaDir
    $instrPath = Assert-PathInsideBase -CandidatePath (Join-Path $schema.schemaDir $artDef.instruction) -BaseDir $schema.schemaDir
    $tplText = if (Test-Path -LiteralPath $tplPath -PathType Leaf) { Get-Content -LiteralPath $tplPath -Raw -Encoding UTF8 } else { '' }
    $instrText = if (Test-Path -LiteralPath $instrPath -PathType Leaf) { Get-Content -LiteralPath $instrPath -Raw -Encoding UTF8 } else { '' }
    $rulesArr = if ($config.rules.ContainsKey($target)) { [string[]]$config.rules[$target] } else { [string[]]@() }

    $deps = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($depId in $artDef.requires) {
      $deps.Add([ordered]@{
        id    = $depId
        paths = [string[]]$st.artifactPaths[$depId].existingOutputPaths
      })
    }

    Write-JsonOutput -Data ([ordered]@{
      changeName         = $st.changeName
      artifactId         = $target
      schemaName         = $st.schemaName
      skipped            = ($artStatus.status -eq 'skipped')
      optional           = [bool]$artDef.optional
      resolvedOutputPath = $st.artifactPaths[$target].resolvedOutputPath
      template           = $tplText.Trim()
      instruction        = $instrText.Trim()
      context            = $config.context
      rules              = $rulesArr
      dependencies       = [object[]]$deps.ToArray()
    })
  }

  'tasks' {
    $changeName = if ($flags.ContainsKey('change')) { [string]$flags['change'] } elseif ($pos.Count -ge 2) { $pos[1] } else { '' }
    $st = Get-ChangeStatusData -RootInfo $rootInfo -Config $config -ChangeName $changeName
    $tasksPath = Join-Path $st.changeRoot $st.schema.apply.tracks
    $taskInfo = Parse-TasksFile -TasksPath $tasksPath
    Write-JsonOutput -Data ([ordered]@{
      changeName      = $st.changeName
      sourcePath      = $tasksPath
      exists          = $taskInfo.exists
      totalTasks      = $taskInfo.totalTasks
      completedTasks  = $taskInfo.completedTasks
      incompleteTasks = $taskInfo.incompleteTasks
      tasks           = [object[]]$taskInfo.tasks
    })
  }

  'show' {
    if ($pos.Count -lt 2) {
      Write-ErrorJson -Code 'missing_id' -Message 'Informe o identificador: show <id> [--type spec|change]'
    }
    $id = $pos[1]
    $type = if ($flags.ContainsKey('type')) { ([string]$flags['type']).ToLowerInvariant() } else { 'change' }
    if ($type -eq 'spec') {
      $specsDir = Join-Path $rootInfo.OpenspecDir 'specs'
      $specPath = Assert-PathInsideBase -CandidatePath (Join-Path $specsDir (Join-Path $id 'spec.md')) -BaseDir $specsDir
      if (-not (Test-Path -LiteralPath $specPath -PathType Leaf)) {
        Write-ErrorJson -Code 'spec_not_found' -Message "Spec '$id' não encontrada em $specPath"
      }
      $lines = @(Get-Content -LiteralPath $specPath -Encoding UTF8)
      if ($flags.ContainsKey('no-scenarios')) {
        $filtered = [System.Collections.Generic.List[string]]::new()
        $skipScenario = $false
        foreach ($line in $lines) {
          if ($line -match '^####\s+Scenario:') { $skipScenario = $true; continue }
          if ($line -match '^#{1,3}\s+') { $skipScenario = $false }
          if (-not $skipScenario) { $filtered.Add($line) }
        }
        $content = ($filtered -join "`n").TrimEnd()
      } else {
        $content = ($lines -join "`n").TrimEnd()
      }
      Write-JsonOutput -Data ([ordered]@{
        id      = $id
        type    = 'spec'
        path    = $specPath
        content = $content
      })
    } else {
      $st = Get-ChangeStatusData -RootInfo $rootInfo -Config $config -ChangeName $id
      $st.PSObject.Properties.Remove('schema')
      Write-JsonOutput -Data $st
    }
  }

  'validate' {
    $errors = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $checked = [System.Collections.Generic.List[string]]::new()

    if ($flags.ContainsKey('change')) {
      $changeName = [string]$flags['change']
      $st = Get-ChangeStatusData -RootInfo $rootInfo -Config $config -ChangeName $changeName
      $deltaFiles = @($st.artifactPaths['specs'].existingOutputPaths)
      if ($st.meta.skip_specs -and $deltaFiles.Count -gt 0) {
        $errors.Add("Mudança '$changeName' declara skip_specs: true, mas possui arquivos em specs/.")
      }
      foreach ($df in $deltaFiles) {
        $checked.Add($df)
        $res = Test-SpecMarkdown -FilePath $df -Kind 'delta' -SkipSpecs ([bool]$st.meta.skip_specs)
        foreach ($e in $res.errors) { $errors.Add($e) }
        foreach ($w in $res.warnings) { $warnings.Add($w) }
      }
      if (-not $st.meta.skip_specs -and $deltaFiles.Count -eq 0) {
        $warnings.Add("Mudança '$changeName' ainda não possui delta specs em specs/.")
      }
    } else {
      $specsDir = Join-Path $rootInfo.OpenspecDir 'specs'
      if (Test-Path -LiteralPath $specsDir -PathType Container) {
        $specFiles = Get-ChildItem -LiteralPath $specsDir -Filter 'spec.md' -Recurse -File -ErrorAction SilentlyContinue | Sort-Object FullName
        foreach ($sf in $specFiles) {
          $checked.Add($sf.FullName)
          $res = Test-SpecMarkdown -FilePath $sf.FullName -Kind 'main'
          foreach ($e in $res.errors) { $errors.Add($e) }
          foreach ($w in $res.warnings) { $warnings.Add($w) }
        }
      }
    }

    $isValid = ($errors.Count -eq 0)
    $exitCode = if ($isValid) { 0 } else { 1 }
    Write-JsonOutput -Data ([ordered]@{
      valid        = $isValid
      checkedFiles = [string[]]$checked.ToArray()
      errors       = [string[]]$errors.ToArray()
      warnings     = [string[]]$warnings.ToArray()
    }) -ExitCode $exitCode
  }

  'archive' {
    $changeName = if ($flags.ContainsKey('change')) { [string]$flags['change'] } elseif ($pos.Count -ge 2) { $pos[1] } else { '' }
    $st = Get-ChangeStatusData -RootInfo $rootInfo -Config $config -ChangeName $changeName
    $tasksPath = Join-Path $st.changeRoot $st.schema.apply.tracks
    $taskInfo = Parse-TasksFile -TasksPath $tasksPath

    $incompleteArtifacts = @($st.artifacts | Where-Object { -not $_.optional -and $_.status -notin @('done', 'skipped') } | ForEach-Object { $_.id })
    if (-not $flags.ContainsKey('force')) {
      if ($incompleteArtifacts.Count -gt 0 -or $taskInfo.incompleteTasks -gt 0) {
        Write-ErrorJson -Code 'incomplete_change' -Message "Mudança '$changeName' possui pendências (artefatos incompletos: $($incompleteArtifacts -join ', '); tarefas pendentes: $($taskInfo.incompleteTasks)). Use --force para arquivar mesmo assim." -Extra @{
          incompleteArtifacts = [string[]]$incompleteArtifacts
          incompleteTasks     = $taskInfo.incompleteTasks
        }
      }
    }

    $archiveDir = Join-Path $st.planningHome.changesDir 'archive'
    if (-not (Test-Path -LiteralPath $archiveDir -PathType Container)) {
      $null = New-Item -ItemType Directory -Path $archiveDir -Force
    }

    $targetName = if ($changeName -match '^\d{4}-\d{2}-\d{2}-') {
      $changeName
    } else {
      "$((Get-Date).ToString('yyyy-MM-dd'))-$changeName"
    }
    $targetPath = Assert-PathInsideBase -CandidatePath (Join-Path $archiveDir $targetName) -BaseDir $archiveDir
    if (Test-Path -LiteralPath $targetPath) {
      Write-ErrorJson -Code 'archive_exists' -Message "Destino de arquivo já existe: $targetPath"
    }

    Move-Item -LiteralPath $st.changeRoot -Destination $targetPath
    Write-JsonOutput -Data ([ordered]@{
      archived     = $true
      changeName   = $changeName
      schemaName   = $st.schemaName
      targetName   = $targetName
      archivedPath = $targetPath
    })
  }

  default {
    Write-ErrorJson -Code 'unknown_command' -Message "Comando desconhecido: '$cmd'. Use --help para ver os comandos suportados."
  }
}
