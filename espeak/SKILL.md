---
name: espeak
description: Generate offline text-to-speech audio with eSpeak NG or eSpeak, including voice/language selection, speed and pitch tuning, WAV/MP3 output, stdout piping, SSML, and IPA/phoneme pronunciation checks. Use when asked to speak text aloud, read a document, narrate content, create voice prompts or IVR audio, choose an eSpeak voice, or debug pronunciation with espeak/espeak-ng.
metadata:
  version: 1.0.0
---

# eSpeak NG Text-to-Speech

Use `espeak-ng` for offline speech synthesis. The older `espeak` binary is compatible for most core flags; prefer NG when both exist. No network or API key is required.

## When to use this skill

- Speak a short message or notification aloud.
- Read a file or document aloud.
- Render narration or voice prompts to WAV, MP3, or OGG.
- Select a language, regional accent, or voice variant.
- Inspect how a word is pronounced with phonemes or IPA.
- Build a simple audio pipeline with `--stdout`.

## Engine check

```bash
command -v espeak-ng && espeak-ng --version
command -v espeak    && espeak --version
```

Use `espeak-ng` if available; otherwise use `espeak` with the same core flags. Run `--version` to see which build is installed; NG provides more voices and better SSML support.

## Quick start

```bash
# Speak immediately
espeak-ng "Hello world"

# Pause on commas and use a different voice/rate
espeak-ng -v en-us -s 160 "Hello, world"

# Write a WAV file instead of playing
espeak-ng -w hello.wav "Hello world"

# Stream WAV audio into a player
espeak-ng --stdout "Hello world" | aplay -q
```

## Choose the right command

| Goal | Command |
| --- | --- |
| Play text now | `espeak-ng "text"` |
| Read a file | `espeak-ng -f notes.txt` |
| Read piped text as one document | `cat notes.txt \| espeak-ng --stdin` |
| Save a WAV | `espeak-ng -w out.wav "text"` |
| Stream audio | `espeak-ng --stdout "text" \| aplay -q` |
| Check pronunciation | `espeak-ng -q -x "text"` |
| Check IPA | `espeak-ng -q --ipa "text"` |
| List languages/voices | `espeak-ng --voices` |
| List voice variants | `espeak-ng --voices=variant` |

Use the bundled wrapper for common tasks; it handles engine fallback, validation, and playback. Call `espeak-ng` directly for advanced flags such as `-l`, `-k`, `-z`, and `--split`.

```bash
scripts/speak.sh "Hello world"
scripts/speak.sh -v en-us+f3 -s 160 -w hello.wav "Hello world"
scripts/speak.sh -f notes.txt -w notes.wav
scripts/speak.sh --list
```

## Voices and languages

```bash
espeak-ng --voices              # all voices
espeak-ng --voices=en           # English voices only
espeak-ng --voices=variant      # timbre variants (f1-f5, m1-m8, whisper, ...)
```

The voice list columns are: priority, language code, age/gender metadata, display name, and voice file. Always verify that a voice exists before relying on it; available languages depend on the installed data package.

Common language codes:

| Language | Code | Language | Code |
| --- | --- | --- | --- |
| English (US) | `en-us` | Portuguese | `pt`, `pt-br` |
| English (UK) | `en-gb` | Russian | `ru` |
| German | `de` | Polish | `pl` |
| French | `fr` | Dutch | `nl` |
| Spanish | `es` | Swedish | `sv` |
| Italian | `it` | Turkish | `tr` |
| Arabic | `ar` | Ukrainian | `uk` |
| Hindi | `hi` | Mandarin | `cmn` |
| Japanese | `ja` | Czech | `cs` |

Append a variant to a language with `+`:

```bash
espeak-ng -v en+f3 "Female English variant"
espeak-ng -v en-us+m3 "Male American variant"
espeak-ng -v en+whisper "Quiet, whispered delivery"
espeak-ng -v en+croak "Very rough, low voice"
```

Notes:

- The age/gender shown by `--voices` is metadata; variants are what actually change timbre.
- MBROLA entries (for example `en-uk`, `mb-*`) need the separate `mbrola` binary and voice data. If unavailable, choose a non-MBROLA voice.
- There is no automatic language detection. Text and voice must match or the pronunciation will be wrong.
- To audition voices, render the same sentence to separate WAV files and compare, or play them sequentially.

## Tuning parameters

| Flag | Range | Default | Effect |
| --- | --- | --- | --- |
| `-v` | voice name | `en` | Language/voice/variant |
| `-s` | 80-450 | 175 | Speed in words per minute |
| `-p` | 0-99 | 50 | Base pitch; higher is higher |
| `-P` | 0-99 | 50 | Pitch range/intonation expressiveness |
| `-a` | 0-200 | 100 | Amplitude; above 100 can clip |
| `-g` | 0-1000 | 0 | Pause between words, in 10 ms units |
| `-k` | 0+ | 0 | Capital letters: 1= sound, 2= say "capitals", higher= pitch rise |
| `-l` | 0+ | 0 | Treat lines shorter than N characters as clause ends |
| `-z` | flag | off | Omit the final sentence pause |
| `-q` | flag | off | Produce no audio (useful with `-x`/`--ipa`) |
| `-D` | flag | off | Deterministic random mode for reproducible output |

Practical presets:

```bash
# Calm long-form narration
espeak-ng -v en-us -s 145 -p 45 -a 110 -f document.txt

# Short status notification
espeak-ng -v en-us -s 190 -p 55 "Build finished"

# Clear IVR prompt
espeak-ng -v en-gb -s 140 -p 50 -w prompt.wav "Press one for sales."

# Slow pronunciation practice
espeak-ng -v en -s 110 -p 50 "Pronunciation practice"
```

Amplitude above 100 often clips. Keep it at 100 or lower and normalize afterward with ffmpeg if needed.

## Input sources

```bash
# Command-line text
espeak-ng "Text from an argument"

# File
espeak-ng -f script.txt

# Entire stdin stream as one document (best for paragraphs)
cat script.txt | espeak-ng --stdin

# No -f/--stdin: stdin is read line by line, each line separately
cat lines.txt | espeak-ng
```

- Use `--stdin` for documents; without it, each input line is synthesized separately and may reset prosody.
- Use `-l N` when line breaks should be treated as clause boundaries.
- Command-line arguments have OS length limits; use `-f` or `--stdin` for long text.
- Quote text containing spaces, `$`, backticks, quotes, or wildcards.
- Put `--` before text that begins with `-`: `espeak-ng -- "-hello"`.

## SSML

Enable SSML with `-m`. Support is intentionally limited, and unsupported tags are silently skipped (their text content still speaks). Test the result before shipping.

```bash
espeak-ng -m -v en-us -w ssml.wav '<speak>
  Hello <break time="500ms"/>
  <prosody rate="slow" pitch="+20">this is slower and higher.</prosody>
  <say-as interpret-as="characters">ABC</say-as>
  <sub alias="World Wide Web">WWW</sub>
</speak>'
```

Useful, tested constructs:

| Tag | Example | Notes |
| --- | --- | --- |
| `<speak>` | `<speak>...</speak>` | Root element |
| `<break>` | `<break time="500ms"/>` | Time in ms or s; scale all breaks with `--ssml-break=200` |
| `<prosody>` | `<prosody rate="slow" pitch="+20">...</prosody>` | Rate and relative pitch |
| `<emphasis>` | `<emphasis level="strong">...</emphasis>` | Prosodic emphasis |
| `<say-as>` | `<say-as interpret-as="characters">ABC</say-as>` | `characters` and `number` work |
| `<sub>` | `<sub alias="World Wide Web">WWW</sub>` | Spoken replacement |

`<voice>`, `<audio>`, and `<mark>` are not reliable in eSpeak NG; use separate CLI calls for voice changes and audio insertion.

Do not enable `-m` for ordinary text containing `<` or `>`; those characters can be consumed as markup.

## Pronunciation debugging

```bash
# eSpeak mnemonics
espeak-ng -q -x "Schedule"

# IPA
espeak-ng -q --ipa -v en-us "Schedule"

# Detailed translation trace
espeak-ng -q -X "Schedule"

# Write phonemes to a file
espeak-ng -q -x --phonout=phonemes.txt "Schedule"
```

Options: `--sep=<char>` changes the separator, `--tie=<char>` controls multi-letter phoneme ties, and `--ipa=1|2|3` selects tie/ZWJ/underscore formatting. Use `-q` so inspection does not also speak.

If a word is wrong, try a different regional voice, a variant, a respelling in the text, or `<sub>` to force a replacement. CLI eSpeak does not provide a simple per-invocation pronunciation dictionary flag; avoid editing system dictionaries in normal workflows.

## Output, playback, and conversion

```bash
# WAV (typically 22050 Hz, mono, 16-bit PCM)
espeak-ng -w out.wav "Hello"

# Verify
file out.wav
ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 out.wav

# Play a WAV
aplay -q out.wav
paplay out.wav
ffplay -nodisp -autoexit -loglevel error out.wav

# Stream and play without a temp file
espeak-ng --stdout "Hello" | aplay -q
espeak-ng --stdout "Hello" | ffplay -nodisp -autoexit -loglevel error -

# Convert to MP3 or OGG
ffmpeg -y -i out.wav -codec:a libmp3lame -q:a 4 out.mp3
ffmpeg -y -i out.wav -codec:a libvorbis -q:a 5 out.ogg

# Normalize and resample for a delivery pipeline
ffmpeg -y -i out.wav -af loudnorm -ar 48000 -ac 1 out-48k.wav

# Split a long render into chunks of N minutes
espeak-ng -w part.wav --split=10 -f long.txt
```

`--split=N` writes `part_01.wav`, `part_02.wav`, and so on instead of `part.wav`.

Important:

- `-w -` does **not** stream; it creates an empty file. Use `--stdout` to stream.
- Do not combine `--stdout` with `-w`; the file is written and stdout stays empty.
- `--stdout` emits a complete WAV container, so pipe it to a player or ffmpeg, not to a raw-audio device expecting headerless PCM.
- Rendering to WAV is the safe choice on headless machines with no audio device.

## Recipes

### Narrate a document

```bash
espeak-ng -v en-us -s 145 -p 45 -f document.txt -w narration.wav
```

For long documents, split into chapters and render separately so a failure does not lose the whole job:

```bash
split -l 200 document.txt chapter-
for f in chapter-*; do
  espeak-ng -v en-us -s 145 -f "$f" -w "$f.wav" || exit 1
done
```

### Generate an MP3 prompt

```bash
espeak-ng -v en-gb -s 140 -p 50 -w prompt.wav "Your call is important to us."
ffmpeg -y -i prompt.wav -codec:a libmp3lame -q:a 4 prompt.mp3
```

### Multilingual announcement

Synthesize each language separately, then concatenate. eSpeak does not switch languages automatically inside one call.

```bash
espeak-ng -v en-us -w en.wav "Welcome."
espeak-ng -v de    -w de.wav "Willkommen."
printf "file 'en.wav'\nfile 'de.wav'\n" > list.txt
ffmpeg -y -f concat -safe 0 -i list.txt -c copy announcement.wav
```

### Check pronunciation before generating final audio

```bash
espeak-ng -q --ipa -v en-us "GIF, cache, schedule, tomato"
```

### Reusable wrapper

```bash
scripts/speak.sh --help
scripts/speak.sh -v en-us+f3 -s 160 --wav hello.wav "Hello from the wrapper"
scripts/speak.sh --stdout "Stream me" | aplay -q
scripts/speak.sh --ipa -v en "Schedule"
```

## Common pitfalls

- **No audio device**: render to WAV and transfer/play elsewhere; do not assume `aplay`/`paplay` succeeds in containers or over SSH.
- **Wrong language**: `en` defaults to British English. Use `en-us` for American pronunciation.
- **MBROLA voices listed but silent/failing**: install MBROLA and its voice data, or select another voice.
- **Clipping**: `-a` above 100 can distort. Prefer 100 and normalize later.
- **SSML ignored**: add `-m`; conversely, remove `-m` if literal angle brackets disappear.
- **Stdin behavior differs**: use `--stdin` for one continuous document; without it, lines are processed independently.
- **Old eSpeak**: 1.48 core flags work, but NG has more voices and better SSML. Check `--version` before using NG-only flags.
- **Arguments too long**: switch from inline text to `-f` or `--stdin`.
- **Leading dash text**: use `--` to end option parsing.
- **Encoding issues**: on old builds pass `-b 1` for UTF-8 input.
- **Sample rate expectations**: eSpeak WAV is 22050 Hz mono; resample with ffmpeg for 44.1/48 kHz pipelines.

## Verification checklist

Before handing off generated audio:

```bash
bash -n scripts/speak.sh
scripts/speak.sh --list | head
scripts/speak.sh -w /tmp/check.wav "Test one two three"
file /tmp/check.wav
ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 /tmp/check.wav
espeak-ng -q --ipa -v en-us "Test one two three"
```

Confirm that the file exists, is non-empty, decodes cleanly, has a plausible duration, and uses the intended language.

## Reference

```bash
espeak-ng --help
espeak-ng --voices
espeak-ng --voices=variant
espeak-ng --version
```
