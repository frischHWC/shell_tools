#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

############################################################################################################################
# This script executes script : `script.sh` (presents in the same folder) to all nodes of a cluster.                       #
# See below exports to change node names and range, but also to allow printing of results or not.                          #
#                                                                                                                          #
# It creates a named, according to first parameter or default to timestamped, directory for each execution.                # 
# If set, it archives results at the end, with script.sh.                                                                  #
############################################################################################################################

echo "Start of script"

# Modify these below settings according to your cluster
export CLUSTER_NAME=
export HOSTS_FILE=
export NODE_USER='root'
export NODE_PASSWORD=
export PRINT_RESULTS=true
export DELETE_RESULTS=true
export ARCHIVE_RESULTS=false
export PARALLEL_EXECUTION=true
export SCRIPT_NAME=script.sh
export RESULT_DIR=
export SSH_KEY=

function usage()
{
    echo "This script is a launch of a specified script into different machines in parallel or not"
    echo ""
    echo "Usage is the following : "
    echo ""
    echo "./execute_to_cluster.sh"
    echo "  -h --help"
    echo "  --cluster-name=$CLUSTER_NAME Required as it will get all machines from /etc/hosts that have this name or use --hosts-file (Default) "
    echo "  --hosts-file=$HOSTS_FILE Required as it gets hosts list from this file or use --cluster-name (Default) "
    echo ""
    echo "  --node-user=$NODE_USER : (Optional) User to connect to machines (Default) root "
    echo "  --node-password=$NODE_PASSWORD : (Optional) Password for the user to connect to machines (Default) "
    echo "  --ssh-key=$SSH_KEY : (Optional) Provides an ssh key to connect to each node (Default) None"
    echo "  --print-result=$PRINT_RESULTS : (Optional) to print result on screen (Default) true "
    echo "  --delete-result=$DELETE_RESULTS : (Optional) to delete result after (Default) true "
    echo "  --archive-result=$ARCHIVE_RESULTS : (Optional) to archive result in a tar file after execution (Default) false "
    echo "  --parallel-execution=$PARALLEL_EXECUTION : (Optional) Executes on all nodes in parallel (Default) true"
    echo "  --script-name=$SCRIPT_NAME : (Optional) The script to execute on each node (Default) "
    echo "  --results-dir=$RESULT_DIR : (Optional) Directory where to store results (Default) Generates under /tmp a random directory"
    echo ""
    echo " <Args> : Arguments to pass to the script to execute (Note that number of node is passed as an argument to the script as 1st argument)"
    echo ""
}

export ARGS=$(echo $@ | sed 's/--[^ ]*//g')

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --cluster-name)
            CLUSTER_NAME=$VALUE
            ;;
        --hosts-file)
            HOSTS_FILE=$VALUE
            ;;        
        --node-user)
            NODE_USER=$VALUE
            ;;
        --node-password)
            NODE_PASSWORD=$VALUE
            ;;    
        --print-result)
            PRINT_RESULTS=$VALUE
            ;;
        --delete-result)
            DELETE_RESULTS=$VALUE
            ;;
        --archive-result)
            ARCHIVE_RESULTS=$VALUE
            ;;
        --parallel-execution)
            PARALLEL_EXECUTION=$VALUE
            ;;
        --script-name)
            SCRIPT_NAME=$VALUE
            ;;
        --results-dir)
            RESULT_DIR=$VALUE
            ;;
        --ssh-key)
            SSH_KEY=$VALUE
            ;;    
        *)
            ;;
    esac
    shift
done

# Create folder name to folder results dir variable given or default to timestamp
if [ -z "$RESULT_DIR" ]
then 
    export FOLDER_NAME=$(mktemp -d)
else 
    export FOLDER_NAME=$RESULT_DIR
fi

# Check if an ssh-key is required
if [ -z "$SSH_KEY" ]
then 
    export SSH_KEY_COMMAND=""
else 
    export SSH_KEY_COMMAND=" -i ${SSH_KEY} "
fi

if [ -z "$NODE_PASSWORD" ]
then 
    export NODE_USER_PASSWORD_COMMAND="${NODE_USER}"
else 
    export NODE_USER_PASSWORD_COMMAND="${NODE_USER}:${NODE_PASSWORD}"
fi

# Get machines to iterate on using cluster-name
if [ -z "$HOSTS_FILE" ]
then
    export MACHINES_UNSORT=$(cat /etc/hosts | grep "${CLUSTER_NAME}" | awk '{print $2}')
    export MACHINES=$(echo "${MACHINES_UNSORT[@]}" | sort | uniq)
else
    export MACHINES=$(cat $HOSTS_FILE)
fi

# Create directories of work
mkdir -p ${FOLDER_NAME}/

# Copy script that will be used in directory of work
cp ${SCRIPT_NAME} ${FOLDER_NAME}/

if [ "${PARALLEL_EXECUTION}" = true ]
then
    PID_ARRAY=()

    # Execute the script on each node and redirect its output in an appropriate named file
    for machine in ${MACHINES}
    do
        echo "*** Launch execution on node $machine ***"
        ssh ${SSH_KEY_COMMAND} ${NODE_USER}@$machine 'bash -s' < ${FOLDER_NAME}/${SCRIPT_NAME} $machine ${ARGS} > ${FOLDER_NAME}/$machine.out &
        PID_ARRAY+=($!)
    done

    # Wait for script on every node to complete
    for p in $PID_ARRAY
    do
        wait $p
    done

    # Wait to be sure, before archiving
    sleep 2

else
    # Execute the script on each node and redirect its output in an appropriate named file
    for machine in ${MACHINES}
    do
        echo "*** Launch execution on node $machine ***"
        ssh ${SSH_KEY_COMMAND} ${NODE_USER_PASSWORD_COMMAND}@$machine 'bash -s' < ${FOLDER_NAME}/${SCRIPT_NAME} $machine ${ARGS} > ${FOLDER_NAME}/$machine.out
    done
fi

# Archive all results in a tar if required
if [ "${ARCHIVE_RESULTS}" = true ]
then 
    echo "*** Creating final archive ***"
    tar -cvzf ${FOLDER_NAME}.tar  ${FOLDER_NAME}/* 
    echo "*** Finished to create final archive ***"
fi    

# Printing results ? 
if [ "${PRINT_RESULTS}" = true ]
then 
    echo "*** Printing results ***"
    for machine in ${MACHINES}
    do
        echo "*** Results of node $machine ***"
        cat ${FOLDER_NAME}/$machine.out
        echo "***End of results of node $machine ***"
    done
    echo "*** Finished printing results ***"
fi

# Deleting results ? 
if [ "${DELETE_RESULTS}" = true ]
then 
    rm -rf ${FOLDER_NAME}
fi

echo "End of script"

