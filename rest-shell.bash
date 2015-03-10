#!/usr/bin/env bash


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

export REST_USER
function user() { REST_USER="${1}"; }
typeset -fx user
export REST_PASS
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

export REST_ACCEPT
function accept() {
	local IFS=";"
	REST_ACCEPT="$*"
}
typeset -fx accept

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
	rest_method="${1}"
	shift
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
		rest_accept="-HAccept: ${REST_ACCEPT}"
	fi
	
	command=(curl "${rest_auth}" "${rest_method}" "${rest_accept}" "${rest_url}")
	echo "${command[@]}" >&2
	"${command[@]}"
	echo
}
${rest_method} typeset -fx _curl

function get() {
	_curl -XGET $*
}
typeset -fx get

function put() {
	_curl -XPUT $*
}
typeset -fx put

function post() {
	_curl -XPOST $*
}
typeset -fx post

function delete() {
	_curl -XDELETE $*
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

function _pg(){
	first="${1}"
	shift
	echo '\[\e\e[1;35m\]['"${first}"'\[\e[1;37m\]'"${*}"'\[\e[1;35m\]]'
}
typeset -fx _pg

export PS1="\[\e[45m\]$(_pg '' '$(prompt)')$(_pg 'A:' \${REST_ACCEPT})    $(_pg '' '\w')\[\e[0m\]\n"

exec bash
