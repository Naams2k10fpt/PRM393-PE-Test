import 'package:firebase_auth/firebase_auth.dart';

class ShelfUser {
  const ShelfUser(this.uid, this.email);
  final String uid;
  final String email;
}

abstract class AuthService {
  Stream<ShelfUser?> get changes;
  Future<void> register(String email, String password);
  Future<void> login(String email, String password);
  Future<void> logout();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this.auth);
  final FirebaseAuth auth;
  @override
  Stream<ShelfUser?> get changes => auth.authStateChanges().map(
    (user) => user == null ? null : ShelfUser(user.uid, user.email ?? ''),
  );
  @override
  Future<void> register(String email, String password) async {
    await auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> logout() => auth.signOut();
}
