import speech_recognition as sr
import pyaudio

recorder = sr.Recognizer()
with sr.Microphone() as source:
    audio_data = recorder.record(source, duration=4)
    try: text = recorder.recognize_google(audio_data)
    except: pass

print(text)