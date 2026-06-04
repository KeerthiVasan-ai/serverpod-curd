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
import 'dart:async' as _i2;
import 'package:smart_notes_client/src/protocol/notes/note.dart' as _i3;
import 'package:smart_notes_client/src/protocol/notes/note_search_result.dart'
    as _i4;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i5;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i6;
import 'protocol.dart' as _i7;

/// Endpoint for managing Smart Notes with AI-powered semantic search.
///
/// This endpoint demonstrates Full-Stack Dart: the same [Note] model
/// defined in YAML is used by the database ORM, the generated client,
/// and the Flutter app — all without leaving Dart.
/// {@category Endpoint}
class EndpointNotes extends _i1.EndpointRef {
  EndpointNotes(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notes';

  /// Returns all notes from the database, ordered by creation date (newest first).
  _i2.Future<List<_i3.Note>> getAllNotes() =>
      caller.callServerEndpoint<List<_i3.Note>>(
        'notes',
        'getAllNotes',
        {},
      );

  /// Adds a new note, generates its Gemini embedding, and persists it.
  ///
  /// This is the magic of Serverpod's ORM: [Note.db.insertRow] is fully
  /// type-safe — no JSON, no raw SQL, no manual mapping.
  _i2.Future<_i3.Note> addNote(
    String title,
    String content,
  ) => caller.callServerEndpoint<_i3.Note>(
    'notes',
    'addNote',
    {
      'title': title,
      'content': content,
    },
  );

  /// Deletes a note by its [id].
  _i2.Future<void> deleteNote(int id) => caller.callServerEndpoint<void>(
    'notes',
    'deleteNote',
    {'id': id},
  );

  /// Performs semantic search against all notes using cosine similarity.
  ///
  /// The query is embedded with Gemini, then compared to each stored note
  /// embedding. Results are sorted by descending similarity score.
  _i2.Future<List<_i4.NoteSearchResult>> searchNotes(String query) =>
      caller.callServerEndpoint<List<_i4.NoteSearchResult>>(
        'notes',
        'searchNotes',
        {'query': query},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i5.Caller(client);
    serverpod_auth_core = _i6.Caller(client);
  }

  late final _i5.Caller serverpod_auth_idp;

  late final _i6.Caller serverpod_auth_core;
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i7.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    notes = EndpointNotes(this);
    modules = Modules(this);
  }

  late final EndpointNotes notes;

  late final Modules modules;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {'notes': notes};

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
