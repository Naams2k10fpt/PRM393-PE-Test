import 'dart:async';

import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/repositories/book_repository.dart';
import 'package:bookshelf/state/book_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late FakeBooks repository;
  late BookStore store;
  setUp(() async {
    repository = FakeBooks();
    for (final (title, author, genre, status, favorite) in [
      ('Dune', 'Frank', 'Fiction', 'To Read', true),
      ('alpha', 'Zed', 'Academic', 'Reading', true),
      ('Alpha', 'Amy', 'Fiction', 'Finished', false),
      ('Notes', 'Student', 'Other', 'Reading', false),
      ('World', 'Student', 'Non-Fiction', 'To Read', true),
    ]) {
      final id = await repository.add(
        'alice',
        BookDraft(title: title, author: author, genre: genre, status: status),
      );
      await repository.setFavorite('alice', id, favorite);
    }
    await repository.add(
      'bob',
      const BookDraft(
        title: 'Private Bob',
        author: 'Bob',
        genre: 'Other',
        status: 'To Read',
      ),
    );
    store = BookStore(repository, 'alice');
    await Future<void>.delayed(Duration.zero);
  });
  tearDown(() async {
    store.dispose();
    await repository.close();
  });

  test(
    'sort ignores case, breaks title ties by author, and excludes other users',
    () {
      expect(store.visibleBooks.map((book) => book.author), [
        'Amy',
        'Zed',
        'Frank',
        'Student',
        'Student',
      ]);
      expect(store.visibleBooks.length, 5);
    },
  );
  test(
    'all four controls combine; Clear resets all; summary uses filtered books',
    () {
      store.setGenre('Fiction');
      store.setStatus('To Read');
      store.setFavoritesOnly(true);
      store.setSearch('  FRANK  ');
      expect(store.visibleBooks.single.title, 'Dune');
      expect(store.statusCounts.map((entry) => '${entry.key}:${entry.value}'), [
        'To Read:1',
      ]);
      store.clearFilters();
      expect(store.visibleBooks.length, 5);
      expect(store.statusCounts.map((entry) => '${entry.key}:${entry.value}'), [
        'To Read:2',
        'Reading:2',
        'Finished:1',
      ]);
      expect(store.genre, 'All');
      expect(store.status, 'All');
      expect(store.favoritesOnly, false);
      expect(store.search, '');
    },
  );
  test(
    'unfavorite removes a result immediately and failed write restores it',
    () async {
      store.setFavoritesOnly(true);
      final book = store.visibleBooks.first;
      repository.failWrites = true;
      repository.favoriteGate = Completer<void>();
      final operation = store.toggleFavorite(book);
      expect(store.visibleBooks.any((value) => value.id == book.id), false);
      repository.favoriteGate!.complete();
      await expectLater(operation, throwsA(isA<BookException>()));
      expect(store.visibleBooks.any((value) => value.id == book.id), true);
    },
  );
  test(
    'rename moves key, cleared rating disappears, and deletion updates stream',
    () async {
      final book = store.visibleBooks.first;
      final nextId = await store.save(
        book.id,
        const BookDraft(
          title: 'New title',
          author: 'New author',
          genre: 'Other',
          status: 'Finished',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(store.find(book.id), isNull);
      expect(store.find(nextId)!.rating, isNull);
      await store.delete(nextId);
      await Future<void>.delayed(Duration.zero);
      expect(store.find(nextId), isNull);
      expect(store.visibleBooks.length, 4);
    },
  );
}
