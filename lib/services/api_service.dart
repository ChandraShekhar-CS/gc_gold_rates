// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Handles all network requests for the application.
class ApiService {
  final String _liveApiUrl = "https://goldrate.divyanshbansal.com/api/live";
  final String _graphApiBaseUrl = "https://goldrate.divyanshbansal.com/api/rates";

  /// Fetches the live rates for the main screen cards.
  Future<Map<String, dynamic>> fetchLiveRates() async {
    final url = Uri.parse(_liveApiUrl);
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load live rates. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Rethrow the exception to be caught by the provider.
      throw Exception('Failed to connect to the server. Error: $e');
    }
  }

  /// Fetches historical data for the graphs screen.
  /// The [queryParams] is a string like "?startDate=2023-01-01&endDate=2023-01-02&resolution=hour"
  Future<Map<String, dynamic>> fetchGraphData(String series, String queryParams) async {
    // The series name must be part of the URL path.
    final url = Uri.parse('$_graphApiBaseUrl/$series$queryParams');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load graph data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Rethrow the exception to be caught by the UI.
      throw Exception('Failed to connect to the server. Error: $e');
    }
  }
}
