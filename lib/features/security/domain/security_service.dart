/// App security & biometric authentication abstraction.
abstract class SecurityService {
  Future<bool> isBiometricAvailable();
  Future<bool> authenticateWithBiometrics({required String reason});
  Future<bool> setPinCode(String pin);
  Future<bool> verifyPinCode(String pin);
  Future<bool> isPinSet();
  Future<void> removePin();
}
