import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class PrescriptionGeneratorPage extends StatefulWidget {
  const PrescriptionGeneratorPage({super.key});
  @override
  _PrescriptionGeneratorPageState createState() => _PrescriptionGeneratorPageState();
}

class _PrescriptionGeneratorPageState extends State<PrescriptionGeneratorPage> {
  final record = AudioRecorder();
  String _filePath = '';
  String _transcription = '';
  bool _isRecording = false;
  String _errorMessage = '';
  bool _isLoading = false;
  String _generatedPrescription = '';

  Future<void> _initRecorder() async {
    try {
      if (await record.hasPermission()) {
        setState(() {_errorMessage = '';});
      } else {
        throw Exception('Microphone permission not granted');
      }
    } catch (e) {
      setState(() {_errorMessage = 'Failed to initialize recorder: $e';});
    }
  }

  Future<void> _startRecording() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      _filePath = '${tempDir.path}/audio.m4a';
      await record.start(const RecordConfig(), path: _filePath);
      setState(() {_isRecording = true;_errorMessage = '';});
    } catch (e) {
      setState(() {print(e);_errorMessage = 'Failed to start recording: $e';});
    }
  }

  Future<void> _stopRecording() async {
    try {
      await record.stop();
      setState(() {_isRecording = false;_isLoading = true;});
      await _transcribeAudio();
    } catch (e) {
      setState(() {_errorMessage = 'Failed to stop recording: $e';_isLoading = false;});
    }
  }

  Future<void> _transcribeAudio() async {
    try {
      final whisperUrl = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
      const apiKey = 'openai_api_key'; // Replace with your actual OpenAI API key
      var request = http.MultipartRequest('POST', whisperUrl);
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.fields['model'] = 'whisper-1';
      request.fields['response_format'] = 'text';
      request.files.add(await http.MultipartFile.fromPath('file', _filePath));
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        setState(() {
          _transcription = responseBody;
          _errorMessage = '';
          _isLoading = false;
        }); 
        // Trigger prescription generation after successful transcription
        _generatePrescription(); 
      } else {
        final responseBody = await response.stream.bytesToString();
        throw Exception('Failed to transcribe audio: ${response.statusCode}\n$responseBody');
      }
    } catch (e) {
      setState(() {_errorMessage = 'Transcription error: $e';_isLoading = false;});
    }
  }

  Future<void> _generatePrescription() async {
    try {
      setState(() {
        _isLoading = true;
      });

      const apiKey = 'gemini_api_key'; // Replace with your actual Gemini API key

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        // safetySettings: Adjust safety settings
        // See https://ai.google.dev/gemini-api/docs/safety-settings
        generationConfig: GenerationConfig(
          temperature: 2,
          topK: 64,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'application/json',
        ),
        systemInstruction: Content.system('''
         # Prescription Generator

You are an AI assistant designed to help doctors generate accurate and complete prescription contents from their natural language input. Your task is to convert the doctor's instructions into a structured prescription format.

## Input:
You will receive a natural language description from a doctor. This may include information about the patient, diagnosis, tests performed, medications, dosages, frequencies, durations, and any special instructions.

## Output:
Generate a structured prescription with the following components:

1. Patient Information:
   - Name: [Leave blank for doctor to fill in]
   - Date of Birth: [Leave blank for doctor to fill in]
   - Date: [Current date]

2. Diagnosis:

3. Medications:
   For each medication mentioned, include:
   a. Medication Name:
   b. Strength:
   c. Form (e.g., tablet, capsule, liquid, injection):
   d. Sig (Instructions):
   e. Dispense Amount:
   f. Refills:

4. Tests Performed:

5. Additional Instructions:

6. Follow-up:

7. Prescribing Doctor: [Leave blank for doctor to fill in]

## Guidelines:
- Extract all relevant information from the doctor's input.
- If any information is missing or unclear, insert "[NEEDS CLARIFICATION]" in the appropriate field.
- Use standard medical abbreviations where appropriate (e.g., BID for twice daily, TID for three times daily).
- Include any warnings or side effects mentioned by the doctor in the Additional Instructions section.
- If the doctor mentions any alternatives, include them in the Additional Instructions section.
- List all tests performed, even if results are pending.
- Include follow-up instructions if mentioned by the doctor.
- For each medication, provide clear and specific instructions in the Sig field.
- If the doctor specifies a duration for a medication, include it in the Sig field.
- Use a numbered list for multiple medications.

Remember, always prioritize patient safety and clarity in the prescription. If there's any ambiguity or potential safety concern in the doctor's input, highlight it with [SAFETY CHECK REQUIRED] in the relevant section.

## Examples:

Example 1: Simple prescription for hypertension

Input: "For a patient with hypertension, prescribe Lisinopril 10mg tablets, one tablet daily. They should take it in the morning. Dispense a 30-day supply with 2 refills. I want to see them back in 3 months for a blood pressure check."

Output:
1. Patient Information:
   - Name: [Leave blank for doctor to fill in]
   - Date of Birth: [Leave blank for doctor to fill in]
   - Date: [Current date]

2. Diagnosis: Hypertension

3. Medications:
   1. a. Medication Name: Lisinopril
      b. Strength: 10 mg
      c. Form: Tablet
      d. Sig: Take 1 tablet by mouth every morning
      e. Dispense Amount: 30 tablets
      f. Refills: 2

4. Tests Performed: [NEEDS CLARIFICATION]

5. Additional Instructions: None

6. Follow-up: Return in 3 months for blood pressure check

7. Prescribing Doctor: [Leave blank for doctor to fill in]

Example 2: Complex prescription for diabetes and depression

Input: "Patient diagnosed with type 2 diabetes and major depressive disorder. Recent HbA1c was 8.2%. Prescribe Metformin 500mg twice daily with meals, increase to 1000mg twice daily after 1 week if tolerated. Also, start Sertraline 50mg daily for depression, taken in the morning. Provide glucose test strips, patient to test blood sugar twice daily. Follow up in 2 weeks to assess medication tolerability."

Output:
1. Patient Information:
   - Name: [Leave blank for doctor to fill in]
   - Date of Birth: [Leave blank for doctor to fill in]
   - Date: [Current date]

2. Diagnosis: Type 2 Diabetes Mellitus, Major Depressive Disorder

3. Medications:
   1. a. Medication Name: Metformin
      b. Strength: 500 mg
      c. Form: Tablet
      d. Sig: Take 1 tablet by mouth twice daily with meals for 1 week, then increase to 2 tablets twice daily with meals if tolerated
      e. Dispense Amount: 56 tablets
      f. Refills: 0

   2. a. Medication Name: Sertraline
      b. Strength: 50 mg
      c. Form: Tablet
      d. Sig: Take 1 tablet by mouth every morning
      e. Dispense Amount: 30 tablets
      f. Refills: 0

   3. a. Medication Name: Glucose Test Strips
      b. Strength: N/A
      c. Form: Test Strips
      d. Sig: Test blood sugar twice daily
      e. Dispense Amount: 60 strips
      f. Refills: 0

4. Tests Performed: HbA1c (Result: 8.2%)

5. Additional Instructions: Monitor for side effects of Metformin and Sertraline. Report any significant adverse effects.

6. Follow-up: Return in 2 weeks to assess medication tolerability

7. Prescribing Doctor: [Leave blank for doctor to fill in]

Example 3: Pediatric prescription for acute otitis media

Input: "6-year-old patient with acute otitis media in the right ear. Prescribe amoxicillin suspension, 250mg/5mL, 15mg/kg/dose twice daily for 10 days. Patient weighs 20kg. Also recommend acetaminophen for pain as needed. Follow up if symptoms don't improve in 3 days."

Output:
1. Patient Information:
   - Name: [Leave blank for doctor to fill in]
   - Date of Birth: [Leave blank for doctor to fill in]
   - Date: [Current date]

2. Diagnosis: Acute Otitis Media, Right Ear

3. Medications:
   1. a. Medication Name: Amoxicillin
      b. Strength: 250 mg/5 mL
      c. Form: Oral Suspension
      d. Sig: Take 6 mL by mouth twice daily for 10 days
      e. Dispense Amount: 120 mL
      f. Refills: 0

   2. a. Medication Name: Acetaminophen
      b. Strength: [NEEDS CLARIFICATION] (Strength depends on the available formulation)
      c. Form: [NEEDS CLARIFICATION] (Form depends on patient/parent preference)
      d. Sig: Take as needed for pain. Do not exceed recommended dosage for age/weight.
      e. Dispense Amount: [NEEDS CLARIFICATION]
      f. Refills: 0

4. Tests Performed: [NEEDS CLARIFICATION]

5. Additional Instructions:
   - Complete full course of antibiotics even if symptoms improve.
   - For acetaminophen, follow package instructions for proper dosing based on child's weight.

6. Follow-up: Return if symptoms don't improve in 3 days

7. Prescribing Doctor: [Leave blank for doctor to fill in]
        '''),
      );

      final chat = model.startChat(history: [
        Content.multi([
          TextPart('Input: $_transcription'), // Pass the transcription as input
        ]),
        Content.model([
          TextPart('1. gfhgf'), // You might want to adjust this initial model response
        ]),
      ]);

      final response = await chat.sendMessage(Content.text('')); // Empty message to trigger generation

      setState(() {
        _generatedPrescription = response.text!; 
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating prescription: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription Generator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(_isRecording ? 'Recording...' : 'Press the button to start recording', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            if (_errorMessage.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14))),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 20),
            const Text('Transcription:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(_transcription, style: const TextStyle(fontSize: 16)),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _transcription = '';
                  _generatedPrescription = ''; 
                });
              },
              child: const Text('Clear'),
            ), 
            const SizedBox(height: 20),
            const Text('Generated Prescription:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(_generatedPrescription, style: const TextStyle(fontSize: 16)),
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
