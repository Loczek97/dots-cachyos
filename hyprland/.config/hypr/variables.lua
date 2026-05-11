local vars = {}

vars.terminal = "kitty"
vars.fileManager = "nautilus"
-- $menu = rofi -show drun -show-icons
vars.menu = os.getenv("HOME") .. "/.config/scripts/qs_manager.sh open launcher"
vars.emoji = os.getenv("HOME") .. "/.config/rofi/emoji-picker/rofi-emoji-picker.sh"
vars.browser = "zen-browser"
vars.editor = "code"
vars.music = "spotify"
vars.mainMod = "SUPER"

return vars
