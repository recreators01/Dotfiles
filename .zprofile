pkill sing-box; cd ~/.config/sing-box; sing-box run &

cd ~

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  exec Hyprland > /dev/null 2>&1
fi
