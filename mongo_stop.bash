#!/bin/bash

# Check if required arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <environment.conf> <userdetails.conf>"
    exit 1
fi

ENV_FILE=$1
USERDETAILS_FILE=$2
LOG_DIR="$HOME/log/mongo_cluster_stop"
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
    LOG_FILE="$LOG_DIR/${HOST}_stop.log"
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
    
    # Identify running MongoDB process
    RUNNING_CMD=$(ssh mongouser@$HOST "ps aux | grep mongod | grep -v grep")
    if [ -z "$RUNNING_CMD" ]; then
        echo "No MongoDB service running on $HOST." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        continue
    fi
    
    # Save the start command to mongo_start.sh
    START_CMD=$(echo "$RUNNING_CMD" | awk '{for(i=11;i<=NF;i++) printf $i" "; print ""}')
    echo "$START_CMD" | ssh mongouser@$HOST "cat > ~/mongo_start.sh && chmod +x ~/mongo_start.sh"
    

	# Identify the MongoDB binary path dynamically and strip the executable name
	MONGO_BINARY_PATH=$(ssh mongouser@$HOST "ps -ef | grep '[m]ongod' | awk '{print \$8}' | head -n 1 | xargs dirname")

	# Check if we got a valid path
	if [ -z "$MONGO_BINARY_PATH" ]; then
		echo "Error: MongoDB binary not found on $HOST." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
		FAILED_SERVERS+=("$HOST")
		continue
	fi
    # Check if it's an arbiter node
    IS_ARBITER=$(ssh mongouser@$HOST "$MONGO_BINARY_PATH/mongosh --username $USERNAME --password $PASSWORD --authenticationDatabase admin --port $PORT --eval 'db.isMaster().arbiterOnly' --quiet")
    
    if [ "$IS_ARBITER" == "true" ]; then
        echo "Arbiter node detected on $HOST. Skipping sync check and shutting down directly." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
    else
        #Shuttingdown MongoDB service
        echo "Proceeding MongoDB shutdown on $HOST..." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
    fi
    
    ssh mongouser@$HOST "$MONGO_BINARY_PATH/mongosh --username $USERNAME --password $PASSWORD --authenticationDatabase admin --port $PORT --eval 'db.shutdownServer({force: true})'"
    
    # Verify shutdown
    sleep 5
    if ssh mongouser@$HOST "pgrep -x mongod"; then
        echo "Failed to stop MongoDB on $HOST." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST")
    else
        echo "Successfully stopped MongoDB on $HOST." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
    fi
    
    # Transfer logs to central log file
    cat "$LOG_FILE" >> "$CENTRAL_LOG_FILE"
done

# Check final result
if [ ${#FAILED_SERVERS[@]} -ne 0 ]; then
    echo -e "\n*******************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "MongoDB cluster stop encountered failures on the following servers:" | tee -a "$CENTRAL_LOG_FILE"
	echo -e "\n*******************************" | tee -a "$CENTRAL_LOG_FILE"
    printf '%s\n' "${FAILED_SERVERS[@]}" | tee -a "$CENTRAL_LOG_FILE"
    echo -e "*******************************\n" | tee -a "$CENTRAL_LOG_FILE"
    exit 1
else
    echo -e "\n*******************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "MongoDB cluster stopped successfully." | tee -a "$CENTRAL_LOG_FILE"
    echo -e "*******************************\n" | tee -a "$CENTRAL_LOG_FILE"
    exit 0
fi
