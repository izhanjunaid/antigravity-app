#!/bin/bash
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.19.0-stable.tar.xz | tar xJ
export PATH=$PATH:`pwd`/flutter/bin
git config --global --add safe.directory `pwd`/flutter
flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
