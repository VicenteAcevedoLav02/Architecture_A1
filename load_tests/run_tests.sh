#!/bin/bash
set -e

CONFIG=${1:-basic_setup}
RESULTS_DIR="$(pwd)/load_tests/results/$CONFIG"
mkdir -p "$RESULTS_DIR"

calculate_test_params() {
    local target_requests=$1
    
    users=$target_requests
    loops=1
    
    echo "$users $loops"
}

for requests in 1 10 100 1000 5000; do
    params=($(calculate_test_params $requests))
    users=${params[0]}
    loops=${params[1]}
    
    TEST_DIR="$RESULTS_DIR/test_${requests}_requests"
    mkdir -p "$TEST_DIR"

    echo "Running test: $requests requests -> $users users, $loops loops"

    STATS_CSV="$TEST_DIR/docker_stats.csv"

    ./load_tests/monitor_docker_stats.sh "$STATS_CSV" &
    stats_pid=$!

    docker run --rm \
        --network host \
        -v "$(pwd)/load_tests:/load_tests" \
        justb4/jmeter:latest \
        -n \
        -t "/load_tests/load_test.jmx" \
        -l "/load_tests/results/$CONFIG/test_${requests}_requests/jmeter.jtl" \
        -Jusers=$users \
        -Jloops=$loops \
        -Jtestname="test_${requests}_requests" \
        -Jsummariser.interval=10 \
        -Jsummariser.out=true | stdbuf -oL tee "$TEST_DIR/jmeter.log"

    kill $stats_pid 2>/dev/null || true

    echo "Test $requests completed."
    echo "Expected requests: $requests, Users: $users, Loops: $loops"
    echo ""
done

echo "Load testing finished. Results directory: $RESULTS_DIR"