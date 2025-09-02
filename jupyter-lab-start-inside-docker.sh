#!/bin/bash

# *****************************************************************************
#
# This script starts Jupyter Lab directly in the Codespace environment
#
# *****************************************************************************

set -euo pipefail


# ERROR HANDLER
#
# We expect this script to often get run automatically on Codespace startup,
# so we'll log errors appropriately.
error_handler() {
  echo "ERROR: Jupyter Lab failed to start at $(date)" >> jupyter-error.log
  echo "Jupyter Lab failed to start. Check jupyter-error.log for details."
}

trap "error_handler" ERR


# CHANGE INTO SCRIPT DIRECTORY
#
# Unset CDPATH to prevent `cd` potentially behaving unexpectedly
unset CDPATH
cd "$( dirname "${BASH_SOURCE[0]}")"

# ...existing code...
# ...existing code...
export EBMDATALAB_BQ_CREDENTIALS_PATH="$PWD/bq-service-account.json"


# CHECK FOR REQUIRED CREDENTIALS
#
# Ensure BQ_CREDENTIALS secret is set before proceeding
if [[ -z "${BQ_CREDENTIALS:-}" ]]; then
  echo "ERROR: BQ_CREDENTIALS secret is not set."
  echo
  echo "To fix this:"
  echo "1. Go to https://github.com/settings/codespaces"
  echo "2. Click 'New secret'"
  echo "3. Name: BQ_CREDENTIALS"
  echo "4. Value: Your BigQuery service account JSON"
  echo "5. Grant access to this repository"
  echo
  exit 1
fi

# Place Codespace credentials directly into the bq-service-account.json file
echo "$BQ_CREDENTIALS" > ./bq-service-account.json





# SET OS-SPECIFIC CONFIG


# GENERATE SERVER URL
#
# Generate a random token with which to authenticate to Jupyter. Jupyter can
# generate this for us, but it massively simplifies things to generate it
# ourselves and pass it in, rather than try to extract the token Jupyter has
# generated. We use `base64` as it's universally available (unlike `base32`)
# and replace any URL-problematic characters.
token=$(head -c 12 /dev/urandom | base64 | tr '+/' '01')

# Likewise, we want to tell Jupyter what port to bind to rather than let it
# choose. We find a free port by asking to bind to port 0 and then seeing what
# port we're given. This is obviously race-unsafe in the sense that the port
# might no longer be free at the point we want to use it, but that's seems
# unlikely on a local workstation.
#
# We shell out to Perl as we can assume the presence of git and git implies the
# presence of Perl.
port=$(
  perl -e '
    use IO::Socket::INET;

    print(
      IO::Socket::INET->new(
        Proto => "tcp", LocalAddr => "127.0.0.1"
      )
      ->sockport()
    );
  '
)

# Generate server URL for Codespace
server_url="https://$CODESPACE_NAME-$port.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/?token=$token"

blue='\033[1;34m'
reset='\033[0m'

jupyterlab_message="${blue}
**********************************************************************

You can access JupyterLab via the link below (CTRL or CMD and click)

$server_url

**********************************************************************
${reset}"

echo -e "$jupyterlab_message"



jupyter lab --ip=0.0.0.0 --port="$port" --IdentityProvider.token="$token" --ServerApp.custom_display_url="$server_url" --no-browser --allow-root
