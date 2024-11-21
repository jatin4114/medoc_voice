import 'package:flutter/material.dart';
import 'audio_recorder.dart';
import 'transcription_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TranscriptionService _transcriptionService = TranscriptionService();
  bool _isRecording = false;
  String? _transcription;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Audio Recorder")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRecording
                    ? null
                    : () {
                  setState(() {
                    _isRecording = true;
                    _transcription = null;
                  });
                  _audioRecorder.startRecording();
                },
                child: Text("Start Recording"),
              ),
              ElevatedButton(
                onPressed: !_isRecording
                    ? null
                    : () async {
                  setState(() {
                    _isRecording = false;
                  });
                  await _audioRecorder.stopRecordingAndSend();

                  // Fetch transcription
                  String? transcription = await _transcriptionService.fetchTranscription();
                  setState(() {
                    _transcription = transcription;
                  });

                },
                child: Text("Stop & Transcribe"),
              ),
              if (_transcription != null) ...[
                SizedBox(height: 20),
                Text("Transcription:"),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_transcription!),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}


