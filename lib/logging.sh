#!/usr/bin/env bash
# logging library

info() {
  echo -e "\033[36mINFO\033[0m  $*"
}

fatal() {
  echo -e "\033[41mFATA  $*\033[0m" >&2
  exit 1
}

error() {
  echo -e "\033[31mERRO\033[0m  $*" >&2
}

warn() {
  echo -e "\033[33mWARN\033[0m  $*" >&2
}