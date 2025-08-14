param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,   # e.g. C:\path\to\project
  [Parameter(Mandatory=$true)][string]$TargetName, # e.g. CppLegs
  [Parameter(Mandatory=$true)][string]$DestDir     # e.g. C:\path\to\project
)

function Log([string]$msg) { Write-Host "[auto_commit] $msg" }

# Use cmd for a few git probes that PowerShell can misparse
function Test-GitHeadExists {
  cmd /c 'git rev-parse --verify --quiet HEAD 1>nul 2>nul'
  return ($LASTEXITCODE -eq 0)
}
function Git-HasOrigin {
  cmd /c 'git remote get-url origin 1>nul 2>nul'
  return ($LASTEXITCODE -eq 0)
}
function Git-HasUpstream {
  # keep @{u} inside cmd so PS doesn't treat it like a hashtable
  cmd /c 'git rev-parse --abbrev-ref --symbolic-full-name @{u} 1>nul 2>nul'
  return ($LASTEXITCODE -eq 0)
}

Set-Location -LiteralPath $RepoRoot

# If git is missing, don't fail the build
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Log "git not found on PATH; skipping auto-commit."
  exit 0
}

$freshRepoInitialized = $false

# Init repo if missing
if (-not (Test-Path ".git")) {
  Log "No git repo found. Initializing one..."
  git init | Out-Null
  git config user.name  "Student Name"
  git config user.email "student@example.com"
}

# Ensure we have a HEAD to compare against; create a tiny bootstrap commit if not
$headExists = Test-GitHeadExists
if (-not $headExists) {
  if (-not (Test-Path ".gitignore")) {
@"
# Build artifacts / temp
build/
*.o
*.obj
*.ilk
*.pdb
*.idb
*.dll
*.lib
*.exp

# Qt/Creator user state
*.pro.user*
.qtc_clangd/
compile_commands.json

# macOS bundles
*.app/
"@ | Out-File ".gitignore" -Encoding utf8
  }
  git add .gitignore | Out-Null
  git commit -m "Initial commit (bootstrap)" | Out-Null
  $headExists = Test-GitHeadExists
  $freshRepoInitialized = $true
  Log "Fresh repo initialized; created bootstrap commit."
}

# Watch your sources in root and in Sources\
$watchCandidates = @(
  "perfect.cpp","soundex.cpp",
  "Sources\perfect.cpp","Sources\soundex.cpp"
)
$watch = @()
foreach ($p in $watchCandidates) {
  if (Test-Path -LiteralPath $p) { $watch += $p }
}
Log ("Watching {0} file(s)" -f $watch.Count)

# Decide whether to run tests this build
$shouldRun = $true
if (-not $freshRepoInitialized -and $watch.Count -gt 0) {
  # This picks up modified AND untracked files
  $statusLines = (& git status --porcelain -- $watch 2>$null)
  if (-not $statusLines -or $statusLines.Count -eq 0) {
    $shouldRun = $false
  }
}

if (-not $shouldRun) {
  Log "Sources unchanged; skipping test run + commit."
  exit 0
}

# Bump counter (for unique output file names)
$counterFile = ".autocommit_counter.txt"
if (Test-Path $counterFile) {
  $count = [int]((Get-Content $counterFile -ErrorAction SilentlyContinue | Select-Object -First 1) -replace '\D','')
  if ($null -eq $count) { $count = 0 }
} else {
  $count = 0
}
$count++
Set-Content -Path $counterFile -Value $count

# Prepare output file
$outputDir  = Join-Path $RepoRoot "output"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
$outputFile = Join-Path $outputDir ("welcome_output_{0}.txt" -f $count)

# Find the exe that qmake just linked
$exePath = Join-Path $DestDir ("{0}.exe" -f $TargetName)
if (-not (Test-Path $exePath)) {
  Log "Executable not found: $exePath (skipping)."
  exit 0
}

# Run your app; capture ONLY app stdout/stderr to the output file
try {
  New-Item -ItemType File -Force -Path $outputFile | Out-Null
  # If your tests are interactive by default, set a test-mode env here if needed:
  # $env:SCREENSHOT_MODE = "1"
  & "$exePath" 2>&1 | Tee-Object -FilePath $outputFile | Out-Null
  $appExit = $LASTEXITCODE
  Log ("App exited with code {0}" -f $appExit)
} catch {
  Log ("Error running app: {0}" -f $_.Exception.Message)
}

if ((Get-Item $outputFile).Length -eq 0) {
  Add-Content -Path $outputFile -Value "[no output captured]"
}

# Stage: watched sources + output + counter + this script
$toStage = @()
foreach ($f in $watch) { if (Test-Path $f) { $toStage += $f } }
if (Test-Path $outputFile)  { $toStage += $outputFile }
if (Test-Path $counterFile) { $toStage += $counterFile }
$toStage += "auto_commit.ps1"

git add -- $toStage | Out-Null

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$commitSource = Split-Path -Leaf (Get-Location)
git commit -m ("Auto-commit #{0} from {1} at {2}" -f $count, $commitSource, $timestamp) 2>$null
if ($LASTEXITCODE -ne 0) {
  Log "Nothing to commit."
  exit 0
}

# Push if origin exists; otherwise skip cleanly
if (Git-HasOrigin) {
  if (-not (Git-HasUpstream)) {
    git branch -M main | Out-Null
    git push -u origin main 2>$null
    if ($LASTEXITCODE -ne 0) { Log "Push failed (continuing)." }
  } else {
    git push 2>$null
    if ($LASTEXITCODE -ne 0) { Log "Push failed (continuing)." }
  }
} else {
  Log "No 'origin' remote configured; skipping push."
}

exit 0
