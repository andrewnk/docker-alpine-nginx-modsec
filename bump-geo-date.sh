#!/bin/bash

# this script automates the process of bumping the geo db which is released every month

GEO_DB_RELEASE=$(date +'%Y-%m')
GEO_DB_CITY_URL="https://download.db-ip.com/free/dbip-city-lite-${GEO_DB_RELEASE}.mmdb.gz"
GEO_DB_COUNTRY_URL="https://download.db-ip.com/free/dbip-country-lite-${GEO_DB_RELEASE}.mmdb.gz"

if $(curl --output /dev/null --silent --fail --head "${GEO_DB_CITY_URL}") && $(curl --output /dev/null --silent --fail --head "${GEO_DB_COUNTRY_URL}"); then
  echo "The GEO DB's exist"
  for branch in $(git branch -a | grep 'remotes' | awk -F/ '{print $3}' | grep -v 'HEAD ->'); do
    git checkout ${branch} 2>/dev/null || git checkout -b ${branch} --track origin/${branch}
    echo "Updating GEO DB to ${GEO_DB_RELEASE} for $(git branch)"
    sed -i 's/GEO_DB_RELEASE=[^"]*/GEO_DB_RELEASE='"${GEO_DB_RELEASE}"'/' Dockerfile
    git add Dockerfile
    git commit -m "Bump GEO DB to ${GEO_DB_RELEASE}"
  done
else
  echo "The GEO DB's for ${GEO_DB_RELEASE} do not exist"
fi
