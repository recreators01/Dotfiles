if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  exec niri --session > /dev/null 2>&1
fi
