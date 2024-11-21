import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:js' as js;

class AudioService {
  // Function to send the audio file to the server immediately after recording
  Future<void> sendAudioToServer(Uint8List audioData) async {
    final uri = Uri.parse('http://127.0.0.1:5000/transcribe');  // Replace with your server URL

    // Create multipart request
    var request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', audioData, filename: 'audiofile.wav'))
      ..headers['Content-Type'] = 'multipart/form-data';

    try {
      // Send request to server
      var response = await request.send();

      if (response.statusCode == 200) {
        print('Audio sent successfully');
        var responseBody = await http.Response.fromStream(response);
        print('Response: ${responseBody.body}');
      } else {
        print('Failed to send audio. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending audio: $e');
    }
  }

  // Start recording (as before)
  void startRecording() {
    _clearPreviousRecording();
    js.context.callMethod('startRecording');
    print("Recording started...");
  }

  // Stop and send the recording to the server
  Future<void> stopAndSendRecording() async {
    js.context.callMethod('stopRecording');
    print("Recording stopped...");

    // Assuming that the audio data is available after stopping the recording.
    Uint8List audioData = await _getRecordedAudioData();

    // Send the recorded audio to the server
    await sendAudioToServer(audioData);
  }

  // Function to simulate retrieving the recorded audio data (e.g., from Web API)
  Future<Uint8List> _getRecordedAudioData() async {
    // In a real scenario, this function would fetch the recorded data from the recording context.
    // For now, let's return a dummy byte array for the sake of example.
    return Uint8List.fromList([0, 1, 2, 3]);  // Replace with actual recorded audio data
  }

  // Clear any previous recordings (optional, for cleanup)
  void _clearPreviousRecording() {
    print("Previous recording cleared.");
  }
}
