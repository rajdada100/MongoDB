#!/bin/ksh
###############################################################################
# Script to Start MongoDB Services
# Developed By: Raj Dada
#-------------------------------------------------------------------------------
# Script Name   : SC_MONGO_START.sh
# Usage         : SC_MONGO_START.sh <userdetails.conf>
###############################################################################

# Ensure required argument is passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <userdetails.conf>"
    exit 1
fi

USERDETAILS_FILE=$1
LOG_DIR="$HOME/log/mongo_cluster_start"
CENTRAL_LOG_FILE="$HOME/log/central_service_start_log.log"
FAILED_SERVERS=()
ALL_SERVICES_UP=true  # Initialize the variable

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Verify user details file exists
if [ ! -f "$USERDETAILS_FILE" ]; then
    echo "Error: User details file $USERDETAILS_FILE not found."
    exit 1
fi

# Read server details from userdetails.conf
while IFS=' ' read -r HOST USERNAME PASSWORD PORT; do
    # Skip empty lines
    if [ -z "$HOST" ] || [ -z "$PORT" ]; then
        continue
    fi
    
    LOG_FILE="$LOG_DIR/${HOST}_start.log"
    echo -e "\n*******************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "Processing $HOST..." | tee -a "$CENTRAL_LOG_FILE"
    echo -e "*******************************\n" | tee -a "$CENTRAL_LOG_FILE"
    
    # Check if mongo_start.sh exists on the host
    if ssh -q -o BatchMode=yes mongouser@"$HOST" "[ ! -f ~/mongo_start.sh ]"; then
        echo "Error: mongo_start.sh not found on $HOST. Cannot start MongoDB." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST")
        ALL_SERVICES_UP=false  # Mark failure
        continue
    fi
    
    # Start MongoDB service using saved start command
    echo -e "\n*******************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "Starting Mongo services on $HOST..." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
    echo -e "*******************************\n" | tee -a "$CENTRAL_LOG_FILE"
    
    ssh -q -o BatchMode=yes mongouser@"$HOST" "bash ~/mongo_start.sh"
    
    # Verify if MongoDB service has started successfully
    sleep 5
    PORT_CHECK=$(ssh -q mongouser@"$HOST" "ss -tulnp | grep -w '$PORT'")

    if [[ -z "$PORT_CHECK" ]]; then
        echo "Failed to start MongoDB on $HOST." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST")
        ALL_SERVICES_UP=false  # Mark failure
    else
        echo "Successfully started MongoDB on $HOST." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
    fi

    # Append logs to central log file
    cat "$LOG_FILE" >> "$CENTRAL_LOG_FILE"

done < "$USERDETAILS_FILE"  # This correctly closes the loop

# Check final status
if [ "$ALL_SERVICES_UP" = true ]; then
    echo -e "\n*******************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "MongoDB cluster started successfully." | tee -a "$CENTRAL_LOG_FILE"
    echo -e "*******************************\n" | tee -a "$CENTRAL_LOG_FILE"
    exit 0
else
    echo -e "\n*******************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "MongoDB cluster start encountered failures." | tee -a "$CENTRAL_LOG_FILE"
    echo -e "*******************************\n" | tee -a "$CENTRAL_LOG_FILE"
    exit 1
fi
