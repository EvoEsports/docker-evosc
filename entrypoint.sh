#!/bin/bash

set -e

# we don't want to start EvoSC with root permissions
if [ "$2" = 'esc' -a "$(id -u)" = '0' ]; then
	chown -R evosc /controller/esc
	exec su-exec evosc "$0" "$@"
fi

if [ "$2" = 'esc' ]; then
    [ ! -f /controller/config/evosc.config.json ] && cp /controller/config/default/evosc.config.json /controller/config/evosc.config.json
	[ ! -f /controller/config/theme.config.json ] && cp /controller/config/default/theme.config.json /controller/config/theme.config.json
	[ ! -f /controller/config/database.config.json ] && cp /controller/config/default/database.config.json /controller/config/database.config.json
	[ ! -f /controller/config/server.config.json ] && cp /controller/config/default/server.config.json /controller/config/server.config.json

	databaseConfig=()
	databaseConfig+=('.host = '\"${DB_HOST}\"'')
	databaseConfig+=('| .db = '\"${DB_NAME}\"'')
	databaseConfig+=('| .user = '\"${DB_USER}\"'')
	databaseConfig+=('| .password = '\"${DB_PASSWORD}\"'')

	eval jq \'${databaseConfig[@]}\' /controller/config/database.config.json > /controller/config/database.config.json.tmp
	mv /controller/config/database.config.json.tmp /controller/config/database.config.json

	serverConfig=()
	serverConfig+=('.ip = '\"${RPC_IP}\"'')
	serverConfig+=('| .port = '\"${RPC_PORT:-5000}\"'')
	serverConfig+=('| .rpc.login = '\"${RPC_LOGIN:-SuperAdmin}\"'')
	serverConfig+=('| .rpc.password = '\"${RPC_PASSWORD:-SuperAdmin}\"'')
	serverConfig+=('| .["default-matchsettings"] = '\"${GAME_SETTINGS:-default.txt}\"'')

	eval jq \'${serverConfig[@]}\' /controller/config/server.config.json > /controller/config/server.config.json.tmp
	mv /controller/config/server.config.json.tmp /controller/config/server.config.json

	[ ! -f /controller/cache/.setupfinished ] && touch /controller/cache/.setupfinished
fi

exec "$@"