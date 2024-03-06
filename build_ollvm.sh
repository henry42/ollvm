#!/bin/bash
VERSION=17.0.6
CmakeExe="cmake"
BuildRootPath="build"
SourceRootPath="${BuildRootPath}/llvm-project-llvmorg-${VERSION}"
OllvmSourceRootPath="${BuildRootPath}/ollvm17-${VERSION}"
mkdir -p "${BuildRootPath}"

if [ ! -d "${SourceRootPath}" ];then
    pushd "${BuildRootPath}" > /dev/null
    wget "https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-${VERSION}.zip" -O "llvmorg-${VERSION}.zip"
    unzip "llvmorg-${VERSION}.zip"
    wget "https://github.com/DreamSoule/ollvm17/archive/refs/tags/${VERSION}.zip" -O "ollvm-${VERSION}.zip"
    unzip ollvm-${VERSION}.zip
    popd > /dev/null
    cp -R "$OllvmSourceRootPath/llvm-project/" $SourceRootPath
fi


projectDir="${BuildRootPath}/project"
buildDir="${BuildRootPath}/output"

if [ -d $projectDir ]
then
    echo "Removing existing Project directory : $projectDir ..."
    rm -rf "$projectDir"
fi
if [ -d $buildDir ]
then
    echo "Removing existing Build directory : $buildDir ..."
    rm -rf "$buildDir"
fi

echo "Creating Project directory : $projectDir ..."
mkdir -p $projectDir
echo "Creating Build directory : $buildDir ..."
mkdir -p $buildDir
buildFullPath=$(realpath "./$buildDir")

echo "Patching LLVM Source Files..."

patchFile="$SourceRootPath/llvm/include/llvm/IR/Function.h"

if [ ! -f "$patchFile.orig" ]
then
    cp "$patchFile" "$patchFile.orig"
else 
    cp "$patchFile.orig" "$patchFile"
fi

sed -i "" 's/const BasicBlockListType/public:\n\tconst BasicBlockListType/' "$patchFile"

echo "Generating Project Files ..."
pushd $projectDir > /dev/null

# -DLLVM_INCLUDE_TOOLS=OFF
# -DLLVM_INCLUDE_UTILS=OFF
$CmakeExe \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_INSTALL_PREFIX="$buildFullPath" \
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
    "../../$SourceRootPath/llvm"
if [ $? -ne 0 ]; then
    echo "Project Generation failed !"
    popd > /dev/null
    exit 1
fi

echo "Building LLVM ..."
$CmakeExe --build . --target install-clang install-lld

if [ $? -ne 0 ]; then
    echo "Compilation failed !"
    popd > /dev/null
    exit 1
fi
popd > /dev/null

echo "Successfully built LLVM !"