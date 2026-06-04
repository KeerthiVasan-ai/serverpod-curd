/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import '../notes/note.dart' as _i2;
import 'package:smart_notes_client/src/protocol/protocol.dart' as _i3;

/// A search result containing a note and its similarity score to the search query.
abstract class NoteSearchResult implements _i1.SerializableModel {
  NoteSearchResult._({
    required this.note,
    required this.score,
  });

  factory NoteSearchResult({
    required _i2.Note note,
    required double score,
  }) = _NoteSearchResultImpl;

  factory NoteSearchResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return NoteSearchResult(
      note: _i3.Protocol().deserialize<_i2.Note>(jsonSerialization['note']),
      score: (jsonSerialization['score'] as num).toDouble(),
    );
  }

  /// The matched note.
  _i2.Note note;

  /// The cosine similarity score (0.0 to 1.0). Higher means more relevant.
  double score;

  /// Returns a shallow copy of this [NoteSearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NoteSearchResult copyWith({
    _i2.Note? note,
    double? score,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NoteSearchResult',
      'note': note.toJson(),
      'score': score,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _NoteSearchResultImpl extends NoteSearchResult {
  _NoteSearchResultImpl({
    required _i2.Note note,
    required double score,
  }) : super._(
         note: note,
         score: score,
       );

  /// Returns a shallow copy of this [NoteSearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NoteSearchResult copyWith({
    _i2.Note? note,
    double? score,
  }) {
    return NoteSearchResult(
      note: note ?? this.note.copyWith(),
      score: score ?? this.score,
    );
  }
}
