#!/bin/bash

GH_TOKEN=$ACCESS_TOKEN
GITHUB_OWNER=$GITHUB_OWNER
GITHUB_REPO=$GITHUB_REPO

#echo "GH_RUNNER_TOKEN ${GH_TOKEN}"
echo "GITHUB_OWNER ${GITHUB_OWNER}"
echo "GITHUB_REPO ${GITHUB_REPO}"

# Get registration token (needed to register the runner)
REG_TOKEN=$(curl -s -X POST -H "Authorization: token ${GH_TOKEN}" -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/"${GITHUB_OWNER}"/"${GITHUB_REPO}"/actions/runners/registration-token | jq -r .token)

echo "Registration token: ${REG_TOKEN}"

cd /home/docker/actions-runner || exit

# Use the registration token here, NOT the PAT
./config.sh --url https://github.com/"${GITHUB_OWNER}"/"${GITHUB_REPO}" --token "${REG_TOKEN}" --unattended --replace

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
