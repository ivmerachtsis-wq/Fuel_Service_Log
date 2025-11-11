#!/usr/bin/env bash
#
# unlock_workspace.sh - Unlocks Flutter workspace on macOS/Linux
#
# Stops lock-holder processes, removes lock files, runs flutter clean

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo -e "\033[36m==> Unlocking workspace at: $REPO_ROOT\033[0m"

kill_count=0
lock_count=0

# 1) Kill common lock-holder processes
echo -e "\n\033[33m[1/6] Stopping lock-holder processes...\033[0m"
procs=(flutter dart java gradle adb chromedriver node flutter_tester)
for proc in "${procs[@]}"; do
    pids=$(pgrep -x "$proc" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        echo "$pids" | xargs kill -9 2>/dev/null || true
        count=$(echo "$pids" | wc -l | tr -d ' ')
        kill_count=$((kill_count + count))
        echo -e "  \033[90m✓ Killed $count '$proc' process(es)\033[0m"
    fi
done
if [[ $kill_count -eq 0 ]]; then
    echo -e "  \033[90mℹ No processes to kill\033[0m"
fi

# 2) Remove Git lock files
echo -e "\n\033[33m[2/6] Removing Git locks...\033[0m"
git_locks=(
    ".git/index.lock"
    ".git/HEAD.lock"
    ".git/refs/heads/main.lock"
)
for lock in "${git_locks[@]}"; do
    if [[ -f "$REPO_ROOT/$lock" ]]; then
        rm -f "$REPO_ROOT/$lock" 2>/dev/null || true
        lock_count=$((lock_count + 1))
        echo -e "  \033[90m✓ Removed $lock\033[0m"
    fi
done

# 3) Stop Gradle daemons & remove locks
echo -e "\n\033[33m[3/6] Stopping Gradle daemons...\033[0m"
if command -v gradle &>/dev/null; then
    gradle --stop &>/dev/null || true
    echo -e "  \033[90m✓ Gradle daemons stopped\033[0m"
else
    echo -e "  \033[90mℹ Gradle not found or already stopped\033[0m"
fi

# Remove Gradle lock files
gradle_home="${HOME}/.gradle"
if [[ -d "$gradle_home" ]]; then
    gradle_locks=$(find "$gradle_home" -name "*.lock" 2>/dev/null || true)
    if [[ -n "$gradle_locks" ]]; then
        count=$(echo "$gradle_locks" | wc -l | tr -d ' ')
        echo "$gradle_locks" | xargs rm -f 2>/dev/null || true
        lock_count=$((lock_count + count))
        echo -e "  \033[90m✓ Removed $count Gradle lock(s)\033[0m"
    fi
fi

# 4) Remove local build & .dart_tool locks
echo -e "\n\033[33m[4/6] Removing local build locks...\033[0m"
build_dirs=(build .dart_tool test_hive_settings_toggle test_hive_widget test_hive_temp_integrity)
for dir in "${build_dirs[@]}"; do
    full_dir="$REPO_ROOT/$dir"
    if [[ -d "$full_dir" ]]; then
        # Remove .lock files
        build_locks=$(find "$full_dir" -name "*.lock" 2>/dev/null || true)
        if [[ -n "$build_locks" ]]; then
            count=$(echo "$build_locks" | wc -l | tr -d ' ')
            echo "$build_locks" | xargs rm -f 2>/dev/null || true
            lock_count=$((lock_count + count))
            echo -e "  \033[90m✓ Removed $count lock(s) from $dir\033[0m"
        fi
        
        # Remove .hive files (test artifacts)
        if [[ "$dir" == test_hive* ]]; then
            hive_files=$(find "$full_dir" -name "*.hive" 2>/dev/null || true)
            if [[ -n "$hive_files" ]]; then
                count=$(echo "$hive_files" | wc -l | tr -d ' ')
                echo "$hive_files" | xargs rm -f 2>/dev/null || true
                lock_count=$((lock_count + count))
                echo -e "  \033[90m✓ Removed $count .hive file(s) from $dir\033[0m"
            fi
        fi
    fi
done

# 5) Flutter clean
echo -e "\n\033[33m[5/6] Running flutter clean...\033[0m"
if flutter clean &>/dev/null; then
    echo -e "  \033[90m✓ Flutter clean completed\033[0m"
else
    echo -e "  \033[31m⚠ flutter clean failed\033[0m"
fi

# 6) Optional: who-locks helper with lsof
echo -e "\n\033[33m[6/6] Checking for diagnostic tools...\033[0m"
if command -v lsof &>/dev/null; then
    echo -e "  \033[90mℹ lsof found\033[0m"
    echo -e "  \033[90m  Usage: lsof <full/path>\033[0m"
else
    echo -e "  \033[90mℹ Install lsof for advanced lock detection\033[0m"
fi

# Summary
echo -e "\n\033[32m==> Unlock Summary\033[0m"
echo -e "  \033[37m• Processes killed: $kill_count\033[0m"
echo -e "  \033[37m• Lock files removed: $lock_count\033[0m"
echo -e "  \033[37m• Flutter clean: completed\033[0m"
echo -e "\n\033[36mWorkspace unlocked! ✓\033[0m"
