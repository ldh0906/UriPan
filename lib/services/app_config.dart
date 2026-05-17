class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.apiKey,
    required this.enableRemoteSync,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment('URIPAN_API_BASE_URL'),
      apiKey: String.fromEnvironment('URIPAN_API_KEY'),
      enableRemoteSync: bool.fromEnvironment('URIPAN_ENABLE_REMOTE_SYNC'),
    );
  }

  final String apiBaseUrl;
  final String apiKey;
  final bool enableRemoteSync;

  bool get hasRemoteConfig => apiBaseUrl.isNotEmpty && apiKey.isNotEmpty;
}
