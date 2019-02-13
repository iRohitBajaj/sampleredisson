#!/usr/bin/env bash

set -ex

export ROOT_FOLDER=$( pwd )

ls -ltr

cf login -o ${organization} -s ${space} -u ${username} -p ${password} -a ${api} --skip-ssl-validation

source source/ci/tasks/service-configuration.sh

cd source

deployServices
waitForServicesToInitialize