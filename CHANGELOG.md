## 0.34.0

* Update [internal] analytics
* Improve performance and memory usage
* Update [internal] dependencies
* Update [internal] tests
* Update webview provider
* Fix an issue where some websites where not trusted to run in webview
* Add oprf-mpc support
* Avoid circuit initialization when using oprf-mpc
* Update operator SDK library
* Update login detection
* Add native network support for IOS
* Update login indicator event names
* Add privacy policy, terms of service and potential failure reasons from feature flags
* Sanitize diagnostic log buffer before upload — redact cookies, auth headers, tokens, JWTs, keys, secrets, proofs, request/response bodies, payloads, and emails (F-021)
* Fix upload bug where log entries were computed before size trimming
* Zero log buffer contents after successful upload (F-054)
* Add session token authentication for AI service endpoints (F-002)
* Add sessionToken to ClientSdkVerificationRequest
* Make sessionToken private in AiServiceClient
* Fix [INTERNAL] TEE service connection check log

## 0.29.0

* Add proof submission events
* Update default TEEK & TEET URLs
* Add IS_RECLAIM_INAPPSDK in log events
* Add isInAppSdk in metadata when SessionManager.onProofSubmitted is called
* Update use of operator package
* Initialize algorithms after first page loading starts

## 0.24.0

* Fix use of capability access token
* Add OS & inapp sdk version to feature flag query
* Add interception options from feature flags
* Re-add rive compatibility for graphic in themes
* Add i18n support and initial en/es l10n
* Update theme to support hiding values shown for data shared
* Update theme to customize text on Verifier App's success screen
* Remove red color for status message on errors
* Update message shown on ReclaimVerificationNoActivityDetectedException
* Add version update notification
* Update settings UI in verifications web page
* Update cronet play services api version
* Fix claim indicator UI update after state changes from error
* Update the request that's sent when disableRequestReplay is true (when document request replay is disabled)
* Fix [internal] [severe] claim creation on retries by clearing error on retry
* Update [internal] gnark circuits and library
* Add events to critical log for better logs summary on devtools
* Update themeing to support blurred background, terms notice color and parameters display style, verifying icon, provider to app loading icon
* Add log level to Log entry that's sent to logging service
* Add [WIP] dark theme support for app
* Update theme data to provide return to app text, terms & privacy policy urls

## 0.16.0

* Add support for custom verification flow theme for any reclaim devtool app
* Add a whitelist to automatically allow permissions for autoplay and protected media id when requested from webview
* Add `writeRedactionMode` in requestData for provider
* Skip and extend time for no activity error when try again is pressed
* Update loading screen messages
* Add [Breaking] `AI_PROOF_SUBMITTED` in a session status type when using overrides
* Add [Breaking] `metadata` to `ReclaimHostOverridesApi.updateSession` callback when using overrides

## 0.15.0

* Add interception of document with `pre` text in html document or the html document on DOMContentLoaded event when `disableRequestReplay` is true
* Fix default user agent for iOS
* Fix url parsing when using hawkeye with default settings
* Fix claim creation to not use `bodySniff.template` when disabled
* Fix an edge case where public data wasn't attached to proofs when updating public data after verification completes
* Add improvements to AI claim creation
* Fix reporting of no activity and verification requirement failure exceptions in session logs
* Add improvements to login detection when using AI
* Add support to follow redirects when parsing a url using `ClientSdkVerificationRequest.fromUrl`

## 0.12.0

* Add support to follow links when starting a session with startVerificationFromUrl
* Add support for optional response matches
* Move request matching to platform from webpage injections
* Add regex match support for http provider's requests
* Remove dependency of requestHash to prevent request matching to fail with accidental re-use of request hashes from devtools
* Add retries when loading fonts
* Update cryptography library dependencies
* Add subscribe and mapChangesStream to ObservableNotifier for firing an event on subscribe to prevent listeners from missing latest event
* Add 16kb memory page alignment support for android archive
* Upgrade android agp to 8.7.3
* Update java compatibility to version 11
* Update libgnarkprover compiled binaries with go 1.25
* Update libgnarkprover from github.com/reclaimprotocol/zk-symmetric-crypto revision af4bb82aba064350a96e87b9bfb5fc9777671459
* Fixes edge cases where initialization would get stuck
* Introduce AI flow: enables automated verification for providers with `verificationType` set to `AI`
* AI flow automatically guides users through verification steps and handles data extraction
* Add AI action controller to manage and coordinate AI-driven actions during the verification process
* Add AI flow coordinator widget to manage and coordinate AI flow
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
* Update activity detection
* Reduce number of browser rpc clients used for value extraction and claim creation
* Lazy initialize browser rpc clients
* Update attestor client recovery
* Show a client error screen when no verification activity is detected for some time
* Replace old attestor clients before use
* Update Hawkeye script
* Add login detection logging
* Fix unnecessary rebuilds of webview used for value extraction by path
* Update retries during message handling for attestor browser rpc
* Handle android render process gone
* Rebuild browser rpc used for value extraction on receiving no response
* Fix timeout by moving it inside async lock scope to prevent useless retries
* Add a fix to prevent app from launching deeplinks in incognito
* Update readiness test for attestor 
* Fix fonts abrupt visual swap when required fonts are loaded 
* Fix param key text overflow verification review (#112)
* Add liveliness checks of javascript calls sent to attestor webview (#111)
* Add humanized summary of values shown in the verification review UI
* Add async lock around json & xml path evaluations to avoid rpc request deadlock
* Update user login interaction requirement detection
* Fix handling of requests where response selection either doesn't have match or redaction options
* Bug fixes and performance improvements
* Add retries on timeout when creating claim creation request
* Throw unsupported warning for non 64 bit runtime platforms
* Add device logging id as a fallback device identifier
* Print logs to attached app debugging consoles when logs upload fails 
* Update exceptions cases
* Add check for 4xx errors when throwing ReclaimExpiredSessionException exception
* Fix attestor startup causing requests to get stuck by pre-initializing a separate single browser rpc client for json path and xpath evaluation
* Update copy for manual review, add feature flags for customizing manual review messages and prompt before manual review submission
* Fixing issues with incognito (regression)
* Fix manual verification
* Update verification review screen
* Fix hawkeye headers bug with a workaround
* Fixing issues with incognito
* Add resolvedVersion to fetch providers override

## 0.8.3

* Updates inapp module dependency to 0.8.3
* Add support for versioned providers
* Update [BREAKING] session init handler
* Updates the UI with a verification review banner in the verification flow
* Remove [BREAKING] `acceptAiProviders`, and `webhookUrl` from ReclaimVerification Request

## 0.6.0

* Update claim creation updates UI
* Bug fixes and performance improvements
* Updates inapp module dependency to 0.6.0

## 0.5.0

* Initial release.
