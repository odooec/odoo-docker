#!/bin/bash
set -e

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=("--config=${ODOO_RC}")

ADDONS=("/usr/lib/python3/dist-packages/odoo/addons/" "/mnt/repos")

# Install requirements.txt and oca_dependencies.txt from root of mount
if [[ "${SKIP_DEPENDS}" != "1" ]] ; then
    export VERSION=$VERSION
    clone_oca_dependencies /mnt/repos /tmp

    # Iterate the newly cloned addons & add into possible dirs
    for dir in /mnt/repos/* ; do
      ADDONS+=("${dir}")
    done
    VALID_ADDONS="$(getaddons.py ${ADDONS[@]})"
    DB_ARGS+=("--addons-path=${VALID_ADDONS}")
fi

function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec gosu odoo /usr/bin/odoo "$@"
        else
            exec gosu odoo /usr/bin/odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        exec gosu odoo /usr/bin/odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
