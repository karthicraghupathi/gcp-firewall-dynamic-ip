#!/usr/bin/env bash

# Ensure required environment variables are set
if [ -z "$CLOUDSDK_ACTIVE_CONFIG_NAME" ]; then
  echo "Error: CLOUDSDK_ACTIVE_CONFIG_NAME environment variable is not set."
  echo "Please set CLOUDSDK_ACTIVE_CONFIG_NAME to the desired gcloud configuration name."
  exit 1
fi

if [ -z "$FIREWALL_RULES" ]; then
  echo "Error: FIREWALL_RULES environment variable is not set."
  echo "Please set FIREWALL_RULES to a space-separated list of firewall rule names."
  exit 1
fi

IP_FILE=./publicip-"$CLOUDSDK_ACTIVE_CONFIG_NAME".txt
PUBLIC_IP=$(curl -s https://api.ipify.org)

# Set the working directory to the location of the script
cd "$(dirname "$0")" || exit 1

# check if ip is same as last check
grep "$PUBLIC_IP" "$IP_FILE" > /dev/null 2>&1

# if not a match, update firewall rules
if [ $? -ne 0 ]; then
    printf $PUBLIC_IP > $IP_FILE
    echo "Public IP has changed to $PUBLIC_IP."

    # Activate the desired gcloud configuration
    echo "Activating gcloud configuration: $CLOUDSDK_ACTIVE_CONFIG_NAME"
    gcloud config configurations activate "$CLOUDSDK_ACTIVE_CONFIG_NAME"

    # Update each firewall rule
    for rule in $FIREWALL_RULES; do
        echo "Updating firewall rule: $rule"
        gcloud compute firewall-rules update "$rule" --source-ranges="$PUBLIC_IP/32"
        echo
        echo "Verifying firewall rule: $rule"
        gcloud compute firewall-rules describe "$rule"
        echo
    done
fi
