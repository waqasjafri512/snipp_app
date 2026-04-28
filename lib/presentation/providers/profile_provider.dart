import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/repositories/api_service.dart';
import '../../data/services/socket_service.dart';

class ProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  StreamSubscription? _socketSub;

  ProfileProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _socketSub?.cancel();
    _socketSub = SocketService().eventStream.listen((event) {
      if (event['event'] == 'newDare') {
        final newDare = event['data'];
        final creatorId = newDare['creator_id']?.toString();
        final currentProfileId = _userProfile?['id']?.toString();
        
        if (currentProfileId != null && creatorId == currentProfileId) {
          final exists = _userDares.any((d) => d['id'].toString() == newDare['id'].toString());
          if (!exists) {
            _userDares.insert(0, newDare);
            // Increment posted count if it exists in profile
            if (_userProfile != null && _userProfile!['dares_posted'] != null) {
              _userProfile!['dares_posted'] = (_userProfile!['dares_posted'] ?? 0) + 1;
            }
            notifyListeners();
          }
        }
      } else if (event['event'] == 'dareDeleted') {
        final dareId = event['data'];
        _userDares.removeWhere((d) => d['id'] == dareId);
        _participatedDares.removeWhere((d) => d['id'] == dareId);
        notifyListeners();
      } else if (event['event'] == 'dareUpdated') {
        final updatedDare = event['data'];
        final index = _userDares.indexWhere((d) => d['id'] == updatedDare['id']);
        if (index != -1) {
          _userDares[index] = updatedDare;
          notifyListeners();
        }
        final pIndex = _participatedDares.indexWhere((d) => d['id'] == updatedDare['id']);
        if (pIndex != -1) {
          _participatedDares[pIndex] = updatedDare;
          notifyListeners();
        }
      }
    });
  }
  
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  List<dynamic> _userDares = [];
  List<dynamic> _participatedDares = [];
  List<dynamic> _followersList = [];
  List<dynamic> _followingList = [];
  String? _error;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<dynamic> get userDares => _userDares;
  List<dynamic> get participatedDares => _participatedDares;
  List<dynamic> get followersList => _followersList;
  List<dynamic> get followingList => _followingList;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Get Profile
  Future<void> fetchProfile(int userId) async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.get('/profile/$userId');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _userProfile = data['data']['profile'];
        _updateFollowStatus(userId, _userProfile!['is_following'] ?? false);
      } else {
        _error = data['message'] ?? 'Failed to fetch profile';
      }
    } catch (e) {
      _error = 'Connection error';
    } finally {
      _setLoading(false);
    }
  }

  // Add dare locally (used after creation)
  void addDareLocally(Map<String, dynamic> dare) {
    final exists = _userDares.any((d) => d['id'].toString() == dare['id'].toString());
    if (!exists) {
      _userDares.insert(0, dare);
      if (_userProfile != null) {
        _userProfile!['dares_posted'] = (_userProfile!['dares_posted'] ?? 0) + 1;
      }
      notifyListeners();
    }
  }

  // Fetch User Dares
  Future<void> fetchUserDares(int userId) async {
    _userDares = [];
    try {
      final response = await _apiService.get('/dares/user/$userId');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _userDares = data['data']['dares'];
        notifyListeners();
      }
    } catch (e) {
      print('Fetch user dares error: $e');
    }
  }

  // Fetch Participated Dares
  Future<void> fetchParticipatedDares(int userId) async {
    _participatedDares = [];
    try {
      final response = await _apiService.get('/dares/user/$userId/participated');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _participatedDares = data['data']['dares'];
        notifyListeners();
      }
    } catch (e) {
      print('Fetch participated dares error: $e');
    }
  }

  // Fetch Followers
  Future<void> fetchFollowers(int userId) async {
    _setLoading(true);
    _followersList = [];
    try {
      final response = await _apiService.get('/profile/$userId/followers');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _followersList = data['data']['followers'];
      }
    } catch (e) {
      print('Fetch followers error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Fetch Following
  Future<void> fetchFollowing(int userId) async {
    _setLoading(true);
    _followingList = [];
    try {
      final response = await _apiService.get('/profile/$userId/following');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _followingList = data['data']['following'];
      }
    } catch (e) {
      print('Fetch following error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Upload Avatar
  Future<bool> uploadAvatar(String filePath) async {
    _setLoading(true);
    try {
      final response = await _apiService.uploadFile('/profile/upload-avatar', filePath, 'avatar');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        if (_userProfile != null) {
          _userProfile!['avatar_url'] = data['data']['avatarUrl'];
        }
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        _error = data['message'] ?? 'Upload failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }

  // Update Profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      final response = await _apiService.put('/profile/update', updates);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _userProfile = data['data']['profile'];
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Failed to update profile';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }

  final Map<int, bool> _followingStatus = {};
  
  bool isFollowing(int userId, {bool fallback = false}) => _followingStatus[userId] ?? fallback;

  List<dynamic> _blockedUsers = [];
  List<dynamic> get blockedUsers => _blockedUsers;

  // Follow/Unfollow
  Future<void> toggleFollow(int userId) async {
    final bool currentStatus = _followingStatus[userId] ?? (_userProfile != null && _userProfile!['id'] == userId ? (_userProfile!['is_following'] ?? false) : false);
    
    try {
      // Optimistic update
      _followingStatus[userId] = !currentStatus;
      if (_userProfile != null && _userProfile!['id'] == userId) {
        _userProfile!['is_following'] = !currentStatus;
        _userProfile!['followers_count'] += currentStatus ? -1 : 1;
        // Update Friend status
        _userProfile!['is_friend'] = _userProfile!['is_following'] && (_userProfile!['follows_me'] ?? false);
      }
      notifyListeners();

      if (currentStatus) {
        await _apiService.delete('/profile/unfollow/$userId');
      } else {
        await _apiService.post('/profile/follow/$userId', {});
      }
    } catch (e) {
      // Rollback on error
      _followingStatus[userId] = currentStatus;
      if (_userProfile != null && _userProfile!['id'] == userId) {
        _userProfile!['is_following'] = currentStatus;
        _userProfile!['followers_count'] += currentStatus ? 1 : -1;
      }
      notifyListeners();
      print('Follow toggle error: $e');
    }
  }

  // Update follow status when fetching profile
  void _updateFollowStatus(int userId, bool status) {
    _followingStatus[userId] = status;
    notifyListeners();
  }

  // Blocking logic
  Future<bool> blockUser(int userId) async {
    try {
      final response = await _apiService.post('/profile/block/$userId', {});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unblockUser(int userId) async {
    try {
      final response = await _apiService.post('/profile/unblock/$userId', {});
      if (response.statusCode == 200) {
        _blockedUsers.removeWhere((u) => u['id'] == userId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchBlockedUsers() async {
    _setLoading(true);
    try {
      final response = await _apiService.get('/profile/settings/blocked');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        _blockedUsers = data['data']['blockedUsers'];
      }
    } catch (e) {
      print('Fetch blocked users error: $e');
    } finally {
      _setLoading(false);
    }
  }
  // Update specific settings toggles
  Future<bool> updateProfileSettings(String key, dynamic value) async {
    if (_userProfile == null) return false;
    
    // Optimistic update
    final oldValue = _userProfile![key];
    _userProfile![key] = value;
    notifyListeners();

    try {
      final response = await _apiService.put('/profile/update', {key: value});
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        _userProfile = data['data']['profile'];
        notifyListeners();
        return true;
      } else {
        // Rollback
        _userProfile![key] = oldValue;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _userProfile![key] = oldValue;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }
}
