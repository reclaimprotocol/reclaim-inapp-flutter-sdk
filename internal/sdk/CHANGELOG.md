## 0.36.0

* Add witnesses list with tee attestation (alpha) for tee mode proofs

## 0.35.0

* Fix PII in some logs
* Update webview interaction

## 0.34.0

* Update [internal] analytics

## 0.33.0

* Update [internal] dependencies
* Update tests
* Update webview provider
* Fix an issue where some websites where not trusted to run in webview
* Fix ANR issues on android & iOS

## 0.32.0

* Add oprf-mpc support
* Avoid circuit initialization when using oprf-mpc
* Update operator SDK library
* Update login detection 
* Update login indicator event names
* Add privacy policy, terms of service and potential failure reasons from feature flags

## 0.31.1

* Sanitize diagnostic log buffer before upload — redact cookies, auth headers, tokens, JWTs, keys, secrets, proofs, request/response bodies, payloads, and emails (F-021)
* Fix upload bug where log entries were computed before size trimming
* Zero log buffer contents after successful upload (F-054)

## 0.31.0

* Add session token authentication for AI service endpoints (F-002)
* Add sessionToken to ClientSdkVerificationRequest
* Make sessionToken private in AiServiceClient

## 0.30.0

* Fix [INTERNAL] TEE service connection check log

## 0.29.0

* Update default TEEK & TEET URLs
* Add IS_RECLAIM_INAPPSDK in log events
* Add isInAppSdk in metadata when SessionManager.onProofSubmitted is called

## 0.28.0

* Update use of operator package
* Initialize algorithms after first page loading starts

## 0.27.0

* Fix feature flag overrides causing interruption with some login pages and returning incorrect values for fields not overriden
* Update default feature flag values

## 0.26.0

* Add potentialFailureReasonsLink in themes

## 0.25.0

* Add option to use Reclaim's TEE+MPC Protocol for HTTP request claim verification & attestation.
* Mention locale in headers for requests sent to reclaim sdk backend.
* Add support for app links & deep links launch using `Reclaim.setAllowedAppLinks` API. This API can be used by provider user scripts.
* Share the exact error message from backend on errors in `ReclaimSessionExpiredException`.
* Add `Reclaim.updateUserAgent(userAgent:string)` API for updating user agent from provider user script.

## 0.24.0

* Add OS & inapp sdk version to feature flag query
* Add interception options from feature flags
* Re-add rive compatibility for graphic in themes

## 0.23.0

* Add i18n support and initial en/es l10n

## 0.22.0

* Update theme to support hiding values shown for data shared
* Update theme to customize text on Verifier App's success screen
* Remove red color for status message on errors
* Update message shown on ReclaimVerificationNoActivityDetectedException

## 0.21.0

* Add version update notification
* Update settings UI in verifications web page
* Update cronet play services api version
* Fix claim indicator UI update after state changes from error
* Update the request that's sent when disableRequestReplay is true (when document request replay is disabled)

## 0.19.1

* Fix [internal] [severe] claim creation on retries by clearing error on retry

## 0.19.0

* Update [internal] gnark circuits and library
* Add events to critical log for better logs summary on devtools
* Add support for rive assets in any graphic used from Reclaim Theme
* Update themeing to support blurred background, terms notice color and parameters display style, verifying icon, provider to app loading icon

## 0.18.0

* Add log level to Log entry that's sent to logging service

## 0.17.0

* Add [WIP] dark theme support for app
* Update theme data to provide return to app text, terms & privacy policy urls

## 0.16.0

* Refactor [internal] attestor client code for better compatibility with new architectures
* Add support for custom verification flow theme for any reclaim devtool app
* Add a whitelist to automatically allow permissions for autoplay and protected media id when requested from webview
* Add `writeRedactionMode` in requestData for provider
* Skip and extend time for no activity error when try again is pressed
* Update loading screen messages

## 0.15.0

* Add interception of document with `pre` text in html document or the html document on DOMContentLoaded event when `disableRequestReplay` is true
* Fix default user agent for iOS
* Fix url parsing when using hawkeye with default settings
* Fix claim creation to not use `bodySniff.template` when disabled

## 0.14.0

* Fix an edge case where public data wasn't attached to proofs when updating public data after verification completes
* Add improvements to AI
* Update [internal] internal hashing hashing of claim requests with a faster algorithm for request identification
* Fix [internal] web context initial state setup for use in AI
* Fix reporting of no activity and verification requirement failure exceptions in session logs

## 0.13.0

* Add improvements to login detection when using AI
* Add support to follow redirects when parsing a url using `ClientSdkVerificationRequest.fromUrl`

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

