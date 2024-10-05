
#### Snow
```bash
set -g @tmux_power_theme 'snow'
```
#### Forest
```bash
set -g @tmux_power_theme 'forest'
```
Violet
```bash
set -g @tmux_power_theme 'violet'
```
#### Redwine
```bash
set -g @tmux_power_theme 'redwine'
```
#### Default
```bash
set -g @tmux_power_theme 'default'
```
Set this theme if you want to honor the terminal colorscheme. To be used with
something like [pywal](https://github.com/dylanaraps/pywal) for instance.

### ⚙  Customizing

You can define your favourite main color if you don't like any of above.

```tmux
set -g @tmux_power_theme '#483D8B' # dark slate blue
```

You can change the date and time formats using strftime:

```tmux
set -g @tmux_power_date_format '%F'
set -g @tmux_power_time_format '%T'
```

You can also customize the icons. As an example,
the following configurations can generate the theme shown in the first screenshot:
```bash
set -g @plugin 'wfxr/tmux-power'
set -g @plugin 'wfxr/tmux-net-speed'
set -g @tmux_power_theme 'everforest'
set -g @tmux_power_date_icon ' '
set -g @tmux_power_time_icon ' '
set -g @tmux_power_user_icon ' '
set -g @tmux_power_session_icon ' '
set -g @tmux_power_show_upload_speed    true
set -g @tmux_power_show_download_speed  true
set -g @tmux_power_show_web_reachable   true
set -g @tmux_power_right_arrow_icon     ''
set -g @tmux_power_left_arrow_icon      ''
set -g @tmux_power_upload_speed_icon    '󰕒'
set -g @tmux_power_download_speed_icon  '󰇚'
set -g @tmux_power_prefix_highlight_pos 'R'
```

*The default icons use glyphs from [nerd-fonts](https://github.com/ryanoasis/nerd-fonts).*

### 📦 Plugin support

**[tmux-net-speed](https://github.com/wfxr/tmux-net-speed)**

```tmux
set -g @tmux_power_show_upload_speed true
set -g @tmux_power_show_download_speed true
```

**[tmux-prefix-highlight](https://github.com/tmux-plugins/tmux-prefix-highlight)**

```tmux
# 'L' for left only, 'R' for right only and 'LR' for both
set -g @tmux_power_prefix_highlight_pos 'LR'
```

**[tmux-web-reachable](https://github.com/wfxr/tmux-web-reachable)**

```tmux
set -g @tmux_power_show_web_reachable true
```



### session manager

https://github.com/joshmedeski/t-smart-tmux-session-manager
