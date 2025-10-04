#!/bin/bash -ex

cd ./eden

if [ "$TARGET" = "pgogen" ]; then
	# patch to generate profraw
	git apply ../patches/android_pgo_gen.patch
fi

if [ "$OPTIMIZE" = "PGO" ]; then
	# pacth to use prfodata
	git apply ../patches/android_pgo_use.patch

	# merge profraw files with the same version ndk to avoid mismatch
	unzip ../pgo/android.zip -d ../pgo
	/usr/local/lib/android/sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-profdata \
    merge -o ../pgo/android.profdata ../pgo/eden-*.profraw/*
fi

if [ "$TARGET" = "Coexist" ]; then
    # Change the App name and application ID to make it coexist with official build
    sed -i 's/applicationId = "dev\.eden\.eden_emulator"/applicationId = "dev.eden.eden_nightly"/' src/android/app/build.gradle.kts
    sed -i 's/resValue("string", "app_name_suffixed", "Eden")/resValue("string", "app_name_suffixed", "Eden Nightly")/' src/android/app/build.gradle.kts
fi        

if [ "$TARGET" = "Optimised" ]; then
    # Add optimised to the App name
    sed -i 's/resValue("string", "app_name_suffixed", "Eden")/resValue("string", "app_name_suffixed", "Eden Optimised")/' src/android/app/build.gradle.kts
fi 

COUNT="$(git rev-list --count HEAD)"

if [ "$OPTIMIZE" = "PGO" ]; then
	APK_NAME="Eden-${COUNT}-Android-${TARGET}-${OPTIMIZE}"
else
	APK_NAME="Eden-${COUNT}-Android-${TARGET}"
fi

cd src/android
chmod +x ./gradlew
if [ "$TARGET" = "Optimised" ]; then
	./gradlew assembleGenshinSpoofRelease
else
	./gradlew assembleMainlineRelease
fi

APK_PATH=$(find app/build/outputs/apk -type f -name "*.apk" | head -n 1)
mkdir -p artifacts
mv "$APK_PATH" "artifacts/$APK_NAME.apk"
