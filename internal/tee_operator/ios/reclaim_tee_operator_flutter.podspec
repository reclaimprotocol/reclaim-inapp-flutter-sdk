#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint reclaim_tee_operator_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'reclaim_tee_operator_flutter'
  s.version          = '1.0.0'
  s.summary          = 'Reclaim Protocol operator library'
  s.description      = <<-DESC
Reclaim Protocol\'s implementation of ZK-Proxy Protocol, and TEE (Trusted Execution Environment) + MPC protocol operator for HTTP request verification & attestation.
                       DESC
  s.homepage         = 'https://reclaimprotocol.org'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Reclaim Protocol' => 'support@reclaimprotocol.org' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :git => 'https://github.com/reclaimprotocol/reclaim-tee-operator-flutter.git', :tag => s.version.to_s }
  # Scope to compilable sources only. The privacy manifest is delivered via
  # resource_bundles below; including it here would land it in the compile
  # sources phase and trigger an Xcode "no rule to process file" warning.
  s.source_files = 'reclaim_tee_operator_flutter/Sources/**/*.{swift,c,h}'
  s.public_header_files = 'reclaim_tee_operator_flutter/Sources/**/*.h'
  s.resource_bundles = {
    'reclaim_tee_operator_flutter_privacy' => ['reclaim_tee_operator_flutter/Sources/reclaim_tee_operator_flutter/PrivacyInfo.xcprivacy']
  }
  s.vendored_frameworks = 'reclaim_tee_operator_flutter/Frameworks/libreclaim.xcframework'
  # Link resolver library required by networking symbols (_res_9_*)
  s.libraries = 'resolv'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  # Dart FFI resolves the Go symbols via LookupInExecutable() -> dlsym(RTLD_DEFAULT),
  # so they must remain in the final app executable's symbol table. The reclaim.c
  # force-link shim defeats dead-code stripping (fixes `flutter run --release`),
  # but a TestFlight/App Store *archive* additionally runs the `strip` pass
  # (DEPLOYMENT_POSTPROCESSING=YES). Xcode's default STRIP_STYLE for an app target
  # is "all", which removes even global symbols -> dlsym fails only from TestFlight.
  # Force "non-global" on the consuming app target(s) so the exported Go symbols
  # (reclaim_get_version, SetZKInitCallback, enable_native_networking, ...) survive.
  s.user_target_xcconfig = { 'STRIP_STYLE' => 'non-global' }
  s.swift_version = '5.9'
end
