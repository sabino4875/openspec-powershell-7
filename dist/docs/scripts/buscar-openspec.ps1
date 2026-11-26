#Requires -Version 7.0
[CmdletBinding()]
param (
    [string]$BasePath = ".agents/skills",
    [string]$SkillPrefix = "openspec*"
)

if (-not (Test-Path -LiteralPath $BasePath) -and -not [System.IO.Path]::IsPathRooted($BasePath)) {
    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
    $candidate = Join-Path $repoRoot $BasePath
    if (Test-Path -LiteralPath $candidate) {
        $BasePath = $candidate
    }
}

$patterns = @(
    "Bash(openspec",
    "Requires openspec CLI",
    "openspec init",
    "openspec store",
    "npm",
    "pnpm",
    "Node.js"
)

$files = @(Get-ChildItem -Path $BasePath -Filter "SKILL.md" -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Directory.Name -like $SkillPrefix })

if ($files.Count -eq 0) {
    Write-Output "arquivos=0 ocorrencias=0"
    return
}

$found = @($files | Select-String -SimpleMatch -Pattern $patterns)

Write-Output "arquivos=$($files.Count) ocorrencias=$($found.Count)"
if ($found.Count -gt 0) {
    $found | Format-Table -Property Path, LineNumber, Line -AutoSize
}
