#!/bin/bash

# this script automates the process of bumping three different args in the Dockerfile. The user has the option
# to update either the GEO_DB_RELEASE, MODSEC_TAG, or OWASP_BRANCH variable. Updating will modify the variable
# on all branches.

modsec_repo_url="https://github.com/SpiderLabs/ModSecurity.git"
owasp_repo_url="https://github.com/coreruleset/coreruleset.git"

options=("GEO_DB_RELEASE" "MODSEC_TAG" "OWASP_BRANCH")
PS3="Choose variable to update: "

update () {
  variable_to_update=$1
  value_to_update=$2

  for branch in $(git branch -a | grep 'remotes' | awk -F/ '{print $3}' | grep -v 'HEAD ->'); do
    git checkout ${branch} 2>/dev/null || git checkout -b ${branch} --track origin/${branch}
    echo "Updating ${variable_to_update} to ${value_to_update} for $(git branch)"
    sed -i 's/ARG '"${variable_to_update}"'=[^"]*/ARG '"${variable_to_update}"'='"${value_to_update}"'/' Dockerfile
    git add Dockerfile
    git commit -m "Bump ${variable_to_update} to ${value_to_update}"
  done
}

select var in "${options[@]}"; do
  case $var in
    "GEO_DB_RELEASE")
      read -p "GEO_DB_RELEASE (Default: $(date +'%Y-%m')): " current_month_and_year
      current_month_and_year=${current_month_and_year:-$(date +'%Y-%m')}
      geo_db_city_url="https://download.db-ip.com/free/dbip-city-lite-${current_month_and_year}.mmdb.gz"
      geo_db_country_url="https://download.db-ip.com/free/dbip-country-lite-${current_month_and_year}.mmdb.gz"

      if $(curl --output /dev/null --silent --fail --head "${geo_db_city_url}") && $(curl --output /dev/null --silent --fail --head "${geo_db_country_url}"); then
        update "GEO_DB_RELEASE" ${current_month_and_year}
      else
        echo "The GEO DB's for ${current_month_and_year} do not exist"
      fi
      exit
      ;;
    "MODSEC_TAG")
      read -p "MODSEC_TAG: " modsec_tag
      if [ $(git ls-remote --tags "${modsec_repo_url}" "${modsec_tag}" | wc -l) -eq 1 ]; then
        update "MODSEC_TAG" ${modsec_tag}
      else
        echo "The tag '${modsec_tag}' for ${modsec_repo_url} does not exist"
      fi
      exit
      ;;
    "OWASP_BRANCH")
      read -p "OWASP_BRANCH: " owasp_branch
      if [ $(git ls-remote --heads "${owasp_repo_url}" "${owasp_branch}" | wc -l) -eq 1 ] ; then
        update "OWASP_BRANCH" ${owasp_branch}
      else
        echo "The branch '${owasp_branch}' for ${owasp_repo_url} does not exist"
      fi
      exit
      ;;
    *)
    echo "Invalid option ${REPLY}"
    exit
    ;;
  esac
done
