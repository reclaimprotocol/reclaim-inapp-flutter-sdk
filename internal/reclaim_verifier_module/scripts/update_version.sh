#!/usr/bin/env bash

file="pubspec.yaml"
minor_flag=false
patch_flag=false

# Check for flags
if [[ "$1" == "--minor" ]]; then
    minor_flag=true
elif [[ "$1" == "--patch" ]]; then
    patch_flag=true
fi

version_line=$(grep "^version:" $file)
current_version=$(echo $version_line | cut -d' ' -f2)
IFS='+' read -ra version_parts <<< "$current_version"

version=${version_parts[0]}
build=$((${version_parts[1]} + 1))  # Always increment build number

IFS='.' read -ra version_numbers <<< "$version"
major=${version_numbers[0]}
minor=${version_numbers[1]}
patch=${version_numbers[2]}

if $minor_flag; then
    # Bump minor version
    minor=$((minor + 1))
    patch=0
elif $patch_flag; then
    # Bump patch version
    patch=$((patch + 1))
fi

new_version="$major.$minor.$patch+$build"

# Use different sed syntax for macOS (BSD) and Linux (GNU)
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/^version:.*/version: $new_version/" $file
else
    sed -i "s/^version:.*/version: $new_version/" $file
fi

echo "Updated version. New version: $new_version"
