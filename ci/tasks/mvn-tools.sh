#!/bin/bash

# Update the revision tag in a POM file
# https://raw.githubusercontent.com/spring-io/concourse-java-scripts/v0.0.2/concourse-java.sh
set_revision_to_pom() {
	[[ -n $1 ]] || { echo "missing set_revision_to_pom() argument" >&2; return 1; }
	grep -q "<revision>.*</revision>" pom.xml || { echo "missing revision tag" >&2; return 1; }
	sed -ie "s|<revision>.*</revision>|<revision>${1}</revision>|" pom.xml > /dev/null
}