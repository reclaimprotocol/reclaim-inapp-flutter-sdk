## 3.4.0

* Update tee library

## 3.3.0

* Updated native library for an edge case where claim could be empty
* Upgrade flutter dependencies

## 3.2.0

* Add authRequest in options of request when executing a request
* Fix iOS TestFlight/App Store crash (`dlsym ... symbol not found` for `reclaim_get_version` and other native symbols) by shipping the native library as its own dynamic framework via Dart native assets (`DynamicLoadingBundled`) instead of statically linking it into the app executable
* iOS no longer requires consumers to set `STRIP_STYLE=non-global` on their Xcode targets — the native library is now stripped and codesigned independently of the consuming app's build settings
* Removed the iOS force-link shim (`reclaim_binding`/`EnforceBinding.swift`), no longer needed now that the native library isn't statically merged into the app

## 3.1.0

* Update TEE library

## 3.0.0

* Update tee library
* Add swiftpm support

## 2.7.0

* Update native library
* Update native library which fixes request creation to enforce 'connection: close' header to be first after request line

## 2.6.1

* Update native library

## 2.4.0

* Updated tee-mpc library

## 2.3.1

* Fix xpath evaluation to be less strict with bad xml

## 2.3.0

* Add OPRF-MPC support
* Update library with bug fixes

## 2.2.0

* Add native network support for IOS

## 2.1.1

* Fix: surface Go extraction error in `extractJSONValueIndexes` instead of throwing generic "missing ranges field" exception

## 2.2.0

* Update native library with support for tk.reclaimprotocol.org and tt.reclaimprotocol.org

## 2.0.1

* Compile native library with reduced dependencies for mobile for a lower native library size.

## 2.0.0

* Rename TEE & Proxy Operator APIs.
* Add lazy initialization of algorithms.

## 1.99.0

* Fix hook/build to ignore unsupported android arch

## 1.98.0

* Refactor to use flutter build hooks to add native library with code_assets

## 1.97.0

* Add stable implementation of Reclaim TEE + MPC protocol operator

## 1.4.0

* Add 16kb memory page alignment support for android archive
* Upgrade android agp to 8.7.3
* Update android ndk version to 29.0.13846066
* Update java compatibility to version 11
* Update libgnarkprover compiled binaries with go 1.25
* Update libgnarkprover from github.com/reclaimprotocol/zk-symmetric-crypto revision af4bb82aba064350a96e87b9bfb5fc9777671459

## 1.1.0

* Add onPerformanceReport callback in `ReclaimZkOperator.computeAttestorProof` & `ReclaimZkOperator.groth16Prove` for collecting performance report of proof computations.

## 1.0.0

* Initial release of Reclaim Protocol's implementation of Zero-Knowledge (ZK) SNARK Operator powered by a Gnark Prover library
