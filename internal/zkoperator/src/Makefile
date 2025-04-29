LIB_NAME=libgnarkprover

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PROJECT_DIR:=$(shell dirname $(ROOT_DIR))
BUILD_DIR:=$(ROOT_DIR)/build

IOS_OUT:=$(PROJECT_DIR)/ios
ANDROID_OUT:=$(PROJECT_DIR)/android/src/main/jniLibs
WEB_OUT:=$(PROJECT_DIR)/build/web

# Could be ANDROID_NDK_HOME=$(ANDROID_HOME)/ndk/23.1.7779620/toolchains/llvm/prebuilt/darwin-x86_64
ifeq ($(findstring android,$(MAKECMDGOALS)),android)
ifndef ANDROID_NDK_HOME
$(error ANDROID_NDK_HOME is not set)
endif
NDK_BIN:=$(ANDROID_NDK_HOME)/bin
endif

# Go library path
ifndef GO_GNARKPROVER_DIR
$(error GO_GNARKPROVER_DIR is not set)
endif
GO_TARGET_LIB:=$(GO_GNARKPROVER_DIR)/libraries/prover/libprove.go
GO_TARGET_LIB_WEB:=$(GO_GNARKPROVER_DIR)/libraries/prover/libprove_web.go

# init
# Create a directory for storing all intermediate build files
$(shell mkdir -p $(BUILD_DIR))
# end init

# Go compiler tags

# 2 versions of proof libraries exist.
# 1. Embedded circuits (by default) which makes ~95mb files but requires less memory.
# 2. Compiles circuits on the fly but weights ~58 mb. Set variable 'USE_LIB_COMPILED' with any string to enable this mode.
GOX_TAGS=
ifdef USE_LIB_COMPILED
GOX_TAGS="-tags=compiled"
$(info "Building libraries which compiles circuits on the fly. Unset 'USE_LIB_COMPILED' to use embedded circuits.")
else
$(info "Building libraries with embedded circuits. Set 'USE_LIB_COMPILED' to build libraries that compiles circuits on the fly.")
endif

android-armv7a:
	CGO_ENABLED=1 \
	GOOS=android \
	GOARCH=arm \
	GOARM=7 \
	CC=$(NDK_BIN)/armv7a-linux-androideabi21-clang \
	CXX=$(NDK_BIN)/armv7a-linux-androideabi21-clang++ \
	go build -C ${GO_GNARKPROVER_DIR} ${GOX_TAGS} -trimpath -ldflags '-s -w' -buildmode=c-shared -o $(ANDROID_OUT)/armeabi-v7a/${LIB_NAME}.so $(GO_TARGET_LIB)

android-arm64:
	CGO_ENABLED=1 \
	GOOS=android \
	GOARCH=arm64 \
	CC=$(NDK_BIN)/aarch64-linux-android21-clang \
	CXX=$(NDK_BIN)/aarch64-linux-android21-clang++ \
	go build -C ${GO_GNARKPROVER_DIR} ${GOX_TAGS} -trimpath -ldflags '-s -w' -buildmode=c-shared -o $(ANDROID_OUT)/arm64-v8a/${LIB_NAME}.so $(GO_TARGET_LIB)

android-x86:
	CGO_ENABLED=1 \
	GOOS=android \
	GOARCH=386 \
	CC=$(NDK_BIN)/i686-linux-android21-clang \
	CXX=$(NDK_BIN)/i686-linux-android21-clang++ \
	go build -C ${GO_GNARKPROVER_DIR} ${GOX_TAGS} -trimpath -ldflags '-s -w' -buildmode=c-shared -o $(ANDROID_OUT)/x86/${LIB_NAME}.so $(GO_TARGET_LIB)

android-x86_64:
	CGO_ENABLED=1 \
	GOOS=android \
	GOARCH=amd64 \
	CC=$(NDK_BIN)/x86_64-linux-android21-clang \
	CXX=$(NDK_BIN)/x86_64-linux-android21-clang++ \
	go build -C ${GO_GNARKPROVER_DIR} ${GOX_TAGS} -trimpath -ldflags '-s -w' -buildmode=c-shared -o $(ANDROID_OUT)/x86_64/${LIB_NAME}.so $(GO_TARGET_LIB)

ios-x86_64-sim:
	GOARCH=amd64 \
	SDK=iphonesimulator \
	LIB_NAME=${LIB_NAME} \
	GO_GNARKPROVER_DIR=${GO_GNARKPROVER_DIR} \
	GO_TARGET_LIB=${GO_TARGET_LIB} \
	BUILD_DIR=${BUILD_DIR} \
	GOX_TAGS=${GOX_TAGS} \
	./build_ios.sh

ios-arm64-sim:
	GOARCH=arm64 \
	SDK=iphonesimulator \
	LIB_NAME=${LIB_NAME} \
	GO_GNARKPROVER_DIR=${GO_GNARKPROVER_DIR} \
	GO_TARGET_LIB=${GO_TARGET_LIB} \
	BUILD_DIR=${BUILD_DIR} \
	GOX_TAGS=${GOX_TAGS} \
	./build_ios.sh

ios-arm64:
	GOARCH=arm64 \
	SDK=iphoneos \
	LIB_NAME=${LIB_NAME} \
	GO_GNARKPROVER_DIR=${GO_GNARKPROVER_DIR} \
	GO_TARGET_LIB=${GO_TARGET_LIB} \
	BUILD_DIR=${BUILD_DIR} \
	GOX_TAGS=${GOX_TAGS} \
	./build_ios.sh

# Omitting 32 bit cpu archs as compilations failes for them
# android: android-armv7a android-arm64 android-x86 android-x86_64
android: android-arm64 android-x86_64

# pod can't install static libraries with different binary names
IOS_LIB_ARM64=${BUILD_DIR}/arm64_iphoneos/${LIB_NAME}.a
IOS_HEADER_ARM64=${BUILD_DIR}/arm64_iphoneos/${LIB_NAME}.h
IOS_LIB_IPHONESIMULATOR=${BUILD_DIR}/iphonesimulator/${LIB_NAME}.a
IOS_FRAMEWORK_OUT=${IOS_OUT}/${LIB_NAME}.xcframework

ios: ios-x86_64-sim ios-arm64-sim ios-arm64
	mkdir -p $(shell dirname ${IOS_LIB_IPHONESIMULATOR});

	# Create multi-arch .a file for iphonesimulator
	lipo \
		-create \
		${BUILD_DIR}/arm64_iphonesimulator/${LIB_NAME}.a \
		${BUILD_DIR}/amd64_iphonesimulator/${LIB_NAME}.a \
		-output ${IOS_LIB_IPHONESIMULATOR}

	# Remove old xcframework from flutter package's ios/ directory
	rm -rf ${IOS_FRAMEWORK_OUT};

	xcodebuild -create-xcframework \
			-output ${IOS_FRAMEWORK_OUT} \
			-library ${IOS_LIB_IPHONESIMULATOR} \
			-headers ${IOS_HEADER_ARM64} \
			-library ${IOS_LIB_ARM64} \
			-headers ${IOS_HEADER_ARM64}

	# Clean up all intermediate build files
	rm -rf ${BUILD_DIR}

wasm:
	CGO_ENABLED=1 \
	GOOS=js \
	GOARCH=wasm \
	mkdir -p $(WEB_OUT)
	go build -C ${GO_GNARKPROVER_DIR} ${GOX_TAGS} -trimpath -ldflags '-s -w' -o $(WEB_OUT)/${LIB_NAME}.wasm $(GO_TARGET_LIB_WEB)
	@# lib instead of misc in go 1.24
	cp "$$(go env GOROOT)/misc/wasm/wasm_exec.js" "$(WEB_OUT)/wasm_exec.js"

gen_bindings:
	rm -f ${BUILD_DIR}/${LIB_NAME}.*
	go build -C ${GO_GNARKPROVER_DIR} -trimpath -buildmode=c-archive -o ${BUILD_DIR}/${LIB_NAME}.o ${GO_TARGET_LIB}
	cd ${PROJECT_DIR} && dart run ffigen --config ffigen.yaml
