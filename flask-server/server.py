import json
from flask import Flask, request, jsonify
from openai import OpenAI
import datetime
import re
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

You are an AI assistant designed to help doctors generate accurate and complete prescription contents from their natural language input. Your task is to convert the doctor's instructions into a structured prescription json format.

## Input:
You will receive a natural language description from a doctor. you may want to add prescription, medication name, dose, route, freq, dur, test name, instruction, date, followup date, reason, vitals BP, Heartrate, Respiratory rate, temp, spO2, nursing instruction, priority, discharge planned date, instruction, Home Care, Recommendations


## Output:
Generate a structured prescription with the following components:
{
  "prescription": {
    "medication": [
      {
        "name": "",
        "dose": "",
        "route": "",
        "freq": "",
        "dur": "",
        "class": ""
      }
    ],
    "test": [
      {
        "name": "",
        "instruction": "",
        "date": ""
      }
    ],
    "followup": {
      "date": "",
      "reason": ""
    },
    "vitals": {
      "BP": "",
      "Heartrate": "",
      "RespiratoryRate": "",
      "temp": "",
      "spO2": ""
    },
    "nursing": [
      {
        "instruction": "",
        "priority": ""
      }
    ],
    "discharge": {
      "planned_date": "",
      "instruction": "",
      "Home_Care": "",
      "Recommendations": ""
    },
    "notes":[""]
  } 
}


## Guidelines:
- Extract all relevant information from the doctor's input.
- If any information is missing leave it blank.
- If any information is unclear insert "unclear" in the appropriate field.
- Add medicine type(example antibiotic, anti-inflammatory,etc) in class in medication section
- In notes Include any warnings or side effects mentioned by the doctor in the notes section.
- If the doctor mentions any alternatives, include them in the notes section.
- List all tests performed, even if results are pending.
- Include follow-up instructions if mentioned by the doctor.
- For each medication, provide clear and specific instructions in the medication field and leave it blank if information is missing and do not mention unclear.

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
        # Generate the prescription
        response = gemini_model.generate_content([system_prompt_with_date_location, transcription_data])
        prescription_raw = response.text

        # Log the raw response for debugging
        print("Raw Prescription Response:", prescription_raw)

        # Remove Markdown markers and any extra data
        if prescription_raw.startswith("```json"):
            prescription_raw = prescription_raw[7:]
        if prescription_raw.endswith("```"):
            prescription_raw = prescription_raw[:-3]

        # Remove extra characters after the valid JSON
        last_closing_brace_index = prescription_raw.rfind("}")
        if last_closing_brace_index != -1:
            prescription_raw = prescription_raw[:last_closing_brace_index + 1]

        # Log cleaned response
        print("Cleaned Prescription Response:", prescription_raw)

        # Parse cleaned JSON
        prescription = json.loads(prescription_raw)
        print(prescription)

        # Return properly formatted JSON
        return jsonify({"prescription":prescription})

    except json.JSONDecodeError as e:
        print("JSONDecodeError:", e)
        return jsonify({"error": "Failed to parse prescription as JSON.", "details": str(e)}), 500
    except Exception as e:
        print("Error Generating Prescription:", e)
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
    
    
