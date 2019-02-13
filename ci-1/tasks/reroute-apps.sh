#!/usr/bin/env bash
set -ex

cf login -o ${organization} -s ${space} -u ${username} -p ${password} -a ${api} --skip-ssl-validation

cf map-route ${pcf_app_name_new} ${pcf_domain} -n ${pcf_app_name}

if [ `cf apps | awk '{print $1}' | grep -ic "^${pcf_app_name}$"` == 1 ]; then
  cf unmap-route ${pcf_app_name} ${pcf_domain} -n ${pcf_app_name}
fi

cf unmap-route ${pcf_app_name_new} ${pcf_domain} -n ${pcf_app_name_new}

cf delete ${pcf_app_name_old} -f

if [ `cf apps | awk '{print $1}' | grep -ic "^${pcf_app_name}$"` == 1 ]; then
  cf rename ${pcf_app_name} ${pcf_app_name_old}
fi

cf rename ${pcf_app_name_new} ${pcf_app_name}

if [ `cf apps | awk '{print $1}' | grep -ic "^${pcf_app_name_old}$"` == 1 ]; then
  cf stop ${pcf_app_name_old}
fi

cf delete-orphaned-routes -f