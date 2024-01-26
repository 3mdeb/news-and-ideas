#!/bin/bash

# Check for the required parameters
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <user@remote-host> <local-src-dir>"
    exit 1
fi

# Function to clean up background processes when the script exits
cleanup() {
    echo "Cleaning up..."
    # Kill the inotifywait background process
    kill $INOTIFY_PID
}

# Set trap to call cleanup function when the script exits
trap cleanup exit

REMOTE_USER_HOST="$1"
LOCAL_SRC_DIR="$2"   # Local source directory provided as the second parameter
REMOTE_SRC_DIR="/tmp/3mdeb-website"
DOCKER_IMAGE="klakegg/hugo:0.105.0-ext-alpine"
DOCKER_PORT="1313"
REMOTE_HOST=$(echo $REMOTE_USER_HOST | cut -d '@' -f2)

# Set DOCKER_HOST environment variable
export DOCKER_HOST="tcp://$REMOTE_HOST:2375"

# Function to continuously sync local directory with remote directory
start_sync() {
    ssh $REMOTE_USER_HOST "rm -rf $REMOTE_SRC_DIR"
    rsync -avz --exclude='.git/' $LOCAL_SRC_DIR $REMOTE_USER_HOST:$REMOTE_SRC_DIR
    inotifywait -m -r -e modify,create,delete --exclude '^\.git/' --format '%w%f' $LOCAL_SRC_DIR | while read file
    do
        # Check if the changed file is not inside .git directory
        if [[ $file != *".git"* ]]; then
            rsync -avz --exclude='.git/' $LOCAL_SRC_DIR $REMOTE_USER_HOST:$REMOTE_SRC_DIR
        fi
    done &
    INOTIFY_PID=$!
}

# Function to run Docker container on remote host
run_docker_container() {
    docker run --rm -it -v $REMOTE_SRC_DIR:/src -p $DOCKER_PORT:$DOCKER_PORT -u $(id -u) $DOCKER_IMAGE serve -b $REMOTE_HOST
}

#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
if ! command_exists rsync; then
    echo "rsync is not installed. Please install it."
    exit 1
fi

if ! command_exists inotifywait; then
    echo "inotify-tools is not installed. Please install it."
    exit 1
fi

# Start continuous synchronization in the background
start_sync

# Run Docker container
run_docker_container

# After the Docker container exits, kill the background sync process
kill $!
