#!/bin/bash

OUTPUT_CSV="$1"
OUTPUT_CSV="$(realpath "$OUTPUT_CSV")"

echo "timestamp,container,cpu_percent,memory_usage,memory_limit,memory_percent,net_io,block_io,pids" > "$OUTPUT_CSV"

while true; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    while IFS= read -r line; do
        clean=$(echo "$line" | sed 's/%//g;s/MiB//g;s/GiB//g;s/MB//g;s/GB//g;s/\s\+/,/g')
        echo "$timestamp,$clean" >> "$OUTPUT_CSV"
    done < <(docker stats --no-stream --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}\t{{.PIDs}}")
    
    sleep 10
done
