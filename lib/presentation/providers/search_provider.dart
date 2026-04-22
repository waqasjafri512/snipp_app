import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/api_service.dart';

class SearchProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  List<dynamic> _searchResultsUsers = [];
  List<dynamic> _searchResultsDares = [];
  List<dynamic> _trendingDares = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get searchResultsUsers => _searchResultsUsers;
  List<dynamic> get searchResultsDares => _searchResultsDares;
  List<dynamic> get trendingDares => _trendingDares;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Global Search
  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResultsUsers = [];
      _searchResultsDares = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.get('/search?q=$query');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _searchResultsUsers = data['data']['users'];
        _searchResultsDares = data['data']['dares'];
      } else {
        _error = data['message'] ?? 'Search failed';
      }
    } catch (e) {
      _error = 'Connection error';
    } finally {
      _setLoading(false);
    }
  }

  // Get Trending
  Future<void> fetchTrending() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/search/trending');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _trendingDares = data['data']['dares'];
      }
    } catch (e) {
      print('Trending error: $e');
    } finally {
      _setLoading(false);
    }
  }
}
