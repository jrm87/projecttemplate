#!/bin/bash
# sync_from_cluster.sh — Download task outputs from DCC or TACC
#
# Usage:
#   ./sync_from_cluster.sh --tacc <task_name>       # sync output/ from TACC
#   ./sync_from_cluster.sh --dcc <task_name>        # sync output/ from DCC
#   ./sync_from_cluster.sh --hand <task_name>       # sync hand/ instead
#   ./sync_from_cluster.sh --both <task_name>       # sync output/ + hand/
#   ./sync_from_cluster.sh --list --tacc            # list tasks with output/ on TACC
#   ./sync_from_cluster.sh --dry-run <task_name>    # preview transfer
#
# After syncing, run `make` for downstream tasks to recreate local symlinks.
#
# Prerequisites:
#   Add SSH multiplexing to ~/.ssh/config:
#
#     Host ls6.tacc.utexas.edu
#       ControlMaster auto
#       ControlPath ~/.ssh/sockets/%r@%h-%p
#       ControlPersist 2h
#
#     Host dcc-login.oit.duke.edu
#       ControlMaster auto
#       ControlPath ~/.ssh/sockets/%r@%h-%p
#       ControlPersist 2h
#
#   Then: mkdir -p ~/.ssh/sockets

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
# CUSTOMIZE: Set these for your project

# TACC settings
TACC_HOST="${TACC_HOST:-ls6.tacc.utexas.edu}"
TACC_REMOTE_USER="${TACC_REMOTE_USER:-$(whoami)}"
TACC_PROJECT="${TACC_PROJECT:-00000}"
TACC_REPO_PATH="${TACC_REPO_PATH:-/work/${TACC_PROJECT}/${TACC_REMOTE_USER}/ls6/$(basename $(pwd))}"

# DCC settings
DCC_HOST="${DCC_HOST:-dcc-login.oit.duke.edu}"
DCC_REMOTE_USER="${DCC_REMOTE_USER:-$(whoami)}"
DCC_REPO_PATH="${DCC_REPO_PATH:-/hpc/group/econ/${DCC_REMOTE_USER}/$(basename $(pwd))}"

# Local repo root
LOCAL_REPO="$(cd "$(dirname "$0")" && pwd)"

# ── Helpers ──────────────────────────────────────────────────────────────────

usage() {
    sed -n '2,/^$/s/^# //p' "$0"
    exit 1
}

sync_dir() {
    local task="$1"
    local dir_type="$2"
    local dry_run="${3:-false}"
    local host="$4"
    local repo_path="$5"

    local remote_path="${host}:${repo_path}/tasks/${task}/${dir_type}/"
    local local_path="${LOCAL_REPO}/tasks/${task}/${dir_type}/"

    # Check remote exists
    if ! ssh "${host}" "test -d '${repo_path}/tasks/${task}/${dir_type}'" 2>/dev/null; then
        echo "  SKIP: ${dir_type}/ does not exist on remote for task '${task}'"
        return 0
    fi

    # Show remote info
    echo ""
    echo "  Remote ${dir_type}/ info:"
    ssh "${host}" "
        dir='${repo_path}/tasks/${task}/${dir_type}'
        echo \"    Files: \$(find \"\$dir\" -type f | wc -l | tr -d ' ')\"
        echo \"    Size:  \$(du -sh \"\$dir\" 2>/dev/null | cut -f1)\"
    " 2>/dev/null || echo "    (could not read remote info)"

    if [[ "$dry_run" == "true" ]]; then
        echo ""
        echo "  DRY RUN — would sync:"
        rsync -avzn "${remote_path}" "${local_path}" 2>/dev/null | tail -5
        return 0
    fi

    # Create local dir and sync
    mkdir -p "$local_path"
    echo ""
    echo "  Syncing ${dir_type}/..."
    rsync -avz --progress "${remote_path}" "${local_path}"
    echo "  Done: ${local_path}"
}

list_remote_tasks() {
    local host="$1"
    local repo_path="$2"
    local cluster_name="$3"

    echo "Tasks with output/ on ${cluster_name} (${host}):"
    echo ""
    ssh "${host}" "
        for d in ${repo_path}/tasks/*/output; do
            if [ -d \"\$d\" ]; then
                task=\$(basename \$(dirname \"\$d\"))
                size=\$(du -sh \"\$d\" 2>/dev/null | cut -f1)
                printf '  %-40s %s\n' \"\$task\" \"\$size\"
            fi
        done
    " 2>/dev/null
}

# ── Parse arguments ──────────────────────────────────────────────────────────

CLUSTER=""
MODE="output"
DRY_RUN="false"
TASKS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tacc)     CLUSTER="tacc";   shift ;;
        --dcc)      CLUSTER="dcc";    shift ;;
        --hand)     MODE="hand";      shift ;;
        --both)     MODE="both";      shift ;;
        --output)   MODE="output";    shift ;;
        --dry-run)  DRY_RUN="true";   shift ;;
        --list)
            shift
            # Need cluster flag
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --tacc) list_remote_tasks "$TACC_HOST" "$TACC_REPO_PATH" "TACC"; exit 0 ;;
                    --dcc)  list_remote_tasks "$DCC_HOST" "$DCC_REPO_PATH" "DCC"; exit 0 ;;
                    *) shift ;;
                esac
            done
            echo "Error: --list requires --tacc or --dcc"
            exit 1
            ;;
        --help|-h)  usage ;;
        -*)         echo "Unknown option: $1"; usage ;;
        *)          TASKS+=("$1"); shift ;;
    esac
done

if [[ -z "$CLUSTER" ]]; then
    echo "Error: specify --tacc or --dcc"
    usage
fi

if [[ ${#TASKS[@]} -eq 0 ]]; then
    echo "Error: no task name(s) provided."
    usage
fi

# Set host and path based on cluster
if [[ "$CLUSTER" == "tacc" ]]; then
    HOST="$TACC_HOST"
    REPO_PATH="$TACC_REPO_PATH"
else
    HOST="$DCC_HOST"
    REPO_PATH="$DCC_REPO_PATH"
fi

# ── Main ─────────────────────────────────────────────────────────────────────

for task in "${TASKS[@]}"; do
    echo ""
    echo "━━━ ${task} (${CLUSTER^^}) ━━━"

    case "$MODE" in
        output) sync_dir "$task" "output" "$DRY_RUN" "$HOST" "$REPO_PATH" ;;
        hand)   sync_dir "$task" "hand" "$DRY_RUN" "$HOST" "$REPO_PATH" ;;
        both)
            sync_dir "$task" "output" "$DRY_RUN" "$HOST" "$REPO_PATH"
            sync_dir "$task" "hand" "$DRY_RUN" "$HOST" "$REPO_PATH"
            ;;
    esac
done

echo ""
echo "━━━ Next steps ━━━"
echo ""
echo "Run 'make' for downstream tasks to recreate input/ symlinks:"
for task in "${TASKS[@]}"; do
    echo "  make -C tasks/<downstream_task>"
done
