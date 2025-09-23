# tmux-forceline Development Container
FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04

LABEL maintainer="tmux-forceline development team"
LABEL version="3.0-dev"
LABEL description="Complete development environment for tmux-forceline"

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Core development tools
    build-essential \
    curl \
    wget \
    git \
    vim \
    nano \
    sudo \
    \
    # tmux and terminal tools
    tmux \
    screen \
    ncurses-dev \
    \
    # Shell and scripting
    bash \
    zsh \
    fish \
    shellcheck \
    shfmt \
    bats \
    \
    # Performance and monitoring tools
    htop \
    iotop \
    iftop \
    nethogs \
    strace \
    ltrace \
    perf-tools-unstable \
    \
    # Development utilities
    jq \
    yq \
    bc \
    tree \
    fd-find \
    ripgrep \
    fzf \
    bat \
    exa \
    \
    # Package building tools
    dpkg-dev \
    rpm \
    alien \
    fakeroot \
    \
    # Container and orchestration tools
    docker.io \
    docker-compose \
    \
    # Network and security tools
    netcat \
    nmap \
    tcpdump \
    wireshark-common \
    \
    # Documentation tools
    pandoc \
    texlive-latex-base \
    texlive-fonts-recommended \
    \
    # Monitoring and observability
    prometheus-node-exporter \
    \
    # Cleanup
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install latest tmux from source for development
RUN cd /tmp \
    && wget https://github.com/tmux/tmux/releases/download/3.3a/tmux-3.3a.tar.gz \
    && tar xzf tmux-3.3a.tar.gz \
    && cd tmux-3.3a \
    && ./configure --prefix=/usr/local \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/tmux-*

# Install Node.js for documentation and web tools
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

# Install global npm packages for development
RUN npm install -g \
    markdown-cli \
    markdownlint-cli \
    live-server \
    http-server \
    nodemon

# Install Ansible for deployment automation
RUN pip3 install \
    ansible \
    ansible-lint \
    yamllint \
    molecule

# Install additional development tools
RUN curl -fsSL https://get.docker.com | sh

# Create development user (if not exists)
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Configure sudo for development user
RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Switch to development user
USER $USERNAME

# Set up development environment for user
RUN mkdir -p /home/$USERNAME/.config/tmux \
    && mkdir -p /home/$USERNAME/.local/bin \
    && mkdir -p /home/$USERNAME/workspace

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Configure tmux for development
RUN cat > /home/$USERNAME/.tmux.conf << 'EOF'
# tmux-forceline Development Configuration

# Set prefix key
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Enable mouse support
set -g mouse on

# Set default terminal
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",xterm-256color*:Tc"

# History limit
set -g history-limit 10000

# Start windows and panes at 1
set -g base-index 1
setw -g pane-base-index 1

# Reload config
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"

# Development key bindings
bind-key v split-window -h
bind-key s split-window -v
bind-key h select-pane -L
bind-key j select-pane -D
bind-key k select-pane -U
bind-key l select-pane -R

# Status bar configuration (will be overridden by forceline)
set -g status-interval 1
set -g status-position bottom
set -g status-justify left
set -g status-style 'bg=colour234 fg=colour137'

# Development session setup
bind-key D new-session -d -s development \; \
    new-window -n 'editor' \; \
    new-window -n 'server' \; \
    new-window -n 'tests' \; \
    new-window -n 'logs' \; \
    select-window -t 1
EOF

# Configure shell environment
RUN cat >> /home/$USERNAME/.bashrc << 'EOF'

# tmux-forceline Development Environment
export FORCELINE_DEV=true
export FORCELINE_DIR="/workspace"
export ENTERPRISE_DIR="/workspace/enterprise"

# Development aliases
alias ll='exa -la'
alias cat='bat'
alias find='fd'
alias grep='rg'

# tmux-forceline development aliases
alias fl='cd $FORCELINE_DIR'
alias flt='cd $FORCELINE_DIR && bats tests/'
alias flb='cd $FORCELINE_DIR && ./scripts/build.sh'
alias fld='cd $FORCELINE_DIR && ./tmux-forceline-cli.sh dashboard performance'

# Quick tmux session management
alias tdev='tmux new-session -d -s dev && tmux switch-client -t dev'
alias ttest='tmux new-session -d -s test && tmux switch-client -t test'
alias tattach='tmux attach-session -t'

# Development utilities
alias performance-test='$FORCELINE_DIR/enterprise/performance/performance_benchmark.sh'
alias security-scan='$FORCELINE_DIR/enterprise/security_hardening.sh scan'
alias monitoring-start='$FORCELINE_DIR/enterprise/monitoring_observability.sh start'

# Git aliases for development
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

# Function to start development environment
start_dev_env() {
    echo "🚀 Starting tmux-forceline development environment..."
    
    # Start tmux with development session
    tmux new-session -d -s development -c "$FORCELINE_DIR"
    
    # Create development windows
    tmux new-window -t development:1 -n 'editor' -c "$FORCELINE_DIR"
    tmux new-window -t development:2 -n 'tests' -c "$FORCELINE_DIR"
    tmux new-window -t development:3 -n 'monitoring' -c "$FORCELINE_DIR"
    tmux new-window -t development:4 -n 'enterprise' -c "$FORCELINE_DIR/enterprise"
    
    # Start monitoring in background
    tmux send-keys -t development:3 'monitoring-start' Enter
    
    # Attach to development session
    tmux attach-session -t development
}

# Auto-start development environment if in workspace
if [[ "$PWD" == "/workspace" ]] && [[ -z "$TMUX" ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then
    echo "🔧 tmux-forceline development container ready!"
    echo "Run 'start_dev_env' to begin development"
fi
EOF

# Configure Git for development
RUN git config --global init.defaultBranch main \
    && git config --global pull.rebase false \
    && git config --global core.editor "code --wait"

# Set up workspace directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]