#!/bin/bash

set -eux

SCRIPT_DIR=$(dirname "$0")
source ${SCRIPT_DIR}/mvn-tools.sh

FINAL_VERSION=$(cat final-version/version)
FULL_FINAL_VERSION="${FINAL_VERSION}${FINAL_VERSION_SUFFIX}"

NEXT_VERSION=$(cat next-version/version)
FULL_NEXT_VERSION="${NEXT_VERSION}${NEXT_VERSION_SUFFIX}"

if [[ -z ${RELEASE_BRANCH} ]]; then
    echo "The RELEASE_BRANCH parameter is required"
    exit 2
fi

git clone source updated-source

pushd updated-source
    git config user.email "wings@pivotal.io"
    git config user.name "Concourse CI"

    git checkout -b version-bump
    set_revision_to_pom ${FULL_FINAL_VERSION}

    git add pom.xml && git commit -m "[ci skip] Finalize POM version for release to ${FULL_FINAL_VERSION}" 
    git tag "v${FINAL_VERSION}"

    set_revision_to_pom ${FULL_NEXT_VERSION}
    git add pom.xml && git commit -m "[ci skip] Bump POM version for next build to ${FULL_NEXT_VERSION}" 

    git checkout ${RELEASE_BRANCH}
    git merge version-bump
    git branch -d version-bump

    git push origin ${RELEASE_BRANCH}
popd