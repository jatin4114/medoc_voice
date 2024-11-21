import 'dart:convert';
import 'dart:io';
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AudioRecorder {

  // String? result;

  // Start recording
  void startRecording() {
    js.context.callMethod('startRecording');
  }

  //Stop recording and send audio to the server
  Future<void> stopRecordingAndSend() async {
    try {
      final result = await js.context.callMethod('sendAudioToServer');
      print("Transcription: $result");
      return result;
    } catch (e) {
      print("Error in sending audio to server: $e");
    }



    Future<String?> sendAudioToServer(AudioRecorder  audioRecorder) async {

      final String url = "http://127.0.0.1:5000/transcribe";

      File audioFile = audioRecorder.stopRecordingAndSend() as File;

      try {
        // Create a multipart request
        final request = http.MultipartRequest('POST', Uri.parse(url));

        // Add the audio file
        request.files.add(
          http.MultipartFile(
            'file',
            audioFile.readAsBytes().asStream(),
            audioFile.lengthSync(),
            filename: 'recording.webm',
            contentType: MediaType('audio', 'webm'),
          ),
        );

        // Send the request
        final response = await request.send();

        if (response.statusCode != 200) {
          throw Exception("Server error: ${response.statusCode}");
        }

        // Parse the response
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> result = jsonDecode(responseBody);

        // Log and return the transcription
        print('Transcription: ${result['transcription']}');
        return result['transcription'];
      } catch (e) {
        print("Error sending audio: $e");
        return null;
      }
    }
  }

  // Stop recording, send the audio to the server, and await the transcription result
  // Future<String?> stopRecordingAndSend() async {
  //   try {
  //     // Call the JavaScript function and convert the Promise to a Dart Future
  //     final transcription = await js_util.promiseToFuture<String>(
  //         js.context.callMethod('sendAudioToServer')
  //     );
  //
  //     // Print and return the transcription result
  //     print("Transcription: $transcription");
  //     return transcription;
  //   } catch (e) {
  //     print("Error in sending audio to server: $e");
  //     return null;
  //   }
  // }

  // Future<String?> stopRecordingAndSend() async {
  //   try {
  //     // Resolve the promise returned by the JavaScript method
  //     final transcription = await js.context
  //         .callMethod('sendAudioToServer'); // It should return a Promise in JS
  //
  //     // Since transcription is a promise, wait for it to resolve
  //     return transcription as String?;
  //   } catch (e) {
  //     print("Error in sending audio to server: $e");
  //   }
  // }
}

//
// import 'dart:js' as js;
// import 'dart:async';
//
// class AudioRecorder {
//
//   String? result;
//
//   // Start recording
//   void startRecording() {
//     js.context.callMethod('startRecording');
//   }
//
//   // Stop recording and send audio to the server
//   Future<String?> stopRecordingAndSend() async {
//     final completer = Completer<String?>();
//
//     try {
//       // Call the sendAudioToServer JavaScript function and handle the Promise
//       js.context.callMethod('sendAudioToServer', [
//         js.JsFunction.withThis((js.JsObject result) {
//           // Resolving the future when Promise is fulfilled
//           completer.complete(result['transcription']);
//         })
//       ]);
//     } catch (e) {
//       completer.completeError("Error in sending audio to server: $e");
//     }
//
//     return completer.future;
//   }
// }
