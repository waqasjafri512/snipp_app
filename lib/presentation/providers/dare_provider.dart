import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';

class DareProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  StreamSubscription? _socketSub;
  
  DareProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _socketSub?.cancel();
    _socketSub = SocketService().eventStream.listen((event) {
      if (event['event'] == 'newDare') {
        final newDare = event['data'];
        final exists = _feedDares.any((d) => d['id'].toString() == newDare['id'].toString());
        if (!exists) {
          _feedDares.insert(0, newDare);
          notifyListeners();
        }
      } else if (event['event'] == 'dareUpdated') {
        final updatedDare = event['data'];
        final index = _feedDares.indexWhere((d) => d['id'] == updatedDare['id']);
        if (index != -1) {
          _feedDares[index] = updatedDare;
          notifyListeners();
        }
      } else if (event['event'] == 'newComment') {
        final data = event['data'];
        final dareId = data['dare_id'];
        final comment = data['comment'];

        // Update comment list if we are viewing this dare's comments
        if (_selectedDare != null && _selectedDare!['id'].toString() == dareId.toString()) {
          final exists = _comments.any((c) => c['id'].toString() == comment['id'].toString());
          if (!exists) {
            _comments.add(comment);
          }
        }

        // Update comment count in feed
        final feedIndex = _feedDares.indexWhere((d) => d['id'].toString() == dareId.toString());
        if (feedIndex != -1) {
          _feedDares[feedIndex]['comments_count'] = (_feedDares[feedIndex]['comments_count'] ?? 0) + 1;
        }
        notifyListeners();
      } else if (event['event'] == 'dareDeleted') {
        final dareId = event['data'];
        _feedDares.removeWhere((d) => d['id'] == dareId);
        notifyListeners();
      }
    });
  }
  
  bool _isLoading = false;
  List<dynamic> _feedDares = [];
  Map<String, dynamic>? _selectedDare;
  List<dynamic> _comments = [];
  List<dynamic> _categories = [];
  List<dynamic> _userParticipatedDares = [];
  String? _error;

  bool get isLoading => _isLoading;
  List<dynamic> get feedDares => _feedDares;
  List<dynamic> get userParticipatedDares => _userParticipatedDares;
  Map<String, dynamic>? get selectedDare => _selectedDare;
  List<dynamic> get comments => _comments;
  List<dynamic> get categories => _categories;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch Feed
  Future<void> fetchFeed({int page = 1}) async {
    if (page == 1) _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.get('/dares/feed?page=$page');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        if (page == 1) {
          _feedDares = data['data']['dares'];
        } else {
          _feedDares.addAll(data['data']['dares']);
        }
      } else {
        _error = data['message'] ?? 'Failed to fetch feed';
      }
    } catch (e) {
      _error = 'Connection error';
    } finally {
      if (page == 1) _setLoading(false);
      notifyListeners();
    }
  }

  // Create Dare
  Future<bool> createDare(Map<String, dynamic> dareData, Map<String, dynamic>? userInfo) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/dares/create', dareData);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        final newDare = Map<String, dynamic>.from(data['data']['dare']);
        // Inject creator info for immediate UI update
        if (userInfo != null) {
          newDare['creator_username'] = userInfo['username'];
          newDare['creator_full_name'] = userInfo['full_name'];
          newDare['creator_avatar'] = userInfo['avatar_url'];
          newDare['creator_verified'] = userInfo['is_verified'];
          newDare['likes_count'] = 0;
          newDare['comments_count'] = 0;
          newDare['is_liked'] = false;
          newDare['is_accepted'] = false;
        }
        _feedDares.insert(0, newDare);
        _setLoading(false);
        return true;
      } else {
        _error = data['message'] ?? 'Failed to create dare';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }

  // Toggle Like
  Future<void> toggleLike(int dareId) async {
    final index = _feedDares.indexWhere((d) => d['id'] == dareId);
    if (index == -1) return;

    final dare = _feedDares[index];
    final bool isLiked = dare['is_liked'] ?? false;

    // Optimistic UI update
    _feedDares[index]['is_liked'] = !isLiked;
    _feedDares[index]['likes_count'] = isLiked 
        ? (_feedDares[index]['likes_count'] - 1) 
        : (_feedDares[index]['likes_count'] + 1);
    notifyListeners();

    try {
      await _apiService.post('/dares/$dareId/like', {});
    } catch (e) {
      // Revert on error
      _feedDares[index]['is_liked'] = isLiked;
      _feedDares[index]['likes_count'] = isLiked 
          ? (_feedDares[index]['likes_count'] + 1) 
          : (_feedDares[index]['likes_count'] - 1);
      notifyListeners();
    }
  }

  // Accept Dare
  Future<bool> acceptDare(int dareId) async {
    try {
      final response = await _apiService.post('/dares/$dareId/accept', {});
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        final index = _feedDares.indexWhere((d) => d['id'] == dareId);
        if (index != -1) {
          _feedDares[index]['is_accepted'] = true;
          _feedDares[index]['accepts_count'] = (_feedDares[index]['accepts_count'] ?? 0) + 1;
          _userParticipatedDares.add(_feedDares[index]);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Fetch Comments
  Future<void> fetchComments(int dareId) async {
    _comments = [];
    // Set selected dare for real-time updates
    final index = _feedDares.indexWhere((d) => d['id'].toString() == dareId.toString());
    if (index != -1) {
      _selectedDare = _feedDares[index];
    }

    try {
      final response = await _apiService.get('/dares/$dareId/comments');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _comments = data['data']['comments'];
        notifyListeners();
      }
    } catch (e) {
      print('Comments fetch error: $e');
    }
  }

  // Add Comment
  Future<bool> addComment(int dareId, String content, {int? parentId}) async {
    try {
      final response = await _apiService.post('/dares/$dareId/comment', {
        'content': content,
        'parent_id': parentId,
      });
      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success']) {
        _comments.add(data['data']['comment']);
        // Update dare comment count in feed
        final index = _feedDares.indexWhere((d) => d['id'] == dareId);
        if (index != -1) {
          _feedDares[index]['comments_count'] = (_feedDares[index]['comments_count'] ?? 0) + 1;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Toggle Comment Like
  Future<void> toggleCommentLike(int commentId) async {
    final index = _comments.indexWhere((c) => c['id'] == commentId);
    if (index == -1) return;

    final comment = _comments[index];
    final bool isLiked = comment['is_liked'] ?? false;
    final int likesCount = comment['likes_count'] ?? 0;

    // Optimistic UI update
    _comments[index]['is_liked'] = !isLiked;
    _comments[index]['likes_count'] = !isLiked ? (likesCount + 1) : (likesCount - 1);
    notifyListeners();

    try {
      await _apiService.post('/dares/comments/$commentId/like', {});
    } catch (e) {
      // Revert on error
      _comments[index]['is_liked'] = isLiked;
      _comments[index]['likes_count'] = likesCount;
      notifyListeners();
    }
  }

  // Fetch Categories
  Future<void> fetchCategories() async {
    try {
      final response = await _apiService.get('/dares/categories');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _categories = data['data']['categories'];
        notifyListeners();
      }
    } catch (e) {
      print('Categories error: $e');
    }
  }

  // Delete Dare
  Future<bool> deleteDare(int dareId) async {
    final index = _feedDares.indexWhere((d) => d['id'] == dareId);
    if (index == -1) return false;

    final backup = _feedDares[index];
    
    // Optimistic removal
    _feedDares.removeAt(index);
    notifyListeners();

    try {
      final response = await _apiService.delete('/dares/$dareId');
      if (response.statusCode == 200) return true;
      
      // Revert if failed
      _feedDares.insert(index, backup);
      notifyListeners();
      return false;
    } catch (e) {
      _feedDares.insert(index, backup);
      notifyListeners();
      return false;
    }
  }

  // Update Dare
  Future<bool> updateDare(int dareId, Map<String, dynamic> dareData) async {
    _setLoading(true);
    try {
      final response = await _apiService.put('/dares/$dareId', dareData);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final index = _feedDares.indexWhere((d) => d['id'] == dareId);
        if (index != -1) {
          // Merge updates while keeping creator info etc.
          _feedDares[index] = <String, dynamic>{
            ..._feedDares[index],
            ...data['data']['dare'],
          };
        }
        _setLoading(false);
        return true;
      } else {
        _error = data['message'] ?? 'Failed to update dare';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }

  // Complete Dare (Submit Proof)
  Future<bool> completeDare(int dareId, String proofUrl) async {
    _setLoading(true);
    try {
      final response = await _apiService.post('/dares/$dareId/complete', {'proof_url': proofUrl});
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final index = _feedDares.indexWhere((d) => d['id'] == dareId);
        if (index != -1) {
          _feedDares[index]['is_accepted'] = true;
        }
        _setLoading(false);
        return true;
      } else {
        _error = data['message'] ?? 'Failed to complete dare';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }
}
