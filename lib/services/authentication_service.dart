import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:unshelf_seller/core/errors/app_exceptions.dart';
import 'package:unshelf_seller/core/interfaces/i_auth_service.dart';
import 'package:unshelf_seller/core/logger.dart';
import 'package:unshelf_seller/data/repositories/auth_repository.dart';

class AuthService implements IAuthService {
  // The repository handles all Firebase Auth SDK calls. The
  // [FirebaseAuth] instance is no longer held by the service — it is owned
  // exclusively by the repository. Google sign-in still lives here because
  // there is no dedicated `GoogleSignInRepository` and the credential flow
  // requires direct access to a Firebase Auth credential, which would leak
  // SDK types through the repository interface if relocated.
  final AuthRepository _repo;
  final GoogleSignIn _googleSignIn;

  AuthService({
    AuthRepository? repo,
    GoogleSignIn? googleSignIn,
  })  : _repo = repo ?? GetIt.instance<AuthRepository>(),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: dotenv.env['GOOGLE_CLIENT_ID']!,
              scopes: <String>['email', 'profile'],
            );

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _repo.signInWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('Sign in failed', e, stackTrace);
      throw AuthException(e.message ?? 'Sign in failed',
          code: e.code, originalError: e);
    }
  }

  @override
  Future<UserCredential?> signInWithGoogle() async {
    // Google sign-in stays service-only. The repository does not expose a
    // `signInWithCredential` method by design — the credential flow is
    // Google-specific and would couple the repo to a third-party provider.
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // We need a `FirebaseAuth.instance` reference for signInWithCredential.
      // Use the repository's view-only convenience by reaching into the
      // ambient instance — Google sign-in is a known service-level concern.
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('Google sign in failed', e, stackTrace);
      throw AuthException(e.message ?? 'Google sign in failed',
          code: e.code, originalError: e);
    }
  }

  @override
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _repo.createUserWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('Registration failed', e, stackTrace);
      throw AuthException(e.message ?? 'Registration failed',
          code: e.code, originalError: e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _repo.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('Failed to send password reset email', e, stackTrace);
      throw AuthException(e.message ?? 'Failed to send password reset email',
          code: e.code, originalError: e);
    }
  }

  @override
  Future<void> signOut() async {
    // Service-level coordination: Firebase signOut + Google signOut. The
    // repository only handles Firebase signOut; Google signOut stays here
    // because it requires the GoogleSignIn handle owned by this service.
    try {
      AppLogger.info('User signing out');
      await _repo.signOut();
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.error('Sign out failed', e, stackTrace);
      throw AuthException(e.message ?? 'Sign out failed',
          code: e.code, originalError: e);
    }
  }
}
