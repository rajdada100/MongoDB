#!/bin/bash

# Check if required arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <environment.conf> <userdetails.conf>"
    exit 1
fi

ENV_FILE=$1
USERDETAILS_FILE=$2
LOG_DIR="$HOME/log/mongo_cluster_start"
CENTRAL_LOG_FILE="$HOME/central_log.log"
FAILED_SERVERS=()

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Read environment file for hostnames
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: Parameter file $ENV_FILE not found."
    exit 1
fi

# Read hostnames properly without HOSTNAMES=
HOSTNAMES=$(cat "$ENV_FILE" | tr -d '[:space:]')  # Remove spaces and newlines
IFS=',' read -r -a HOSTS <<< "$HOSTNAMES"

# Process each server
for HOST in "${HOSTS[@]}"; do
    HOST=$(echo "$HOST" | tr -d '"')  # Remove unwanted quotes
    LOG_FILE="$LOG_DIR/${HOST}_start.log"
    echo -e "\n*******************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "Processing $HOST..." | tee -a "$CENTRAL_LOG_FILE"
    echo -e "*******************************\n" | tee -a "$CENTRAL_LOG_FILE"
    
    # Extract credentials from userdetails.conf
    if [ ! -f "$USERDETAILS_FILE" ]; then
        echo "Error: User details file $USERDETAILS_FILE not found." | tee -a "$CENTRAL_LOG_FILE"
        exit 1
    fi
    
    CREDENTIALS=$(grep -w "^$HOST" "$USERDETAILS_FILE")
    USERNAME=$(echo "$CREDENTIALS" | awk '{print $2}')
    PASSWORD=$(echo "$CREDENTIALS" | awk '{print $3}')
    PORT=$(echo "$CREDENTIALS" | awk '{print $4}')
    
    if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$PORT" ]; then
        echo "Error: Missing credentials for $HOST. Check $USERDETAILS_FILE." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST")
        continue
    fi
    
    # Check if mongo_start.sh exists for the host
    if ssh mongouser@$HOST "[ ! -f ~/mongo_start.sh ]"; then
        echo "Error: mongo_start.sh not found on $HOST. Cannot start MongoDB." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST")
        continue
    fi
    
    # Start the MongoDB service using the saved start command
    echo "Starting MongoDB on $HOST..." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
    ssh mongouser@$HOST "bash ~/mongo_start.sh"
    
    # Verify if the MongoDB service has started successfully
    sleep 5
    if ! ssh mongouser@$HOST "pgrep -x mongod"; then
        echo "Failed to start MongoDB on $HOST." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST")
    else
        echo "Successfully started MongoDB on $HOST." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
    fi
    
    # Transfer logs to central log file
    cat "$LOG_FILE" >> "$CENTRAL_LOG_FILE"
done

# Check final result
if [ ${#FAILED_SERVERS[@]} -ne 0 ]; then
    echo -e "\n*******************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "MongoDB cluster start encountered failures on the following servers:" | tee -a "$CENTRAL_LOG_FILE"
    echo -e "\n*******************************" | tee -a "$CENTRAL_LOG_FILE"
    printf '%s\n' "${FAILED_SERVERS[@]}" | tee -a "$CENTRAL_LOG_FILE"
    echo -e "*******************************\n" | tee -a "$CENTRAL_LOG_FILE"
    exit 1
else
    echo -e "\n*******************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "MongoDB cluster started successfully." | tee -a "$CENTRAL_LOG_FILE"
    echo -e "*******************************\n" | tee -a "$CENTRAL_LOG_FILE"
    exit 0
fi
