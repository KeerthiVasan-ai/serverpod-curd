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
import 'package:serverpod/serverpod.dart' as _i1;
import '../notes/notes_endpoint.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i4;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'notes': _i2.NotesEndpoint()
        ..initialize(
          server,
          'notes',
          null,
        ),
    };
    connectors['notes'] = _i1.EndpointConnector(
      name: 'notes',
      endpoint: endpoints['notes']!,
      methodConnectors: {
        'getAllNotes': _i1.MethodConnector(
          name: 'getAllNotes',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notes'] as _i2.NotesEndpoint).getAllNotes(
                session,
              ),
        ),
        'addNote': _i1.MethodConnector(
          name: 'addNote',
          params: {
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'content': _i1.ParameterDescription(
              name: 'content',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notes'] as _i2.NotesEndpoint).addNote(
                session,
                params['title'],
                params['content'],
              ),
        ),
        'deleteNote': _i1.MethodConnector(
          name: 'deleteNote',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notes'] as _i2.NotesEndpoint).deleteNote(
                session,
                params['id'],
              ),
        ),
        'searchNotes': _i1.MethodConnector(
          name: 'searchNotes',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['notes'] as _i2.NotesEndpoint).searchNotes(
                session,
                params['query'],
              ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i3.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i4.Endpoints()
      ..initializeEndpoints(server);
  }
}
