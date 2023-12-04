#!/bin/bash -x
# gbcsha - get the branches that contain a commit sha
# 1 argument is the target, if none specified, the target is domain.com
# The string output contains the branch, and the sha

function target () {
  TARGET=${1:-go}
  [[ ! "${TARGET}" == *"."* ]] && TARGET="${TARGET}.domain.com"
  echo "${TARGET}"
}

function editor_sha () {
  if [ "$#" -gt 1 ]; then
    echo "editor_sha requires exactly one TARGET" > /dev/stderr
    return 1
  fi
  editor_sha="$(lynx --dump https://$(target ${1})/go/svrStatus | grep Editor 2>/dev/null)"
  editor_sha="$(echo $editor_sha | cut -d ':' -f 2 | xargs 2>/dev/null)"
  echo "${editor_sha:-noSHA}"
}

function branch_contains () {
  # Requires a SHA of a branch from within the ember-products repository
  if [[ ! "$#" -eq 1 ]]; then
    echo "Exactly one SHA is required by branch_contains" > /dev/stderr
    return 1
  fi
  cur_dir=$(pwd)
  if [ ! -x ../ember-products/.git ]; then
    cd ..
    git clone git@github.com:domain/ember-products.git > /dev/null 2>&1
  fi
  cd $(dirname "${cur_dir}")/ember-products
  git fetch > /dev/null 2>&1
  git checkout master > /dev/null 2>&1
  git pull > /dev/null 2>&1
  alias gbsha='git branch --remote --contains'
  gbsha "${1}" > /dev/null 2>&1
  if [ "$?" -eq 0 ]; then
    echo "$(gbsha ${1} | egrep -v '(master|HEAD)'  | head -n 1 | sed -e 's/.*origin\///' -e 's/.*remotes\/origin\///' 2>/dev/null)"
  else
    echo "noBRANCH"
  fi
  cd "${cur_dir}"
}

function human_readable_target () {
  if [ "$#" -gt 1 ]; then
    echo "gbcsha requires exactly one TARGET" > /dev/null 2>&1
    return 1
  fi
  ed_sha="$(editor_sha $(target $1))"
  echo "$(branch_contains ${ed_sha})_${ed_sha}" | xargs;
}
