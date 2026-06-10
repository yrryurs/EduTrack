import 'dart:convert';
import 'package:http/http.dart' as http;

class QuoteService {
  static final QuoteService _instance = QuoteService._internal();
  factory QuoteService() => _instance;
  QuoteService._internal();

  Future<Map<String, String>> fetchQuote() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://motivational-spark-api.vercel.app/api/quotes/random',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'quote': data['quote'] ?? '',
          'author': data['author'] ?? 'Unknown',
        };
      } else {
        return {'quote': 'Stay motivated!', 'author': 'EduTrack'};
      }
    } catch (e) {
      return {'quote': 'Stay motivated!', 'author': 'EduTrack'};
    }
  }
}
