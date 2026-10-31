#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

function usage() {
    local exit_code="${1:-1}"
    cat <<EOM
Speak text or render it to a WAV file with eSpeak NG (falls back to eSpeak).

usage: ${SCRIPT_NAME} [options] [text...]
       ${SCRIPT_NAME} [options] -f <file>
       cat <file> | ${SCRIPT_NAME} [options]

options:
    -f|--file <file>         Read text from a file
    -v|--voice <voice>       Voice or language, e.g. en-us, de, en+f3
    -s|--speed <wpm>         Speed in words per minute (80-450, default 175)
    -p|--pitch <0-99>        Base pitch (default 50)
    -P|--pitch-range <0-99>  Pitch range (default 50)
    -a|--amplitude <0-200>   Amplitude (default 100)
    -g|--word-gap <n>        Word gap in 10 ms units (default 0)
    -w|--wav <file>          Write WAV output instead of playing
       --stdout              Write WAV output to stdout
       --play                Play the WAV after --wav finishes
       --ssml                Interpret input as SSML
       --ipa                 Print IPA phonemes (implies quiet mode)
       --phonemes            Print eSpeak phoneme mnemonics (implies quiet mode)
       --punct <chars>       Speak names of the listed punctuation characters
       --list                List available voices
       --list-variants       List available voice variants
    -h|--help                Show this help
       --version             Show version information

examples:
    ${SCRIPT_NAME} "Hello world"
    ${SCRIPT_NAME} -v en-us -s 160 "Hello world"
    ${SCRIPT_NAME} -w hello.wav "Hello world"
    ${SCRIPT_NAME} -f notes.txt -w notes.wav --play
    ${SCRIPT_NAME} --stdout "Hello" | aplay -q
    ${SCRIPT_NAME} --ipa -v en "Schedule"

dependencies: espeak-ng or espeak; paplay, aplay, or ffplay for --play

EOM
    exit "$exit_code"
}

function find_engine() {
    if command -v espeak-ng >/dev/null 2>&1; then
        printf '%s\n' "espeak-ng"
        return 0
    fi
    if command -v espeak >/dev/null 2>&1; then
        printf '%s\n' "espeak"
        return 0
    fi
    printf "Error: neither espeak-ng nor espeak is installed\n" >&2
    return 1
}

function validate_integer() {
    local name="$1"
    local value="$2"
    local min="$3"
    local max="$4"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        printf "Error: %s must be an integer\n" "$name" >&2
        exit 1
    fi
    if (( value < min || value > max )); then
        printf "Error: %s must be between %s and %s\n" "$name" "$min" "$max" >&2
        exit 1
    fi
}

function play_file() {
    local file="$1"

    if command -v paplay >/dev/null 2>&1; then
        paplay "$file"
    elif command -v aplay >/dev/null 2>&1; then
        aplay -q "$file"
    elif command -v ffplay >/dev/null 2>&1; then
        ffplay -nodisp -autoexit -loglevel error "$file"
    else
        printf "Error: no audio player found (paplay, aplay, or ffplay)\n" >&2
        return 1
    fi
}

function main() {
    local voice=""
    local speed=""
    local pitch=""
    local pitch_range=""
    local amplitude=""
    local word_gap=""
    local wav_file=""
    local input_file=""
    local text=""
    local punct=""
    local ssml=false
    local stdout_mode=false
    local play=false
    local phonemes=false
    local ipa=false
    local list_voices=false
    local list_variants=false

    while (($# > 0)); do
        case "$1" in
        -f | --file)
            if (($# < 2)); then
                printf "Error: %s requires a file path\n" "$1" >&2
                usage
            fi
            input_file="$2"
            shift 2
            continue
            ;;
        -v | --voice)
            if (($# < 2)); then
                printf "Error: %s requires a voice name\n" "$1" >&2
                usage
            fi
            voice="$2"
            shift 2
            continue
            ;;
        -s | --speed)
            if (($# < 2)); then
                printf "Error: %s requires a number\n" "$1" >&2
                usage
            fi
            speed="$2"
            shift 2
            continue
            ;;
        -p | --pitch)
            if (($# < 2)); then
                printf "Error: %s requires a number\n" "$1" >&2
                usage
            fi
            pitch="$2"
            shift 2
            continue
            ;;
        -P | --pitch-range)
            if (($# < 2)); then
                printf "Error: %s requires a number\n" "$1" >&2
                usage
            fi
            pitch_range="$2"
            shift 2
            continue
            ;;
        -a | --amplitude)
            if (($# < 2)); then
                printf "Error: %s requires a number\n" "$1" >&2
                usage
            fi
            amplitude="$2"
            shift 2
            continue
            ;;
        -g | --word-gap)
            if (($# < 2)); then
                printf "Error: %s requires a number\n" "$1" >&2
                usage
            fi
            word_gap="$2"
            shift 2
            continue
            ;;
        -w | --wav)
            if (($# < 2)); then
                printf "Error: %s requires a file path\n" "$1" >&2
                usage
            fi
            wav_file="$2"
            shift 2
            continue
            ;;
        --punct=*)
            punct="${1#*=}"
            ;;
        --punct)
            if (($# < 2)); then
                printf "Error: %s requires a character list\n" "$1" >&2
                usage
            fi
            punct="$2"
            shift 2
            continue
            ;;
        --stdout) stdout_mode=true ;;
        --play) play=true ;;
        --ssml) ssml=true ;;
        --ipa) ipa=true ;;
        --phonemes) phonemes=true ;;
        --list) list_voices=true ;;
        --list-variants) list_variants=true ;;
        -h | --help) usage 0 ;;
        --version)
            local engine
            engine=$(find_engine) || exit 1
            printf "%s %s\n" "$SCRIPT_NAME" "$VERSION"
            "$engine" --version
            exit 0
            ;;
        --)
            shift
            text="$*"
            break
            ;;
        -*)
            printf "Error: Unknown option '%s'\n" "$1" >&2
            usage
            ;;
        *)
            text="$*"
            break
            ;;
        esac
        shift
    done

    local engine
    engine=$(find_engine) || exit 1

    if [[ "$list_voices" == true ]]; then
        "$engine" --voices
        exit $?
    fi

    if [[ "$list_variants" == true ]]; then
        "$engine" --voices=variant
        exit $?
    fi

    if [[ -n "$input_file" && -n "$text" ]]; then
        printf "Error: provide either text or --file, not both\n" >&2
        exit 1
    fi

    if [[ -n "$wav_file" && "$stdout_mode" == true ]]; then
        printf "Error: --wav and --stdout are mutually exclusive\n" >&2
        exit 1
    fi

    if [[ "$play" == true && -z "$wav_file" ]]; then
        printf "Error: --play requires --wav\n" >&2
        exit 1
    fi

    if [[ "$phonemes" == true || "$ipa" == true ]]; then
        if [[ -n "$wav_file" || "$stdout_mode" == true ]]; then
            printf "Error: phoneme output cannot be combined with --wav or --stdout\n" >&2
            exit 1
        fi
    fi

    if [[ -z "$input_file" && -z "$text" && -t 0 ]]; then
        printf "Error: no text provided\n" >&2
        usage
    fi

    if [[ -n "$speed" ]]; then
        validate_integer "speed" "$speed" 80 450
    fi
    if [[ -n "$pitch" ]]; then
        validate_integer "pitch" "$pitch" 0 99
    fi
    if [[ -n "$pitch_range" ]]; then
        validate_integer "pitch range" "$pitch_range" 0 99
    fi
    if [[ -n "$amplitude" ]]; then
        validate_integer "amplitude" "$amplitude" 0 200
    fi
    if [[ -n "$word_gap" ]]; then
        validate_integer "word gap" "$word_gap" 0 1000
    fi

    local -a args=()
    if [[ -n "$voice" ]]; then
        args+=(-v "$voice")
    fi
    if [[ -n "$speed" ]]; then
        args+=(-s "$speed")
    fi
    if [[ -n "$pitch" ]]; then
        args+=(-p "$pitch")
    fi
    if [[ -n "$pitch_range" ]]; then
        args+=(-P "$pitch_range")
    fi
    if [[ -n "$amplitude" ]]; then
        args+=(-a "$amplitude")
    fi
    if [[ -n "$word_gap" ]]; then
        args+=(-g "$word_gap")
    fi
    if [[ -n "$punct" ]]; then
        args+=(--punct="$punct")
    fi
    if [[ "$ssml" == true ]]; then
        args+=(-m)
    fi
    if [[ "$phonemes" == true ]]; then
        args+=(-x)
    fi
    if [[ "$ipa" == true ]]; then
        args+=(--ipa)
    fi
    if [[ "$phonemes" == true || "$ipa" == true ]]; then
        args+=(-q)
    fi
    if [[ -n "$wav_file" ]]; then
        args+=(-w "$wav_file")
    fi
    if [[ "$stdout_mode" == true ]]; then
        args+=(--stdout)
    fi

    if [[ -n "$input_file" ]]; then
        if [[ ! -r "$input_file" ]]; then
            printf "Error: cannot read file '%s'\n" "$input_file" >&2
            exit 1
        fi
        "$engine" "${args[@]}" -f "$input_file" || exit $?
    elif [[ -n "$text" ]]; then
        "$engine" "${args[@]}" -- "$text" || exit $?
    else
        "$engine" "${args[@]}" --stdin || exit $?
    fi

    if [[ -n "$wav_file" ]]; then
        if [[ ! -s "$wav_file" ]]; then
            printf "Error: no audio was produced; the input may be empty\n" >&2
            exit 1
        fi
    fi

    if [[ -n "$wav_file" && "$play" == true ]]; then
        play_file "$wav_file" || exit $?
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit 0
fi
