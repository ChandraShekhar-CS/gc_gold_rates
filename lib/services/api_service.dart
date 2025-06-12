import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _liveApiUrl = "https://goldrate.divyanshbansal.com/api/live";
  final String _graphApiBaseUrl =
      "https://goldrate.divyanshbansal.com/api/rates";
  Future<Map<String, dynamic>> fetchLiveRates() async {
    final url = Uri.parse(_liveApiUrl);
    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load live rates. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server. Error: $e');
    }
  }

  Future<Map<String, dynamic>> fetchGraphData(
    String series,
    String queryParams,
  ) async {
    final url = Uri.parse('$_graphApiBaseUrl/$series$queryParams');
    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load graph data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server. Error: $e');
    }
  }
}
