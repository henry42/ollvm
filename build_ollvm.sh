#!/bin/bash
# set -e

VERSION=19.1.6
CMAKE_EXEC="cmake"
BASE_DIR=$(cd $(dirname $(readlink -f $0));pwd)
BUILD_ROOT_PATH="${BASE_DIR}/build"
SOURCE_ROOT_PATH="${BUILD_ROOT_PATH}/llvm-project-${VERSION}.src"
mkdir -p "${BUILD_ROOT_PATH}"

if [ ! -d "${SOURCE_ROOT_PATH}" ];then
    pushd "${BUILD_ROOT_PATH}" > /dev/null
    wget "https://github.com/llvm/llvm-project/releases/download/llvmorg-${VERSION}/llvm-project-${VERSION}.src.tar.xz" -O "llvm-${VERSION}.tar.xz"
    tar xvjf "llvm-${VERSION}.tar.xz"
    wget "https://github.com/user-attachments/files/18228906/passes.patch.zip" -O "passes.patch.zip"
    pushd "$SOURCE_ROOT_PATH/llvm/lib/Passes" > /dev/null
    unzip -o "${BUILD_ROOT_PATH}/passes.patch.zip"
    popd > /dev/null
    popd > /dev/null
fi

PROJECT_DIR="${BUILD_ROOT_PATH}/project"
OUTPUT_DIR="${BUILD_ROOT_PATH}/output"

if [ -d $PROJECT_DIR ]
then
    echo "Removing existing project directory : $PROJECT_DIR ..."
    rm -rf "$PROJECT_DIR"
fi
if [ -d $OUTPUT_DIR ]
then
    echo "Removing existing output directory : $OUTPUT_DIR ..."
    rm -rf "$OUTPUT_DIR"
fi

echo "Creating project directory : $PROJECT_DIR ..."
mkdir -p $PROJECT_DIR
echo "Creating output directory : $OUTPUT_DIR ..."
mkdir -p $OUTPUT_DIR


echo "Generating project files ..."
pushd $PROJECT_DIR > /dev/null

$CMAKE_EXEC \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" \
    \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_RUNTIMES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    \
    -DLLVM_BUILD_BENCHMARKS=OFF \
    -DLLVM_BUILD_EXAMPLES=OFF \
    -DLLVM_BUILD_RUNTIME=OFF \
    -DLLVM_BUILD_RUNTIMES=OFF \
    -DLLVM_BUILD_TESTS=OFF \
    -DLLVM_BUILD_TOOLS=OFF \
    -DLLVM_BUILD_UTILS=OFF \
    \
    -DLLVM_BUILD_LLVM_DYLIB=OFF \
    \
    -DLLVM_ENABLE_PIC=False \
    -DLLVM_ENABLE_EH=OFF \
    -DLLVM_ENABLE_RTTI=OFF \
    \
    -G "Ninja" \
    \
    "$SOURCE_ROOT_PATH/llvm/"
if [ $? -ne 0 ]; then
    echo "Project generation failed !"
    popd > /dev/null
    exit 1
fi

echo "Building LLVM ..."
$CMAKE_EXEC --build . --target install-clang install-lld

if [ $? -ne 0 ]; then
    echo "Compilation failed !"
    popd > /dev/null
    exit 1
fi
popd > /dev/null

echo "Successfully built LLVM !"