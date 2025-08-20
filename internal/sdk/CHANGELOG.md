## 0.12.0

* Add support for optional response matches
* Move request matching to platform from webpage injections
* Add regex match support for http provider's requests
* Remove dependency of requestHash to prevent request matching to fail with accidental re-use of request hashes from devtools
* Add retries when loading fonts
* Update cryptography library dependencies
* Add subscribe and mapChangesStream to ObservableNotifier for firing an event on subscribe to prevent listeners from missing latest event
* Fixes edge cases where initialization would get stuck

## 0.11.0

* Introduce AI flow: enables automated verification for providers with `verificationType` set to `AI`
* AI flow automatically guides users through verification steps and handles data extraction
* Add AI action controller to manage and coordinate AI-driven actions during the verification process
* Add AI flow coordinator widget to manage and coordinate AI flow

## 0.10.15

* Fix visibility of terms of service
* Add text with hyperlink when an error occurs to help users learn more about potential failures

## 0.10.13

* Fix webview re-initialization when initial attempt fails
* Update verification review screen UI
* Add handling of local client errors on attestor browser rpc message
* Fix permissions request dialog on permissions from android webview
* Fix url loading without trying app link from webview
* Add cookie `credentials` field in requests
* Fix verification review UI when oprf is enabled and real value is unavailable

## 0.10.11

* Update activity detection
* Reduce number of browser rpc clients used for value extraction and claim creation
* Lazy initialize browser rpc clients

## 0.10.10

* Update attestor client recovery
* Show a client error screen when no verification activity is detected for some time

## 0.10.9

* Replace old attestor clients before use

## 0.10.8

* Update Hawkeye script
* Add login detection logging
* Fix unnecessary rebuilds of webview used for value extraction by path

## 0.10.7

* Update retries during message handling for attestor browser rpc
* Handle android render process gone
* Rebuild browser rpc used for value extraction on receiving no response

## 0.10.5

* Fix timeout by moving it inside async lock scope to prevent useless retries

## 0.10.4

* Add a fix to prevent app from launching deeplinks in incognito
* Update readiness test for attestor 
* Fix fonts abrupt visual swap when required fonts are loaded 

## 0.10.3

* Fix param key text overflow verification review (#112)
* Add liveliness checks of javascript calls sent to attestor webview (#111)

## 0.10.2

* Add humanized summary of values shown in the verification review UI
* Add async lock around json & xml path evaluations to avoid rpc request deadlock
* Update user login interaction requirement detection
* Fix handling of requests where response selection either doesn't have match or redaction options

## 0.10.0

* Bug fixes and performance improvements
* Add retries on timeout when creating claim creation request
* Throw unsupported warning for non 64 bit runtime platforms
* Add device logging id as a fallback device identifier
* Print logs to attached app debugging consoles when logs upload fails 
* Update exceptions cases
* Add check for 4xx errors when throwing ReclaimExpiredSessionException exception
* Fix attestor startup causing requests to get stuck by pre-initializing a separate single browser rpc client for json path and xpath evaluation
* Update copy for manual review, add feature flags for customizing manual review messages and prompt before manual review submission

## 0.9.2

* Fixing issues with incognito (regression)
* Fix manual verification
* Update verification review screen
* Fix hawkeye headers bug with a workaround

## 0.9.1

* Fixing issues with incognito

## 0.9.0

* Add resolvedVersion to fetch providers override

## 0.8.0

* Support for provider versions

## 0.7.0

* Bug fixes and performance improvements

## 0.6.0

* Update ReclaimVerification apis
* Update claim creation updates UI

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

