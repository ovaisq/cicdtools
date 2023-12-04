#!/bin/bash
function announce_host() {
    # echo the ip address of the current linux host
    ip -o -4 -f inet addr | \
    grep eth | \
    sed -e 's/^.*inet //' -e 's/\/16.*$//';
}

function lower() {
    # pass through so you don't have to remember how to lowcase a string
    tr '[:upper:]' '[:lower:]';
}

function env_file() {
    # find the correct .env.* file for the current TARGET
    echo ".env.${TARGET}" | lower;
}

function grab_env() {
    # Find the variable that exactly matches the first argument
    # in a .env.target file
    # Tech notes:
    #   Removes the TARGET string from the front of all variables before match
    #   variables that don't match are left alone.
    cat $(env_file) | \
    sed -e "s/^${TARGET}_//" | \
    grep "^$1=" | \
    sed -e 's/^.*=//';
}
