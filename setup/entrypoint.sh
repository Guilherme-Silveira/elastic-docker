#!/usr/bin/env bash

set -eu
set -o pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"


# --------------------------------------------------------
# Users declarations

declare -A users_passwords
users_passwords=(
	[logstash_internal]="${LOGSTASH_INTERNAL_PASSWORD:-}"
	[kibana_system]="${KIBANA_SYSTEM_PASSWORD:-}"
)

declare -A users_roles
users_roles=(
	[logstash_internal]='logstash_writer'
)

# --------------------------------------------------------
# Roles declarations

declare -A roles_files
roles_files=(
	[logstash_writer]='logstash_writer.json'
)

# --------------------------------------------------------
# Certificate creation
if [ ! -f config/certs/ca.zip ]; then
	echo "Creating CA";
	bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
	unzip config/certs/ca.zip -d config/certs;
fi;
if [ ! -f config/certs/certs.zip ]; then
	echo "Creating certs";
	echo -ne \
	"instances:\n"\
	"  - name: es01\n"\
	"    dns:\n"\
	"      - es01\n"\
	"      - localhost\n"\
	"    ip:\n"\
	"      - 127.0.0.1\n"\
	"  - name: es02\n"\
	"    dns:\n"\
	"      - es02\n"\
	"      - localhost\n"\
	"    ip:\n"\
	"      - 127.0.0.1\n"\
	"  - name: es03\n"\
	"    dns:\n"\
	"      - es03\n"\
	"      - localhost\n"\
	"    ip:\n"\
	"      - 127.0.0.1\n"\
	"  - name: es04\n"\
	"    dns:\n"\
	"      - es04\n"\
	"      - localhost\n"\
	"    ip:\n"\
	"      - 127.0.0.1\n"\
	> config/certs/instances.yml;
	bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
	unzip config/certs/certs.zip -d config/certs;
fi;
echo "Setting file permissions"

# --------------------------------------------------------


echo "-------- $(date) --------"


log 'Waiting for availability of Elasticsearch'
wait_for_elasticsearch
sublog 'Elasticsearch is running'

state_file="$(dirname ${BASH_SOURCE[0]})/state/.done"
if [[ -e "$state_file" ]]; then
	log "State file exists at '${state_file}', skipping setup"
	exit 0
fi

for role in "${!roles_files[@]}"; do
	log "Role '$role'"

	declare body_file
	body_file="$(dirname "${BASH_SOURCE[0]}")/roles/${roles_files[$role]:-}"
	if [[ ! -f "${body_file:-}" ]]; then
		sublog "No role body found at '${body_file}', skipping"
		continue
	fi

	sublog 'Creating/updating'
	ensure_role "$role" "$(<"${body_file}")"
done

for user in "${!users_passwords[@]}"; do
	log "User '$user'"
	if [[ -z "${users_passwords[$user]:-}" ]]; then
		sublog 'No password defined, skipping'
		continue
	fi

	declare -i user_exists=0
	user_exists="$(check_user_exists "$user")"

	if ((user_exists)); then
		sublog 'User exists, setting password'
		set_user_password "$user" "${users_passwords[$user]}"
	else
		if [[ -z "${users_roles[$user]:-}" ]]; then
			err '  No role defined, skipping creation'
			continue
		fi

		sublog 'User does not exist, creating'
		create_user "$user" "${users_passwords[$user]}" "${users_roles[$user]}"
	fi
done

create_snapshot_repo

create_slm_policy

mkdir -p "$(dirname "${state_file}")"
touch "$state_file"
