import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<UserCredential> signInWithEmail({required String email, required String password});
  Future<UserCredential> createUserWithEmail({required String email, required String password});
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> confirmPasswordReset({required String code, required String newPassword});
  Future<void> signOut();
  Stream<User?> authStateChanges();
  User? get currentUser;
}
