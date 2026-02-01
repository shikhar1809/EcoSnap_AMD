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

  Future<Map<String, dynamic>> getAnalysisQuestions(List<int> bytes, String filename, {String? userNote, String scanMode = "quick"}) async {
    try {
      final formData = FormData.fromMap({
        'files': MultipartFile.fromBytes(bytes, filename: filename),
        if (userNote != null) 'user_note': userNote,
        'scan_mode': scanMode,  // Pass quick/deep mode to backend
      });
      final response = await _dio.post('/analysis/analyze/context', data: formData);
      return Map<String, dynamic>.from(response.data);
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
      return Map<String, dynamic>.from(response.data);
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
      return Map<String, dynamic>.from(response.data);
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
      return Map<String, dynamic>.from(response.data);
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
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        throw e.response!.data['detail'] ?? "Redemption failed";
      }
      throw e.toString();
    }
  }

  // ==================== CCTS 2023 CARBON CREDITS ====================

  Future<Map<String, dynamic>> calculateCompliance(String sector, double emissions, double production) async {
    try {
      final response = await _dio.post('/carbon/ccts/calculate', data: {
        'sector': sector,
        'emissions_tco2': emissions,
        'production_tonnes': production
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCarbonWallet(String userId) async {
    try {
      final response = await _dio.get('/carbon/wallet/$userId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getOffsetProjects(String userId) async {
    try {
      final response = await _dio.get('/carbon/offset/projects/$userId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> calculateOffset(String userId, String type, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/carbon/offset/calculate', data: {
        'user_id': userId,
        'project_type': type,
        'project_data': data
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMarketPrice() async {
    try {
      final response = await _dio.get('/carbon/ccts/market/price');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ==================== SUBSIDIES ====================

  Future<Map<String, dynamic>> recommendSubsidies(String state, String action, {double? capacityKw, String? incomeBracket}) async {
    try {
      final response = await _dio.post('/subsidies/recommend', data: {
        'state': state,
        'action': action,
        'capacity_kw': capacityKw,
        'income_bracket': incomeBracket
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSubsidyCoverage() async {
    try {
      final response = await _dio.get('/subsidies/coverage');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<List<dynamic>> getTrendingSubsidies(String state) async {
    try {
      final response = await _dio.get('/subsidies/trending/$state');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getDemoSolarCalculation(String state, double capacityKw) async {
    try {
      final response = await _dio.get('/subsidies/demo/solar-calculation', queryParameters: {
        'state': state,
        'capacity_kw': capacityKw
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ==================== COMMUNITY ====================

  Future<Map<String, dynamic>> getCommunityFeed(String city) async {
    try {
      final response = await _dio.get('/community/feed', queryParameters: {'city': city});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCommunityLeaderboard(String city) async {
    try {
      final response = await _dio.get('/community/leaderboard', queryParameters: {'city': city});
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getCommunityInsights(String city) async {
    try {
      final response = await _dio.get('/community/insights/$city');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ==================== MARKETPLACE ====================

  Future<Map<String, dynamic>> getMarketplaceProducts({String? category}) async {
    try {
      final response = await _dio.get('/marketplace/products', queryParameters: 
        category != null ? {'category': category} : {}
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getDemoSolarSystem(double capacityKw) async {
    try {
      final response = await _dio.get('/marketplace/demo/solar-system', queryParameters: {
        'capacity_kw': capacityKw
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> analyzeBill(String base64Image) async {
    try {
      final response = await _dio.post('/carbon/analyze_bill', data: {
        'image': base64Image,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
