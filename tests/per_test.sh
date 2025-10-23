#!/usr/bin/env bash

per_test_setup() {
  set -e -o pipefail
  set +u

  echo "# doing 'ddev add-on get ${PROJECT_SOURCE:-}' PROJNAME=${PROJNAME:-} in TESTDIR=${TESTDIR:-} ($(pwd))" >&3
  run ddev add-on get ${PROJECT_SOURCE:-}
  assert_success
  # Save add-on installation output for version warning tests
  echo "$output" > .ddev/addon-install.log

  echo "# ddev start with PROJNAME=${PROJNAME:-} in ${TESTDIR:-} ($(pwd))" >&3
  run ddev start -y
  assert_success

  # Install composer dependencies (web/ and vendor/ are gitignored)
  echo "# Running composer install to create vendor/ and web/ directories" >&3
  run ddev composer install --no-dev --no-interaction
  assert_success

  # Select database dump based on database type
  if [[ "${EXPECTED_DB_TYPE:-}" == "postgres" ]]; then
    DB_DUMP="${PROJECT_SOURCE}/tests/testdata/drupal11-base/db-postgres.sql.gz"
  else
    DB_DUMP="${PROJECT_SOURCE}/tests/testdata/drupal11-base/db-mysql.sql.gz"
  fi

  if [ -f "${DB_DUMP}" ]; then
    echo "# Importing database ${DB_DUMP}" >&3
    run ddev import-db --file="${DB_DUMP}"
    assert_success
  fi
}

per_test_teardown() {
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
}
