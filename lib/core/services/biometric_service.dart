import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication auth;
  BiometricService({LocalAuthentication? authentication})
    : auth = authentication ?? LocalAuthentication();
  Future<void> verify(bool checkout) async {
    if (!await auth.canCheckBiometrics ||
        (await auth.getAvailableBiometrics()).isEmpty) {
      throw Exception(
        'Enable fingerprint or Face ID in your phone settings to record attendance.',
      );
    }
    final verified = await auth.authenticate(
      localizedReason: checkout
          ? 'Verify your identity to check out of Mavens'
          : 'Verify your identity to check in to Mavens',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
    if (!verified) {
      throw Exception(
        'Biometric verification cancelled. Attendance was not recorded.',
      );
    }
  }
}
