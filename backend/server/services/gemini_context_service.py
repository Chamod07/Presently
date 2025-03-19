import os
import json
# noinspection PyUnresolvedReferences
import google.generativeai as genai
from dotenv import load_dotenv
from typing import Dict, Any
from pathlib import Path
import logging
from fastapi import HTTPException
from services import storage_service

logger = logging.getLogger(__name__)

class GeminiContextAnalyzer:
    def __init__(self):
        load_dotenv()
        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment variables")
        
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel('gemini-2.0-pro-exp-02-05')

    def analyze_presentation(self, transcription: str, topic: str) -> Dict[str, Any]:
        """
         Analyze presentation transcription using Gemini API with a dynamic topic.
         
         Args:
             transcription (str): The presentation transcription text.
             topic (str): The topic to use in the analysis.
             
         Returns:
             Dict containing analysis results.
         """
 
        prompt = f"""You are a presentation analysis expert. Analyze this presentation transcription about "{topic}" and provide structured feedback.
        
        Generate a JSON response with the following structure exactly:
        {{
            "overall_score": <number between 0-10>,
            "confidence_level": <number between 0-1>,
            "content_analysis": {{
                "topic_relevance": <number between 0-10>,
                "flow_coherence": <number between 0-10>,
                "clarity": <number between 0-10>
            }},
            "weakness_topics": [
                {{
                    "topic": "<weakness area>",
                    "examples": ["<specific example from transcription>"],
                    "suggestions": ["<actionable improvement suggestion>"]
                }}
            ]
        }}

        Key requirements:
        1. Evaluate content flow, coherence and topic relevance
        2. Score must be numerical values only
        3. Examples must be direct quotes or clear references from the transcription
        4. Suggestions must be specific and actionable
        
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


    def retrieve_scenario_data(self, report_id: str) -> Dict[str, Any]:
        """Retrieves session data from the Supabase 'Sessions' table by report_id."""
        logger.info(f"Retrieving session data for report_id: {report_id}")
        try:
            response = storage_service.supabase.table("Sessions").select("session_type, session_goal, audience, topic").eq("report_id", report_id).execute()

            if response.data:
                # Assuming report_id is unique, return the first element
                logger.info(f"Session data found for report_id: {report_id} : {response.data[0]}")
                return response.data[0]
            else:
                logger.warning(f"No session data found for report_id: {report_id}")
                return {}  # Return empty dict if no data found
        except Exception as e:
            logger.error(f"Error retrieving session data: {e}")
            raise HTTPException(status_code=500, detail=str(e))


def main():
    # Test the analyzer with sample transcription
    analyzer = GeminiContextAnalyzer()
    
    # Read sample transcription
    sample_path = Path(__file__).parent.parent.parent / 'sample_transcription.txt'
    with open(sample_path, 'r') as f:
        transcription = f.read()
    
    # Test analysis
    try:
        result = analyzer.analyze_presentation(transcription, "default topic")
        print("\nAnalysis Result:")
        print(f"Overall Score: {result['overall_score']}/10")
        print(f"Confidence Level: {result['confidence_level']}")
        print("\nContent Analysis:")
        for metric, score in result['content_analysis'].items():
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
