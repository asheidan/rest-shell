#!/usr/bin/env bash

if [[ $_ != $0 ]]; then
	echo "Setting up variables for resting"
	script_sourced=1
else
	echo "Launching rest-shell"
	REST_SCRIPT="${0}"
	if [[ "${REST_SCRIPT}" != /* ]]; then
		REST_SCRIPT="$(pwd)/${REST_SCRIPT}"
	fi
fi
export REST_SCRIPT

function _reload() {
	source "${REST_SCRIPT}"
}
typeset -fx _reload


function help() {
	cat <<EOF
Help for rest-shell

Commands:
   accept   Sets the Accept-header for all calls
   proto    Sets the protocol used for calls
   user     Sets or removes user used for basic authentication
   pass     Sets or removes user used for basic authentication
   get      Perform a GET with the current settings, also possible
            to give path as parameter
   rcd      Change the uri
   delete   Perform a DELETE request
   post     Perform a POST request
   put      Perform a PUT request
   pretty   Formats data read on stdin according to the current accept
            headers set
EOF
}
typeset -fx help


export REST_PROTO=${REST_PROTO:-"http"}
function proto() { REST_PROTO="${1}"; }
typeset -fx proto

export REST_HOST=${REST_HOST:-"localhost"}
function host() { REST_HOST="${1}"; }
typeset -fx host

export REST_USER=${REST_USER}
function user() { REST_USER="${1}"; }
typeset -fx user
export REST_PASS=${REST_PASS}
function pass() { REST_PASS="${1}"; }
typeset -fx pass

export REST_BASE=${REST_BASE:-"/"}
function rcd() {
	# TODO: error on more than one argument (or loop?)
	if [[ ".." = "${1}" ]]; then
		REST_BASE=$(dirname "${REST_BASE}")
	else
		REST_BASE="${REST_BASE%%/}/${1}"
	fi
}
typeset -fx rcd

export REST_ACCEPT=${REST_ACCEPT}
function accept() {
	local IFS=";"
	REST_ACCEPT="$*"
}
typeset -fx accept

export REST_CONTENT=${REST_CONTENT}
function content() {
	local IFS=";"
	REST_CONTENT="$*"
}
typeset -fx content

export REST_VERBOSE=${REST_VERBOSE:-0}
function verbose() {
	if [[ 1 -eq ${REST_VERBOSE} ]]; then
		echo "Resetting verbosity level" >&2
		REST_VERBOSE=0
	else
		REST_VERBOSE=$((REST_VERBOSE+1))
		echo "Increasing verbosity level to ${REST_VERBOSE}" >&2
	fi
}
typeset -fx verbose

export REST_INSECURE=${REST_INSECURE:-1}
function insecure() {
	if [[ 1 -eq ${REST_INSECURE} ]]; then
		echo "Verify certificates" >&2
		REST_INSECURE=0
	else
		REST_INSECURE=$((REST_INSECURE+1))
		echo "Do not verify certificates" >&2
	fi
}
typeset -fx insecure


function pretty() {
	case "${REST_ACCEPT}" in
		"application/json" )
			python -m json.tool ;;
		"application/xml" )
			xmllint -format - ;;
		* )
			cat ;;
	esac
}
typeset -fx pretty

function _curl() {
	local OPTIND opt headers method command
	declare -a headers=()
	declare -a command=(curl)

	while getopts ":F:H:X:" opt; do
		case "${opt}" in
			"F")
				data_file="${OPTARG}"
				;;
			"H")
				headers+=(-H ${OPTARG})
				;;
			"X")
				echo "Method: '${OPTARG}'" >&2
				method=$OPTARG
				;;
			"?")
				echo "Invalid option: -${OPTARG}." >&2
				return
				;;
			":")
				echo "Option -$OPTARG requires an argument." >&2
				return
				;;
		esac
	done
	shift $((OPTIND-1))
	
	if [[ "${REST_USER}" ]]; then
		rest_auth="-u${REST_USER}"
	fi
	if [[ "${REST_PASS}" ]]; then
		rest_auth="${rest_auth}:${REST_PASS}"
	fi

	rest_url="${REST_PROTO}://${REST_HOST}${REST_BASE}"
	if [[ "${1}" ]]; then
		rest_url="${rest_url%%/}/${1}"
	fi

	if [[ "${REST_ACCEPT}" ]]; then
		headers+=("-H" "Accept: ${REST_ACCEPT}")
	fi

	if [[ "${REST_CONTENT}" ]]; then
		headers+=("-H" "Content-type: ${REST_CONTENT}")
	fi

	if [[ 1 -le ${REST_VERBOSE} ]]; then
		command+=(-v)
	fi

	if [[ 1 -le ${REST_INSECURE} ]]; then
		command+=(-k)
	fi

	if [[ "${data_file}" ]]; then
		command+=("--data-binary" "@${data_file}")
	fi
	
	command+=("${rest_auth}" -X "${method}" "${headers[@]}" "${rest_url}")
	echo "${command[@]}" >&2
	"${command[@]}"
	echo
}
typeset -fx _curl

function get() {
	_curl -X GET $*
}
typeset -fx get

function put() {
	_curl -X PUT $*
}
typeset -fx put

function post() {
	_curl -X POST $*
}
typeset -fx post

function delete() {
	_curl -X DELETE $*
}
typeset -fx delete

function prompt() {
	if [[ "${REST_USER}" ]]; then
		prompt_string="${REST_PROTO}://${REST_USER}@${REST_HOST}${REST_BASE}"
	else
		prompt_string="${REST_PROTO}://${REST_HOST}${REST_BASE}"
	fi

	echo $prompt_string
}
typeset -fx prompt

function _pg() {
	first="${1}"
	shift
	echo '\[\e\e[1;35m\]['"${first}"'\[\e[1;37m\]'"${*}"'\[\e[1;35m\]]'
}
typeset -fx _pg

export PS1="\[\e[45m\]$(_pg '' '$(prompt)')$(_pg 'A:' \${REST_ACCEPT})$(_pg 'C:' \${REST_CONTENT})    $(_pg '' '\w')\[\e[0m\]\n"

# Should we launch bash?
[[ -z "${script_sourced}" ]] && exec bash
