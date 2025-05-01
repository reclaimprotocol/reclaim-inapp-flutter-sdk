#!/usr/bin/env bash

file="pubspec.yaml"
version_line=$(grep "^version:" $file)
current_version=$(echo $version_line | cut -d' ' -f2)
IFS='.' read -ra version_parts <<< "${current_version%+*}"
IFS='+' read -ra build_parts <<< "$current_version"

major=${version_parts[0]}
minor=${version_parts[1]}
patch=${version_parts[2]}
build=$((${build_parts[1]} + 1))

if [[ $1 == "--minor" ]]; then
    minor=$((minor + 1))
    patch=0
elif [[ $1 == "--patch" ]] || [[ $# -eq 0 ]]; then
    patch=$((patch + 1))
fi

new_version="$major.$minor.$patch"

if [[ $1 == '--build' ]] || [[ $2 == '--build' ]]; then
    new_version="$new_version+$build"
fi

# Use different sed syntax for macOS (BSD) and Linux (GNU)
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/^version:.*/version: $new_version/" $file
else
    sed -i "s/^version:.*/version: $new_version/" $file
fi

echo "Updated version from $current_version to $new_version"
