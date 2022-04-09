from gtts import gTTS

text = input('')
dir = input('')
language = 'en'
myobj = gTTS(text=text, lang=language, slow=False)
myobj.save(dir + 'tts.mp3')