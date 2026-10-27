import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

const genres = ['Fiction', 'Non-Fiction', 'Academic', 'Other'];
const readingStatuses = ['To Read', 'Reading', 'Finished'];

String normalizeBookText(String value) => value.trim().toLowerCase();

String bookDocumentId(String uid, String title, String author) {
  String hash(String value) => sha256.convert(utf8.encode(value)).toString();
  return '${hash(uid)}_${hash(normalizeBookText(title))}_'
      '${hash(normalizeBookText(author))}';
}

class BookDraft {
  const BookDraft({
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    this.rating,
    this.notes = '',
  });

  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final String notes;

  Map<String, dynamic> toFields() => {
    'title': title.trim(),
    'author': author.trim(),
    'genre': genre,
    'status': status,
    if (rating != null) 'rating': rating,
    'notes': notes,
  };
}

class Book {
  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.favorite,
    required this.createdAt,
    this.rating,
    this.notes = '',
  });

  factory Book.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return Book(
      id: document.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      author: data['author'] as String,
      genre: data['genre'] as String,
      status: data['status'] as String,
      favorite: data['favorite'] as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      rating: (data['rating'] as num?)?.toInt(),
      notes: data['notes'] as String? ?? '',
    );
  }

  final String id;
  final String userId;
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String notes;
  final DateTime? createdAt;

  BookDraft get draft => BookDraft(
    title: title,
    author: author,
    genre: genre,
    status: status,
    rating: rating,
    notes: notes,
  );

  Book withFavorite(bool value) => Book(
    id: id,
    userId: userId,
    title: title,
    author: author,
    genre: genre,
    status: status,
    rating: rating,
    favorite: value,
    notes: notes,
    createdAt: createdAt,
  );
}
