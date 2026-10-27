import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../state/auth_session.dart';
import '../state/book_store.dart';
import '../theme.dart';
import '../widgets/book_card.dart';
import '../widgets/book_form.dart';
import '../widgets/shared.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  bool _adding = false;
  bool _loggingOut = false;
  bool _filtersOpen = false;
  String? _notice;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await context.read<AuthSession>().logout();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _favorite(Book book) async {
    try {
      await context.read<BookStore>().toggleFavorite(book);
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    final store = context.watch<BookStore>();
    final books = store.visibleBooks;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_stories_rounded, size: 23),
              SizedBox(width: 8),
              Text('BookShelf'),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _loggingOut ? null : _logout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Logout'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: PageWidth(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                session.user?.email ?? '',
                style: const TextStyle(color: ShelfColors.muted),
              ),
              const SizedBox(height: 22),
              Text(
                'Your library',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Good stories deserve a place to stay.',
                style: TextStyle(color: ShelfColors.muted),
              ),
              const SizedBox(height: 20),
              if (session.notice != null) ...[
                InlineNotice(session.notice!, onDismiss: session.dismissNotice),
                const SizedBox(height: 14),
              ],
              if (_notice != null) ...[
                InlineNotice(
                  _notice!,
                  onDismiss: () => setState(() => _notice = null),
                ),
                const SizedBox(height: 14),
              ],
              if (!_adding)
                FilledButton.icon(
                  onPressed: () => setState(() {
                    _adding = true;
                    _notice = null;
                  }),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add a book'),
                ),
              if (_adding)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Add Book',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        BookForm(
                          submitLabel: 'Add book',
                          onCancel: () => setState(() => _adding = false),
                          onSubmit: (draft) async {
                            await store.add(draft);
                            if (!mounted) return;
                            setState(() {
                              _adding = false;
                              _notice = 'Book added';
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted || !_scroll.hasClients) return;
                              _scroll.animateTo(
                                0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
                icon: const Icon(Icons.tune_rounded),
                label: Text(_filtersOpen ? 'Hide filters' : 'Filters & search'),
              ),
              if (_filtersOpen)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Find your next read',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _search.clear();
                                store.clearFilters();
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _search,
                          onChanged: store.setSearch,
                          decoration: const InputDecoration(
                            labelText: 'Search',
                            hintText: 'Title or author',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final genre = DropdownButtonFormField<String>(
                              key: ValueKey('genre-${store.genre}'),
                              initialValue: store.genre,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Genre',
                              ),
                              items: ['All', ...genres]
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) store.setGenre(value);
                              },
                            );
                            final status = DropdownButtonFormField<String>(
                              key: ValueKey('status-${store.status}'),
                              initialValue: store.status,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                              ),
                              items: ['All', ...readingStatuses]
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) store.setStatus(value);
                              },
                            );
                            if (constraints.maxWidth < 300) {
                              return Column(
                                children: [
                                  genre,
                                  const SizedBox(height: 14),
                                  status,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: genre),
                                const SizedBox(width: 12),
                                Expanded(child: status),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Favorites only'),
                          value: store.favoritesOnly,
                          onChanged: store.setFavoritesOnly,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ShelfColors.green,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Books: ${books.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Favorites: ${books.where((book) => book.favorite).length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (store.statusCounts.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      for (final count in store.statusCounts)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  count.key,
                                  style: const TextStyle(
                                    color: Color(0xFFDCE8D8),
                                  ),
                                ),
                              ),
                              Text(
                                '${count.value}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (store.loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (store.error != null)
                InlineNotice(store.error!, error: true)
              else if (books.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 40,
                          color: ShelfColors.muted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No books found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Add a book or try another filter.',
                          style: TextStyle(color: ShelfColors.muted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final book in books)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BookCard(
                      book: book,
                      onFavorite: store.pendingFavorites.contains(book.id)
                          ? null
                          : () => _favorite(book),
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DetailScreen(bookId: book.id),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
