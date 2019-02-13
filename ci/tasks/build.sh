#!/bin/bash

set -eux

SCRIPT_DIR=$(dirname "$0")
source ${SCRIPT_DIR}/mvn-tools.sh

export ROOT_FOLDER="$( pwd )"

VERSION=$(cat version/version)

M2_HOME="${HOME}/.m2"
M2_CACHE="${ROOT_FOLDER}/maven"

[[ -d $M2_CACHE && ! -d $M2_HOME ]] && ln -s $M2_CACHE $M2_HOME

echo "Root folder is [${ROOT_FOLDER}]"
echo "M2 Home folder is [${M2_HOME}]"
echo "M2 Cache folder is [${M2_CACHE}]"

echo "Version Number is [${VERSION}]"

pushd source
	# Update revision tag in the pom.xml so that Maven build get proper version
	set_revision_to_pom ${VERSION}
	
	./mvnw clean package ${MVN_PARAMS} 

	# Expose application and manifests to the output directory
	cp target/*.jar ../unpacked-artifacts/application.jar
	mkdir -p ../unpacked-artifacts/manifests
	cp manifest.yml ../unpacked-artifacts/manifests/development.yml
popd