#!/bin/sh

set -e

base_url='http://wiki.garrysmod.com'

detag() {
    printf '%s' "${1##*>}"
}

wget -o /dev/null -O - "$base_url"/navbar/ |
    sed -r '
        # Split up before each closing tag
        s#</#\n\0#g
    ' |
    sed -r '
        # Remove navbarlink tags
        s/<a class='\''navbarlink'\'' .*>//g

        # Remove everything before the last tag
        s/.*</</
    ' |
    {
        section=
        while read -r line; do
            detagged="$(detag "$line")"

            case "$line" in
                '<h2'*' &raquo;')
                    # Parse menu headers
                    detagged="${detagged% &raquo;}"
                    if printf '%s' "$detagged" | grep -v -q '^[[:alpha:]_][[:alnum:]_]*$'; then continue; fi
                    case "$section" in
                        Hooks|Libraries|Classes|Panels)
                            printf '  "%s",\n' "$detagged"
                        ;;

                        Structures|Shaders|'Lua Reference'|'Lua Tutorials'|Global|Enumerations)
                            :
                        ;;

                        *)
                            echo >&2 "unknown section '$section' for '$detagged'"
                        ;;
                    esac
                ;;

                '<a'*)
                    # Parse menu entries
                    case "$section" in
                        Global)
                            printf '  "%s",\n' "$detagged"
                        ;;

                        Enumerations)
                            echo >&2 "Retrieving enum data for $detagged"

                            url="$base_url/page/Enums/$detagged" # TODO: use URL from the <a> tag
                            output="$(wget "$url" -o /dev/null -O -)"

                            if ! printf '%s' "$output" | grep -q "These enumerations do not exist in the game"; then
                                printf '\n  --- %s\n' "$detagged"
                                printf '%s' "$output" | sed -rn 's/^<td> ('"$detagged"'_[^[:space:]]+|[A-Z][A-Z0-9_]{2,})$/  "\1",/p'
                            fi
                        ;;

                        Structures|Shaders|'Lua Reference'|'Lua Tutorials'|Hooks|Libraries|Classes|Panels)
                            :
                        ;;

                        *)
                            echo >&2 "unknown section '$section' for '$detagged'"
                        ;;
                    esac
                ;;

                '<h1>'*)
                    section="$detagged"
                    case "$section" in
                        Reference)
                            :
                        ;;

                        *)
                            echo >&2 "Parsing section $section"
                            printf '\n  -- %s\n' "$section"
                        ;;
                    esac
                ;;

                '<h2>'*)
                    section="$detagged"
                    case "$section" in
                        Enumerations)
                            echo >&2 "Parsing section $section"
                            printf '\n  -- %s' "$section" # No newline after this, to avoid double newlines
                        ;;
                    esac
                ;;

                '</'*|'<ul'*)
                    # Ignore closing tags and <ul> tags
                    :
                ;;

                *)
                    echo >&2 "Warning: Unhandled line '$line'"
            esac
        done

        printf '\n'
    } |
    sed -ri '
        0,/BEGIN_GENERATED_CODE/ {
            /BEGIN_GENERATED_CODE/ {
                r /dev/stdin
            }
            b
        }
        /END_GENERATED_CODE/,$ b
        d
    ' .luacheckrc
