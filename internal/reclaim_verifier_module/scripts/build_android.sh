#!/usr/bin/env bash

set -ex;

export VERSION=$(grep '^version:' pubspec.yaml | sed -e 's/version: //')

DIST_ANDROID=./dist/android/$VERSION

mkdir -p debug/android/

KOTLIN_VERSION="2.0.21"

## Downgrade the Kotlin version in your settings.gradle to the lowest Kotlin version we intend to support.
sed -i '' "s/id \"org\.jetbrains\.kotlin\.android\" version \".*\"/id \"org\.jetbrains\.kotlin\.android\" version \"$KOTLIN_VERSION\"/" ./.android/settings.gradle;

# Force kotlin compiler version
# Use python for robust multi-line string replacement
python3 - <<EOF
import sys
import os

file_path = "./.android/build.gradle"

# The exact block you want to find
search_text = """allprojects {
    repositories {
        google()
        mavenCentral()
    }
}"""

# The block you want to replace it with
replace_text = """allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.all {
        resolutionStrategy {
            // Force the standard library to match your compiler version
            force "org.jetbrains.kotlin:kotlin-stdlib:$KOTLIN_VERSION"
            force "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$KOTLIN_VERSION"
            force "org.jetbrains.kotlin:kotlin-stdlib-jdk8:$KOTLIN_VERSION"
        }
    }
}"""

try:
    with open(file_path, 'r') as f:
        content = f.read()

    # Check if the replacement is already there to prevent duplication
    if "force \"org.jetbrains.kotlin:kotlin-stdlib:2.0.21\"" in content:
        print(f"Skipping {file_path}: Fix already applied.")
        sys.exit(0)

    # Perform the replacement
    if search_text in content:
        new_content = content.replace(search_text, replace_text)
        with open(file_path, 'w') as f:
            f.write(new_content)
        print(f"Success: Patched {file_path}")
    else:
        print(f"Warning: Could not find the exact 'allprojects' block in {file_path}.")
        print("Ensure the indentation (spaces) matches exactly.")
        sys.exit(1)

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
EOF

flutter build aar --build-number=$VERSION; # --split-debug-info=debug/android/v$VERSION
rm -rf $DIST_ANDROID
mkdir -p $DIST_ANDROID
mv build/host/outputs/repo/ $DIST_ANDROID/repo
