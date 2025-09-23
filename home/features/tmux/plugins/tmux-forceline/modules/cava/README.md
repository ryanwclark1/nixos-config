# tmux-forceline Static Cava Solutions

This directory contains multiple solutions for using cava audio visualization in tmux without streaming output.

## 🎯 Problem Solved

The original `cava.sh` creates a continuous stream that scrolls in tmux status bars. These solutions provide **static, non-streaming output** that updates in place.

## 📁 Available Solutions

### 1. **Simple Wrapper** (`cava_wrapper.sh`) - **RECOMMENDED**
The most straightforward solution that wraps the original cava.sh:

```bash
# Usage
./cava_wrapper.sh        # Cached output (1s cache)
./cava_wrapper.sh fresh  # Fresh output
./cava_wrapper.sh tmux   # tmux-safe output

# tmux integration
set -g status-right "#(~/.config/tmux/forceline/modules/cava/cava_wrapper.sh tmux) %H:%M"
```

**Features:**
- ✅ Directly wraps original cava.sh
- ✅ Simple 1-second caching
- ✅ Minimal dependencies
- ✅ Fallback patterns
- ✅ 20-character width limit

### 2. **One-Shot Capture** (`cava_oneshot.sh`)
Advanced solution with custom cava configuration:

```bash
# Usage
./cava_oneshot.sh        # Cached output
./cava_oneshot.sh fresh  # Force new capture
./cava_oneshot.sh test   # Comprehensive testing

# tmux integration
set -g status-right "#(~/.config/tmux/forceline/modules/cava/cava_oneshot.sh tmux) %H:%M"
```

**Features:**
- ✅ Custom cava configuration
- ✅ Timeout protection
- ✅ Performance optimized
- ✅ Configurable via environment variables
- ✅ Built-in monitoring mode

### 3. **Static v2** (`cava_static_v2.sh`) - **MOST ADVANCED**
Multiple capture methods with fallback:

```bash
# Usage
./cava_static_v2.sh      # Best available output
./cava_static_v2.sh test # Test all capture methods
./cava_static_v2.sh monitor # Live monitoring

# tmux integration
set -g status-right "#(~/.config/tmux/forceline/modules/cava/cava_static_v2.sh tmux) %H:%M"
```

**Features:**
- ✅ Multiple capture methods
- ✅ Best reliability
- ✅ Advanced testing
- ✅ Method comparison
- ✅ Optimal output selection

## 🚀 Quick Start

### Option 1: Use Simple Wrapper (Recommended)
```bash
# Test it works
./cava_wrapper.sh test

# Add to tmux.conf
echo 'set -g status-right "#(~/.config/tmux/forceline/modules/cava/cava_wrapper.sh tmux) %H:%M"' >> ~/.tmux.conf

# Reload tmux
tmux source-file ~/.tmux.conf
```

### Option 2: Use Integration Helper
```bash
# Automatic integration
./integrate_static_cava.sh install right

# Or test first
./integrate_static_cava.sh session
```

## ⚙️ Customization

### Environment Variables
```bash
# For simple wrapper
export CAVA_CACHE_SECONDS=2        # Cache for 2 seconds

# For one-shot capture
export FORCELINE_CAVA_TTL=1        # Cache TTL
export FORCELINE_CAVA_WIDTH=16     # Output width
export FORCELINE_CAVA_ICON=true    # Show music icon
export FORCELINE_CAVA_TIMEOUT=3    # Capture timeout

# For static v2
export FORCELINE_CAVA_BARS=12      # Number of bars
export FORCELINE_CAVA_FALLBACK="♪♫♪" # Custom fallback
```

### tmux Configuration Examples

**Basic Integration:**
```bash
set -g status-right "#(cava_wrapper.sh) %H:%M"
set -g status-interval 1
```

**With Icon:**
```bash
set -g status-right "🎵 #(cava_wrapper.sh) %H:%M"
```

**Performance Optimized:**
```bash
set -g status-right "#(cava_wrapper.sh tmux) %H:%M"
set -g status-interval 2
```

**Conditional Display:**
```bash
# Only show when cava is working
set -g status-right "#{?#{!=:#(cava_wrapper.sh),♪♫♪♫♪♫♪♫},#(cava_wrapper.sh) ,}%H:%M"
```

## 🧪 Testing & Debugging

### Test All Solutions
```bash
echo "Testing all solutions:"
echo "1. Simple: $(./cava_wrapper.sh)"
echo "2. One-shot: $(./cava_oneshot.sh)"  
echo "3. Static v2: $(./cava_static_v2.sh)"
```

### Monitor Live Output
```bash
# Simple wrapper
./cava_wrapper.sh monitor

# One-shot with advanced monitoring
./cava_oneshot.sh monitor

# Static v2 with method testing
./cava_static_v2.sh test
```

### Integration Testing
```bash
# Test tmux integration
./integrate_static_cava.sh session

# Test specific solution
./integrate_static_cava.sh test
```

## 🔧 Troubleshooting

### Cava Not Found
```bash
# Install cava
sudo apt-get install cava          # Ubuntu/Debian
brew install cava                  # macOS
sudo pacman -S cava               # Arch Linux
```

### No Audio Output
```bash
# Check audio system
pulseaudio --check -v
# or
pipewire --version

# Test cava directly
cava

# Check permissions
groups $USER | grep audio
```

### Fallback Patterns
All solutions provide fallback patterns when cava is unavailable:
- Simple wrapper: `♪♫♪♫♪♫♪♫`
- One-shot: `♪♫♪♫♪♫♪♫`  
- Static v2: `♪♫♪♫♪♫` or `▁▁▁▁▁▁▁▁▁▁▁▁`

### Performance Issues
```bash
# Increase cache duration
export CAVA_CACHE_SECONDS=3

# Use tmux-safe output
./cava_wrapper.sh tmux

# Reduce update frequency
set -g status-interval 2
```

## 📊 Comparison

| Feature | Simple Wrapper | One-Shot | Static v2 |
|---------|----------------|----------|-----------|
| Simplicity | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| Reliability | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Performance | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Features | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Dependencies | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |

## 💡 Recommendations

1. **Start with Simple Wrapper**: Easy to understand and implement
2. **Upgrade to Static v2**: If you need better reliability and features
3. **Use One-Shot**: If you want custom configuration and monitoring
4. **Integration Helper**: For automatic setup and testing

## 📝 Example tmux.conf

```bash
# tmux-forceline with static cava
set -g status-interval 1
set -g status-right-length 60

# Choose one:
set -g status-right "#(~/.config/tmux/forceline/modules/cava/cava_wrapper.sh tmux) | %H:%M %d-%b"
# set -g status-right "#(~/.config/tmux/forceline/modules/cava/cava_static_v2.sh tmux) | %H:%M %d-%b"  
# set -g status-right "#(~/.config/tmux/forceline/modules/cava/cava_oneshot.sh tmux) | %H:%M %d-%b"

# Optional: Add to left status too
# set -g status-left "#{session_name} | #(cava_wrapper.sh) "
```

---

All solutions provide **static, non-streaming cava output** perfect for tmux status bars! 🎵