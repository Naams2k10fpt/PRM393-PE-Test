import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/shared.dart';
import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void _open(BuildContext context, bool register) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AuthScreen(register: register)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
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
            Text(
              'BookShelf',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _open(context, false),
          child: const Text('Login'),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: () => _open(context, true),
            child: const Text('Register'),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: PageWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
          children: [
            const Text(
              'A LITTLE SPACE FOR YOUR NEXT CHAPTER',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: ShelfColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            Text('BookShelf', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 14),
            const Text(
              'Every book,\none personal shelf.',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 29,
                height: 1.2,
                color: ShelfColors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keep the books you own and the stories you want to read '
              'together. Your private library, always close at hand.',
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: ShelfColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _open(context, true),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Start your shelf'),
            ),
            const SizedBox(height: 26),
            const _ShelfIllustration(),
            const SizedBox(height: 28),
            const _Feature(
              Icons.library_books_outlined,
              'Track your books',
              'A home for everything you own or want to read.',
            ),
            const SizedBox(height: 12),
            const _Feature(
              Icons.bookmark_border_rounded,
              'Sort by status',
              'From your next read to the final page.',
            ),
            const SizedBox(height: 12),
            const _Feature(
              Icons.star_outline_rounded,
              'Rate your favorites',
              'Remember the stories that stayed with you.',
            ),
            const SizedBox(height: 24),
            const Text(
              'YOUR BOOKS. YOUR NOTES. JUST FOR YOU.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                color: ShelfColors.muted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ShelfColors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: ShelfColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ShelfIllustration extends StatelessWidget {
  const _ShelfIllustration();
  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
    decoration: BoxDecoration(
      color: const Color(0xFFE8EDDF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (color, height, label) in [
                (const Color(0xFF315742), 115.0, 'STORIES'),
                (const Color(0xFFBA844E), 136.0, 'A NEW CHAPTER'),
                (const Color(0xFFE5D4AD), 105.0, 'WANDER'),
                (const Color(0xFF738471), 125.0, 'SLOW DAYS'),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 38,
                    height: height,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFA68E69),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    ),
  );
}
