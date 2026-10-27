import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('required text, length boundaries and exact messages', () {
    expect(Validators.title(' \t\n '), 'Title is required');
    expect(Validators.title('a' * 100), isNull);
    expect(Validators.title('a' * 101), 'Title must be at most 100 characters');
    expect(Validators.author(' '), 'Author is required');
    expect(Validators.author('a' * 60), isNull);
    expect(Validators.author('a' * 61), 'Author must be at most 60 characters');
    expect(Validators.notes('a' * 300), isNull);
    expect(Validators.notes('a' * 301), 'Notes must be at most 300 characters');
  });
  test('optional rating accepts only whole numbers from zero to five', () {
    for (final value in ['', ' ', '0', '5', ' 3 ']) {
      expect(Validators.rating(value), isNull, reason: value);
    }
    for (final value in ['-1', '6', '2.5', '3.0', 'five', '1e0']) {
      expect(
        Validators.rating(value),
        'Rating must be a whole number from 0 to 5',
      );
    }
  });
  test('auth validators distinguish login from registration', () {
    expect(Validators.email(''), 'Email is required');
    expect(Validators.email('a@b'), 'Please enter a valid email address');
    expect(Validators.email(' test@example.com '), isNull);
    expect(Validators.password(''), 'Password is required');
    expect(Validators.password('123'), isNull);
    expect(
      Validators.password('123', register: true),
      'Password must be at least 6 characters',
    );
    expect(
      Validators.confirmPassword('', 'secret'),
      'Confirm password is required',
    );
    expect(
      Validators.confirmPassword('wrong', 'secret'),
      'Passwords do not match',
    );
  });
  test(
    'canonical keys ignore case and outer whitespace, isolate users and fields',
    () {
      expect(
        bookDocumentId('alice', ' Dune ', 'Frank Herbert'),
        bookDocumentId('alice', 'dune', 'frank herbert'),
      );
      expect(
        bookDocumentId('alice', 'Dune', 'Frank Herbert'),
        isNot(bookDocumentId('bob', 'Dune', 'Frank Herbert')),
      );
      expect(
        bookDocumentId('alice', 'a_b', 'c'),
        isNot(bookDocumentId('alice', 'a', 'b_c')),
      );
      expect(bookDocumentId('alice', 'a/b', 'c/d').contains('/'), isFalse);
    },
  );
}
