import 'dart:async';

import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/repositories/book_repository.dart';
import 'package:bookshelf/services/auth_service.dart';

class FakeAuth implements AuthService {
  FakeAuth({this.user, this.initialGate});
  ShelfUser? user;
  final Completer<void>? initialGate;
  Object? failure;
  final events = StreamController<ShelfUser?>.broadcast();
  @override
  Stream<ShelfUser?> get changes async* {
    await initialGate?.future;
    yield user;
    yield* events.stream;
  }

  @override
  Future<void> register(String email, String password) =>
      login(email, password);
  @override
  Future<void> login(String email, String password) async {
    if (failure != null) throw failure!;
    user = ShelfUser(email, email);
    events.add(user);
  }

  @override
  Future<void> logout() async {
    user = null;
    events.add(null);
  }

  Future<void> close() => events.close();
}

class FakeBooks implements BookRepository {
  final books = <Book>[];
  final events = StreamController<void>.broadcast();
  bool failWrites = false;
  Completer<void>? favoriteGate;
  List<Book> _snapshot(String uid) =>
      books.where((book) => book.userId == uid).toList();
  void emit() => events.add(null);
  @override
  Stream<List<Book>> watchBooks(String uid) async* {
    yield _snapshot(uid);
    yield* events.stream.map((_) => _snapshot(uid));
  }

  @override
  Future<String> add(String uid, BookDraft draft) async {
    if (failWrites) throw const BookException('Write refused');
    final id = bookDocumentId(uid, draft.title, draft.author);
    if (books.any((book) => book.id == id)) {
      throw const BookException('Duplicate book');
    }
    books.add(_fromDraft(uid, id, draft));
    emit();
    return id;
  }

  @override
  Future<String> save(String uid, String id, BookDraft draft) async {
    if (failWrites) throw const BookException('Write refused');
    final old = books.firstWhere((book) => book.id == id && book.userId == uid);
    final newId = bookDocumentId(uid, draft.title, draft.author);
    if (newId != id && books.any((book) => book.id == newId)) {
      throw const BookException('Duplicate book');
    }
    books.remove(old);
    books.add(_fromDraft(uid, newId, draft).withFavorite(old.favorite));
    emit();
    return newId;
  }

  Book _fromDraft(String uid, String id, BookDraft draft) => Book(
    id: id,
    userId: uid,
    title: draft.title.trim(),
    author: draft.author.trim(),
    genre: draft.genre,
    status: draft.status,
    rating: draft.rating,
    notes: draft.notes,
    favorite: false,
    createdAt: DateTime(2026),
  );
  @override
  Future<void> setFavorite(String uid, String id, bool favorite) async {
    await favoriteGate?.future;
    if (failWrites) throw const BookException('Write refused');
    final index = books.indexWhere(
      (book) => book.id == id && book.userId == uid,
    );
    books[index] = books[index].withFavorite(favorite);
    emit();
  }

  @override
  Future<void> delete(String uid, String id) async {
    if (failWrites) throw const BookException('Write refused');
    books.removeWhere((book) => book.id == id && book.userId == uid);
    emit();
  }

  Future<void> close() => events.close();
}
