#!/bin/bash

# Dependencies: rofi, translate-shell

# Default languages
DEFAULT_INPUT_LANG="en"
DEFAULT_OUTPUT_LANG="ru"
SELECTED_SIGN="⪧"
SHOW_TRANSLATION=true
TRANSLATION_CHARS_PER_LINE=50

CACHE_DIR="$HOME/.cache/rofi-translate"
LANG_FILE="$CACHE_DIR/rofi-translate-languages.conf"
LANG_CACHE_FILE="$CACHE_DIR/rofi-translate-languages_cache"

# Create cache directory if it doesn't exist
if [[ ! -d "$CACHE_DIR" ]]; then
    # Delete if it exists but is not a dir
    if [[ -e "$CACHE_DIR" ]]; then
        rm $CACHE_DIR
    fi
    mkdir -p "$CACHE_DIR"
fi

# Language cache
readarray -t LANGUAGES < <(trans -list-codes)

# Load saved languages
load_languages() {
    if [[ -f "$LANG_FILE" ]]; then
        source "$LANG_FILE"
    else
        INPUT_LANG="$DEFAULT_INPUT_LANG"
        OUTPUT_LANG="$DEFAULT_OUTPUT_LANG"
    fi
}

# Save current languages
save_languages() {
    echo "INPUT_LANG=\"$INPUT_LANG\"" > "$LANG_FILE"
    echo "OUTPUT_LANG=\"$OUTPUT_LANG\"" >> "$LANG_FILE"
}

# Show language selection menu
select_language() {
    local current_lang="$1"
    local prompt="$2"

    local menu_items=()
    for lang in "${LANGUAGES[@]}"; do
        if [[ "$lang" == "$current_lang" ]]; then
            menu_items+=("$SELECTED_SIGN $lang")
        else
            menu_items+=("  $lang")
        fi
    done

    local selection=$(printf "%s\n" "${menu_items[@]}" | rofi -dmenu -i -p "$prompt")

    # Trim
    if [[ -n "$selection" ]]; then
        echo $(echo "$selection" | sed "s/^$SELECTED_SIGN *//")
    fi
}

# Translate text
translate_text() {
    local text="$1"
    local from_lang="$2"
    local to_lang="$3"
    
    if [[ -n "$text" ]]; then
        echo $(trans -b "$from_lang:$to_lang" "$text" 2>/dev/null)
    fi
}

# Wraps the text into lines
wrap_text() {
    local text="$1"
    local width="${2:-60}"
    local current=""

    lines=()
    local words
    read -ra words <<<"$text"

    for w in "${words[@]}"; do
        # If adding the next word would overflow the line, flush it.
        if [[ ${#current} -gt 0 && $((${#current} + ${#w} + 1)) -gt width ]]; then
            lines+=("$current")
            current="$w"
        else
            # Build the current line.
            [[ -n $current ]] && current+=" "
            current+="$w"
        fi
    done

    # Don’t forget the last line if anything is left.
    [[ -n $current ]] && lines+=("$current")
}

# Shows the translated text
show_translation() {
    local translation="$1"

    if [[ "$SHOW_TRANSLATION" == "true" ]]; then
        wrap_text "$translation" "${TRANSLATION_CHARS_PER_LINE}"
        printf '%s\n' "${lines[@]}" | rofi -dmenu -i -p "🗐 Translation copied to clipboard"
    fi
}

# Main interface
main_interface() {
    local last_input=""
    local last_translation=""
    
    while true; do
        local menu_items=""
        menu_items+="  Input Language $SELECTED_SIGN $INPUT_LANG\n"
        menu_items+="  Output Language $SELECTED_SIGN $OUTPUT_LANG\n"
        menu_items+="⇵  Swap Languages"
        
        # Show rofi menu
        local selection=$(echo -e "$menu_items" | rofi -dmenu -i -p " " -format "s")
        
        # Handle selection
        if [[ -z "$selection" ]]; then
            break
        elif [[ "$selection" == *"Input Language"* ]]; then
            local new_lang=$(select_language "$INPUT_LANG" "Select Input Language ->")
            if [[ -n "$new_lang" ]]; then
                INPUT_LANG="$new_lang"
                save_languages
                # Re-translate if we have input
                if [[ -n "$last_input" ]]; then
                    last_translation=$(translate_text "$last_input" "$INPUT_LANG" "$OUTPUT_LANG")
                fi
            fi
        elif [[ "$selection" == *"Output Language"* ]]; then
            local new_lang=$(select_language "$OUTPUT_LANG" "Select Output Language ->")
            if [[ -n "$new_lang" ]]; then
                OUTPUT_LANG="$new_lang"
                save_languages
                # Re-translate if we have input
                if [[ -n "$last_input" ]]; then
                    last_translation=$(translate_text "$last_input" "$INPUT_LANG" "$OUTPUT_LANG")
                fi
            fi
        elif [[ "$selection" == *"Swap Languages"* ]]; then
            local temp="$INPUT_LANG"
            INPUT_LANG="$OUTPUT_LANG"
            OUTPUT_LANG="$temp"
            save_languages
            # Re-translate if we have input
            if [[ -n "$last_input" ]]; then
                last_translation=$(translate_text "$last_input" "$INPUT_LANG" "$OUTPUT_LANG")
            fi
        else
            # User entered text
            last_input="$selection"

            last_translation=$(translate_text "$last_input" "$INPUT_LANG" "$OUTPUT_LANG")

            # Copy to clipboard
            if command -v wl-copy &> /dev/null; then
                echo "$last_translation" | wl-copy
            elif command -v xclip &> /dev/null; then
                echo "$last_translation" | xclip -selection clipboard
            elif command -v pbcopy &> /dev/null; then
                echo "$last_translation" | pbcopy
            else
                echo "Warning: No clipboard tool found!" >&2
            fi

            show_translation "$last_translation"
            exit
        fi
    done
}

# Initialize
load_languages
main_interface
