import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/api_service.dart';

class StoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _stories = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get stories => _stories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/stories/feed');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _stories = data['data']['stories'];
      } else {
        _error = data['message'] ?? 'Failed to load stories';
      }
    } catch (e) {
      _error = 'Connection error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadStory(String filePath, {String caption = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.uploadFile('/stories/create', filePath, 'media');
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        await fetchStories(); // Refresh stories
        return true;
      } else {
        _error = data['message'] ?? 'Upload failed';
        return false;
      }
    } catch (e) {
      _error = 'Connection error';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<bool> deleteStory(int storyId) async {
    try {
      final response = await _apiService.delete('/stories/$storyId');
      if (response.statusCode == 200) {
        await fetchStories(); // Refresh
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
