# categorize.py
import os
import json

# List of strings to categorize
texts = [
    "I love hiking in the mountains.",
    "The stock market crashed today.",
    "Just baked a chocolate cake!",
    "Python programming is fun.",
    "The new iPhone release was announced."
]

# Gemini API key (from settings)
API_KEY = "AIzaSyC2adH_dBVXAcY-c3PWobVYOr-JKeC9g0w"

try:
    import google.generativeai as genai
except ImportError:
    raise ImportError("google-generativeai library not installed. Please install it first.")

genai.configure(api_key=API_KEY)
model = genai.GenerativeModel('gemini-1.5-flash')

prompt = "Categorize each of the following sentences into one of the categories: 'Travel', 'Finance', 'Food', 'Technology', 'Programming', 'Other'. Return a JSON object mapping each sentence to its category." 

input_text = "\n".join(texts)

response = model.generate_content(f"{prompt}\n\n{input_text}")
print(response.text)
