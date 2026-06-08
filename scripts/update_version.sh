#!/bin/bash

# Simple script to update app version in pubspec.yaml
if [ -z "$1" ]; then
    echo "Usage: ./update_version.sh 1.1.0+2"
    exit 1
fi

NEW_VERSION=$1
sed -i "s/version: .*/version: $NEW_VERSION/" pubspec.yaml

echo "✅ Version updated to $NEW_VERSION"
