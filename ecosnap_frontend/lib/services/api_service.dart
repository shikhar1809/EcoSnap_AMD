import 'package:dio/dio.dart';
import 'dart:convert';

class ApiService {
  // Use 10.0.2.2 for Android emulator to access localhost
  // Use localhost for iOS simulator or web
  // Use 192.168.1.2 for LAN access (Mobile + PC)
  static const String baseUrl = 'http://localhost:8000'; 
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<String> getHealthStatus() async {
    try {
      final response = await _dio.get('/health');
      return response.data['status'] ?? 'unknown';
    } catch (e) {
      return 'error: $e';
    }
  }

  Future<Map<String, dynamic>> getAnalysisQuestions(List<int> bytes, String filename, {String? userNote}) async {
    try {
      final formData = FormData.fromMap({
        'files': MultipartFile.fromBytes(bytes, filename: filename),
        if (userNote != null) 'user_note': userNote,
      });
      final response = await _dio.post('/analysis/analyze/context', data: formData);
      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadImage(List<int> bytes, String filename, Map<String, dynamic> userResponses) async {
    try {
      // Serialize answers to JSON string
      String responsesJson = "{}";
      // Manually simple serialization or use jsonEncode if imported
      // Assuming simple strings for now or import dart:convert
      
      final formData = FormData.fromMap({
        'files': MultipartFile.fromBytes(bytes, filename: filename),
        'user_responses': jsonEncode(userResponses), 
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

  Future<void> rewardUser(String userId, String action, {double carbonKg = 0.0}) async {
    try {
      await _dio.post('/gamification/reward', data: {
        'user_id': userId,
        'action': action,
        'carbon_kg': carbonKg
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

  Future<Map<String, dynamic>> getUserStatus(String userId) async {
    try {
      final response = await _dio.get('/gamification/status/$userId');
      return response.data;
    } catch (e) {
      return {};
    }
  }

  Future<List<dynamic>> getMarketplaceItems() async {
    try {
      final response = await _dio.get('/gamification/marketplace');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> redeemItem(String userId, String itemId) async {
    try {
      final response = await _dio.post('/gamification/redeem', data: {
        'user_id': userId,
        'item_id': itemId,
      });
      return response.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw e.response!.data['detail'] ?? "Redemption failed";
      }
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> analyzeBill(String base64Image) async {
    try {
      final response = await _dio.post('/carbon/analyze_bill', data: {
        'image': base64Image,
      });
      return response.data;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
