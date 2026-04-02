#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"

apply_repo_patch() {
    local repo_dir="$1"
    local patch_file="$2"

    if git -C "$repo_dir" apply --reverse --check "$patch_file" >/dev/null 2>&1; then
        return
    fi

    git -C "$repo_dir" apply --check "$patch_file"
    git -C "$repo_dir" apply "$patch_file"
}

find_cmake() {
    if command -v cmake >/dev/null 2>&1; then
        command -v cmake
        return
    fi

    local sdk_root="${ANDROID_SDK_ROOT:-$HOME/Develop/android/sdk}"
    local candidates=(
        /opt/homebrew/bin/cmake
        /usr/local/bin/cmake
        "$sdk_root/cmake/3.22.1/bin/cmake"
        "$sdk_root/cmake/3.18.1/bin/cmake"
    )

    for candidate in "${candidates[@]}"; do
        if [ -x "$candidate" ]; then
            echo "$candidate"
            return
        fi
    done

    echo "cmake not found" >&2
    exit 1
}

cmake_bin="$(find_cmake)"

if [ ! -d third_party ]; then
    mkdir third_party
fi
cd third_party

if [ ! -d ios-cmake ]; then
    git clone https://github.com/leetal/ios-cmake.git
    cd ios-cmake
    git checkout a7a5dd0e9ca8e818c0d73a1d3da06d830fa45970
    cd ..
fi

if [ ! -d sfizz ]; then
    git clone https://github.com/sfztools/sfizz.git
    cd sfizz
    git checkout fc1f0451cebd8996992cbc4f983fcf76b03295c5
    git submodule update --init --recursive
    cd ..
fi

cd sfizz

apply_repo_patch "$PWD" "$script_dir/../patches/sfizz-ios-compat.patch"

if [ -f build/CMakeCache.txt ]; then
    rm -rf build
fi

mkdir -p build
cd build

"$cmake_bin" \
    -DCMAKE_BUILD_TYPE=Release \
    -DSFIZZ_JACK=OFF \
    -DSFIZZ_RENDER=OFF \
    -DSFIZZ_LV2=OFF \
    -DSFIZZ_LV2_UI=OFF \
    -DSFIZZ_VST=OFF \
    -DSFIZZ_AU=OFF \
    -DSFIZZ_SHARED=OFF \
    -DCMAKE_TOOLCHAIN_FILE=../../ios-cmake/ios.toolchain.cmake \
    -DAPPLE_APPKIT_LIBRARY=/System/Library/Frameworks/AppKit.framework \
    -DAPPLE_CARBON_LIBRARY=/System/Library/Frameworks/Carbon.framework \
    -DAPPLE_COCOA_LIBRARY=/System/Library/Frameworks/Cocoa.framework \
    -DAPPLE_OPENGL_LIBRARY=/System/Library/Frameworks/OpenGL.framework \
    -DPLATFORM=OS64COMBINED \
    -G Xcode \
    ..

xcodebuild \
    -project sfizz.xcodeproj \
    -scheme ALL_BUILD \
    -xcconfig ../../../overrides.xcconfig \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -destination "generic/platform=iOS Simulator"

device_libs=(**/Release-iphoneos/*.a(N))
simulator_libs=(**/Release-iphonesimulator/*.a(N))

rm -f libsfizz_all_iphoneos.a libsfizz_all_iphonesimulator.a libsfizz_fat.a

libtool -static -o libsfizz_all_iphoneos.a $device_libs
libtool -static -o libsfizz_all_iphonesimulator.a $simulator_libs
lipo -create libsfizz_all_iphoneos.a libsfizz_all_iphonesimulator.a -output libsfizz_fat.a
