import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/book.dart';
import '../state/book_store.dart';
import '../theme.dart';
import '../widgets/book_form.dart';
import '../widgets/shared.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.bookId});
  final String bookId;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String _id = widget.bookId;
  bool _editing = false;
  bool _deleting = false;
  String? _awaitingId;
  String? _notice;

  Future<void> _favorite(Book book) async {
    try {
      await context.read<BookStore>().toggleFavorite(book);
    } catch (error) {
      if (mounted) showError(context, error);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this book?'),
        content: const Text(
          'This book and its notes will be removed from your shelf.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await context.read<BookStore>().delete(_id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _deleting = false);
        showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<BookStore>();
    final book = store.find(_id);
    if (book != null) _awaitingId = null;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: SafeArea(
        child: PageWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              if (book == null) ...[
                if (_awaitingId != null || _deleting)
                  const Center(child: CircularProgressIndicator())
                else
                  const InlineNotice('This book is no longer available.'),
              ] else if (_editing) ...[
                Text(
                  'Edit book',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                BookForm(
                  initial: book.draft,
                  submitLabel: 'Save',
                  onCancel: () => setState(() => _editing = false),
                  onSubmit: (draft) async {
                    final nextId = await store.save(_id, draft);
                    if (!mounted) return;
                    setState(() {
                      _id = nextId;
                      _awaitingId = nextId;
                      _editing = false;
                      _notice = 'Book saved';
                    });
                  },
                ),
              ] else ...[
                if (_notice != null) ...[
                  InlineNotice(
                    _notice!,
                    onDismiss: () => setState(() => _notice = null),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    FavoriteButton(
                      favorite: book.favorite,
                      onPressed: store.pendingFavorites.contains(book.id)
                          ? null
                          : () => _favorite(book),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  book.author,
                  style: const TextStyle(
                    fontSize: 18,
                    color: ShelfColors.muted,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DetailField('Genre', book.genre),
                        _DetailField('Status', book.status),
                        _DetailField(
                          'Rating',
                          book.rating == null
                              ? 'Not rated'
                              : '${book.rating} / 5',
                        ),
                        _DetailField(
                          'Notes',
                          book.notes.isEmpty ? 'No notes yet' : book.notes,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _deleting
                      ? null
                      : () => setState(() {
                          _editing = true;
                          _notice = null;
                        }),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _deleting ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField(this.label, this.value, {this.last = false});
  final String label;
  final String value;
  final bool last;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ShelfColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    ),
  );
}
