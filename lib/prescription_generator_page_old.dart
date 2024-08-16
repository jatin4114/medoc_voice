import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class PrescriptionGeneratorPage extends StatefulWidget {
  const PrescriptionGeneratorPage({super.key});

  @override
  _PrescriptionGeneratorPageState createState() =>
      _PrescriptionGeneratorPageState();
}

class _PrescriptionGeneratorPageState extends State<PrescriptionGeneratorPage> {
  final record = AudioRecorder();
  String _filePath = '';
  String _transcription = '';
  bool _isRecording = false;
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      if (await record.hasPermission()) {
        setState(() {
          _errorMessage = '';
        });
      } else {
        throw Exception('Microphone permission not granted');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize recorder: $e'; 
      });
    }
  } 

  Future<void> _startRecording() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      _filePath = '${tempDir.path}/audio.m4a';
      await record.start(const RecordConfig(), path: _filePath);
      setState(() {
        _isRecording = true;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        print(e);
        _errorMessage = 'Failed to start recording: $e';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      await record.stop();
      setState(() {
        _isRecording = false;
        _isLoading = true; // Show loading indicator
      });
      await _transcribeAudio();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to stop recording: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _transcribeAudio() async {
    try {
      final whisperUrl =
          Uri.parse('https://api.openai.com/v1/audio/transcriptions');
      const apiKey = 'openai_api_key'; 
      var request = http.MultipartRequest('POST', whisperUrl);
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.fields['model'] = 'whisper-1';
      request.fields['response_format'] = 'text';

      request.files.add(await http.MultipartFile.fromPath('file', _filePath));
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print(responseBody);
        setState(() {
          _transcription = responseBody;
          _errorMessage = '';
          _isLoading = false;
        });
      } else {
        final responseBody = await response.stream.bytesToString();
        throw Exception(
            'Failed to transcribe audio: ${response.statusCode}\n$responseBody');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Transcription error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _isRecording
                  ? 'Recording...'
                  : 'Press the button to start recording',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            if (_isLoading) 
              const Center(child: CircularProgressIndicator()), 
            const SizedBox(height: 20),
            const Text(
              'Transcription:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(_transcription, style: const TextStyle(fontSize: 16)),
            ElevatedButton( // Added clear button
              onPressed: () {
                setState(() {
                  _transcription = '';
                });
              },
              child: const Text('Clear Transcription'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    record.dispose();
    super.dispose();
  }
}
