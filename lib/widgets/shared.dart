import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../repositories/book_repository.dart';
import '../theme.dart';

String friendlyError(Object exception) {
  if (exception is FirebaseException) {
    return exception.message ?? 'Firebase could not complete this request.';
  }
  if (exception is BookException) return exception.message;
  return 'Something went wrong. Please try again.';
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(friendlyError(error)),
      backgroundColor: const Color(0xFF943D35),
    ),
  );
}

class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child, this.maxWidth = 760});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class InlineNotice extends StatelessWidget {
  const InlineNotice(
    this.text, {
    super.key,
    this.error = false,
    this.onDismiss,
  });
  final String text;
  final bool error;
  final VoidCallback? onDismiss;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFFEDE8) : const Color(0xFFE8EFE4),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          error ? Icons.error_outline : Icons.check_circle_outline,
          size: 21,
          color: error ? const Color(0xFF943D35) : ShelfColors.green,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: error ? const Color(0xFF943D35) : ShelfColors.green,
            ),
          ),
        ),
        if (onDismiss != null)
          IconButton(
            tooltip: 'Dismiss',
            onPressed: onDismiss,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close, size: 18),
          ),
      ],
    ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: switch (text) {
        'Reading' => const Color(0xFFFFEDD2),
        'Finished' => const Color(0xFFE2ECDF),
        _ => const Color(0xFFE9ECF0),
      },
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.favorite,
    required this.onPressed,
  });
  final bool favorite;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
    isSelected: favorite,
    onPressed: onPressed,
    color: favorite ? ShelfColors.gold : ShelfColors.muted,
    icon: Icon(
      favorite ? Icons.star_rounded : Icons.star_outline_rounded,
      size: 28,
    ),
  );
}
