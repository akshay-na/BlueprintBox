#!/bin/bash

# Script Name: my_script.sh
# Description: Enhances robustness, captures formatted execution time, logs command output, and safely navigates directories.

# This sets the shell to fail if any subcommand fails (errexit),
# and stops the script if a command fails in a pipeline (pipefail).
set -eo pipefail

# Push the original directory onto the stack to ensure we can return here
pushd "$(pwd)" >/dev/null

# Dynamically determine the script name and use it for logs and other purposes.
SCRIPT_NAME=$(basename "$0" .sh)

# Configuration for directories
TEMP_DIR="./tmp/${SCRIPT_NAME}"
LOG_DIR="./log"
START_TIME=$(date +%s) # Record the start time of the script.

# Create a dynamic log file name with the date and time to ensure it's unique for each run.
LOG_FILE="./log/${SCRIPT_NAME}_$(date +"%Y-%m-%d_%H-%M-%S").log"

# Load environment variables from a .env file if it exists
if [ -f ".env" ]; then
  echo "Loading environment variables from .env file..."
  set -o allexport # Automatically export all variables
  source ".env"
  set +o allexport # Turn off auto export
fi

# This function adds a timestamp to every log message and writes it to both the console and the log file.
log() {
  local message="$1"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" | tee -a "$LOG_FILE"
}

# Function to execute commands, log their output, and display it on the terminal.
execute_and_log() {
  local command="$1"
  echo "Executing command: $command"
  # Runs the command, logs its output, and checks for errors.
  eval $command 2>&1 | tee -a "$LOG_FILE"
  local status=${PIPESTATUS[0]}
  if [[ $status -ne 0 ]]; then
    log "Command failed with status $status: $command"
    exit $status
  fi
}

# Checks and prepares necessary directories for the script's operation.
check_directories() {
  execute_and_log "mkdir -p $TEMP_DIR"
  execute_and_log "mkdir -p $LOG_DIR"
}

# Calculates and logs the execution time in a human-readable format.
calculate_execution_time() {
  local end_time=$(date +%s)
  local execution_time=$((end_time - START_TIME))
  local hours=$((execution_time / 3600))
  local minutes=$(((execution_time % 3600) / 60))
  local seconds=$((execution_time % 60))
  log "Execution time: { hours: $hours, minutes: $minutes, seconds: $seconds }"
}

# Logs the script's CPU and memory usage in a readable format.
monitor_resources() {
  local resource_usage=$(ps -o %cpu,%mem,cmd -p $$ | tail -n 1)
  local cpu=$(echo $resource_usage | awk '{print $1}')
  local mem=$(echo $resource_usage | awk '{print $2}')
  local cmd=$(echo $resource_usage | awk '{$1=$2=""; print $0}' | sed 's/^\s*//')
  log "Resource usage: CPU: $cpu%, Memory: $mem%, Command: $cmd"
}

# Handles errors by logging the line number and the error message.
error_handler() {
  local lineno="$1"
  local msg="$2"
  log "ERROR at line $lineno: $msg"
  popd >/dev/null
  exit 1
}

# Main function where the script's logic is executed.
main() {
  log "Starting script execution..."
  check_directories
  # Example command to list contents of TEMP_DIR.
  execute_and_log "ls -lah $TEMP_DIR"
  log "Script execution completed successfully."
  popd >/dev/null
}

# Setup traps for error handling and cleanup.
trap 'error_handler ${LINENO} "$BASH_COMMAND"' ERR
trap 'calculate_execution_time; monitor_resources; exit 0' EXIT

# Start the main function to execute the script.
main
