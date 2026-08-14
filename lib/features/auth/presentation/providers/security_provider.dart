import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

class SecurityState {
  final bool isAppLocked;
  final bool isSecuritySetup;
  final bool isBiometricEnabled;
  final bool isBiometricAvailable;

  const SecurityState({
    required this.isAppLocked,
    required this.isSecuritySetup,
    required this.isBiometricEnabled,
    required this.isBiometricAvailable,
  });

  SecurityState copyWith({
    bool? isAppLocked,
    bool? isSecuritySetup,
    bool? isBiometricEnabled,
    bool? isBiometricAvailable,
  }) {
    return SecurityState(
      isAppLocked: isAppLocked ?? this.isAppLocked,
      isSecuritySetup: isSecuritySetup ?? this.isSecuritySetup,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
    );
  }
}

class SecurityNotifier extends StateNotifier<AsyncValue<SecurityState>> {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  static const _pinKey = 'user_secure_pin';
  static const _biometricKey = 'use_biometrics';

  SecurityNotifier(this._storage, this._auth)
      : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      final biometricEnabled = await _storage.read(key: _biometricKey);
      
      final isAvailable = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();

      final isSetup = pin != null && pin.isNotEmpty;

      state = AsyncValue.data(SecurityState(
        isAppLocked: isSetup, // Start locked if setup
        isSecuritySetup: isSetup,
        isBiometricEnabled: biometricEnabled == 'true',
        isBiometricAvailable: isAvailable,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setupSecurity(String pin, bool useBiometrics) async {
    await _storage.write(key: _pinKey, value: pin);
    await _storage.write(key: _biometricKey, value: useBiometrics.toString());
    
    state = state.whenData((s) => s.copyWith(
      isSecuritySetup: true,
      isBiometricEnabled: useBiometrics,
      isAppLocked: false, // Unlocked after setup
    ));
  }

  Future<bool> verifyPin(String enteredPin) async {
    final savedPin = await _storage.read(key: _pinKey);
    if (savedPin == enteredPin) {
      state = state.whenData((s) => s.copyWith(isAppLocked: false));
      return true;
    }
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    final s = state.valueOrNull;
    if (s == null || !s.isBiometricEnabled || !s.isBiometricAvailable) {
      return false;
    }

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock Chiromo Hospital',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );

      if (didAuthenticate) {
        state = state.whenData((s) => s.copyWith(isAppLocked: false));
        return true;
      }
    } catch (e) {
      // Handle error (e.g. no hardware)
    }
    return false;
  }

  void lockApp() {
    final s = state.valueOrNull;
    if (s != null && s.isSecuritySetup) {
      state = AsyncValue.data(s.copyWith(isAppLocked: true));
    }
  }

  Future<void> clearSecurity() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _biometricKey);
    state = state.whenData((s) => s.copyWith(
      isSecuritySetup: false,
      isBiometricEnabled: false,
      isAppLocked: false,
    ));
  }
}

final securityNotifierProvider =
    StateNotifierProvider<SecurityNotifier, AsyncValue<SecurityState>>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final auth = ref.watch(localAuthProvider);
  return SecurityNotifier(storage, auth);
});
