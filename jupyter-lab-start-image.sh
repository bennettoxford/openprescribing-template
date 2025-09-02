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


# dirname="$(basename "$PWD")"
# path_hash=$(echo "$PWD" | shasum | head -c 8)
# image_name="jupyter-$dirname-$path_hash"
image_name="ghcr.io/bennettoxford/mark-notebook-bigquery-2:latest"

# Generate a short random suffix so that we can set a meaningful name for the
# container but still ensure uniqueness (with sufficiently high probability)
container_suffix=$(head -c 6 /dev/urandom | base64 | tr '+/' '01')
container_name="jupyter-lab-container"


# BUILD IMAGE
#
# We explicitly specify the platform so that when running on Apple silicon we
# still get the `amd64` image rather than the `arm64` image. Not all the Python
# packages we want to install have `arm64` wheels, and we don't always have the
# headers we need to compile them. Insisting on `amd64` gives us cross-platform
# consistency.
# docker build --platform linux/amd64 --tag "$image_name" .


# SET OS-SPECIFIC CONFIG
#
# On Linux, where the ownership of mounted files maps directly through to the
# host filesystem, we want the Docker user ID to match the current user ID so
# files end up with the right owner. On Windows/macOS files inside the
# container will appear owned as root, so we want to run as root.
if [[ "$(docker info -f '{{.OSType}}')" == "linux" ]]; then
  docker_user="$UID:$(id -g)"
else
  docker_user="root"
fi
# The git-bash terminal (which most of our Windows users will run this under)
# does not provide a TTY unless we run the command via the `winpty` tool. So we
# try to detect when we are running in git-bash and get the path to `winpty` if
# we are.
if [[ -z "${MSYSTEM:-}" ]]; then
  winpty_path=""
else
  winpty_path="$(command -v winpty || true)"
fi


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

# Wait until JupyterLab is running
# (
#   until curl -fsS --output /dev/null "$server_url" 2>/dev/null; do
#     sleep 1
#   done
#   "$BROWSER" "$server_url"
# ) &

# START JUPYTER LAB IN DOCKER

docker_args=(
  run
  --rm
  --interactive
  --tty
  --name "$container_name"
  --user "$docker_user"

  # The leading slash before PWD here is needed when running on Windows to stop
  # git-bash mangling the path
  --volume "/$PWD:/workspace"
  --publish "$port:$port"

  "$image_name"

  jupyter lab
    --ip=0.0.0.0
    --port="$port"
    --IdentityProvider.token="$token"
    --ServerApp.custom_display_url="$server_url"
    --no-browser
    --allow-root
)

if [[ -z "$winpty_path" ]]; then
  docker "${docker_args[@]}"
else
  "$winpty_path" -- docker "${docker_args[@]}"
fi
