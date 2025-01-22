# tmux-pass

> Quick password-store browser with preview using fzf in tmux.

## Features

- Browse your password-store using fzf
- Preview password in a tmux split (optional)
- Detects pbcopy (macOS), xclip or xsel (Linux)
- Copy password (<kbd>Enter</kbd>)
- Copy username (<kbd>Alt</kbd>-<kbd>Enter</kbd>)
- OTP support (<kbd>Alt</kbd>-<kbd>Space</kbd>)
- Edit (<kbd>Ctrl</kbd>-<kbd>e</kbd>) and Delete (<kbd>Ctrl</kbd>-<kbd>d</kbd>)
- Toggle password preview (<kbd>Tab</kbd>)

## Install

### Requirements
* [password-store](https://www.passwordstore.org)
* [tmux](https://github.com/tmux/tmux/wiki) 3.x+
* bash 4+
* [fzf](https://github.com/junegunn/fzf)

### Using [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)

Add the following to your list of TPM plugins in `~/.tmux.conf`:

```bash
set -g @plugin 'rafi/tmux-pass'
```

Hit prefix + I to fetch and source the plugin.
You should now be able to use the plugin!

### Manual

Clone the repo:


Source it in your `~/.tmux.conf`:

```bash
run-shell ~/.tmux/plugins/tmux-pass/plugin.tmux
```

Reload tmux config by running:

```bash
tmux source-file ~/.tmux.conf
```

## Configuration

NOTE: for changes to take effect,
you'll need to source again your `~/.tmux.conf` file.

- [tmux-pass](#tmux-pass)
  - [Features](#features)
  - [Install](#install)
    - [Requirements](#requirements)
    - [Using Tmux Plugin Manager](#using-tmux-plugin-manager)
    - [Manual](#manual)
  - [Configuration](#configuration)
    - [@pass-key](#pass-key)
    - [@pass-copy-to-clipboard](#pass-copy-to-clipboard)
    - [@pass-window-size](#pass-window-size)
    - [@pass-hide-pw-from-preview](#pass-hide-pw-from-preview)
    - [@pass-hide-preview](#pass-hide-preview)

### @pass-key

```
default: B
```

Customize how to display the pass browser.
Always preceded by prefix: prefix + @pass-key

For example:

```bash
set -g @pass-key b
```

### @pass-copy-to-clipboard

```
default: on
```

Copies selected password into clipboard.

For example:

```bash
set -g @pass-copy-to-clipboard on
```

### @pass-window-size

```
default: 10
```

The size of the tmux split that will be opened.

For example:

```bash
set -g @pass-window-size 10
```

### @pass-hide-pw-from-preview

```
default: off
```

Show only additional information in the preview pane (e.g. login, url, etc.),
but hide the password itself.
This can be desirable in situations when you don't want bystanding people to
get a glimpse at your passwords.

For example:

```bash
set -g @pass-hide-pw-from-preview 'on'
```

### @pass-hide-preview

```
default: off
```

Start with the preview pane hidden.

For example:

```bash
set -g @pass-hide-preview
```
