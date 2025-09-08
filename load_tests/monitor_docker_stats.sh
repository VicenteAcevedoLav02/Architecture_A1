#!/bin/bash

OUTPUT_CSV="$1"
OUTPUT_CSV="$(realpath "$OUTPUT_CSV")"

echo "timestamp,container,cpu_percent,memory_usage,memory_limit,memory_percent,pids" > "$OUTPUT_CSV"

while true; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    docker stats --no-stream --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.PIDs}}" | while IFS=$'\t' read -r name cpu mem memperc pids; do   
        cpu_clean=$(echo "$cpu" | tr -d '%')
        memperc_clean=$(echo "$memperc" | tr -d '%')
        
        mem_usage=$(echo "$mem" | awk -F' / ' '{print $1}' | sed 's/MiB//;s/GiB//;s/MB//;s/GB//')
        mem_limit=$(echo "$mem" | awk -F' / ' '{print $2}' | sed 's/MiB//;s/GiB//;s/MB//;s/GB//')
        
        echo "$timestamp,$name,$cpu_clean,$mem_usage,$mem_limit,$memperc_clean,$pids" >> "$OUTPUT_CSV"
    done

    sleep 5
done
