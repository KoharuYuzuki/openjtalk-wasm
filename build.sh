set -eu

CURRENT_DIR=$(cd $(dirname $0); pwd)
TOOLS_DIR="$CURRENT_DIR/tools"

EMSDK_DIR="$TOOLS_DIR/emsdk"
HTSENGINEAPI_DIR="$TOOLS_DIR/htsengineapi"
OPENJTALK_DIR="$TOOLS_DIR/openjtalk"

EMSDK_REPO="https://github.com/emscripten-core/emsdk.git"
HTSENGINEAPI_REPO="https://github.com/KoharuYuzuki/hts_engine_API.git"
OPENJTALK_REPO="https://github.com/KoharuYuzuki/open_jtalk.git"

mkdir -p "$EMSDK_DIR"
mkdir -p "$HTSENGINEAPI_DIR"
mkdir -p "$OPENJTALK_DIR"

git clone "$EMSDK_REPO" "$EMSDK_DIR"
git clone "$HTSENGINEAPI_REPO" "$HTSENGINEAPI_DIR"
git clone "$OPENJTALK_REPO" "$OPENJTALK_DIR"

cd "$EMSDK_DIR"
./emsdk install latest
./emsdk activate latest
source "./emsdk_env.sh"

mkdir -p "$HTSENGINEAPI_DIR/src/build"
cd "$HTSENGINEAPI_DIR/src/build"
emcmake cmake -DCMAKE_INSTALL_PREFIX=../.. ..
emmake make -j
emmake make install

mkdir -p "$CURRENT_DIR/build"
mkdir -p "$OPENJTALK_DIR/src/build"
cd "$OPENJTALK_DIR/src/build"
emcmake cmake -DCMAKE_BUILD_TYPE=Release \
  -DHTS_ENGINE_LIB="$HTSENGINEAPI_DIR/lib" \
  -DHTS_ENGINE_INCLUDE_DIR="$HTSENGINEAPI_DIR/include" \
  ..
emmake make

emcc "$OPENJTALK_DIR/src/bin/open_jtalk.c" \
  -O2 \
  -lnodefs.js \
  "$OPENJTALK_DIR/src/build/libopenjtalk.a" \
  "$HTSENGINEAPI_DIR/src/build/lib/libhts_engine_API.a" \
	-I "$OPENJTALK_DIR/src/jpcommon" \
	-I "$OPENJTALK_DIR/src/mecab/src" \
	-I "$OPENJTALK_DIR/src/mecab2njd" \
	-I "$OPENJTALK_DIR/src/njd" \
	-I "$OPENJTALK_DIR/src/njd2jpcommon" \
	-I "$OPENJTALK_DIR/src/njd_set_accent_phrase" \
	-I "$OPENJTALK_DIR/src/njd_set_accent_type" \
	-I "$OPENJTALK_DIR/src/njd_set_digit" \
	-I "$OPENJTALK_DIR/src/njd_set_long_vowel" \
	-I "$OPENJTALK_DIR/src/njd_set_pronunciation" \
	-I "$OPENJTALK_DIR/src/njd_set_unvoiced_vowel" \
	-I "$OPENJTALK_DIR/src/text2mecab" \
  -I "$HTSENGINEAPI_DIR/lib" \
  -I "$HTSENGINEAPI_DIR/include" \
  -o "$CURRENT_DIR/build/openjtalk.js" \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s NODERAWFS=1 \
  -s MODULARIZE \
  -s INVOKE_RUN=0 \
	-s EXPORTED_RUNTIME_METHODS=callMain
