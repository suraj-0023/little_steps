import google.generativeai as genai

API_KEY = "AIzaSyC2adH_dBVXAcY-c3PWobVYOr-JKeC9g0w"
genai.configure(api_key=API_KEY)

try:
    print("Listing models...")
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(f"  - {m.name}")
except Exception as e:
    print(f"Error listing models: {e}")
