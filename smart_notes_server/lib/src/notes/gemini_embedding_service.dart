import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service for generating text embeddings using Google Gemini.
class GeminiEmbeddingService {
  final GenerativeModel _model;

  GeminiEmbeddingService({required String apiKey})
      : _model = GenerativeModel(
          model: 'text-embedding-004',
          apiKey: apiKey,
        );

  /// Generates an embedding vector for the given [text].
  Future<List<double>> embed(String text) async {
    final content = Content.text(text);
    final result = await _model.embedContent(content);
    return result.embedding.values;
  }

  /// Computes cosine similarity between two vectors.
  /// Returns a value between -1.0 and 1.0, where 1.0 means identical direction.
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double magnitudeA = 0.0;
    double magnitudeB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      magnitudeA += a[i] * a[i];
      magnitudeB += b[i] * b[i];
    }

    magnitudeA = sqrt(magnitudeA);
    magnitudeB = sqrt(magnitudeB);

    if (magnitudeA == 0 || magnitudeB == 0) return 0.0;
    return dotProduct / (magnitudeA * magnitudeB);
  }
}
