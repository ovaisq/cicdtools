#!/usr/bin/env bash

# get version information from here
# https://github.com/ollama/ollama/releases

version="0.3.3"
ollama_url="https://github.com/ollama/ollama/releases/download/v${version}/ollama-darwin"

# bypassing brew install - this way I am able to install RC builds
# I froze brew install at 0.1.32
# I am sure this can be done much better - but for me this gets
# job done
brew_cellar="/opt/homebrew/Cellar/ollama/0.1.32"

# sudo login 
sudo ls -1 > /dev/null

# Check current version
ollama -v

# Remove old versions
rm -f ollama-darwin*

# Stop the Ollama service
brew services stop ollama

# Download the new version
wget ${ollama_url}

# Copy the plist file to the Cellar directory
cp homebrew.mxcl.ollama.plist "${brew_cellar}"/

# Make the downloaded binary executable
chmod +x ollama-darwin

# Copy the new version to the bin directory
sudo cp ollama-darwin /opt/homebrew/bin/ollama

# Copy the shell script to the Cellar directory
cp ollama.sh "${brew_cellar}/bin/"

# Restart the Ollama service
brew services stop ollama && brew services start ollama

sleep 5

# Check new version
ollama -v
