import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("GEMINI_API_KEY")
print(f"Testing API Key: {api_key[:5]}...{api_key[-5:] if api_key else 'None'}")

if not api_key:
    print("Error: No API Key found.")
    exit(1)

genai.configure(api_key=api_key)

print("Listing available models:")
for m in genai.list_models():
    if 'generateContent' in m.supported_generation_methods:
        print(m.name)

try:
    # Fallback to gemini-pro if flash fails
    model = genai.GenerativeModel('gemini-1.5-flash')
    response = model.generate_content("Explain sustainability in one sentence.")
    print("Success! Response:")
    print(response.text)
except Exception as e:
    print(f"API Error: {e}")
