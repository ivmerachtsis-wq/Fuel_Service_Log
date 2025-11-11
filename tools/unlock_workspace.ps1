#requires -Version 5
<#
.SYNOPSIS
    Unlocks the Flutter workspace by killing processes and removing lock files.
.DESCRIPTION
    Stops common lock-holder processes (Flutter, Dart, Gradle, etc.),
    removes Git/Gradle/Hive lock files, runs flutter clean, and reports status.
.PARAMETER RepoRoot
    Path to repository root. Defaults to parent of script directory.
.EXAMPLE
    .\unlock_workspace.ps1
#>
param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

Write-Host "==> Unlocking workspace at: $RepoRoot" -ForegroundColor Cyan
Set-Location $RepoRoot

$killCount = 0
$lockCount = 0

# 1) Kill common lock-holder processes
Write-Host "`n[1/6] Stopping lock-holder processes..." -ForegroundColor Yellow
$procs = @('flutter', 'dart', 'java', 'gradle', 'adb', 'code', 'chromedriver', 'node', 'flutter_tester')
foreach ($p in $procs) {
    $running = Get-Process -Name $p -ErrorAction SilentlyContinue
    if ($running) {
        $running | Stop-Process -Force -ErrorAction SilentlyContinue
        $killCount += $running.Count
        Write-Host "  ✓ Killed $($running.Count) '$p' process(es)" -ForegroundColor DarkGray
    }
}
if ($killCount -eq 0) {
    Write-Host "  ℹ No processes to kill" -ForegroundColor DarkGray
}

# 2) Remove Git lock files
Write-Host "`n[2/6] Removing Git locks..." -ForegroundColor Yellow
$gitLocks = @(
    ".git\index.lock",
    ".git\HEAD.lock",
    ".git\refs\heads\main.lock"
)
foreach ($lock in $gitLocks) {
    $fullPath = Join-Path $RepoRoot $lock
    if (Test-Path $fullPath) {
        Remove-Item $fullPath -Force -ErrorAction SilentlyContinue
        $lockCount++
        Write-Host "  ✓ Removed $lock" -ForegroundColor DarkGray
    }
}

# 3) Stop Gradle daemons & remove locks
Write-Host "`n[3/6] Stopping Gradle daemons..." -ForegroundColor Yellow
try {
    $gradleStopOut = & gradle --stop 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Gradle daemons stopped" -ForegroundColor DarkGray
    }
} catch {
    Write-Host "  ℹ Gradle not found or already stopped" -ForegroundColor DarkGray
}

# Remove Gradle lock files
$gradleHome = "$env:USERPROFILE\.gradle"
if (Test-Path $gradleHome) {
    $gradleLocks = Get-ChildItem -Path $gradleHome -Recurse -Filter "*.lock" -ErrorAction SilentlyContinue
    if ($gradleLocks) {
        $gradleLocks | Remove-Item -Force -ErrorAction SilentlyContinue
        $lockCount += $gradleLocks.Count
        Write-Host "  ✓ Removed $($gradleLocks.Count) Gradle lock(s)" -ForegroundColor DarkGray
    }
}

# 4) Remove local build & .dart_tool locks
Write-Host "`n[4/6] Removing local build locks..." -ForegroundColor Yellow
$buildDirs = @("build", ".dart_tool", "test_hive_settings_toggle", "test_hive_widget", "test_hive_temp_integrity")
foreach ($dir in $buildDirs) {
    $fullDir = Join-Path $RepoRoot $dir
    if (Test-Path $fullDir) {
        # Remove .lock files
        $buildLocks = Get-ChildItem -Path $fullDir -Recurse -Filter "*.lock" -ErrorAction SilentlyContinue
        if ($buildLocks) {
            $buildLocks | Remove-Item -Force -ErrorAction SilentlyContinue
            $lockCount += $buildLocks.Count
            Write-Host "  ✓ Removed $($buildLocks.Count) lock(s) from $dir" -ForegroundColor DarkGray
        }
        
        # Remove .hive files (test artifacts)
        if ($dir -like "test_hive*") {
            $hiveFiles = Get-ChildItem -Path $fullDir -Recurse -Filter "*.hive" -ErrorAction SilentlyContinue
            if ($hiveFiles) {
                $hiveFiles | Remove-Item -Force -ErrorAction SilentlyContinue
                $lockCount += $hiveFiles.Count
                Write-Host "  ✓ Removed $($hiveFiles.Count) .hive file(s) from $dir" -ForegroundColor DarkGray
            }
        }
    }
}

# 5) Flutter clean
Write-Host "`n[5/6] Running flutter clean..." -ForegroundColor Yellow
try {
    $cleanOut = flutter clean 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Flutter clean completed" -ForegroundColor DarkGray
    } else {
        Write-Warning "flutter clean exit code: $LASTEXITCODE"
    }
} catch {
    Write-Warning "flutter clean failed: $($_.Exception.Message)"
}

# 6) Optional: who-locks helper with Sysinternals handle.exe
Write-Host "`n[6/6] Checking for diagnostic tools..." -ForegroundColor Yellow
$handleExe = "${env:ProgramFiles(x86)}\Sysinternals\handle.exe"
if (-not (Test-Path $handleExe)) {
    $handleExe = "${env:ProgramFiles}\Sysinternals\handle.exe"
}
if (Test-Path $handleExe) {
    Write-Host "  ℹ Sysinternals handle.exe found" -ForegroundColor DarkGray
    Write-Host "    Usage: & `"$handleExe`" -u -a -nobanner <full\path>" -ForegroundColor DarkGray
} else {
    Write-Host "  ℹ Install Sysinternals Suite for advanced lock detection:" -ForegroundColor DarkGray
    Write-Host "    https://learn.microsoft.com/en-us/sysinternals/downloads/handle" -ForegroundColor DarkGray
}

# Summary
Write-Host "`n==> Unlock Summary" -ForegroundColor Green
Write-Host "  • Processes killed: $killCount" -ForegroundColor White
Write-Host "  • Lock files removed: $lockCount" -ForegroundColor White
Write-Host "  • Flutter clean: completed" -ForegroundColor White
Write-Host "`nWorkspace unlocked! ✓" -ForegroundColor Cyan
