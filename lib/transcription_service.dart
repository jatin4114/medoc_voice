import 'package:http/http.dart' as http;
import 'dart:convert';

class TranscriptionService {

  Future<String?> fetchTranscription() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_transcription'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transcription'];
      } else {
        print("Error fetching transcription: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error in fetching transcription: $e");
      return null;
    }
  }
}