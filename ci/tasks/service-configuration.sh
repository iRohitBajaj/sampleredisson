#!/bin/bash

set -eux


function deployServices() {

	parsePipelineDescriptor

	if [[ -z "${PARSED_YAML}" ]]; then
		return
	fi

	while read -r serviceName serviceType; do
	    local lowerServiceType=$(toLowerCase "${serviceType}")
        if [[ "$(serviceExists "${serviceName}")" == "true" ]]; then
            echo "Skipping deployment since service ${serviceName} is already deployed"
        else
            deployService "${serviceName}" "${lowerServiceType}"
        fi
	# retrieve the space separated name and type
	done <<<"$(echo "${PARSED_YAML}" | jq -r --arg x "${service_env}" '.[$x].services[] | "\(.name) \(.type) "')"
}

function deployService() {
	local serviceName="${1}"
	local serviceType="${2}"

	case ${serviceType} in
		broker)
			local broker
			broker="$(echo "${PARSED_YAML}" |  jq --arg x "${service_env}" --arg y "${serviceName}" '.[$x].services[] | select(.name == $y) | .broker' | sed 's/^"\(.*\)"$/\1/')"
			local plan
			plan="$(echo "${PARSED_YAML}" |  jq --arg x "${service_env}" --arg y "${serviceName}" '.[$x].services[] | select(.name == $y) | .plan' | sed 's/^"\(.*\)"$/\1/')"
			local params
			params="$(echo "${PARSED_YAML}" |  jq --arg x "${service_env}" --arg y "${serviceName}" '.[$x].services[] | select(.name == $y) | .params' | sed 's/^"\(.*\)"$/\1/')"
			deployBrokeredService "${serviceName}" "${broker}" "${plan}" "${params}"
		;;
		*)
			echo "Unknown service type [${serviceType}] for service name [${serviceName}]"
			return 1
		;;
	esac
}


function deployBrokeredService() {
	local serviceName="${1}"
	local broker="${2}"
	local plan="${3}"
	local params="${4}"
	if [[ -z "${params}" || "${params}" == "null" ]]; then
		cf create-service "${broker}" "${plan}" "${serviceName}" || return 1
		echo "Deploying [${serviceName}] via Service Broker in [${service_env}] env. Options - broker [${broker}], plan [${plan}]"
	else
		echo "Deploying [${serviceName}] via Service Broker in [${service_env}] env. Options - broker [${broker}], plan [${plan}], params:"
		set +x
		local sensitive="$(echo "${params}" | jq '.sensitive')"
		if [[ "${sensitive}" == "true" ]]; then
		    local paramsName=$(echo ${params} | jq '.name' | sed 's/^"\(.*\)"$/\1/')
		    local serviceParamJson=$(echo "${services}" | jq --arg x ${paramsName} '.[] | select( .name == $x) | .value' | sed -e 's/^"//' -e 's/"$//' -e 's/\\//g')
		    cf create-service "${broker}" "${plan}" "${serviceName}" -c ${serviceParamJson}  || return 1
		fi
		set -x
	fi
}

function parsePipelineDescriptor() {
	if [[ ! -f ci/services-config.yml ]]; then
		echo "No pipeline descriptor found - will not deploy any services"
		return
	fi
	export PARSED_YAML
	PARSED_YAML=$(yaml2json ci/services-config.yml)
}

function yaml2json() {
	ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' "$@"
}

# Converts a string to lower case
function toLowerCase() {
	echo "$1" | tr '[:upper:]' '[:lower:]'
}

function findAppByName() {
	local serviceName="${1}"
	cf s | awk -v "app=${serviceName}" '$1 == app {print($0)}'
}

function serviceExists() {
	local serviceName="${1}"
	local foundApp
	foundApp=$(findAppByName "${serviceName}")
	if [[ "${foundApp}" == "" ]]; then
		echo "false"
	else
		echo "true"
	fi
}

function waitForServicesToInitialize() {
	# Wait until services are ready
	while cf services | grep 'create in progress'
	do
		sleep 10
		echo "Waiting for services to initialize..."
	done

	# Check to see if any services failed to create
	if cf services | grep 'create failed'; then
		echo "Service initialization - failed. Exiting."
		return 1
	fi
	echo "Service initialization - successful"
}