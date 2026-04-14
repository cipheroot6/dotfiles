#!/usr/bin/env bash

FIFO=$(mktemp -u)
mkfifo "$FIFO"
ueberzugpp layer --silent -o kitty < "$FIFO" &
UP_PID=$!
exec 3>"$FIFO"

cleanup() {
    exec 3>&-
    kill "$UP_PID" 2>/dev/null
    rm -f "$FIFO" /tmp/_ff_preview
}
trap cleanup EXIT INT TERM

cat > /tmp/_ff_preview << EOF
#!/usr/bin/env bash
file="\$1"
mime=\$(file --mime-type -b "\$file" 2>/dev/null)

case "\$mime" in
    image/*)
        printf '{"action":"remove","identifier":"p"}\n' >> "$FIFO"
        for i in \$(seq 1 "\$FZF_PREVIEW_LINES"); do printf '\n'; done
        printf '{"action":"add","identifier":"p","x":%s,"y":%s,"width":%s,"height":%s,"path":"%s"}\n' \
            "\$FZF_PREVIEW_LEFT" "\$FZF_PREVIEW_TOP" \
            "\$FZF_PREVIEW_COLUMNS" "\$FZF_PREVIEW_LINES" \
            "\$file" >> "$FIFO"
        sleep infinity
        ;;
    text/*|application/json|application/javascript|application/xml)
        printf '{"action":"remove","identifier":"p"}\n' >> "$FIFO"
        bat --color=always --style=numbers "\$file" 2>/dev/null || cat "\$file"
        ;;
    application/pdf)
        printf '{"action":"remove","identifier":"p"}\n' >> "$FIFO"
        pdftotext "\$file" - 2>/dev/null | bat --color=always --style=numbers --language=text
        ;;
    *)
        printf '{"action":"remove","identifier":"p"}\n' >> "$FIFO"
        echo "  \$(basename "\$file")"
        echo "  mime: \$mime"
        echo "  size: \$(du -sh "\$file" 2>/dev/null | cut -f1)"
        ;;
esac
EOF
chmod +x /tmp/_ff_preview

selected=$(fzf --prompt="  " \
               --preview '/tmp/_ff_preview {}' \
               --preview-window='right:60%:wrap' \
               --bind='ctrl-/:toggle-preview' \
               --height=100% \
               --layout=reverse \
               --border=rounded \
               --info=inline \
               --color='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8' \
               --color='fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc' \
               --color='marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8' \
               < <(fd --type f --hidden --follow --absolute-path \
                      --exclude '.git' \
                      --exclude 'node_modules' \
                      --exclude '.cache' \
                      --exclude 'target' \
                      --exclude '.bun' \
                      --exclude 'dist' \
                      --exclude '.npm' \
                      --exclude 'BurpSuite' \
                      --exclude 'chromium' \
                      --exclude '.mozilla' \
                      --exclude 'firefox' \
                      --exclude 'java' \
                      --exclude '.gradle' \
                      --exclude 'zen' \
                      . "$HOME" 2>/dev/null))

[[ -n "$selected" ]] && nvim "$selected"
