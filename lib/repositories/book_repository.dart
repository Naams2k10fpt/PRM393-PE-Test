import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book.dart';

class BookException implements Exception {
  const BookException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class BookRepository {
  Stream<List<Book>> watchBooks(String uid);
  Future<String> add(String uid, BookDraft draft);
  Future<String> save(String uid, String id, BookDraft draft);
  Future<void> setFavorite(String uid, String id, bool favorite);
  Future<void> delete(String uid, String id);
}

class FirestoreBookRepository implements BookRepository {
  FirestoreBookRepository(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _books =>
      firestore.collection('books');

  @override
  Stream<List<Book>> watchBooks(String uid) => _books
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Book.fromDocument).toList());

  @override
  Future<String> add(String uid, BookDraft draft) async {
    final id = bookDocumentId(uid, draft.title, draft.author);
    final reference = _books.doc(id);
    final created = await firestore.runTransaction<bool>((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        return false;
      }
      transaction.set(reference, {
        ...draft.toFields(),
        'id': id,
        'userId': uid,
        'favorite': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    // Keep domain errors outside the SDK callback: Web bridges callback
    // exceptions through JavaScript and can lose their original Dart type.
    if (!created) {
      throw const BookException(
        'A book with this title and author already exists.',
      );
    }
    return id;
  }

  @override
  Future<String> save(String uid, String id, BookDraft draft) async {
    final nextId = bookDocumentId(uid, draft.title, draft.author);
    final outcome = await firestore.runTransaction<String>((transaction) async {
      final current = await transaction.get(_books.doc(id));
      if (!current.exists || current.data()!['userId'] != uid) {
        return 'unavailable';
      }
      if (nextId != id) {
        final target = await transaction.get(_books.doc(nextId));
        if (target.exists) {
          return 'duplicate';
        }
      }
      // A full replacement also removes an optional rating cleared in Edit.
      transaction.set(_books.doc(nextId), {
        ...draft.toFields(),
        'id': nextId,
        'userId': uid,
        'favorite': current.data()!['favorite'],
        'createdAt': current.data()!['createdAt'],
      });
      if (nextId != id) transaction.delete(_books.doc(id));
      return 'saved';
    });
    if (outcome == 'duplicate') {
      throw const BookException(
        'A book with this title and author already exists.',
      );
    }
    if (outcome == 'unavailable') {
      throw const BookException('This book is no longer available.');
    }
    return nextId;
  }

  @override
  Future<void> setFavorite(String uid, String id, bool favorite) =>
      _books.doc(id).update({'favorite': favorite});

  @override
  Future<void> delete(String uid, String id) => _books.doc(id).delete();
}
