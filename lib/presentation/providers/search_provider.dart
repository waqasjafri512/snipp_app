import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/api_service.dart';

class SearchProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  Timer? _debounceTimer;
  
  bool _isLoading = false;
  List<dynamic> _searchResultsUsers = [];
  List<dynamic> _searchResultsDares = [];
  List<dynamic> _trendingDares = [];
  List<dynamic> _trendingUsers = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get searchResultsUsers => _searchResultsUsers;
  List<dynamic> get searchResultsDares => _searchResultsDares;
  List<dynamic> get trendingDares => _trendingDares;
  List<dynamic> get trendingUsers => _trendingUsers;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Global Search with debounce
  Future<void> search(String query) async {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      _searchResultsUsers = [];
      _searchResultsDares = [];
      notifyListeners();
      return;
    }

    // Debounce: wait 300ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
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
    });
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

  // Get Trending Creators
  Future<void> fetchTrendingCreators() async {
    try {
      final response = await _apiService.get('/search/trending/creators');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _trendingUsers = data['data']['users'];
        notifyListeners();
      }
    } catch (e) {
      print('Trending creators error: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
