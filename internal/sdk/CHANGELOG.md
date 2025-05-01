## 0.5.0

* Add devtools ordering preference for params displayed in UI 
* Fix display of different params with same key
* Update [BREAKING] session initialization api
* Collect performance metrics and send it to session logs
* Add provider script environment

## 0.4.0

* Updated verification flow UI
* Fixed support for cascading requests (fixed number)
* Add param interpolation for xpath and jsonpath

## 0.3.0

* Add [attestorAuthenticationRequest] in verification option of [ReclaimVerification].

## 0.2.1

* [BREAKING] Add mandatory azp validation from capability access token
* [BREAKING] Update issuer of capability access token to [https://dev.reclaimprotocol.org](https://dev.reclaimprotocol.org)

## 0.2.0

* Add capability access token utilities.

## 0.1.3

* Depends on Flutter `3.29.0` and Dart `3.7.0`. Migrated deprecated `Color` APIs from dart:ui.
* Update the reclaim claim creation bottom sheet UI when showing verification progress.

## 0.1.2

* Bump version to match with dependent sdks

## 0.1.1

* Add cascading providers support where a single provider can have multiple requests that can be used to create multiple proofs.
* Refactor utilities in `util/` based on functionality.
* Simplify imports in dependents by exporting relevant files in `reclaim_flutter_sdk.dart`.
* Simplified the example code.
* Disable debug logs from reclaim_flutter_sdk by default.
* Updated the example app to show how to use the local prover.
* Fixed log reporting.
* Throw a ReclaimSessionExpiredException when a used session id is passed to the SDK.
* Add ReclaimException as the exception thrown from startVerification in the reclaim_flutter_sdk.
* Added support for local prover using Gnark.
* Added a method to set the compute witness proof callback to compute the witness proof externally.

## 0.1.0

* Initial deployment of the SDK, contains all the basic logic of the Reclaim Protocol.

