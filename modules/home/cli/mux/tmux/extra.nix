{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.strings) optionalString;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  inherit (lib.meta) getExe' getExe;
  shell = getExe (builtins.getAttr config.my.shell pkgs);
in {
  programs.tmux.extraConfig = with config.my.keyboard.keys; ''
    # Fix colors and enable true color support and italics
    if 'infocmp -x tmux-256color > /dev/null 2>&1' 'set -g default-terminal "tmux-256color"'
    # sets
    set -s extended-keys
    set -as terminal-features 'xterm*:extkeys'
    set -gs exit-empty on

    # undercurl support
    set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
    # underscore colours - needs tmux-3.0
    set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

    # utf8 is on
    set -qg status-utf8 on
    setw -qg utf8 on

    # display time
    set -g display-time 4000

    setw xterm-keys on
    set -sg repeat-time 300

    # Border lines between panes are thicker
    # single -> single lines using ACS or UTF-8 characters
    # double -> double lines using UTF-8 characters
    # heavy  -> heavy lines using UTF-8 characters
    # simple -> simple ASCII characters
    # number -> the pane number
    set -g pane-border-lines single

    # Indicate active pane by colouring only half of the border in windows with
    # exactly two panes, by displaying arrow markers, by drawing both or neither.
    # [off | colour | arrows | both]
    set -g pane-border-indicators colour

    # binds
    # send prefix to nested tmux session
    bind C-a send-prefix

    # source tmux config file
    bind C-r source-file "~/.config/tmux/tmux.conf" \; display 'Sourced tmux.conf'
    bind q kill-window
    bind Q kill-session

    bind t new-window -c "#{pane_current_path}"

    # rotate panes
    bind r rotate-window -D
    bind R rotate-window -U

    # even layout
    bind | select-layout even-vertical
    bind - select-layout even-horizontal

    # main layout
    bind M select-layout main-vertical
    bind m select-layout main-horizontal

    # select layout
    bind > select-layout -n
    bind < select-layout -p

    bind b break-pane
    bind B list-buffers
    bind p select-pane -t:.+
    bind P display-panes

    # Search sessions using an fzf menu
    # Found this gem down here:
    # https://github.com/majjoha/dotfiles/blob/cd6f966d359e16b3a7c149f96d4edb8a83e769db/.config/tmux/tmux.conf#L41
    bind s display-popup -E -w 75% -h 75% "\
      tmux list-sessions -F '#{?session_attached,,#{session_name}}' |\
      sed '/^$/d' |\
      fzf --reverse --header jump-to-session --preview 'tmux capture-pane -pt {}'  |\
      xargs tmux switch-client -t"

    # fzf menu to kill sessions
    # Credit: video below by Waylon Walker
    # https://www.youtube.com/watch?v=QWPyYx54JbE
    bind S display-popup -E "\
        tmux list-sessions -F '#{?session_attached,,#{session_name}}' |\
        fzf --reverse -m --header=kill-session |\
        xargs -I {} tmux kill-session -t {}"

    bind Tab switch-client -l

    # repeat bindings
    bind [ previous-window
    bind ] next-window

    # When pressing prefix+s to list sessions, I want them sorted by time
    # That way my latest used sessions show at the top of the list
    # -s starts with sessions collapsed (doesn't show windows)
    # -Z zooms the pane (don't understand what this does)
    # -O specifies the initial sort field: one of ‘index’, ‘name’, or ‘time’ (activity).
    # https://unix.stackexchange.com/questions/608268/how-can-i-force-tmux-to-sort-my-sessions-alphabetically
    # bind s choose-tree -Zs -O time
    # bind s choose-tree -Zs -O time -y
    bind , choose-tree -Zs -O time -F "#{session_windows}"

    # -y at the end is a feature I requested so that the session is closed without confirmation
    # https://github.com/tmux/tmux/issues/4152
    # bind s choose-tree -Zs -O time -F "#{session_windows}" -y
    # bind s choose-tree -Zs -O time -F "#{?session_attached,#[fg=$linkarzu_color02],#[fg=$linkarzu_color03]}#{session_name}#[default]" -y
    # bind s choose-tree -Zs -O time -F "#{?session_attached,#[fg=$linkarzu_color02],#[fg=$linkarzu_color03]}" -y
    # splits
    unbind '"'
    unbind %

    # split panes
    bind ${k} split-window -vb -c '#{pane_current_path}'
    bind ${j} split-window -v -c '#{pane_current_path}'
    bind ${h} split-window -hb -c '#{pane_current_path}'
    bind ${l} split-window -h -c '#{pane_current_path}'
    # move panes with C-a C-HJKL
    bind ${H} swap-pane -U
    bind ${L} swap-pane -D
    bind ${J} swap-pane -D
    bind ${K} swap-pane -U
    # layouts switch
    bind ${n} next-layout
    bind ${N} previous-layout

    # copy-mode-vi
    bind Space copy-mode
    bind -T copy-mode-vi v send-keys -X begin-selection
    bind -T copy-mode-vi ${h} send-keys -X cursor-left
    bind -T copy-mode-vi ${l} send-keys -X cursor-right
    bind -T copy-mode-vi ${k} send-keys -X cursor-up
    bind -T copy-mode-vi ${j} send-keys -X cursor-down
    bind -T copy-mode-vi ${J} send -X scroll-down
    bind -T copy-mode-vi ${K} send -X scroll-up
    bind -T copy-mode-vi ${e} send-keys -X next-word-end
    bind -T copy-mode-vi ${H} send-keys -X start-of-line
    bind -T copy-mode-vi ${L} send-keys -X end-of-line
    bind -T copy-mode-vi ${n} send-keys -X search-again
    bind -T copy-mode-vi ${N} send-keys -X search-reverse
    bind -T copy-mode-vi ${o} send-keys -X other-end
    # don't exit copy mode when dragging with mouse
    unbind -T copy-mode-vi MouseDragEnd1Pane

    # copy to X11 clipboard
    if -b 'command -v xsel > /dev/null 2>&1' 'bind y run -b "tmux save-buffer - | xsel -i -b"'
    if -b '! command -v xsel > /dev/null 2>&1 && command -v xclip > /dev/null 2>&1' 'bind y run -b "tmux save-buffer - | xclip -i -selection clipboard >/dev/null 2>&1"'
    # copy to macOS clipboard
    if -b 'command -v pbcopy > /dev/null 2>&1' 'bind y run -b "tmux save-buffer - | pbcopy"'
    if -b 'command -v reattach-to-user-namespace > /dev/null 2>&1' 'bind y run -b "tmux save-buffer - | reattach-to-user-namespace pbcopy"'
    # copy to Windows clipboard
    if -b 'command -v clip.exe > /dev/null 2>&1' 'bind y run -b "tmux save-buffer - | clip.exe"'
    if -b '[ -c /dev/clipboard ]' 'bind y run -b "tmux save-buffer - > /dev/clipboard"'

    # -- toggle_syn_input
    bind C-g setw synchronize-panes

    # -- toggle_status
    bind C-b set status

    # vim tmux navigation
    is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
    bind-key -n C-${h} if-shell "$is_vim" 'send-keys C-${h}'  'select-pane -L'
    bind-key -n C-${j} if-shell "$is_vim" 'send-keys C-${j}'  'select-pane -D'
    bind-key -n C-${k} if-shell "$is_vim" 'send-keys C-${k}'  'select-pane -U'
    bind-key -n C-${l} if-shell "$is_vim" 'send-keys C-${l}'  'select-pane -R'

    bind-key -n C-q if-shell "$is_vim" 'send-keys C-q'  'kill-pane'

    bind-key -n M-${h} if-shell "$is_vim" 'send-keys C-Left' 'resize-pane -L 3'
    bind-key -n M-${j} if-shell "$is_vim" 'send-keys C-Down' 'resize-pane -D 3'
    bind-key -n M-${k} if-shell "$is_vim" 'send-keys C-Up' 'resize-pane -U 3'
    bind-key -n M-${l} if-shell "$is_vim" 'send-keys C-Right' 'resize-pane -R 3'

    tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
    if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
    if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

    bind-key -T copy-mode-vi 'C-${h}' select-pane -L
    bind-key -T copy-mode-vi 'C-${j}' select-pane -D
    bind-key -T copy-mode-vi 'C-${k}' select-pane -U
    bind-key -T copy-mode-vi 'C-${l}' select-pane -R
    bind-key -T copy-mode-vi 'C-\' select-pane -l

    ${optionalString isDarwin ''
      set-option -g default-command "${getExe' pkgs.reattach-to-user-namespace "reattach-to-user-namespace"} -l ${shell}"
    ''}
  '';
}
