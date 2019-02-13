#!/usr/bin/env bash

set -ex

  status_code=$(curl -sSIL -k -X GET --header "Accept: */*" "${test_url}${health_path}"|head -n 1|cut -d$' ' -f2)
  response=$(curl -i -k "${test_url}${health_path}")

  echo "Status Code:" $status_code
  echo "Response: " $response

  if [[ $status_code != 200  ]]; then
	  echo "Unsuccessful call to ${health_path}"
		exit 1
	else
    echo "Successful call to ${health_path}"
  fi