# espeak-skill

Offline text-to-speech with [eSpeak NG](https://github.com/espeak-ng/espeak-ng) / eSpeak. Provides a wrapper script and skill documentation for voice selection, tuning, WAV/MP3 output, streaming, SSML, and pronunciation debugging.

## Install

```bash
npx skills add hurzelpurzel/espeak-skill
```

Or install just the skill directly:

```bash
npx skills add https://github.com/hurzelpurzel/espeak-skill/tree/main/espeak
```

## Structure

- `espeak/SKILL.md` - Skill definition and usage documentation
- `espeak/scripts/speak.sh` - Wrapper with engine fallback, validation, and playback helpers

## Quick Usage

```bash
# Speak immediately
espeak/scripts/speak.sh "Hello world"

# Render WAV
espeak/scripts/speak.sh -v en-us -s 160 -w /tmp/out.wav "Hello"

# Stream to player
espeak/scripts/speak.sh --stdout "Hello" | aplay -q

# Check pronunciation
espeak/scripts/speak.sh --ipa -v en-us "Schedule"

# List voices
espeak/scripts/speak.sh --list
```

## Requirements

- `espeak-ng` (preferred) or `espeak`
- Optional: `aplay`, `paplay`, `ffplay` for `--play`; `ffmpeg` for MP3/OGG/conversion/normalization

## License

[MIT](LICENSE)
