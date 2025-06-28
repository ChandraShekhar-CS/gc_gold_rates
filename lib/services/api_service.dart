import 'dart:async'; // Import the async library for TimeoutException
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _liveApiUrl = "https://goldrate.divyanshbansal.com/api/live";
  final String _graphApiBaseUrl =
      "https://goldrate.divyanshbansal.com/api/rates";

  Future<Map<String, dynamic>> fetchLiveRates() async {
    final url = Uri.parse(_liveApiUrl);
    try {
      // We will now give the request 20 seconds to complete before timing out.
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20)); // Added timeout

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load live rates. Status code: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      // This will be thrown if the server doesn't respond in 20 seconds.
      throw Exception('The connection to the server timed out.');
    } catch (e) {
      // Catches other errors, like no internet connection.
      throw Exception('Failed to connect to the server. Error: $e');
    }
  }

  Future<Map<String, dynamic>> fetchGraphData(
    String series,
    String queryParams,
  ) async {
    final url = Uri.parse('$_graphApiBaseUrl$queryParams');
    try {
      // Also adding a timeout to the graph data request for consistency.
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20)); // Added timeout

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load graph data. Status code: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('The connection to the server timed out.');
    } catch (e) {
      throw Exception('Failed to connect to the server. Error: $e');
    }
  }
}
