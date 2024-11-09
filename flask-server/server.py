from flask import Flask, request, jsonify
#from dotenv import load_dotenv
from openai import OpenAI
import datetime
import google.generativeai as genai
# from io import BytesIO
#load_dotenv()

client = OpenAI()
# Configuration
# client.api_key = "asd"

genai.configure(api_key="place the key")  

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
      "Respiratory rate": "",
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
        
        return jsonify({"transcription": transcript})
    except Exception as e:
        return jsonify({"error": f"Transcription failed: {str(e)}"}), 500

@app.route('/generate_prescription', methods=['POST'])
def generate_prescription():
    data = request.get_json()
    if 'transcription' not in data:
        return jsonify({"error": "Transcription text not provided."}), 400

    transcription = data['transcription']
    location = data.get('location', "xxxxxxx")
    current_date = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=5, minutes=30))).strftime("%Y-%m-%d")

    system_prompt_with_date_location = f"{system_prompt}\n\nDate: {current_date}\nLocation: {location}"
    try:
        response = gemini_model.generate_content([system_prompt_with_date_location, transcription])
        prescription = response.text
        return jsonify({"prescription": prescription})
    except genai.Error as e:
        return jsonify({"error": f"Gemini API Error: {e}"}), 500
    except Exception as e:
        return jsonify({"error": f"Prescription generation failed: {e}"}), 500
     
@app.route('/test', methods=['POST'])
def test():
   return "Test Successful"

if __name__ == '__main__':
    app.run(debug=True)