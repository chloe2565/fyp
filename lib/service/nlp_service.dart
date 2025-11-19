import 'dart:convert';
import 'package:http/http.dart' as http;

class NLPService {
  static const String baseUrl = 'https://fyp-nlp-letu.onrender.com';

  // Extract keyword from service request description
  static Future<KeywordAnalysis?> extractKeywords(
    String reqID,
    String description,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/batch-extract'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reqID': reqID, 'description': description}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return KeywordAnalysis.fromJson(data);
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception in extractKeywords: $e');
      return null;
    }
  }

  // Analyze description
  static Future<ComprehensiveAnalysis?> analyzeDescription(
    String description,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': description}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ComprehensiveAnalysis.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Exception in analyzeDescription: $e');
      return null;
    }
  }

  // Batch process multiple requests
  static Future<List<KeywordAnalysis>> batchExtract(
    List<Map<String, String>> requests,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/batch-extract'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requests': requests}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        return results.map((json) => KeywordAnalysis.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Exception in batchExtract: $e');
      return [];
    }
  }
}

class KeywordAnalysis {
  final String reqID;
  final List<String> keywords;
  final String urgency;
  final String suggestedCategory;
  final String complexity;
  final Map<String, dynamic>? analysis;

  KeywordAnalysis({
    required this.reqID,
    required this.keywords,
    required this.urgency,
    required this.suggestedCategory,
    this.complexity = 'normal',
    this.analysis,
  });

  factory KeywordAnalysis.fromJson(Map<String, dynamic> json) {
    return KeywordAnalysis(
      reqID: json['reqID'] ?? '',
      keywords: [],
      urgency: json['urgency'] ?? 'normal',
      suggestedCategory: json['suggestedCategory'] ?? 'general',
      complexity: json['complexity'] ?? 'normal',
      analysis: json['analysis'],
    );
  }
}

class ComprehensiveAnalysis {
  final List<String> keywords;
  final String urgency;
  final String category;
  final String complexity;
  final Map<String, dynamic> insights;
  final List<String> recommendations;

  ComprehensiveAnalysis({
    required this.keywords,
    required this.urgency,
    required this.category,
    required this.complexity,
    required this.insights,
    required this.recommendations,
  });

  factory ComprehensiveAnalysis.fromJson(Map<String, dynamic> json) {
    final insightsMap = json['insights'] ?? {};

    return ComprehensiveAnalysis(
      keywords: List<String>.from(json['keywords'] ?? []),
      urgency: json['urgency'] ?? 'normal',
      category: json['category'] ?? 'general',
      complexity: insightsMap['complexity'] ?? 'medium',
      insights: json['insights'] ?? {},
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}
