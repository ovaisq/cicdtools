#!/usr/bin/env bash
# load/update LLMs on all your LLMs servers - assumes
# local ollama server

llm='granite-code'

# remote linux hosts
hosts=(ollama_server1 ollama_server2)

# remote macos hosts
remote_host=<hostname or ip add>

# Function to handle Linux hosts
process_host() {
    local host=$1
    if ssh $host "ping -c 1 $host &> /dev/null"; then
        echo "ssh $host ollama rm ${llm}"
        ssh $host "ollama rm ${llm}"

        if ssh $host "ollama list | grep ^${llm}:latest"; then
            echo "ssh $host ollama pull ${llm}"
            ssh $host "ollama pull ${llm}"
        else
            echo "${llm} is not available on $host"
            echo "ssh $host ollama pull ${llm}"
            ssh $host "ollama pull ${llm}"
        fi
    else
        echo "$host is not reachable"
    fi
}

# Process Linux hosts in parallel
for host in "${hosts[@]}"; do
    process_host $host &
done

# Function to handle macOS remote host
process_remote_host() {
    if ping -c 1 $remote_host &> /dev/null; then
        if ssh $remote_host "/opt/homebrew/bin/ollama list | grep ^${llm}:latest"; then
            echo "ssh $remote_host /opt/homebrew/bin/ollama rm ${llm}"
            ssh $remote_host "/opt/homebrew/bin/ollama rm ${llm}"

            echo "ssh $remote_host /opt/homebrew/bin/ollama pull ${llm}"
            ssh $remote_host "/opt/homebrew/bin/ollama pull ${llm}"
        else
            echo "${llm} is not available on $remote_host"
            echo "ssh $remote_host /opt/homebrew/bin/ollama pull ${llm}"
            ssh $remote_host "/opt/homebrew/bin/ollama pull ${llm}"
        fi
    else
        echo "$remote_host is not reachable"
    fi
}

# Process remote macOS host in parallel
process_remote_host &

# Function to handle local macOS host
process_local_host() {
    if ollama list | grep ^${llm}:latest; then
        echo "ollama rm ${llm}"
        ollama rm ${llm}

        echo "ollama pull ${llm}"
        ollama pull ${llm}
    else
        echo "${llm} is not available on the local machine"
        echo "ollama pull ${llm}"
        ollama pull ${llm}
    fi
}

# Process local macOS host in parallel
process_local_host &

# Wait for all background processes to finish
wait

echo "All processes completed."

