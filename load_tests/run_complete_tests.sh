#!/bin/bash
set -e

CONFIG=${1:-basic_setup}
RESULTS_DIR="$(pwd)/load_tests/results/$CONFIG"
mkdir -p "$RESULTS_DIR"

calculate_users() {
    local target=$1
    local users=$((target / (5*4)))
    [ $users -lt 1 ] && users=1
    echo $users
}

for requests in 1 10 100 1000 5000; do
    users=$(calculate_users $requests)
    TEST_DIR="$RESULTS_DIR/test_${requests}_users"
    mkdir -p "$TEST_DIR"

    echo "Runnig test: $requests requests -> $users users"

    STATS_CSV="$TEST_DIR/docker_stats.csv"

    ./load_tests/monitor_docker_stats.sh "$STATS_CSV" &
    stats_pid=$!

    docker run --rm \
        --network host \
        -v "$(pwd)/load_tests:/load_tests" \
        justb4/jmeter:latest \
        -n \
        -t "/load_tests/load_test.jmx" \
        -l "/load_tests/results/$CONFIG/test_${requests}_users/jmeter.jtl" \
        -Jusers=$users \
        -Jtestname="test_${requests}_users" \
        -Jsummariser.interval=10 \
        -Jsummariser.out=true | stdbuf -oL tee "$TEST_DIR/jmeter.log"

    kill $stats_pid 2>/dev/null || true

    echo "Test $requests completed."
    echo ""
done

echo "Load testing finished. Results directory: $RESULTS_DIR"
