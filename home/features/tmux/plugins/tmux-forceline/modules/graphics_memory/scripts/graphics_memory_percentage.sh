#!/usr/bin/env bash
# Graphics memory percentage script for tmux-forceline v3.0
# Multi-vendor GPU VRAM usage monitoring with enhanced compatibility

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/graphics_memory/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=scripts/helpers.sh
    source "$CURRENT_DIR/helpers.sh"
fi

# NVIDIA GPU memory via nvidia-smi
nvidia_memory_percentage() {
  if ! command_exists "nvidia-smi"; then
    echo "N/A"
    return 1
  fi
  
  local memory_info
  memory_info=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null) || {
    echo "N/A"
    return 1
  }
  
  # Handle multiple GPUs by taking the first one
  memory_info=$(echo "$memory_info" | head -n1)
  
  local used total
  used=$(echo "$memory_info" | cut -d',' -f1 | tr -d ' ')
  total=$(echo "$memory_info" | cut -d',' -f2 | tr -d ' ')
  
  if [[ -n "$used" && -n "$total" && "$total" -gt 0 ]]; then
    echo "$((used * 100 / total))%"
  else
    echo "N/A"
  fi
}

# AMD GPU memory via rocm-smi (if available)
amd_memory_percentage() {
  if ! command_exists "rocm-smi"; then
    echo "N/A"
    return 1
  fi
  
  local memory_info
  memory_info=$(rocm-smi --showmeminfo vram --csv 2>/dev/null | tail -n +2) || {
    echo "N/A"
    return 1
  }
  
  # Parse CSV output: device,vram_total,vram_used
  local total used
  total=$(echo "$memory_info" | head -n1 | cut -d',' -f2 | tr -d ' ')
  used=$(echo "$memory_info" | head -n1 | cut -d',' -f3 | tr -d ' ')
  
  if [[ -n "$used" && -n "$total" && "$total" -gt 0 ]]; then
    # Convert bytes to MB to prevent integer overflow
    local used_mb=$((used / 1048576))
    local total_mb=$((total / 1048576))
    if [[ "$total_mb" -gt 0 ]]; then
      echo "$((used_mb * 100 / total_mb))%"
    else
      echo "N/A"
    fi
  else
    echo "N/A"
  fi
}

# Intel GPU memory (integrated graphics) - fallback estimation
intel_memory_percentage() {
  # Intel integrated graphics share system memory
  # For systems without dedicated GPU monitoring, provide a conservative estimate
  if is_linux && [ -f /proc/meminfo ]; then
    local available_kb total_kb
    available_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null)
    total_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)
    
    if [[ -n "$available_kb" && -n "$total_kb" && "$total_kb" -gt 0 ]]; then
      local used_kb=$((total_kb - available_kb))
      local memory_usage_pct=$((used_kb * 100 / total_kb))
      
      # Very conservative estimate: Intel iGPU typically uses 5-15% when active
      # Scale based on memory pressure but cap at reasonable levels
      local graphics_estimate
      if [[ "$memory_usage_pct" -lt 30 ]]; then
        graphics_estimate=5  # Low usage
      elif [[ "$memory_usage_pct" -lt 60 ]]; then
        graphics_estimate=10 # Medium usage
      else
        graphics_estimate=15 # High usage
      fi
      
      echo "${graphics_estimate}%"
    else
      echo "N/A"
    fi
  else
    echo "N/A"
  fi
}

# macOS Metal GPU memory estimation
macos_metal_memory_percentage() {
  if ! is_osx; then
    echo "N/A"
    return 1
  fi
  
  # Use vm_stat for rough estimation of graphics memory pressure
  local vm_stats
  vm_stats=$(vm_stat 2>/dev/null) || {
    echo "N/A"
    return 1
  }
  
  # Extract relevant metrics for graphics memory estimation
  local pages_free pages_active pages_wired
  pages_free=$(echo "$vm_stats" | awk '/Pages free:/ {print $3}' | tr -d '.')
  pages_active=$(echo "$vm_stats" | awk '/Pages active:/ {print $3}' | tr -d '.')
  pages_wired=$(echo "$vm_stats" | awk '/Pages wired down:/ {print $4}' | tr -d '.')
  
  if [[ -n "$pages_free" && -n "$pages_active" && -n "$pages_wired" ]]; then
    # Rough estimation: graphics memory is proportional to wired memory
    local total_pages=$((pages_free + pages_active + pages_wired))
    local graphics_pressure=$((pages_wired * 100 / total_pages))
    
    # Scale down as this is just an estimation
    graphics_pressure=$((graphics_pressure / 2))
    [[ "$graphics_pressure" -gt 100 ]] && graphics_pressure=100
    
    echo "${graphics_pressure}%"
  else
    echo "N/A"
  fi
}

# Get graphics memory percentage
print_graphics_memory_percentage() {
  local percentage="N/A"
  
  # Try NVIDIA first (most specific)
  if is_nvidia_gpu; then
    percentage=$(nvidia_memory_percentage)
  fi
  
  # Try AMD if NVIDIA failed
  if [[ "$percentage" == "N/A" ]] && is_amd_gpu; then
    percentage=$(amd_memory_percentage)
  fi
  
  # Try macOS Metal estimation
  if [[ "$percentage" == "N/A" ]] && is_osx; then
    percentage=$(macos_metal_memory_percentage)
  fi
  
  # Fall back to Intel/integrated estimation
  if [[ "$percentage" == "N/A" ]] && is_intel_gpu; then
    percentage=$(intel_memory_percentage)
  fi
  
  echo "$percentage"
}

# Main function
main() {
  cached_eval print_graphics_memory_percentage
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi