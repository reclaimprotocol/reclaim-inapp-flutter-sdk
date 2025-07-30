enum HawkeyeInterceptionMethod {
  PROXY,
  DIRECT_REPLACEMENT,
  GETTER_SETTER;

  static const defaultMethod = HawkeyeInterceptionMethod.PROXY;

  static HawkeyeInterceptionMethod fromString(String? value) {
    return switch (value?.toUpperCase()) {
      'PROXY' => HawkeyeInterceptionMethod.PROXY,
      'DIRECT_REPLACEMENT' => HawkeyeInterceptionMethod.DIRECT_REPLACEMENT,
      'GETTER_SETTER' => HawkeyeInterceptionMethod.GETTER_SETTER,
      _ => defaultMethod,
    };
  }

  bool get useProxyForFetch => this == HawkeyeInterceptionMethod.PROXY;
  bool get useGetterForFetch => this == HawkeyeInterceptionMethod.GETTER_SETTER;
}
