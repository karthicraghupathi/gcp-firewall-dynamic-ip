# GCP Firewall Update for Dynamic IPs

A simple script to update firewall rules on GCP for dynamic IPs.

## Setup Service Account

### Create a Service Account

- Open the [Google Cloud Console](https://console.cloud.google.com/).
- Navigate to **IAM & Admin > Service Accounts**.
- Click **Create Service Account**.
- Provide a name and description (e.g., `firewall-updater`).
- Click **Create and Continue**.

### Create a Custom Role

- Go to **IAM & Admin > Roles**.
- Click **Create Role**.
- Name the role (e.g., `FirewallUpdater`).
- Add the following permissions:
  - `compute.firewalls.create`
  - `compute.firewalls.delete`
  - `compute.firewalls.get`
  - `compute.firewalls.list`
  - `compute.firewalls.update`
  - `compute.networks.updatePolicy`
- Save the role.

### Assign Permissions to the Service Account

- Go to **IAM & Admin > IAM**.
- Click **Add**.
- Add the service account email.
- Assign the custom role (e.g., `FirewallUpdater`).
- If using predefined roles: **Assign the Compute Network Admin** role, which includes:
-- `compute.firewalls.*` (All permissions for managing firewalls).

### Authenticate the Google Cloud SDK

On the machine where the script will run:

- Install the Google Cloud SDK. These instructions are for Debian / Ubuntu systems. Find the correct instructions for your OS at https://cloud.google.com/sdk/docs/install.
  ```bash
  sudo apt update && sudo apt install apt-transport-https ca-certificates gnupg curl

  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

  sudo apt update && sudo apt install google-cloud-cli
  ```
- Authenticate as the Service Account:
  - Download the service account's JSON key from the Google Cloud Console.
  - Authenticate using the key:
    ```bash
    gcloud auth activate-service-account --key-file=/path/to/service-account-key.json
    ```
- Set the Active Project:
  ```bash
  gcloud config set project [PROJECT_ID]
  ```

### Verify the Setup

Run a dry-run of the gcloud compute firewall-rules command to ensure the permissions are correctly configured:

```bash
gcloud compute firewall-rules list
```

Attempt creating a temporary firewall rule:

```bash
gcloud compute firewall-rules create test-rule --allow tcp:80 --source-ranges="1.2.3.4" --network default
```

If it works, delete the rule:

```bash
gcloud compute firewall-rules delete test-rule
```

## Multiple Accounts

### Understand `gcloud` Configurations

A configuration in gcloud stores:
- Active account (user or service account).
- Active project.
- Compute region/zone.
- Other SDK settings.

You can switch between configurations to operate in different accounts or projects.

### Create a New Configuration for Each Account

#### For each GCP account:

- Create a new configuration:
  ```bash
  gcloud config configurations create [CONFIG_NAME]
  ```
- Replace `[CONFIG_NAME]` with a descriptive name (e.g., `account1`, `project-dev`).

#### Set the active account:

```bash
gcloud auth activate-service-account --key-file=/path/to/service-account-key.json
```

#### Set the active project:

```bash
gcloud config set project [PROJECT_ID]
```

#### Set a default compute region/zone (Optional):

```bash
gcloud config set compute/region [REGION]
gcloud config set compute/zone [ZONE]
```

### Switch Between Configurations

To use a specific account or project, activate its configuration:

```bash
gcloud config configurations activate [CONFIG_NAME]
```

### List Configurations

To view all configurations and their current settings:

```bash
gcloud config configurations list
```

## Environment Variables

Use the following environment variables to pass configuration names to the script:

- `CLOUDSDK_ACTIVE_CONFIG_NAME` - Sets the configuration the script must use to make updates.
- `FIREWALL_RULES` - An array of firewall rule names that will be updated to use the new IP.

To run the script manually, run this:

```bash
export CLOUDSDK_ACTIVE_CONFIG_NAME=account1
export FIREWALL_RULES="rule1 rule2"
```

There is a helper script `setup_env.sh` that you can modify to set the appropriate configuration. Run this script everytime to setup your environment before calling the main script to update the IP address.

## Usage

### Manual

- Ensure you've completed the steps listed above to setup the service account in Google Cloud Console.
- Clone the repository first:
  ```bash
  git clone https://github.com/karthicraghupathi/gcp-firewall-dynamic-ip.git /var/tasks
  ```
- Then modify `setup_env.sh` with the appropriate values and run it:
  ```bash
  source ./setup_env.sh
  ```
- Finally run the script to update the IPs:
```bash
./updater.sh
```

### Automation

Use `cron` to automate changing the IP address:

```
# shell needs to be bash; add this to the top of the crontab
SHELL=/usr/bin/bash

*/2 * * * * source /var/tasks/gcp-firewall-dynamic-ip/setup_env.sh && /var/tasks/gcp-firewall-dynamic-ip/updater.sh
```

OR

```
*/2 * * * * /usr/bin/bash -c "source /var/tasks/gcp-firewall-dynamic-ip/setup_env.sh && /var/tasks/gcp-firewall-dynamic-ip/updater.sh"
```
