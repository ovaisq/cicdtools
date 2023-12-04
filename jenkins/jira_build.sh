#!/bin/bash
# First pass at a jira_build.sh command which will run the command specified by
# the argument CUCUMBER_CMD against the tags in $TAGS with the format options
# set in the variable FORMAT_OPTIONS - the command must be formatted and
# executed carefully
#
# # Fix npm run test -- npm eats the command arguments poorly
# Convert the TAGS environment variable to the --tags arguments
tags=""
if [ ]! -z "$TAGS" ]; then
  i=0
  tags="--tags '"
  for tag in ${TAGS//,/ }; do
    [ $i -gt 0 ] && tags="${tags} or "
    tags="${tags}${tag}"
    ((i++))
  done
  tags="${tags}'"
fi

# Turn off color output for jenkins
FORMAT_OPTIONS=" --format-options '{\"colorsEnabled\": false}'"

# Use the following eval_command to execute
function eval_command () {
  echo "***** $@ *****";
  let i=0;
  for a in "$@"; do
    echo "argv[$i] = $a";
    ((i++));
  done;
  cmd="$@"
  eval $cmd;
}
# Do we have arguments to pass?  If so include " -- " before the arguments
args=""
[ "${tags} ${FORMAT_OPTIONS}" != " " ] && args="-- ${tags} ${FORMAT_OPTIONS}"

eval_command "${CUCUMBER_CMD} ${args}"
# eval_command ${CUCUMBER_CMD} ${tags}

test_status="$?"
