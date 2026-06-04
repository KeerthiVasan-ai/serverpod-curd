import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'gemini_embedding_service.dart';

/// Endpoint for managing Smart Notes with AI-powered semantic search.
///
/// This endpoint demonstrates Full-Stack Dart: the same [Note] model
/// defined in YAML is used by the database ORM, the generated client,
/// and the Flutter app — all without leaving Dart.
class NotesEndpoint extends Endpoint {
  GeminiEmbeddingService? _embeddingService;

  /// Lazily initialises and returns the [GeminiEmbeddingService].
  /// Reads the GEMINI_API_KEY from environment variables or server passwords.
  GeminiEmbeddingService _getEmbeddingService(Session session) {
    if (_embeddingService != null) return _embeddingService!;

    // Try env variable first, then server passwords.
    final apiKey = Platform.environment['GEMINI_API_KEY'] ??
        session.passwords['geminiApiKey'] ??
        '';

    if (apiKey.isEmpty) {
      throw Exception(
        'Gemini API key not found. Set the GEMINI_API_KEY environment variable '
        'or add geminiApiKey to config/passwords.yaml.',
      );
    }

    _embeddingService = GeminiEmbeddingService(apiKey: apiKey);
    return _embeddingService!;
  }

  /// Returns all notes from the database, ordered by creation date (newest first).
  Future<List<Note>> getAllNotes(Session session) async {
    return Note.db.find(
      session,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
  }

  /// Adds a new note, generates its Gemini embedding, and persists it.
  ///
  /// This is the magic of Serverpod's ORM: [Note.db.insertRow] is fully
  /// type-safe — no JSON, no raw SQL, no manual mapping.
  Future<Note> addNote(Session session, String title, String content) async {
    final service = _getEmbeddingService(session);

    // Generate semantic embedding for the content.
    final embedding = await service.embed('$title\n$content');

    final note = Note(
      title: title,
      content: content,
      embedding: embedding,
      createdAt: DateTime.now(),
    );

    return Note.db.insertRow(session, note);
  }

  /// Deletes a note by its [id].
  Future<void> deleteNote(Session session, int id) async {
    await Note.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
  }

  /// Performs semantic search against all notes using cosine similarity.
  ///
  /// The query is embedded with Gemini, then compared to each stored note
  /// embedding. Results are sorted by descending similarity score.
  Future<List<NoteSearchResult>> searchNotes(
    Session session,
    String query,
  ) async {
    final service = _getEmbeddingService(session);

    // Embed the user's search query.
    final queryEmbedding = await service.embed(query);

    // Fetch all notes from the database.
    final notes = await Note.db.find(session);

    // Filter notes that have embeddings, compute cosine similarity,
    // filter low-relevance results (< 0.5), and sort by score descending.
    final results = notes
        .where((note) => note.embedding != null && note.embedding!.isNotEmpty)
        .map((note) {
          final score = GeminiEmbeddingService.cosineSimilarity(
            queryEmbedding,
            note.embedding!,
          );
          return NoteSearchResult(note: note, score: score);
        })
        .where((r) => r.score > 0.5)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return results;
  }
}
