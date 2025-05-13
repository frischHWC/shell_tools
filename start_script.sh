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

########## WARNING ###########
#
# Requires Bash version > 4.0
#
##############################

########## Helper with Description and Variable Exporter to use for any script ##########
# Load this file into your script with . ./start_script.sh
# Then use it in 3 steps:
#
# 1. Add a description to your script:
#       add_desc "This is a global description of the script"
#
# 2. Add variables to your script with a default value and a description (Optional)
#       add_var <VARIABLE_NAME> <OPTIONAL_DEFAULT_VALUE> <OPTIONAL_DESCRIPTION>
#   
#   As an example:
#       add_var USER "root" "Name of the user"
#
# 3. Get all variables directly from command line and export them so they can be used in your script
#       export_vars $@
#
#
#


script_vars=()
declare -A script_vars_value
declare -A script_vars_desc
declare -A script_vars_cmdline
global_desc=""
script_name=""

function add_desc() {
    global_desc=$1
}

function add_var() {
    local NAME=$1
    local DEFAULT_VALUE=$2
    local DESCRIPTION=$3

    script_vars+=("$NAME")
    script_vars_value["${NAME}"]="${DEFAULT_VALUE}"
    script_vars_desc["${NAME}"]="${DESCRIPTION}"
    script_vars_cmdline["${NAME}"]=$(echo "$NAME" |  tr '[:upper:]' '[:lower:]' | tr '_' '-' )

    export "${NAME}"=$DEFAULT_VALUE
    
}

function usage() {

    echo "$global_desc"
    echo ""
    echo "Usage is the following : "
    echo ""
    echo "./<script_name>.sh"
    echo "  -h --help"
    echo ""

    for i in ${script_vars[@]} ; do

        echo "  --${script_vars_cmdline["${i}"]}=${script_vars_value["${i}"]}"
        echo "          ${script_vars_desc["${i}"]}"
        echo ""

    done
}


function export_vars() {
    while [ "$1" != "" ] ; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
        for i in ${script_vars[@]} ; do
            if [ "$PARAM" == "--${script_vars_cmdline["${i}"]}" ] ; then
                export "${i}"=$VALUE
                break 
            fi
        done
        shift
    done

}