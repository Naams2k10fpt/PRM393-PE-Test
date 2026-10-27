import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../repositories/book_repository.dart';

class BookStore extends ChangeNotifier {
  BookStore(this.repository, this.uid) {
    _subscription = repository
        .watchBooks(uid)
        .listen(
          (value) {
            _books = value;
            loading = false;
            error = null;
            notifyListeners();
          },
          onError: (Object exception) {
            loading = false;
            error = exception.toString();
            _books = [];
            notifyListeners();
          },
        );
  }

  final BookRepository repository;
  final String uid;
  late final StreamSubscription<List<Book>> _subscription;
  List<Book> _books = [];
  final Map<String, bool> _favoriteOverrides = {};
  final Set<String> pendingFavorites = {};
  bool loading = true;
  String? error;
  String genre = 'All';
  String status = 'All';
  bool favoritesOnly = false;
  String search = '';

  List<Book> get allBooks => _books.map((book) {
    final override = _favoriteOverrides[book.id];
    return override == null ? book : book.withFavorite(override);
  }).toList();

  List<Book> get visibleBooks {
    final query = search.trim().toLowerCase();
    final result = allBooks
        .where(
          (book) =>
              (genre == 'All' || book.genre == genre) &&
              (status == 'All' || book.status == status) &&
              (!favoritesOnly || book.favorite) &&
              (query.isEmpty ||
                  book.title.toLowerCase().contains(query) ||
                  book.author.toLowerCase().contains(query)),
        )
        .toList();
    result.sort((a, b) {
      final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      if (byTitle != 0) return byTitle;
      final byAuthor = a.author.toLowerCase().compareTo(b.author.toLowerCase());
      return byAuthor == 0 ? a.id.compareTo(b.id) : byAuthor;
    });
    return result;
  }

  List<MapEntry<String, int>> get statusCounts {
    final visible = visibleBooks;
    final counts = readingStatuses
        .map(
          (status) => MapEntry(
            status,
            visible.where((book) => book.status == status).length,
          ),
        )
        .where((entry) => entry.value > 0)
        .toList();
    counts.sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0
          ? byCount
          : readingStatuses
                .indexOf(a.key)
                .compareTo(readingStatuses.indexOf(b.key));
    });
    return counts;
  }

  Book? find(String id) {
    for (final book in allBooks) {
      if (book.id == id) return book;
    }
    return null;
  }

  void setGenre(String value) {
    genre = value;
    notifyListeners();
  }

  void setStatus(String value) {
    status = value;
    notifyListeners();
  }

  void setFavoritesOnly(bool value) {
    favoritesOnly = value;
    notifyListeners();
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  void clearFilters() {
    genre = status = 'All';
    favoritesOnly = false;
    search = '';
    notifyListeners();
  }

  Future<String> add(BookDraft draft) => repository.add(uid, draft);
  Future<String> save(String id, BookDraft draft) =>
      repository.save(uid, id, draft);
  Future<void> delete(String id) => repository.delete(uid, id);

  Future<void> toggleFavorite(Book book) async {
    if (pendingFavorites.contains(book.id)) return;
    pendingFavorites.add(book.id);
    _favoriteOverrides[book.id] = !book.favorite;
    notifyListeners();
    try {
      await repository.setFavorite(uid, book.id, !book.favorite);
    } finally {
      _favoriteOverrides.remove(book.id);
      pendingFavorites.remove(book.id);
      if (!_disposed) notifyListeners();
    }
  }

  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
