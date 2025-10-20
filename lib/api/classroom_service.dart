import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/classroom.model.dart';

class ClassroomService {
  static const int _timeoutDuration = 10; // Timeout in seconds
  static const int _maxRetries = 2; // Max retry attempts for failed requests
  static const String _cacheKey = 'classrooms';
  static const String _cacheTimestampKey = 'classrooms_timestamp';
  static const String _cacheHashKey = 'classrooms_hash';
  static const int _cacheValidityHours = 24; // Cache valid for 24 hours

  // Common headers for HTTP requests
  Future<Map<String, String>> _setHeaders(String token) async {
    var newToken = token.replaceAll('"', "");
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': newToken,
    };
  }

  // Generic HTTP GET with retry logic
  Future<http.Response> _getWithRetry(String url, Map<String, String> headers) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        debugPrint('=== GET Request (Attempt ${attempt + 1}/$_maxRetries) ===');
        debugPrint('URL: $url');
        debugPrint('Headers: $headers');

        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(Duration(seconds: _timeoutDuration));

        debugPrint('Response Status: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('========================================');

        return response;
      } catch (e) {
        attempt++;
        debugPrint('Request failed (Attempt $attempt/$_maxRetries): $e');
        if (attempt == _maxRetries) {
          debugPrint('Max retries reached. Request failed.');
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    throw Exception('Request failed after $_maxRetries attempts');
  }

  // Generate hash for data comparison
  String _generateHash(String data) {
    return data.hashCode.toString();
  }

  // Check if cache is valid
  Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);
      
      if (timestamp == null) return false;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      return difference.inHours < _cacheValidityHours;
    } catch (e) {
      debugPrint('Error checking cache validity: $e');
      return false;
    }
  }

  // Check if data has changed
  Future<bool> _hasDataChanged(String newData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedHash = prefs.getString(_cacheHashKey);
      final newHash = _generateHash(newData);

      return cachedHash != newHash;
    } catch (e) {
      debugPrint('Error checking data changes: $e');
      return true; // Assume changed if error
    }
  }

  // Save to cache
  Future<void> _saveToCache(String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hash = _generateHash(data);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(_cacheKey, data);
      await prefs.setString(_cacheHashKey, hash);
      await prefs.setInt(_cacheTimestampKey, timestamp);

      debugPrint('Cache updated successfully');
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  // Load from cache
  Future<SchoolClassroomModel?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData == null) return null;

      final jsonData = jsonDecode(cachedData);
      debugPrint('Loaded classrooms from cache');
      return SchoolClassroomModel.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error loading from cache: $e');
      await _clearCache();
      return null;
    }
  }

  // Clear cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheHashKey);
      await prefs.remove(_cacheTimestampKey);
      debugPrint('Cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Fetch school classrooms with smart caching
  Future<SchoolClassroomModel> fetchSchoolClassrooms({
    bool forceRefresh = false,
  }) async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      String token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      // Check cache first (unless force refresh)
      if (!forceRefresh && await _isCacheValid()) {
        final cachedModel = await _loadFromCache();
        if (cachedModel != null) {
          debugPrint('Using cached classrooms (cache is valid)');
          return cachedModel;
        }
      }

      // Fetch fresh data
      debugPrint('Fetching fresh classrooms data...');
      final response = await _getWithRetry(
        '${dotenv.get('mainUrl')}/api/classrooms?page=0&size=50',
        headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch classrooms: ${response.statusCode}');
      }

      final Map<String, dynamic> results = jsonDecode(response.body);
      final responseBody = jsonEncode(results);

      debugPrint("Classrooms: ${results['data'].toString()}");

      final classroomModel = SchoolClassroomModel.fromJson(results);
      debugPrint("Classroom Model: ${classroomModel.data?.classrooms?.length}");

      if (classroomModel.success == true) {
        // Only update cache if data has changed
        if (await _hasDataChanged(responseBody)) {
          debugPrint('Data has changed, updating cache...');
          await _saveToCache(responseBody);
        } else {
          debugPrint('Data unchanged, keeping existing cache');
          // Update timestamp to extend cache validity
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
        }
      }

      return classroomModel;
    } catch (e) {
      debugPrint("Error fetching classrooms: $e");

      // Try to return cached data as fallback
      final cachedModel = await _loadFromCache();
      if (cachedModel != null) {
        debugPrint('Using cached data as fallback due to error');
        return cachedModel;
      }

      return SchoolClassroomModel(
        status: 500,
        success: false,
        message: "Failed to fetch classrooms: $e",
        data: null,
      );
    }
  }

  // Method to manually clear cache (useful for logout or data refresh)
  Future<void> clearClassroomCache() async {
    await _clearCache();
  }
}