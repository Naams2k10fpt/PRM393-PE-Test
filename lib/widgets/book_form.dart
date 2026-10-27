import 'package:flutter/material.dart';

import '../models/book.dart';
import '../validation.dart';
import 'shared.dart';

class BookForm extends StatefulWidget {
  const BookForm({
    super.key,
    this.initial,
    required this.onSubmit,
    required this.submitLabel,
    this.onCancel,
  });
  final BookDraft? initial;
  final Future<void> Function(BookDraft) onSubmit;
  final String submitLabel;
  final VoidCallback? onCancel;
  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _author = TextEditingController(
    text: widget.initial?.author ?? '',
  );
  late final _rating = TextEditingController(
    text: widget.initial?.rating?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: widget.initial?.notes ?? '');
  late String? _genre = widget.initial?.genre;
  late String? _status = widget.initial?.status;
  bool _submitted = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await widget.onSubmit(
        BookDraft(
          title: _title.text,
          author: _author.text,
          genre: _genre!,
          status: _status!,
          rating: int.tryParse(_rating.text.trim()),
          notes: _notes.text,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _rating.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    autovalidateMode: _submitted
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _title,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Title'),
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          validator: Validators.title,
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _author,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Author'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: Validators.author,
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          initialValue: _genre ?? '',
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Genre'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Choose genre')),
            ...genres.map(
              (value) => DropdownMenuItem(value: value, child: Text(value)),
            ),
          ],
          onChanged: _busy ? null : (value) => setState(() => _genre = value),
          validator: (value) =>
              value == null || value.isEmpty ? 'Please choose a genre' : null,
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          initialValue: _status ?? '',
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Status'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Choose status')),
            ...readingStatuses.map(
              (value) => DropdownMenuItem(value: value, child: Text(value)),
            ),
          ],
          onChanged: _busy ? null : (value) => setState(() => _status = value),
          validator: (value) =>
              value == null || value.isEmpty ? 'Please choose a status' : null,
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _rating,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Rating (optional)',
            hintText: '0 to 5',
          ),
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          textInputAction: TextInputAction.next,
          validator: Validators.rating,
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _notes,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'A thought to remember…',
            alignLabelWithHint: true,
          ),
          minLines: 3,
          maxLines: 6,
          validator: Validators.notes,
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.submitLabel),
        ),
        if (widget.onCancel != null) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy ? null : widget.onCancel,
            child: const Text('Cancel'),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 14),
          InlineNotice(_error!, error: true),
        ],
      ],
    ),
  );
}
