#!/usr/bin/env bash


export REST_PROTO="http"
function proto() { REST_PROTO="${1}"; }
typeset -fx proto

export REST_HOST="localhost"
function host() { REST_HOST="${1}"; }
typeset -fx host

export REST_USER
function user() { REST_USER="${1}"; }
typeset -fx user
export REST_PASS
function pass() { REST_PASS="${1}"; }
typeset -fx pass

export REST_BASE="/"
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

function _curl() {
	rest_method="${1} ${2}"
	shift 2
	if [[ "${REST_USER}" ]]; then
		rest_auth="-u '${REST_USER}'"
	fi
	if [[ "${REST_PASS}" ]]; then
		rest_auth="${rest_auth}:'${REST_PASS}'"
	fi

	rest_url="${REST_PROTO}://${REST_HOST}${REST_BASE}"
	if [[ "${1}" ]]; then
		rest_url="${rest_url%%/}/${1}"
	fi

	if [[ "${REST_ACCEPT}" ]]; then
		rest_accept="-H '${REST_ACCEPT}'"
	fi
	
	echo curl $rest_auth $rest_method $rest_accept $rest_url
}
typeset -fx _curl

function get() {
	_curl -X GET $*
}
typeset -fx get


function prompt() {
	if [[ "${REST_USER}" ]]; then
		echo "${REST_PROTO}://${REST_USER}@${REST_HOST}${REST_BASE}"
	else
		echo "${REST_PROTO}://${REST_HOST}${REST_BASE}"
	fi
}
typeset -fx prompt

export PS1="\[\e[45m\e[1;35m\][\[\e[1;37m\]\$(prompt)\[\e[1;35m\]]\[\e[0m\]\n"

exec bash
