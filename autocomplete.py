from transformers import pipeline
from fuzzywuzzy import fuzz
from difflib import get_close_matches

class MedicineAutocomplete:
    # ... (Same __init__ method as the previous example) ...

    def get_user_input(self):
        """Gets partial medicine name input from the user."""
        while True:
            partial_name = input("Enter partial medicine name (or 'quit' to exit): ")
            if partial_name.lower() == 'quit':
                break
            suggestions = self.suggest_medicines(partial_name)
            if suggestions:
                print("Suggestions:", ", ".join(suggestions))
            else:
                print("No suggestions found.")

    def suggest_medicines(self, partial_name, max_suggestions=5):
        """Suggests medicines, prioritizing LLM then fuzzy matching."""

        # ... (Same logic for exact match and LLM suggestions as before) ...

        # Optimization: Only use fuzzy matching if LLM finds nothing
        if not llm_suggestions:
            matches = [(fuzz.ratio(partial_name.lower(), med.lower()), med) for med in self.medicine_list]
            matches = sorted(matches, reverse=True)[:max_suggestions]
            enhanced_suggestions = get_close_matches(partial_name, self.medicine_list, n=max_suggestions)

            # Combine and deduplicate
            combined_suggestions = list(set(enhanced_suggestions + [med for _, med in matches]))
            return combined_suggestions[:max_suggestions]
        else:
            return llm_suggestions

# Example Usage (with user input loop)
if __name__ == "__main__":
    medicine_list = ["Paracetamol", "Ibuprofen", "Aspirin", "Amoxicillin", "Lisinopril"]  # Your medicine data here
    autocomplete = MedicineAutocomplete(medicine_list)
    autocomplete.get_user_input()
