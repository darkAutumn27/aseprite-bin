name: Build Aseprite

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: windows-latest

    env:
      ASEPRITE_VERSION: v1.3.14.1
      SKIA_VERSION: m124-08a5439a6b

    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Set up MSVC environment
      uses: ilammy/msvc-dev-cmd@v1

    - name: Install dependencies
      run: |
        choco install 7zip ninja cmake jq curl python -y

    - name: Fetch Aseprite source
      run: |
        git clone --recursive -b %ASEPRITE_VERSION% https://github.com/aseprite/aseprite.git

        # Patch version file
        python -c "v = open('aseprite/src/ver/CMakeLists.txt').read(); open('aseprite/src/ver/CMakeLists.txt', 'w').write(v.replace('1.x-dev', '%ASEPRITE_VERSION%'[1:]))"

    - name: Download Skia
      run: |
        curl -L -o skia.zip https://github.com/aseprite/skia/releases/download/%SKIA_VERSION%/Skia-Windows-Release-x64.zip
        7z x skia.zip -oskia-%SKIA_VERSION%

    - name: Configure CMake
      run: |
        cmake ^
          -G Ninja ^
          -S aseprite ^
          -B build ^
          -DCMAKE_BUILD_TYPE=Release ^
          -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded ^
          -DLAF_BACKEND=skia ^
          -DSKIA_DIR=%cd%\skia-%SKIA_VERSION% ^
          -DSKIA_LIBRARY_DIR=%cd%\skia-%SKIA_VERSION%\out\Release-x64 ^
          -DSKIA_LIBRARY=%cd%\skia-%SKIA_VERSION%\out\Release-x64\skia.lib ^
          -DSKIA_OPENGL_LIBRARY=opengl32.lib

    - name: Build Aseprite
      run: ninja -C build

    - name: Package Artifacts
      run: |
        mkdir aseprite-build
        echo # portable build > aseprite-build\aseprite.ini
        xcopy /E /Q /Y build\bin\aseprite.exe aseprite-build\
        xcopy /E /Q /Y build\bin\data aseprite-build\data\
        xcopy /E /Q /Y aseprite\docs aseprite-build\docs\

    - name: Upload Artifacts
      uses: actions/upload-artifact@v4
      with:
        name: aseprite-windows-build
        path: aseprite-build
