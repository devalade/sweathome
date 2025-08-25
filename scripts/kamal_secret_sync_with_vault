#!/bin/bash

# ==============================================================================
#
# TITLE:        Kamal & Bitwarden Secret Synchronizer
#
# DESCRIPTION:  This script synchronizes secrets from a local .env file with a
#               Bitwarden Secrets Manager project. It uses a Kamal deploy.yml
#               file to determine which secrets to sync. After syncing, it
#               generates a .kamal/secrets file to be used for deployment.
#
# USAGE:        ./kamal_secret_sync_with_vault.sh <path/to/deploy.yml> <path/to/.env>
#
# DEPENDENCIES: - bws (Bitwarden Secrets Manager CLI)
#               - yq
#               - jq
#               - kamal
#
# SETUP:        The BWS_ACCESS_TOKEN environment variable must be set and have
#               access to the target project in Bitwarden Secrets Manager.
#
# ==============================================================================

# --- Script Settings ---
# NOTE: We are intentionally not using 'set -e' to handle a specific issue where
# the bws command causes the script to exit unexpectedly.
set -uo pipefailset -uo pipefail

DEPLOY_YML_PATH="${1:-config/deploy.yml}"
if [ -z "${2:-}" ]; then
	echo "❌ Error: Please provide the path to the source .env file as the second argument." >&2
	echo "Usage: $0 <path-to-your-deploy-yml> <path-to-your-env-file>" >&2
	exit 1
fi
ENV_FILE_PATH="$2"
TIMEOUT_SECONDS=30

# --- Main Logic ---
main() {
	# 1. Initial Checks and Setup
	check_dependencies
	authenticate_bws
	local repository_name
	repository_name=$(get_repository_name)
	local project_id
	project_id=$(ensure_bitwarden_project "$repository_name")

	echo "🚀 Starting secret synchronization for project: $repository_name"
	echo "   - Source environment file: $ENV_FILE_PATH"
	echo "   - Target Project ID: $project_id"

	# 2. Fetch required and existing secrets
	local required_keys
	required_keys=$(get_required_secret_keys)
	declare -A env_vars
	declare -A existing_secrets_map
	load_env_file env_vars
	load_existing_secrets "$project_id" existing_secrets_map

	# 3. Process and synchronize secrets
	process_secrets "$project_id" "$required_keys" env_vars existing_secrets_map

	# 4. Update the .kamal/secrets file
	update_kamal_secrets_file "$project_id" "$required_keys"
}

# --- Helper Functions ---
check_dependencies() {
	if ! command -v bws &>/dev/null; then
		echo "❌ Error: Bitwarden Secrets Manager CLI (bws) is not installed." >&2
		exit 1
	fi
	if ! command -v yq &>/dev/null; then
		echo "❌ Error: yq is not installed." >&2
		exit 1
	fi
	if ! command -v kamal &>/dev/null; then
		echo "❌ Error: kamal is not installed." >&2
		echo "   Please install it via: gem install kamal" >&2
		exit 1
	fi
}

authenticate_bws() {
	if [ -z "${BWS_ACCESS_TOKEN:-}" ]; then
		echo "❌ Error: BWS_ACCESS_TOKEN environment variable is not set." >&2
		exit 1
	fi
	if ! bws project list &>/dev/null; then
		echo "❌ Error: Invalid or expired BWS_ACCESS_TOKEN." >&2
		exit 1
	fi
}

get_repository_name() {
	local repo_name
	repo_name=$(basename -s .git "$(git config --get remote.origin.url)" 2>/dev/null)
	if [ -z "$repo_name" ]; then
		echo "❌ Error: Could not determine repository name from git." >&2
		exit 1
	fi
	echo "$repo_name"
}

ensure_bitwarden_project() {
	local project_name=$1
	echo "🗂️  Ensuring Bitwarden project '$project_name' exists..." >&2

	local project_id
	project_id=$(bws project list | jq -r --arg name "$project_name" '.[] | select(.name == $name) | .id')

	if [ -z "$project_id" ]; then
		echo "   - Project not found. Creating..." >&2
		project_id=$(bws project create "$project_name" | jq -r '.id')
		echo "   - Created project with ID: $project_id" >&2
	else
		echo "   - Project already exists with ID: $project_id" >&2
	fi
	echo "$project_id"
}

get_required_secret_keys() {
	if [ ! -f "$DEPLOY_YML_PATH" ]; then
		echo "❌ Error: Deploy configuration file not found: $DEPLOY_YML_PATH" >&2
		exit 1
	fi
	yq e '.env.secret | .[]' "$DEPLOY_YML_PATH"
}

load_env_file() {
	local -n vars_ref=$1
	if [ ! -f "$ENV_FILE_PATH" ]; then
		echo "❌ Error: The source environment file was not found at: $ENV_FILE_PATH" >&2
		exit 1
	fi

	while IFS= read -r line || [[ -n "$line" ]]; do
		if [[ "$line" =~ ^\s*# || -z "$line" ]]; then continue; fi
		if [[ "$line" =~ ^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(.*)\s*$ ]]; then
			local key="${BASH_REMATCH[1]}"
			local value="${BASH_REMATCH[2]}"
			value="${value#\"}"
			value="${value%\"}"
			value="${value#\'}"
			value="${value%\'}"
			vars_ref["$key"]=$value
		fi
	done <"$ENV_FILE_PATH"
}

load_existing_secrets() {
	local project_id=$1
	local -n secrets_ref=$2
	echo "📡 Fetching existing secrets from Bitwarden..." >&2

	local secrets_json
	secrets_json=$(timeout "$TIMEOUT_SECONDS" bws secret list "$project_id")
	if [ $? -eq 124 ]; then
		echo "❌ Error: Timed out fetching existing secrets." >&2
		exit 1
	fi

	while IFS='=' read -r key id; do
		secrets_ref["$key"]=$id
	done < <(echo "$secrets_json" | jq -r '.[] | "\(.key)=\(.id)"')
	echo "   - Found ${#secrets_ref[@]} existing secrets." >&2
}

process_secrets() {
	local project_id=$1
	local required_keys_string=$2
	local -n env_vars_ref=$3
	local -n secrets_map_ref=$4

	echo "🔄 Processing and synchronizing secrets..."
	local pushed_count=0
	local skipped_count=0

	local -a keys_array
	readarray -t keys_array <<<"$required_keys_string"

	for key in "${keys_array[@]}"; do
		key=$(echo "$key" | xargs)
		if [ -z "$key" ]; then continue; fi

		if [[ -v "env_vars_ref[$key]" ]]; then
			local value="${env_vars_ref[$key]}"

			if [[ -v "secrets_map_ref[$key]" ]]; then
				local secret_id="${secrets_map_ref[$key]}"
				echo "   - Updating secret: $key"

				timeout "$TIMEOUT_SECONDS" bws secret edit "$secret_id" --key "$key" --value "$value" &>/dev/null
				local exit_code=$?
				if [ $exit_code -ne 0 ]; then
					echo "     ❌ WARNING: Failed to update secret '$key' (Exit code: $exit_code)."
				fi
			else
				echo "   - Creating secret: $key"

				timeout "$TIMEOUT_SECONDS" bws secret create "$key" "$value" "$project_id" &>/dev/null
				local exit_code=$?
				if [ $exit_code -ne 0 ]; then
					echo "     ❌ WARNING: Failed to create secret '$key' (Exit code: $exit_code)."
				fi
			fi
			((pushed_count++))
		else
			echo "   - ⚠️  SKIPPING: Key '$key' not found in $ENV_FILE_PATH."
			((skipped_count++))
		fi
	done

	echo ""
	echo "✅ Synchronization complete:"
	echo "   - Pushed/Updated: $pushed_count secrets"
	if [ "$skipped_count" -gt 0 ]; then
		echo "   - Skipped: $skipped_count secrets (not found in .env)"
	fi
}

update_kamal_secrets_file() {
	local project_id=$1
	local required_keys_string=$2
	local secrets_dir=".kamal"
	local secrets_file="${secrets_dir}/secrets"

	echo "📝 Updating Kamal secrets file at '$secrets_file'..." >&2

	# Ensure the .kamal directory exists
	mkdir -p "$secrets_dir"

	# Use a temporary file to build the content safely
	local tmp_file
	tmp_file=$(mktemp)

	# Write the header and the main fetch command
	{
		echo "# Generated by secret sync script on $(date)"
		echo
		echo "SECRETS=\$(kamal secrets fetch --adapter bitwarden-sm ${project_id}/all)"
		echo
		echo "# Extract each secret from the fetched block"
		echo "KAMAL_REGISTRY_PASSWORD=\$(kamal secrets extract KAMAL_REGISTRY_PASSWORD \$SECRETS)"
	} >>"$tmp_file"

	# Loop through the required keys and add an extract command for each
	local -a keys_array
	readarray -t keys_array <<<"$required_keys_string"
	for key in "${keys_array[@]}"; do
		key=$(echo "$key" | xargs)
		if [ -n "$key" ]; then
			echo "${key}=\$(kamal secrets extract ${key} \$SECRETS)" >>"$tmp_file"
		fi
	done

	# Move the temporary file to the final destination
	mv "$tmp_file" "$secrets_file"
	echo "   - Successfully updated '$secrets_file'." >&2
}

# --- Script Execution ---
main "$@"
