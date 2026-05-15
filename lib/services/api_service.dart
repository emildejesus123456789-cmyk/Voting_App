// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../models/room.dart';
import '../models/voting_option.dart';
import '../models/irv_result.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class RoomData {
  final Room room;
  final List<VotingOption> options;
  final int voteCount;

  RoomData({required this.room, required this.options, required this.voteCount});
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = AppConstants.baseUrl;

  Future<RoomData> createRoom({
    required String title,
    required List<String> options,
    required String userId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/rooms'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'title': title, 'options': options, 'userId': userId}),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 201) {
      throw ApiException(
        body['error'] as String? ?? 'Failed to create room',
        statusCode: response.statusCode,
      );
    }

    final room = Room.fromJson(body['room'] as Map<String, dynamic>);
    final opts = (body['options'] as List)
        .map((o) => VotingOption.fromJson(o as Map<String, dynamic>))
        .toList();

    return RoomData(room: room, options: opts, voteCount: 0);
  }

  Future<RoomData> getRoom(String code) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/rooms/${code.toUpperCase()}'))
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 404) {
      throw ApiException('Room not found. Check the room code and try again.');
    }
    if (response.statusCode != 200) {
      throw ApiException(
        body['error'] as String? ?? 'Failed to load room',
        statusCode: response.statusCode,
      );
    }

    final room = Room.fromJson(body['room'] as Map<String, dynamic>);
    final opts = (body['options'] as List)
        .map((o) => VotingOption.fromJson(o as Map<String, dynamic>))
        .toList();

    return RoomData(
      room: room,
      options: opts,
      voteCount: body['voteCount'] as int? ?? 0,
    );
  }

  Future<bool> checkHasVoted(String roomCode, String userId) async {
    final response = await http
        .get(Uri.parse('$_baseUrl/rooms/${roomCode.toUpperCase()}/check-vote/$userId'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return false;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['hasVoted'] as bool? ?? false;
  }

  Future<void> submitVote({
    required String roomCode,
    required String userId,
    required List<String> rankings,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/votes'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'roomCode': roomCode,
            'userId': userId,
            'rankings': rankings,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 409) {
      throw ApiException('You have already voted in this room.');
    }
    if (response.statusCode != 201) {
      throw ApiException(
        body['error'] as String? ?? 'Failed to submit vote',
        statusCode: response.statusCode,
      );
    }
  }

  Future<IrvResult> closeVotingAndGetResults({
    required String roomCode,
    required String userId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/rooms/${roomCode.toUpperCase()}/close'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId}),
        )
        .timeout(const Duration(seconds: 30));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 403) {
      throw ApiException('Only the room creator can close voting.');
    }
    if (response.statusCode == 400) {
      throw ApiException(body['error'] as String? ?? 'Cannot close voting.');
    }
    if (response.statusCode != 200) {
      throw ApiException(
        body['error'] as String? ?? 'Failed to close voting',
        statusCode: response.statusCode,
      );
    }

    return IrvResult.fromJson(body);
  }
}