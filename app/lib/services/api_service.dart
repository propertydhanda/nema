import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://localhost:8600';

  // ── CAPTURE ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> capture({
    required String text,
    String sourceType = 'direct',
    String inputModality = 'text',
    String? eventAt,
    String? locationLabel,
    List<String>? peopleNames,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/capture'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'source_type': sourceType,
        'input_modality': inputModality,
        if (eventAt != null) 'event_at': eventAt,
        if (locationLabel != null) 'location_label': locationLabel,
        if (peopleNames != null) 'people_names': peopleNames,
      }),
    );
    return jsonDecode(res.body);
  }

  // ── RECALL ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> recall({
    required String query,
    int limit = 10,
    String? layerFilter,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/recall'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'limit': limit,
        if (layerFilter != null) 'layer_filter': layerFilter,
      }),
    );
    final data = jsonDecode(res.body);
    return data['results'] ?? [];
  }

  // ── MEMORIES ──────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getMemories({int limit = 50, String? layer}) async {
    var url = '$baseUrl/memories?limit=$limit';
    if (layer != null) url += '&layer=$layer';
    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);
    return data['memories'] ?? [];
  }

  // ── STATS ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getStats() async {
    final res = await http.get(Uri.parse('$baseUrl/stats'));
    return jsonDecode(res.body);
  }

  // ── IDENTITY ──────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getIdentity() async {
    final res = await http.get(Uri.parse('$baseUrl/identity'));
    final data = jsonDecode(res.body);
    return data['identity'] ?? [];
  }

  static Future<Map<String, dynamic>> addStatement({
    required String type,
    required String content,
    String certainty = 'certain',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/identity/statement'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'statement_type': type, 'content': content, 'certainty': certainty}),
    );
    return jsonDecode(res.body);
  }

  // ── PEOPLE ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getPeople() async {
    final res = await http.get(Uri.parse('$baseUrl/people'));
    final data = jsonDecode(res.body);
    return data['people'] ?? [];
  }

  // ── HEALTH ────────────────────────────────────────────────────────────────
  static Future<bool> isAlive() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
