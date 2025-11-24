## 1.6.1

* Remove unnecessary logs

## 1.6.0

* Update asset links for v3 circuits
* Add support for new circuits

## 1.5.1

* Add tests for identifyAlgorithmFromZKOperationRequest
* Update logs to show which algorithm maybe used in proof generation

## 1.5.0

* Refactor all isolate workers to be a runnable and add `WorkerManager` that manages background worker with runnables and runs them on isolate

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
