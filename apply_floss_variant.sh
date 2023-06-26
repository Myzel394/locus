sed -i -e 's/^#f//' pubspec.yaml
sed -i -e 's/^\/\/f //' android/app/build.gradle
sed -i -e '/<!-- GMS -->/{N;d;}' android/app/src/main/AndroidManifest.xml
