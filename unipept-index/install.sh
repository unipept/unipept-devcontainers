#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# and ensure failing commands in pipes are also detected
set -euo pipefail

# Function to handle errors and exit gracefully
error_exit() {
    echo "Error: $1"
    exit 1
}

# Function to handle any error that occurs during execution
trap 'error_exit "An unexpected error occurred."' ERR

# Define variables
FEATURE_DIR="/unipept-index-data"
VERSION_OPTION="${VERSION:-latest}"
GITHUB_API="https://api.github.com/repos/unipept/unipept-index/releases"

# Create the feature directory if it doesn't exist
mkdir -p "$FEATURE_DIR"

# Function to get releases from GitHub
get_releases() {
    curl -s "$GITHUB_API" | jq -r '.[] | .tag_name' || error_exit "Failed to retrieve releases from GitHub."
}

# Function to download and extract the specified version
download_and_extract() {
    local version=$1
    local release_url
    local zip_file_name
    local zip_file

    # Construct the expected ZIP file name based on the version date
    zip_file_name="index_SP_${version}.zip"

    # Get the release URL for the specific ZIP file
    release_url=$(curl -s "$GITHUB_API" | jq -r --arg zip_name "$zip_file_name" '.[] | .assets[] | select(.name == $zip_name) | .browser_download_url')

    # Check if release URL is found
    if [ -z "$release_url" ]; then
        error_exit "No release found for version $version with the expected ZIP file: $zip_file_name."
    fi

    zip_file="${FEATURE_DIR}/$(basename "$release_url")"
    echo "Downloading $zip_file..."

    # Perform the curl command
    curl -L -o "$zip_file" "$release_url"
    # Check if curl command succeeded
    if [ $? -ne 0 ]; then
        error_exit "Failed to download $zip_file."
    fi

    echo "Extracting $zip_file to $FEATURE_DIR..."

    # Perform the unzip command
    unzip -o "$zip_file" -d "$FEATURE_DIR"
    # Check if unzip command succeeded
    if [ $? -ne 0 ]; then
        error_exit "Failed to extract $zip_file."
    fi

    # Remove the ZIP file
    rm "$zip_file"
    # Check if removal succeeded
    if [ $? -ne 0 ]; then
        error_exit "Failed to remove $zip_file after extraction."
    fi

    # Store the version in the .VERSION file
    echo "$version" > "$FEATURE_DIR/.VERSION" || error_exit "Failed to write version to .VERSION file."
}

# Function to list the last 10 releases
list_last_10_releases() {
    echo "Available releases:"
    get_releases | head -n 10 || error_exit "Failed to list the last 10 releases."
}

# Determine which version to download
download_version() {
    if [ "$VERSION_OPTION" = "latest" ]; then
        # Get the latest version
        latest_version=$(get_releases | head -n 1) || error_exit "Failed to determine the latest version."

        # Extract the date part from the latest version
        latest_version_date=${latest_version#*SP_}; latest_version_date=${latest_version_date%.zip}

        download_and_extract "$latest_version_date"
        echo "Successfully downloaded and extracted the latest version: $latest_version_date"
    else
        # Attempt to download the specified version
        download_and_extract "$VERSION_OPTION" || {
            echo "No release available for the specified date: $VERSION_OPTION"
            list_last_10_releases
            exit 1
        }
    fi
}

# Call the function to download the specified version
download_version
