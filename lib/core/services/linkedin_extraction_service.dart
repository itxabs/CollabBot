import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// LinkedIn Profile Data Extraction Service
/// 
/// Dart client for communicating with the Python backend LinkedIn extraction service.
/// Supports:
/// - HTML parsing (LinkedIn profile HTML)
/// - Image extraction (OCR from screenshots)
/// - Resume analysis
/// - Health check

class LinkedInExtractionService {
  // Backend URL - Update this to match your server URL
  static String get baseUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://192.168.1.5:8000';
    }
    return 'http://127.0.0.1:8000';
  }
  
  static const String htmlExtractEndpoint = '/linkedin/extract/html';
  static const String imageExtractEndpoint = '/linkedin/extract/image';
  static const String resumeAnalyzeEndpoint = '/analyze-resume';
  static const String healthCheckEndpoint = '/health';

  /// Extract LinkedIn data from HTML content
  /// 
  /// Args:
  ///   html: Raw HTML from LinkedIn profile page
  /// 
  /// Returns:
  ///   Map with 'skills' (List) and 'experience' (List)
  static Future<Map<String, dynamic>> extractFromHtml(String html) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$htmlExtractEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'html': html,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to extract from HTML: ${e.toString()}',
        'skills': <String>[],
        'experience': <Map<String, dynamic>>[],
      };
    }
  }

  /// Extract LinkedIn data from image screenshot using OCR
  /// 
  /// Args:
  ///   imagePath: Path to image file (PNG, JPG, etc.)
  /// 
  /// Returns:
  ///   Map with 'skills' (List) and 'experience' (List)
  static Future<Map<String, dynamic>> extractFromImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      
      if (!await imageFile.exists()) {
        return {
          'success': false,
          'error': 'Image file not found: $imagePath',
          'skills': <String>[],
          'experience': <Map<String, dynamic>>[],
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$imageExtractEndpoint'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imagePath),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Request timeout'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to extract from image: ${e.toString()}',
        'skills': <String>[],
        'experience': <Map<String, dynamic>>[],
      };
    }
  }

  /// Analyze a resume file (PDF or DOCX)
  /// 
  /// Args:
  ///   filePath: Path to resume file
  ///   userId: User ID for storing the resume
  /// 
  /// Returns:
  ///   Map with 'score' (int) and 'recommendations' (List<String>)
  static Future<Map<String, dynamic>> analyzeResume(
    String filePath,
    String userId,
  ) async {
    try {
      final File resumeFile = File(filePath);
      
      if (!await resumeFile.exists()) {
        return {
          'success': false,
          'error': 'Resume file not found: $filePath',
          'score': 0,
          'recommendations': <String>[],
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$resumeAnalyzeEndpoint'),
      );

      request.fields['user_id'] = userId;
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Request timeout'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'score': result['score'] ?? 0,
          'recommendations': result['recommendations'] ?? <String>[],
        };
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to analyze resume: ${e.toString()}',
        'score': 0,
        'recommendations': <String>[],
      };
    }
  }

  /// Check health of all backend services
  /// 
  /// Returns:
  ///   Map with service status information
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$healthCheckEndpoint'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'status': 'unhealthy',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 'offline',
        'error': 'Backend unavailable: ${e.toString()}',
      };
    }
  }

  /// Parse extracted experience data into structured format
  /// 
  /// Args:
  ///   experienceList: Raw experience data from extraction
  /// 
  /// Returns:
  ///   List of parsed experience objects
  static List<Map<String, String>> parseExperience(
    List<dynamic> experienceList,
  ) {
    return experienceList
        .map((exp) => {
              'roleCompany': exp['role_company'] ?? '',
              'duration': exp['duration'] ?? '',
            })
        .cast<Map<String, String>>()
        .toList();
  }

  /// Validate extraction result
  /// 
  /// Args:
  ///   result: Extraction result map
  /// 
  /// Returns:
  ///   true if result has required fields
  static bool validateResult(Map<String, dynamic> result) {
    return result.containsKey('skills') &&
        result.containsKey('experience') &&
        result['skills'] is List &&
        result['experience'] is List;
  }
}
