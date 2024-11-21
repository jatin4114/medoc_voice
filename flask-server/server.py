from flask import Flask, request, jsonify
from openai import OpenAI
import datetime
import google.generativeai as genai
from flask_cors import CORS  # Import CORS
# from io import BytesIO

client = OpenAI()
# Configuration
# client.api_key = "asd"
genai.configure(api_key="gemini_api_key")  

# Models
gemini_model = genai.GenerativeModel(model_name="gemini-1.5-flash")


system_prompt = '''
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
   - Name: [Leave blank for doctor to fill in]0
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
'''

app = Flask(__name__)
CORS(app)

transcription_data = None

@app.route('/transcribe', methods=['POST'])
def transcribe_audio():
    if 'file' not in request.files:
        return jsonify({"error": "No audio file provided."}), 400
    
    audio_file = request.files['file']
    if audio_file.filename == '':
        return jsonify({"error": "Empty audio file provided."}), 400
    
    supported_formats = ('.flac', '.m4a', '.mp3', '.mp4', '.mpeg',
                         '.mpga', '.oga', '.ogg', '.wav', '.webm')
    if not any(audio_file.filename.lower().endswith(ext) for ext in supported_formats):
        return jsonify({"error": f"Unsupported audio format. Supported formats: {supported_formats}"}), 400
    
    try:
        # Read the file data into memory
        audio_data = audio_file.read()
        
        transcript = client.audio.transcriptions.create(
            model="whisper-1",
            file=("audio1.mp3", audio_data),  # Tuple of (filename, file data)
            response_format="text"
        )
        
        # Print the transcript on the server console
        print("Transcription:", transcript)
        
        # Store the transcript for retrieval
        global transcription_data
        transcription_data = transcript
      
        return jsonify({"transcription": transcript})
    except Exception as e:
        print("Transcription error:", e)   
        return jsonify({"error": f"Transcription failed: {str(e)}"}), 500

# Endpoint to retrieve the current transcription data
@app.route('/get_transcription', methods=['GET'])
def get_transcription():
    global transcription_data
    if transcription_data is None:
        return jsonify({"error": "No transcription available."}), 404
    return jsonify({"transcription": transcription_data})

# Endpoint to generate a prescription using transcription data
@app.route('/generate_prescription', methods=['POST'])
def generate_prescription():
    global transcription_data
    if transcription_data is None:
        return jsonify({"error": "No transcription data available to generate prescription."}), 400

    location = request.json.get('location', "Unknown Location")
    current_date = datetime.datetime.now().strftime("%Y-%m-%d")
    system_prompt_with_date_location = f"{system_prompt}\n\nDate: {current_date}\nLocation: {location}"
    
    try:
        response = gemini_model.generate_content([system_prompt_with_date_location, transcription_data])
        prescription = response.text
        return jsonify({"prescription": prescription})
    except Exception as e:
        return jsonify({"error": f"Prescription generation failed: {str(e)}"}), 500

# Optional endpoint to reset transcription data
@app.route('/reset_transcription', methods=['POST'])
def reset_transcription():
    global transcription_data
    transcription_data = None
    return jsonify({"message": "Transcription data reset."}), 200

# Test endpoint
@app.route('/test', methods=['POST'])
def test():
    return "Test Successful"

if __name__ == '__main__':
    app.run(debug=True)
    
