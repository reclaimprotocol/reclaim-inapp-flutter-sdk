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
