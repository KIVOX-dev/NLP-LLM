import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) => SecureStorageService());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(secureStorage: ref.watch(secureStorageProvider));
});

enum ThemeModePreference { light, dark, system }

/// Light/dark/system theme preference, defaults to following the system.
final themeModeProvider =
    StateProvider<ThemeModePreference>((ref) => ThemeModePreference.system);
