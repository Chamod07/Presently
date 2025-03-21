import os
import json
import logging
import google.generativeai as genai
from dotenv import load_dotenv
from typing import Dict, Any
from pathlib import Path
import re

# Configure standard logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()  # Load environment variables from .env file

class GeminiContextAnalyzer:
    def __init__(self):
        # Get API key from environment variables
        api_key = os.getenv("GEMINI_API_KEY")
        
        if not api_key:
            logger.error("GEMINI_API_KEY not found in environment variables")
            raise ValueError("Missing GEMINI_API_KEY environment variable")
      
        # Configure the Gemini API
        try:
            genai.configure(api_key=api_key)
            
            # Get available models first to make sure we use one that exists
            available_models = self._get_available_models()
            
            # Choose the most suitable model based on availability
            self.model_name = self._get_best_model(available_models)
            
        except Exception as e:
            logger.error(f"Failed to initialize Gemini API: {str(e)}")
            raise
    
    def _get_available_models(self):
        """Get list of available models from the API"""
        try:
            models = genai.list_models()
            return [model.name for model in models]
        except Exception as e:
            logger.error(f"Error listing models: {e}")
            return []
    
    def _get_best_model(self, available_models):
        """Select the best available model based on capabilities"""
        # Model preference order from best to fallback
        preferred_models = [
            "gemini-2.0-pro-exp-02-05",
            "gemini-pro",
            "gemini-1.5-pro",
            "gemini-1.0-pro",
            "text-bison", 
            "chat-bison",
            "models/gemini-pro",
            "models/text-bison-001",
        ]
        
        # Check if any model names in available_models contain our preferred models
        for preferred in preferred_models:
            for available in available_models:
                if preferred in available:
                    return available
        
        # If no preferred model is found, use the first available model that can generate text
        for model in available_models:
            if any(text_model in model.lower() for text_model in ["text", "chat", "gemini"]):
                return model
        
        # If still nothing suitable, return a fallback or raise an error
        if available_models:
            return available_models[0]
        else:
            logger.error("No suitable models available")
            raise ValueError("No text generation models available in your Gemini API account")

    def get_session_data(self, report_id):
        """
        Retrieve session data for a presentation by first getting the session_id 
        from the UserReport table and then retrieving data from the session table
        
        Args:
            report_id: The report ID to query
            
        Returns:
            A dictionary containing session data or None if no data found
        """
        try:
            from services import storage_service
            import logging
            
            # Step 1: Query UserReport table to get session_id using report_id
            response = storage_service.supabase.table("UserReport") \
                .select("session_id") \
                .eq("reportId", report_id) \
                .execute()
                
            if not response.data or len(response.data) == 0:
                logging.error(f"No UserReport found for report ID: {report_id}")
                return None
            
            # Get the session_id from the response
            session_id = response.data[0].get("session_id")
            
            if not session_id:
                logging.error(f"Session ID is null for report ID: {report_id}")
                return None
            
            # Step 2: Query Sessions table with the session_id
            session_response = storage_service.supabase.table("Sessions") \
                .select("*") \
                .eq("session_id", session_id) \
                .execute()
                
            if not session_response.data or len(session_response.data) == 0:
                logging.error(f"No session data found for session ID: {session_id}")
                return None
             
            # Extract session data from response, handling potential field name differences
            session_data = session_response.data[0]
            
            # Map the session data, accounting for different possible field names
            result = {
                "session_type": session_data.get("session_type", session_data.get("type")),
                "session_goal": session_data.get("session_goal", session_data.get("goal")),
                "audience": session_data.get("audience"),
                "session_topic": session_data.get("session_topic", session_data.get("topic"))
            }
            
            # Remove any None values from the result
            result = {k: v for k, v in result.items() if v is not None}
            
            if not result:
                logger.warning("Retrieved session data has no usable fields")
                return None
                
            return result
        except Exception as e:
            logging.error(f"Error fetching session data: {e}")
            return None

    def analyze_presentation(self, transcription, report_id, session_data):
        """
        Analyze a presentation's content and context using Gemini AI.
        
        Args:
            transcription: Text transcription of the presentation
            report_id: ID of the report
            session_data: Dictionary containing presentation context data ( session_type, session_goal, audience, session_topic)
            
        Returns:
            Dictionary containing score and weaknesses
        """
        try:
            # Use session_data if provided, otherwise get it
            if not session_data:
                session_data = self.get_session_data(report_id)
            
            # If still no session data, use minimal data structure to avoid errors
            if not session_data:
                logger.warning("No session data available for context analysis")
                session_data = {}
            
            presentation_topic = session_data.get("session_topic", "unknown")
            
            # Updated prompt structure to match the requested format
            prompt = f"""
            You are an expert presentation analyzer specializing in content and structure.
            Analyze the following presentation transcript focusing on a {presentation_topic}.
            
            PRESENTATION CONTEXT:
            - Type: {session_data.get('session_type', 'unknown')}
            - Goal: {session_data.get('session_goal', 'unknown')}
            - Target Audience: {session_data.get('audience', 'unknown')}
            
            Evaluate the presentation based on these criteria :
            1. Content relevance and accuracy
            2. Organization and flow
            3. Clarity of main points
            4. Depth of analysis
            5. Supporting evidence and examples
            6. Introduction and conclusion effectiveness
            
            Provide a score from 1 to 10 (where 10 is perfect) based on all criteria.
            
            For each weakness you identify, include:
            1. The specific topic or issue
            2. Example passages from the text demonstrating the issue
            3. Specific suggestions for improvement
            
            Format your response as a valid JSON object with these fields:
            Format your response as a valid JSON object with these fields:
            {{
              "score": <score from 1-10>,
              "weaknesses": [
                {{
                  "topic": "<issue description>",
                  "examples": ["<example from text>", ...],
                  "suggestions": ["<suggestion for improvement>", ...]
                }},
                ...
              ]
            }}
            Important: Return ONLY the JSON object, with no other text before or after.
            TRANSCRIPT TO ANALYZE:
            {transcription}
            """
            
            # Log the text length
            logger.info(f"Analyzing content for {len(transcription)} characters of text on topic: {presentation_topic}")
            
            # Truncate text if too long (Gemini has a token limit)
            max_chars = 60000  # Safe limit for Gemini API
            if len(transcription) > max_chars:
                logger.warning(f"Text exceeds {max_chars} characters, truncating...")
                transcription = transcription[:max_chars] + "..."
            
            # Create the model with the previously selected model name
            model = genai.GenerativeModel(self.model_name)
            
            # Generate content
            logger.info(f"Making API call to Gemini using model: {self.model_name}...")
            
            # Use safety settings to ensure we get a response
            generation_config = {
                "temperature": 0.2,
                "top_p": 0.8,
                "top_k": 40,
                "max_output_tokens": 8192,
            }
            
            safety_settings = [
                {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
                {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
                {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH"},
                {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"},
            ]
            
            response = model.generate_content(
                prompt,
                generation_config=generation_config,
                safety_settings=safety_settings
            )
            
            # Check if response is empty
            if not response or not response.text:
                logger.error("Received empty response from Gemini API")
                return {"score": 0, "weaknesses": []}
            
            # Log the raw response for debugging
            raw_response = response.text
            
            # Extract JSON from the response
            clean_json = self._extract_json_from_response(raw_response)
                
            if (clean_json):
                try:
                    # Parse the extracted JSON
                    result = json.loads(clean_json)
                    logger.info(f"Successfully parsed JSON response: score={result.get('score', 'N/A')}")
                    
                    # Validate and enforce correct structure
                    if 'score' not in result:
                        logger.warning("Score missing from result, setting to 0")
                        result['score'] = 0
                    
                    if 'weaknesses' not in result:
                        logger.warning("Weaknesses missing from result, setting to empty list")
                        result['weaknesses'] = []
                    
                    return result
                    
                except json.JSONDecodeError as e:
                    logger.error(f"Failed to parse extracted JSON: {str(e)}")
            
            # If all extraction methods fail, return default
            logger.error("Could not extract valid JSON from response")
            return {"score": 0, "weaknesses": []}
                
        except Exception as e:
            logger.error(f"Error in context analysis: {str(e)}")
            # Return default values instead of failing
            return {"score": 0, "weaknesses": []}
    
    def _extract_json_from_response(self, text):
        """Extract JSON from a response that might contain markdown or other text"""
        # Try several extraction methods
        
        # 1. First, check if the text is already valid JSON
        try:
            json.loads(text)
            return text  # It's already valid JSON
        except json.JSONDecodeError:
            pass  # Not valid JSON, try other methods
        
        # 2. Check for markdown code blocks (```json ... ```)
        code_block_pattern = r'```(?:json)?\s*([\s\S]*?)```'
        code_matches = re.findall(code_block_pattern, text)
        if code_matches:
            # Use the first code block that contains valid JSON
            for match in code_matches:
                try:
                    json.loads(match.strip())
                    logger.info("Successfully extracted JSON from code block")
                    return match.strip()
                except json.JSONDecodeError:
                    continue
        
        # 3. Try to find JSON-like pattern between curly braces
        if "{" in text and "}" in text:
            start = text.find("{")
            end = text.rfind("}") + 1
            json_candidate = text[start:end]
            
            # Verify it's valid JSON
            try:
                json.loads(json_candidate)
                logger.info("Successfully extracted JSON from curly braces")
                return json_candidate
            except json.JSONDecodeError:
                pass
        
        # 4. None of the extraction methods worked
        return None
