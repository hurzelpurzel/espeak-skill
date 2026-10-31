# AGENTS.md

## Overview
This is an **OpenCode/Claude Code skill repo** (not a Node/py project). Content lives under `espeak/`:
- `espeak/SKILL.md` – full documentation for using eSpeak NG
- `espeak/scripts/speak.sh` – wrapper around `espeak-ng`/`espeak` with validation/playback helpers

## Key facts
- No package manager manifests/lockfiles (no package.json/pyproject/etc.). Treat as a pure script + docs repo.
- Runtime dependency: `espeak-ng` preferred, falls back to `espeak`. Optional: `aplay`, `paplay`, `ffplay` for `--play`; `ffmpeg` for MP3/OGG/conversion/normalization.
- Wrapper defaults (from `speak.sh`): speed 175 wpm, pitch 50, pitch-range 50, amplitude 100, word-gap 0. Flags validated (speed 80-450, pitch/pitch-range 0-99, amplitude 0-200, word-gap 0-1000).
- `--play` requires `--wav`. `--wav` and `--stdout` are mutually exclusive. Phoneme/IPA modes cannot combine with `--wav`/`--stdout`. Cannot pass both text and `-f/--file`. If no text/file and stdin is a TTY, it errors.

## Common commands
- Quick check: `bash -n espeak/scripts/speak.sh && scripts/speak.sh --help` (from repo root or run with relative paths)
- List voices: `espeak/scripts/speak.sh --list` or `espeak-ng --voices`
- Quick speak: `espeak/scripts/speak.sh "Hello world"` (uses engine fallback)
- Render WAV: `espeak/scripts/speak.sh -v en-us -s 160 -w /tmp/out.wav "Hello"`
- Stream: `espeak/scripts/speak.sh --stdout "Hello" | aplay -q`
- IPA/phonemes: `espeak/scripts/speak.sh --ipa -v en-us "Schedule"` (implies quiet)

## Gotchas
- `espeak-ng -w -` does not stream; use `--stdout`. `--stdout` emits a full WAV header.
- Without `--stdin`, piped stdin is processed line-by-line (prosody resets). Use `--stdin` for a continuous document.
- Leading `-` text: pass `--` before it.
- `-m` enables SSML; unsupported SSML tags are skipped silently; don’t enable for literal `<`/`>`.
- MBROLA voices may need separate packages/binaries.
- `en` defaults to British English; use `en-us` for American.
- Long text: use `-f` or `--stdin` (arg length limits).

## Repo layout notes
- Skill definition is `espeak/SKILL.md` (frontmatter + usage). If updating behavior, keep both `speak.sh` validation/help and SKILL.md in sync.
- Scripts are executable. This repo has no tests/lint/CI/build configs present.
