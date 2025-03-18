import os
import json
import google.generativeai as genai
import os
import json
import google.generativeai as genai
from dotenv import load_dotenv
from typing import Dict, Any
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class GeminiGrammarAnalyzer:
    def __init__(self):
        load_dotenv()
        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            logger.error("GEMINI_API_KEY not found in environment variables")
            raise ValueError("GEMINI_API_KEY not found in environment variables")

        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-2.0-pro-exp-02-05')

    def analyze_grammar(self, transcription: str) -> Dict[str, Any]:
        """
        Analyze presentation transcription for grammar issues using Gemini API

        Args:
            transcription (str): The presentation transcription text

        Returns:
            Dict containing grammar analysis results including scores and feedback
        """

        prompt = """You are a professional grammar and language expert. Analyze this presentation transcription for grammar, sentence structure, and word choice. Provide detailed feedback grouped by topic.

        Generate a JSON response with the following structure exactly:
        {
            "grammar_score": <number between 0-10>,
            "confidence_level": <number between 0-1>,
            "analysis": {
                "grammatical_accuracy": <number between 0-10>,
                "sentence_structure": <number between 0-10>,
                "word_choice": <number between 0-10>
            },
            "weakness_topics": [
                {
                    "topic": "<grammar topic>",
                    "examples": ["<specific example from transcription>"],
                    "suggestions": ["<actionable improvement suggestion>"]
                }
            ]
        }

        Key requirements:
        1. Group grammar issues by topic (e.g., Subject-Verb Agreement, Tense Consistency)
        2. All scores must be numerical values only
        3. Each identified issue must include the exact problematic text from the transcription
        4. Suggestions must be specific and actionable
        5. Include clear explanations in the suggestions

        Transcription to analyze:
        {transcription}

        Respond only with the JSON structure, no additional text.
        """

        try:
            response = self.model.generate_content(prompt)
            #print("\nRaw Gemini Response:")
            #print(response.text)
            print("\nAttempting to parse response...")

            # Clean the response text to ensure it's valid JSON
            response_text = response.text.strip()
            if response_text.startswith('```json'):
                response_text = response_text.replace('```json', '').replace('```', '').strip()

            return json.loads(response_text)

        except json.JSONDecodeError as e:
            logger.error(f"JSON parsing error: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Error in API response: {str(e)}")
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

        print("\nIdentified Weaknesses:")
        for topic in result['weakness_topics']:
            print(f"\nTopic: {topic['topic']}")
            print("Examples:")
            for example in topic['examples']:
                print(f"- {example}")
            print("Suggestions:")
            for suggestion in topic['suggestions']:
                print(f"- {suggestion}")

    except Exception as e:
        print(f"Error during analysis: {str(e)}")
        raise


if __name__ == "__main__":
    main()
