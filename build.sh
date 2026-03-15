#!/bin/bash

echo "Cloning Flutter Stable..."
if cd flutter; then git pull && cd .. ; else git clone https://github.com/flutter/flutter.git -b stable ; fi

echo "Exporting Flutter path..."
export PATH="$PATH:`pwd`/flutter/bin"

echo "Checking Flutter version..."
flutter --version

echo "Getting dependencies..."
flutter pub get

echo "Building for Web..."
flutter build web --release
