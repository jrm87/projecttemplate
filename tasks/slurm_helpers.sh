#!/bin/bash
# SLURM Job Dependency Management Helper Script
#
# This script provides utilities for managing SLURM job dependencies
# to ensure efficient resource utilization and proper task ordering.
#
# Usage:
#   source slurm_helpers.sh
#   job_id=$(submit_slurm_job "path/to/job.slurm" "dep_id1:dep_id2")
#   wait_for_jobs "job_id1:job_id2:job_id3"

# Submit a SLURM job with optional dependencies
# Arguments:
#   $1: Path to the SLURM script
#   $2: (Optional) Colon-separated list of job IDs to depend on
#   $3+: (Optional) Additional sbatch arguments
# Returns: Job ID of the submitted job
submit_slurm_job() {
    local slurm_script="$1"
    local dependency_ids="$2"
    shift 2
    local extra_args="$@"

    if [ ! -f "$slurm_script" ]; then
        echo "ERROR: SLURM script not found: $slurm_script" >&2
        return 1
    fi

    local sbatch_cmd="sbatch"

    # Add dependency if provided
    if [ -n "$dependency_ids" ]; then
        local clean_ids=$(echo "$dependency_ids" | tr ':' '\n' | grep -v '^$' | tr '\n' ':' | sed 's/:$//')
        if [ -n "$clean_ids" ]; then
            sbatch_cmd="$sbatch_cmd --dependency=afterok:$clean_ids"
        fi
    fi

    # Add any extra arguments
    if [ -n "$extra_args" ]; then
        sbatch_cmd="$sbatch_cmd $extra_args"
    fi

    sbatch_cmd="$sbatch_cmd $slurm_script"

    # Submit job and extract job ID
    local output=$($sbatch_cmd 2>&1)
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        echo "ERROR: Failed to submit job: $output" >&2
        return 1
    fi

    # Extract job ID (handles TACC banner noise)
    local job_id=$(echo "$output" | grep "Submitted batch job" | grep -oE '[0-9]+' | head -1)

    if [ -z "$job_id" ]; then
        echo "ERROR: Could not extract job ID from output: $output" >&2
        return 1
    fi

    echo "$job_id"
    return 0
}

# Submit a SLURM array job with optional dependencies
# Arguments:
#   $1: Path to the SLURM script
#   $2: Array specification (e.g., "0-10%3")
#   $3: (Optional) Colon-separated list of dependency job IDs
#   $4+: (Optional) Additional sbatch arguments
submit_slurm_array_job() {
    local slurm_script="$1"
    local array_spec="$2"
    local dependency_ids="$3"
    shift 3
    local extra_args="$@"

    if [ ! -f "$slurm_script" ]; then
        echo "ERROR: SLURM script not found: $slurm_script" >&2
        return 1
    fi

    submit_slurm_job "$slurm_script" "$dependency_ids" "--array=$array_spec" $extra_args
}

# Wait for one or more SLURM jobs to complete
# Arguments:
#   $1: Colon-separated list of job IDs
#   $2: (Optional) Timeout in seconds (default: 86400 = 24 hours)
# Returns: 0 if all jobs completed successfully, 1 otherwise
wait_for_jobs() {
    local job_ids="$1"
    local timeout="${2:-86400}"

    if [ -z "$job_ids" ]; then
        echo "ERROR: No job IDs provided" >&2
        return 1
    fi

    IFS=':' read -ra job_array <<< "$job_ids"

    local start_time=$(date +%s)
    local all_complete=false

    echo "Waiting for jobs to complete: ${job_array[*]}"

    while [ "$all_complete" = false ]; do
        all_complete=true

        for job_id in "${job_array[@]}"; do
            [ -z "$job_id" ] && continue
            if squeue -j "$job_id" &>/dev/null; then
                all_complete=false
                break
            fi
        done

        if [ "$all_complete" = false ]; then
            local current_time=$(date +%s)
            local elapsed=$((current_time - start_time))

            if [ $elapsed -ge $timeout ]; then
                echo "ERROR: Timeout reached after $elapsed seconds" >&2
                return 1
            fi

            echo "Jobs still running... (waited $elapsed seconds)"
            sleep 30
        fi
    done

    echo "All jobs completed"
    return 0
}

# Check if a job completed successfully
# Arguments: $1 = Job ID
# Returns: 0 if COMPLETED, 1 otherwise
check_job_success() {
    local job_id="$1"

    if [ -z "$job_id" ]; then
        echo "ERROR: No job ID provided" >&2
        return 1
    fi

    local job_state=$(sacct -j "$job_id" --format=State --noheader | head -n 1 | tr -d ' ')

    if [ "$job_state" = "COMPLETED" ]; then
        return 0
    else
        echo "WARNING: Job $job_id finished with state: $job_state" >&2
        return 1
    fi
}

# Save job ID to a file
save_job_id() {
    local job_id="$1"
    local file_path="$2"

    if [ -z "$job_id" ] || [ -z "$file_path" ]; then
        echo "ERROR: Job ID and file path required" >&2
        return 1
    fi

    echo "$job_id" > "$file_path"
    echo "Saved job ID $job_id to $file_path"
}

# Read job ID from a file
read_job_id() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        echo "ERROR: Job ID file not found: $file_path" >&2
        return 1
    fi

    cat "$file_path"
}

# Submit multiple jobs as a sequential chain
# Arguments: slurm script paths (as "$@")
# Returns: Colon-separated list of all job IDs
submit_job_chain() {
    local job_ids=""
    local prev_job_id=""

    for slurm_script in "$@"; do
        local job_id=$(submit_slurm_job "$slurm_script" "$prev_job_id")
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to submit job in chain: $slurm_script" >&2
            return 1
        fi

        if [ -n "$job_ids" ]; then
            job_ids="$job_ids:$job_id"
        else
            job_ids="$job_id"
        fi

        prev_job_id="$job_id"
        echo "Submitted job $job_id (depends on: ${prev_job_id:-none})" >&2
    done

    echo "$job_ids"
}

# Cancel jobs by ID
# Arguments: $1 = Colon-separated list of job IDs
cancel_jobs() {
    local job_ids="$1"

    if [ -z "$job_ids" ]; then
        echo "ERROR: No job IDs provided" >&2
        return 1
    fi

    IFS=':' read -ra job_array <<< "$job_ids"

    for job_id in "${job_array[@]}"; do
        [ -z "$job_id" ] && continue
        echo "Canceling job $job_id"
        scancel "$job_id"
    done
}

# Export functions for child processes
export -f submit_slurm_job
export -f submit_slurm_array_job
export -f wait_for_jobs
export -f check_job_success
export -f save_job_id
export -f read_job_id
export -f submit_job_chain
export -f cancel_jobs
