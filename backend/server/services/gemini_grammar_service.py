import os
import json
import google.generativeai as genai
from dotenv import load_dotenv
from typing import Dict, Any
from pathlib import Path

class GeminiGrammarAnalyzer:
    def __init__(self):
        load_dotenv()
        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment variables")
        
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-pro')

    def analyze_grammar(self, transcription: str) -> Dict[str, Any]:
        """
        Analyze presentation transcription for grammar issues using Gemini API
        
        Args:
            transcription (str): The presentation transcription text
            
        Returns:
            Dict containing grammar analysis results including scores and feedback
        """
        
        prompt = """You are a professional grammar and language expert. Analyze this presentation transcription for grammar, sentence structure, and word choice. Provide detailed feedback.
        
        Generate a JSON response with the following structure exactly:
        {
            "grammar_score": <number between 0-10>,
            "confidence_level": <number between 0-1>,
            "analysis": {
                "grammatical_accuracy": <number between 0-10>,
                "sentence_structure": <number between 0-10>,
                "word_choice": <number between 0-10>
            },
            "identified_issues": [
                {
                    "type": "<error type: grammar/structure/word-choice>",
                    "error": "<actual error from transcription>",
                    "suggestion": "<correction suggestion>",
                    "explanation": "<why this is an error>"
                }
            ]
        }

        Key requirements:
        1. Identify and analyze grammar errors, sentence structure issues, and word choice problems
        2. All scores must be numerical values only
        3. Each identified issue must include the exact problematic text from the transcription
        4. Suggestions must be specific and actionable
        5. Include clear explanations for why each issue is problematic
        
        Transcription to analyze:
        {transcription}

        Respond only with the JSON structure, no additional text.
        """

        try:
            response = self.model.generate_content(prompt)
            print("\nRaw Gemini Response:")
            print(response.text)
            print("\nAttempting to parse response...")
            
            # Clean the response text to ensure it's valid JSON
            response_text = response.text.strip()
            if response_text.startswith('```json'):
                response_text = response_text.replace('```json', '').replace('```', '').strip()
            
            return json.loads(response_text)
            
        except json.JSONDecodeError as e:
            print(f"JSON parsing error: {str(e)}")
            raise
        except Exception as e:
            print(f"Error in API response: {str(e)}")
            raise

def main():
    # Test the analyzer with sample transcription
    analyzer = GeminiGrammarAnalyzer()
    
    # Read sample transcription
    sample_path = Path(__file__).parent.parent.parent / 'sample_transcription.txt'
    with open(sample_path, 'r') as f:
        transcription = f.read()
    
    # Test analysis
    try:
        result = analyzer.analyze_grammar(transcription)
        print("\nGrammar Analysis Result:")
        print(f"Grammar Score: {result['grammar_score']}/10")
        print(f"Confidence Level: {result['confidence_level']}")
        
        print("\nDetailed Analysis:")
        for metric, score in result['analysis'].items():
            print(f"{metric.replace('_', ' ').title()}: {score}/10")
        
        print("\nIdentified Issues:")
        for issue in result['identified_issues']:
            print(f"\nType: {issue['type']}")
            print(f"Error: {issue['error']}")
            print(f"Suggestion: {issue['suggestion']}")
            print(f"Explanation: {issue['explanation']}")
    
    except Exception as e:
        print(f"Error during analysis: {str(e)}")
        raise

if __name__ == "__main__":
    main()