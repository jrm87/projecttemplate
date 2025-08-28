#!/bin/bash
# Script to generate a dependency graph from task symlink-creation scripts

output_file="../output/graph.txt"
temp_edges=$(mktemp)

echo 'digraph G {' > "$output_file"

# Look for Makefile dependencies that follow the pattern: 
#   input/...: ../<src_task>/output/...
find ../../* -maxdepth 2 -type f -name "Makefile" | while read -r makefile; do
    # For each Makefile, look for lines matching the pattern "input.*:.*output"
    grep -o 'input.*:.*output' "$makefile" | while read -r dep_line; do
        # dep_line example:
        # input/texts/meta/%: ../text_for_embedding/output/texts/meta/% | input/texts/meta
        if [[ $dep_line =~ :[[:space:]]*\.\./([^/]+)/output ]]; then
            src_task="${BASH_REMATCH[1]}"
        else
            continue
        fi
        # Determine the current (target) task from the Makefile location.
        # Remove the leading ../../ and any trailing /code.
        task=$(dirname "$makefile" | sed 's|\.\./\.\./||' | sed 's/\/code$//')
        # Write the edge to the temporary file.
        echo "\"$src_task\" -> \"$task\"" >> "$temp_edges"
    done
done

# Deduplicate the edges and append to the output file.
sort -u "$temp_edges" >> "$output_file"

echo '}' >> "$output_file"

rm "$temp_edges"