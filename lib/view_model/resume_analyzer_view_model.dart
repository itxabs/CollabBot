import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ResumeAnalyzerViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _score;
  int? get score => _score;

  List<String> _recommendations = [];
  List<String> get recommendations => _recommendations;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _fileName;
  String? get fileName => _fileName;

  // Platform-specific localhost
  // Android Emulator: 10.0.2.2
  // iOS/Web/Windows: 127.0.0.1
  String get _baseUrl {
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://10.69.48.133:8000';
    }
    return 'http://127.0.0.1:8000';
  } 

  Future<void> pickAndAnalyzeFile() async {
    try {
      _errorMessage = null;
      notifyListeners();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        _fileName = result.files.single.name;
        notifyListeners();
        
        await _analyzeResume(file);
      } else {
        // User canceled the picker
      }
    } catch (e) {
      _errorMessage = "Error picking file: $e";
      notifyListeners();
    }
  }

  Future<void> _analyzeResume(File file) async {
    _isLoading = true;
    _score = null;
    _recommendations = [];
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/analyze-resume'),
      );

      request.fields['user_id'] = 'test_user_flutter'; // TODO: Replace with actual user ID
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _score = data['score'];
        _recommendations = List<String>.from(data['recommendations']);
      } else {
        _errorMessage = "Server error: ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      _errorMessage = "Failed to connect to backend: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
