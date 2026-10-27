import 'dart:async';

import 'package:bookshelf/app.dart';
import 'package:bookshelf/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late FakeAuth auth;
  late FakeBooks repository;
  setUp(() {
    auth = FakeAuth();
    repository = FakeBooks();
  });
  tearDown(() async {
    await auth.close();
    await repository.close();
  });

  Future<void> launch(WidgetTester tester) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(BookShelfApp(auth: auth, repository: repository));
    await tester.pumpAndSettle();
  }

  testWidgets('public Home, Register validation and live error clearing', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('Every book,\none personal shelf.'), findsOneWidget);
    await tester.tap(find.text('Register').first);
    await tester.pumpAndSettle();
    expect(find.text('Email is required'), findsNothing);
    final submit = find.widgetWithText(FilledButton, 'Register');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Confirm password is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'sum@example.com');
    await tester.pumpAndSettle();
    expect(find.text('Email is required'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'registration reaches List with success and has no auth route to go back to',
    (tester) async {
      await launch(tester);
      await tester.tap(find.text('Register').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'sum@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Secret123!');
      await tester.enterText(find.byType(TextFormField).at(2), 'Secret123!');
      final submit = find.widgetWithText(FilledButton, 'Register');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Registration successful'), findsOneWidget);
      expect(find.text('sum@example.com'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Firebase error remains below submit and does not navigate', (
    tester,
  ) async {
    auth.failure = FirebaseAuthException(
      code: 'email-already-in-use',
      message: 'This email is already in use.',
    );
    await launch(tester);
    await tester.tap(find.text('Register').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'sum@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Secret123!');
    await tester.enterText(find.byType(TextFormField).at(2), 'Secret123!');
    final submit = find.widgetWithText(FilledButton, 'Register');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('This email is already in use.'), findsOneWidget);
    expect(find.text('Your library'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('auth loading does not flash private content', (tester) async {
    final gate = Completer<void>();
    auth = FakeAuth(
      user: const ShelfUser('alice', 'alice@example.com'),
      initialGate: gate,
    );
    await tester.pumpWidget(BookShelfApp(auth: auth, repository: repository));
    await tester.pump();
    expect(find.text('Your library'), findsNothing);
    expect(find.text('Login'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Your library'), findsOneWidget);
  });

  testWidgets('Add validates empty fields without initially showing errors', (
    tester,
  ) async {
    auth.user = const ShelfUser('alice', 'alice@example.com');
    await launch(tester);
    await tester.tap(find.text('Add a book'));
    await tester.pumpAndSettle();
    expect(find.text('Title is required'), findsNothing);
    final submit = find.widgetWithText(FilledButton, 'Add book');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Author is required'), findsOneWidget);
    expect(find.text('Please choose a genre'), findsOneWidget);
    expect(find.text('Please choose a status'), findsOneWidget);
    expect(repository.books, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
