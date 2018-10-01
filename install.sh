#!/bin/sh

set -o nounset    # error when referencing undefined variable
set -o errexit    # exit when command fails

BOLD="$(tput bold 2>/dev/null || echo '')"
GREY="$(tput setaf 0 2>/dev/null || echo '')"
BLUE="$(tput setaf 4 2>/dev/null || echo '')"
RED="$(tput setaf 1 2>/dev/null || echo '')"
NO_COLOR="$(tput sgr0 2>/dev/null || echo '')"
YELLOW="$(tput setaf 3 2>/dev/null || echo '')"

error() {
  printf "${RED} $@${NO_COLOR}\n" >&2
}

warn() {
  printf "${YELLOW}! $@${NO_COLOR}\n"
}

info() {
  printf "${BLUE} $@${NO_COLOR}\n"
}

fetch() {
  local command
  if hash curl 2>/dev/null; then
    set +e
    command="curl --fail -L $1"
    curl --compressed --fail -L "$1"
    rc=$?
    set -e
  else
    if hash wget 2>/dev/null; then
      set +e
      command="wget -O- -q $1"
      wget -O- -q "$1"
      rc=$?
      set -e
    else
      error "No HTTP download program (curl, wget) found…"
      exit 1
    fi
  fi

  if [ $rc -ne 0 ]; then
    error "Command failed (exit code $rc): ${BLUE}${command}${NO_COLOR}"
    exit $rc
  fi
}

get_latest_release() {
  fetch "https://api.github.com/repos/raghur/fruzzy/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

download() {
  cd rplugin/python3
  url="https://github.com/raghur/fruzzy/releases/download/$tag/${1}"
  info "Downloading binary from ${url}"
  if fetch "${url}" > fruzzy_mod.so; then
    return
  else
    warn "Binary not found, please wait for a few minutes."
  fi
}

info "Fetching latest release."
tag=$(get_latest_release)

arch=$(uname -sm)
case "${arch}" in
  "Linux x86_64") download fruzzy_mod.so ;;
  "Linux i686") download fruzzy_mod.so ;;
  "Darwin x86_64") download fruzzy_mod_mac.so ;;
  *) info "No pre-built binary available for ${arch}.";;
esac
