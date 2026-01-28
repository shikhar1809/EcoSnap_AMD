import 'package:dio/dio.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost
  // Use localhost for iOS simulator or web
  static const String baseUrl = 'http://127.0.0.1:8000'; 
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<String> getHealthStatus() async {
    try {
      final response = await _dio.get('/health');
      return response.data['status'] ?? 'unknown';
    } catch (e) {
      return 'error: $e';
    }
  }

  Future<Map<String, dynamic>> uploadImage(List<int> bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'files': MultipartFile.fromBytes(bytes, filename: filename),
      });
      
      final response = await _dio.post(
        '/analysis/analyze', 
        data: formData,
      );
      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  Future<Map<String, dynamic>> askAdvisor(String userId, String message, {String context = ""}) async {
    try {
      final response = await _dio.post('/chat/ask', data: {
        'user_id': userId,
        'message': message,
        'context': context,
      });
      return response.data;
    } catch (e) {
      return {'error': e.toString(), 'response': 'Could not connect to Advisor.'};
    }
  }

  Future<void> rewardUser(String userId, String action) async {
    try {
      await _dio.post('/gamification/reward', data: {
        'user_id': userId,
        'action': action,
      });
    } catch (e) {
      print('Reward error: $e');
    }
  }

  Future<List<dynamic>> getLeaderboard() async {
    try {
      final response = await _dio.get('/gamification/leaderboard');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }
}
