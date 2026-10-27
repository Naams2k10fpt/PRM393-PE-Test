import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme.dart';
import 'shared.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.onOpen,
    required this.onFavorite,
  });
  final Book book;
  final VoidCallback onOpen;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 45,
              height: 66,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: switch (book.genre) {
                  'Fiction' => const Color(0xFF576F59),
                  'Non-Fiction' => const Color(0xFFB08053),
                  'Academic' => const Color(0xFF667987),
                  _ => const Color(0xFF8C7781),
                },
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.author,
                    style: const TextStyle(color: ShelfColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusBadge(book.status),
                      Text(
                        book.genre,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ShelfColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View details →',
                    style: TextStyle(fontSize: 12, color: ShelfColors.green),
                  ),
                ],
              ),
            ),
            FavoriteButton(favorite: book.favorite, onPressed: onFavorite),
          ],
        ),
      ),
    ),
  );
}
