#!/usr/bin/env pwsh
#
# Install Akokuntaro Coding Skills (David's coding-style conventions) into every detected AI agent (Windows).
#
#   irm https://raw.githubusercontent.com/ProgrammerDATCH/Akokuntaro-Coding-Skills/develop/install.ps1 | iex
#
# Fetches (or updates) the skills source, finds every agent that uses the
# SKILL.md format, and links each skill into it (copying if symlinks aren't
# permitted — symlinks on Windows need Developer Mode or an elevated shell).
#
# Env overrides:
#   SKILLS_BRANCH    branch to pull          (default: develop)
#   SKILLS_SRC_DIR   where to keep source    (default: %LOCALAPPDATA%\coding-style-skills)
#   SKILLS_TARGETS   ';'-separated skills dirs to install into (skips auto-detect)
#   CLAUDE_CONFIG_DIR  honored when detecting Claude Code

$ErrorActionPreference = 'Stop'

$RepoSlug = 'ProgrammerDATCH/Akokuntaro-Coding-Skills'
$Branch   = if ($env:SKILLS_BRANCH)  { $env:SKILLS_BRANCH }  else { 'develop' }
$SrcDir   = if ($env:SKILLS_SRC_DIR) { $env:SKILLS_SRC_DIR } else { Join-Path $env:LOCALAPPDATA 'coding-style-skills' }
$Skills   = @('coding-principles', 'ui-review','nextjs-dashboard','express-prisma-api','react-vite-app','python-app')

function Info($m) { Write-Host "==> $m" -ForegroundColor Blue }
function Ok($m)   { Write-Host "  + $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  ! $m" -ForegroundColor Yellow }

# 1. Fetch the skills source (clone/update, or download a zip without git).
Info 'Installing coding-style skills'
if (Get-Command git -ErrorAction SilentlyContinue) {
  if (Test-Path (Join-Path $SrcDir '.git')) {
    Info "Updating skills source in $SrcDir"
    git -C $SrcDir pull --ff-only --quiet
  } else {
    Info "Cloning skills into $SrcDir"
    if (Test-Path $SrcDir) { Remove-Item -Recurse -Force $SrcDir }
    git clone --depth 1 --branch $Branch "https://github.com/$RepoSlug.git" $SrcDir --quiet
  }
} else {
  Info "Downloading skills zip into $SrcDir"
  if (Test-Path $SrcDir) { Remove-Item -Recurse -Force $SrcDir }
  New-Item -ItemType Directory -Force -Path $SrcDir | Out-Null
  $zip = Join-Path $env:TEMP 'coding-style-skills.zip'
  Invoke-WebRequest -Uri "https://github.com/$RepoSlug/archive/refs/heads/$Branch.zip" -OutFile $zip
  $tmp = Join-Path $env:TEMP "coding-style-skills-extract"
  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
  Expand-Archive -Path $zip -DestinationPath $tmp -Force
  $extracted = Get-ChildItem -Directory $tmp | Select-Object -First 1
  Copy-Item -Recurse -Force (Join-Path $extracted.FullName '*') $SrcDir
  Remove-Item $zip, $tmp -Recurse -Force
}
if (-not (Test-Path (Join-Path $SrcDir 'skills'))) { throw "skills/ not found in $SrcDir" }

# 2. Discover every agent that consumes SKILL.md skills.
$agents = @()
if ($env:SKILLS_TARGETS) {
  foreach ($d in ($env:SKILLS_TARGETS -split ';' | Where-Object { $_ })) {
    $agents += [pscustomobject]@{ Name = 'Custom'; Dir = $d }
  }
} else {
  $claudeHome = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
  $agents += [pscustomobject]@{ Name = 'Claude Code'; Dir = (Join-Path $claudeHome 'skills') }
}

# 3. Link (or copy) each skill into each agent.
foreach ($a in $agents) {
  New-Item -ItemType Directory -Force -Path $a.Dir | Out-Null
  foreach ($s in $Skills) {
    $target = Join-Path $SrcDir "skills\$s"
    $link   = Join-Path $a.Dir $s
    if (Test-Path $link) { Remove-Item -Recurse -Force $link }
    try {
      New-Item -ItemType SymbolicLink -Path $link -Target $target -ErrorAction Stop | Out-Null
    } catch {
      Copy-Item -Recurse -Force $target $link
    }
  }
  Ok "$($a.Name) -> $($a.Dir)"
}
Info "Done — installed: $($Skills -join ', ')"
Info 'Start a new agent session to pick up the skills.'
