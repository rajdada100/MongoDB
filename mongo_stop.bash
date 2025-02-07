#!/bin/bash


# Check if required argument is passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <userdetails.conf>"
    exit 1
fi

USERDETAILS_FILE=$1
LOG_DIR="$HOME/log/mongo_cluster_stop"
CENTRAL_LOG_FILE="$HOME/log/central_log.log"
FAILED_SERVERS=()

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Verify user details file exists
if [ ! -f "$USERDETAILS_FILE" ]; then
    echo "Error: User details file $USERDETAILS_FILE not found."
    exit 1
fi

# Set IFS to newline to process each line correctly
IFS=$'\n'

# Process each line in the user details file
for cred_line in $(cat "$USERDETAILS_FILE"); do
    # Skip empty lines
    if [ -z "$cred_line" ]; then
        continue
    fi

    # Extract values
    HOST=$(echo "$cred_line" | awk '{print $1}')
    USERNAME=$(echo "$cred_line" | awk '{print $2}')
    PASSWORD=$(echo "$cred_line" | awk '{print $3}')
    PORT=$(echo "$cred_line" | awk '{print $4}')

    # Skip lines with missing details
    if [ -z "$HOST" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$PORT" ]; then
        echo "Error: Missing details for $HOST on port $PORT. Check $USERDETAILS_FILE." \
            | tee -a "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST:$PORT")
        continue
    fi

    LOG_FILE="$LOG_DIR/${HOST}_stop.log"
    echo -e "\n****************************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "Processing to stop $HOST:$PORT" | tee -a "$CENTRAL_LOG_FILE"
    echo -e "****************************************\n" | tee -a "$CENTRAL_LOG_FILE"


    # Identify running MongoDB process for this port using a pattern that matches ":$PORT"
    RUNNING_CMD=$(ssh -o LogLevel=QUIET -o BatchMode=yes mongouser@$HOST "ss -tulnp | grep -w '$PORT' 2>&1")
    if [ $? -ne 0 ] || [ -z "$RUNNING_CMD" ]; then
        echo "Error with SSH or MongoDB service check on $HOST for port $PORT: $RUNNING_CMD" \
            | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST:$PORT")
        continue
    fi

	
	# Save the start command ONCE per server
	if ! ssh -o LogLevel=QUIET mongouser@$HOST "[ -f ~/mongo_start.sh ]"; then
	echo -e "\n------------------------------------------------------------" | tee -a "$CENTRAL_LOG_FILE"
    echo "Saving MongoDB startup commands for $HOST" | tee -a "$CENTRAL_LOG_FILE"
	echo -e "\n------------------------------------------------------------" | tee -a "$CENTRAL_LOG_FILE"
    
    CURRENT_RUNNING_CMD=$(ssh -o LogLevel=QUIET mongouser@$HOST "ps aux | grep mongod | grep -v grep")
    if [ -z "$CURRENT_RUNNING_CMD" ]; then
        echo "No MongoDB services found running on $HOST" | tee -a "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST:$PORT")
        continue
    fi

    START_CMDS=$(echo "$CURRENT_RUNNING_CMD" | awk '{for(i=11;i<=NF;i++) printf $i" "; print ""}')
    
    ssh -o LogLevel=QUIET mongouser@$HOST "echo '#!/bin/bash' > ~/mongo_start.sh"
    echo "$START_CMDS" | ssh -o LogLevel=QUIET mongouser@$HOST "tee -a ~/mongo_start.sh > /dev/null"
    ssh -o LogLevel=QUIET mongouser@$HOST "chmod +x ~/mongo_start.sh"
	fi


    # Identify the MongoDB binary path dynamically
    MONGO_BINARY_PATH=$(ssh -o LogLevel=QUIET -o BatchMode=yes mongouser@$HOST "ps -ef | grep 'mongod' | awk '{print \$8}' | head -n 1 | xargs dirname 2>&1")
    if [ $? -ne 0 ] || [ -z "$MONGO_BINARY_PATH" ]; then
        echo "Error: MongoDB binary not found on $HOST for port $PORT. $MONGO_BINARY_PATH" \
            | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST:$PORT")
        continue
    fi
	
    # Determine the path to mongosh
    MONGOSH_PATH=$(ssh -o LogLevel=QUIET -o BatchMode=yes mongouser@$HOST "if [ -x '$MONGO_BINARY_PATH/mongosh' ]; then echo '$MONGO_BINARY_PATH/mongosh'; else which mongosh 2>/dev/null; fi 2>&1")
    if [ $? -ne 0 ] || [ -z "$MONGOSH_PATH" ]; then
        echo "Error: mongosh not found on $HOST for port $PORT. $MONGOSH_PATH" \
            | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST:$PORT")
        continue
    fi

    # Check if it's an arbiter node
    IS_ARBITER=$(ssh -o LogLevel=QUIET -o BatchMode=yes mongouser@$HOST "$MONGOSH_PATH --port $PORT --eval 'db.isMaster().arbiterOnly' --quiet 2>&1")
    if [ $? -ne 0 ]; then
        echo "Error with mongosh while checking arbiter node on $HOST for port $PORT: $IS_ARBITER" \
            | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST:$PORT")
        continue
    fi

    if [ "$IS_ARBITER" == "true" ]; then
        SHUTDOWN_CMD=$(ssh -o LogLevel=QUIET -o BatchMode=yes mongouser@$HOST "$MONGOSH_PATH --port $PORT --eval 'db.shutdownServer({force: true})' 2>&1")
    else
        SHUTDOWN_CMD=$(ssh -o LogLevel=QUIET -o BatchMode=yes mongouser@$HOST "$MONGOSH_PATH --username '$USERNAME' --password '$PASSWORD' --authenticationDatabase admin --port $PORT --eval 'db.shutdownServer({force: true})' 2>&1")
    fi


    # Run the check and store output in a variable
    PORT_CHECK=$(ssh -o LogLevel=QUIET -o BatchMode=yes mongouser@$HOST "ss -tulnp | grep '$PORT '")

    # Trim whitespace (if any) and check if it's truly empty
    if [[ -z "$PORT_CHECK" ]]; then
        echo "Successfully stopped MongoDB on $HOST for port $PORT." | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
    else
        echo "Failed to stop MongoDB on $HOST for port $PORT. Process still running:" | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        echo "$PORT_CHECK" | tee -a "$LOG_FILE" "$CENTRAL_LOG_FILE"
        FAILED_SERVERS+=("$HOST:$PORT")
    fi


done

# Final reporting
if [ ${#FAILED_SERVERS[@]} -ne 0 ]; then
    echo -e "\n************************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "MongoDB cluster stop encountered failures on the following servers:" | tee -a "$CENTRAL_LOG_FILE"
    printf '%s\n' "${FAILED_SERVERS[@]}" | tee -a "$CENTRAL_LOG_FILE"
    echo -e "***************************************\n" | tee -a "$CENTRAL_LOG_FILE"
    exit 1
else
    echo -e "\n*****************************************" | tee -a "$CENTRAL_LOG_FILE"
    echo "MongoDB cluster stopped successfully." | tee -a "$CENTRAL_LOG_FILE"
    echo -e "*******************************************\n" | tee -a "$CENTRAL_LOG_FILE"
    exit 0
fi
