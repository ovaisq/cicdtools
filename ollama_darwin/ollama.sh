#!/usr/bin/env bash
export OLLAMA_HOST=0.0.0.0
export OLLAMA_NUM_PARALLEL=4
export OLLAMA_MAX_LOADED_MODELS=4
/opt/homebrew/bin/ollama $1
