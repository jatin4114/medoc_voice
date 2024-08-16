import re
import spacy

# Load the larger spaCy model (make sure you have it installed)
try:
    nlp = spacy.load("en_core_web_lg")
except OSError:
    print("Warning: Large spaCy model 'en_core_web_lg' not found. Using 'en_core_web_md' instead.")
    nlp = spacy.load("en_core_web_md")


def extract_vitals(text):
    """Extracts heart rate, blood pressure, and temperature from medical text using NLP."""

    vitals = {'heart_rate': None, 'blood_pressure': None, 'temperature': None}
    doc = nlp(text)

    # Enhanced blood pressure extraction
    bp_patterns = [
        r"(\d{2,3}) ?/ ?(\d{2,3}) (?:mm ?hg|hg/mm|millimeters of mercury|mercury)",
        r"(?:systolic|diastolic) (\d{2,3}) (?:over|mmHg)",
        r"bp (\d{2,3} ?/ ?\d{2,3})",
        r"(?:blood ?pressure|bp) (?:is|was|of) (\d{2,3} ?/ ?\d{2,3})",
        r"(?:my|his|her|the patient's) (?:blood ?pressure|bp) (?:is|was) (\d{2,3})(?: and| over) (\d{2,3})",
        r"(\d{2,3}) ?(?:over|/) ?(\d{2,3})",
        r"bp is (\d{2,3}) (\d{2,3})",
        r"(\d{2,3}) (\d{2,3})"  # Handle "120 80" without explicit delimiter
    ]

    for pattern in bp_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            if len(match.groups()) == 2:
                vitals['blood_pressure'] = f"{match.group(1)}/{match.group(2)}"
            else:
                vitals['blood_pressure'] = match.group(1)
            break

    # Enhanced heart rate extraction (including "rate" keyword)
    heart_rate_patterns = [
        r"(\d{2,3}) (?:bpm|beats per minute|beats/minute|heartrate|rate)",
        r"heart rate (\d{2,3})",
        r"pulse (?:rate )?is (\d{2,3})",
        r"hr (\d{2,3})"
    ]
    for pattern in heart_rate_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            vitals['heart_rate'] = int(match.group(1))
            break

    # Enhanced temperature extraction (handle multiple mentions)
    temp_values = []
    temp_patterns = [
        r"(\d{1,2}\.\d) ?(?:degrees )?(?:c|celsius)",
        r"(\d{2,3}\.\d) ?(?:degrees )?(?:f|fahrenheit)",
        r"(?:temp|temperature) (?:is|was|of) (\d{1,2}\.\d)",
        r"(\d{1,2}\.\d) ?(?:degrees|deg|°)(?:c|f)",
        r"fever of (\d{1,2}\.\d)",
        r"(\d{1,2}\.\d)(?: ?degrees)?(?: ?c| celsius)?",
        r"(\d{2,3})(?: ?degrees)?(?: ?f| fahrenheit)?",
        r"(\d{1,2})(?: ?degrees)?(?: ?c| celsius)?",
        r"temp(?:erature)? ?(\d{2,3})",  # Handling cases like "temp 101" or "temperature 101"
        r"fever(?: of)? (\d{2,3})"       # Handling cases like "fever 101" or "fever of 101"
    ]

    for pattern in temp_patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        for match in matches:
            temp_value = float(match)
            if "f" in pattern.lower() or "fever" in pattern.lower() or "temp" in pattern.lower() and int(match) > 100:
                temp_value = (temp_value - 32) * 5 / 9  # Convert Fahrenheit to Celsius
            temp_values.append(round(temp_value, 1))

    # if temp_values:
    #     vitals['temperature'] = max(temp_values)

    return vitals


# Main loop for user input (or use in your medical recommendation system)
while True:
    text = input("Enter medical text (or type 'quit' to exit): ")

    if text.lower() == "quit":
        break

    vitals = extract_vitals(text)
    if any(vitals.values()):
        print(f"Vitals extracted from text: {vitals}")
    else:
        print("No vitals found in the text.")
