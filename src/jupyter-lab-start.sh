#!/bin/bash

# *****************************************************************************
#
# This script starts Jupyter Lab directly in the Codespace environment
#
# *****************************************************************************

set -euo pipefail

# Setting some variables to enable formatting of terminal print outs
blue='\033[1;34m'
red='\033[0;31m'
underline='\033[4m'
underline_off='\033[24m'
reset='\033[0m'


# Unset CDPATH to prevent `cd` potentially behaving unexpectedly
unset CDPATH
cd "$( dirname "${BASH_SOURCE[0]}")/.."


credentials_error_msg="${red}
************************************************************************************

  ERROR: the 'BQ_CREDENTIALS' secret is not available in this Codespace!

  Either you have never created a BQ_CREDENTIALS secret and/or have not
  given this repository (named: $GITHUB_REPOSITORY) access to the secret.

  To fix this either create a new secret by:

    1. Going to https://github.com/settings/codespaces/secrets/new
    2. Name: BQ_CREDENTIALS
    3. Value: Your BigQuery service account JSON
    4. Grant access to the '$GITHUB_REPOSITORY' repository

  Or if you already have a BQ_CREDENTIALS secret, ensure it the 
  repository you are working in has been granted access.

    1. Go to https://github.com/settings/codespaces/secrets/BQ_CREDENTIALS/edit
    2. Add 'Repository access' to this repository.

************************************************************************************
${reset}"


# Ensure BQ_CREDENTIALS secret is set before proceeding
if [[ -z "${BQ_CREDENTIALS:-}" ]]; then
  echo -e "$credentials_error_msg"
  exit 1
fi


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


jupyterlab_message="${blue}
************************************************************************************************

You can access JupyterLab via the link below (CTRL or CMD and click)

${underline}$server_url${underline_off}

We will try and open the above url for you, but your pop-up blocker may stop this.

************************************************************************************************
${reset}"



# Print message when ready and open JupyterLab (although pop-ups might be blocked)
print_jupyterlab_message_on_ready() {
  while IFS= read -r line; do
    printf "%s\n" "$line"
    if [[ "$line" == *"Use Control-C to stop this server and shut down all kernels"* ]]; then
      echo -e "$jupyterlab_message"

      # Wait for the server to respond before opening the browser
      for i in {1..40}; do
        if curl -s --fail "$server_url" > /dev/null; then
          "$BROWSER" "$server_url" &
          break
        else
          sleep 2
        fi
      done
    fi
  done
}

# Start JupyterLab Notebook
jupyter lab \
  --ip=0.0.0.0 \
  --port="$port" \
  --IdentityProvider.token="$token" \
  --ServerApp.custom_display_url="$server_url" \
  --no-browser \
  --allow-root 2>&1 | print_jupyterlab_message_on_ready
