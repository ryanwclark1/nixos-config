# apps.sh - List installed applications from .desktop files.
# Keep icon identifiers raw so QML can resolve them lazily at render time.

dirs=(
  "/usr/share/applications"
  "/usr/local/share/applications"
  "$HOME/.local/share/applications"
  "$HOME/.nix-profile/share/applications"
  "/run/current-system/sw/share/applications"
)

output=$(for dir in "${dirs[@]}"; do
  if [ -d "$dir" ]; then
    find "$dir" -maxdepth 1 -name "*.desktop" -print0
  fi
done | xargs -0 awk '
function json_escape(value,    out) {
  out = value
  gsub(/\\/, "\\\\", out)
  gsub(/"/, "\\\"", out)
  gsub(/\t/, "\\t", out)
  return out
}

function bool_string(value) {
  return tolower(value) == "true" ? "true" : "false"
}

function flush_entry(    cleaned_exec, cleaned_categories, cleaned_keywords) {
  if (!in_desktop_entry)
    return
  if (name == "" || exec == "" || tolower(no_display) == "true" || tolower(hidden) == "true")
    return

  cleaned_exec = exec
  gsub(/ %[fFuUdDnNickvm]/, "", cleaned_exec)
  gsub(/"/, "", cleaned_exec)

  cleaned_categories = categories
  gsub(/;/, " ", cleaned_categories)

  cleaned_keywords = keywords
  gsub(/;/, " ", cleaned_keywords)

  if (count > 0)
    printf(",\n")
  printf("{\"name\":\"%s\",\"exec\":\"%s\",\"icon\":\"%s\",\"desktopId\":\"%s\",\"category\":\"%s\",\"keywords\":\"%s\",\"terminal\":%s}",
         json_escape(name),
         json_escape(cleaned_exec),
         json_escape(icon_name),
         json_escape(desktop_id),
         json_escape(cleaned_categories),
         json_escape(cleaned_keywords),
         bool_string(terminal))
  count += 1
}

function reset_entry() {
  in_desktop_entry = 0
  in_other_group = 0
  name = ""
  exec = ""
  icon_name = ""
  desktop_id = ""
  categories = ""
  keywords = ""
  no_display = ""
  hidden = ""
  terminal = ""
}

BEGIN {
  printf("[")
  count = 0
  reset_entry()
}

FNR == 1 {
  if (NR > 1)
    flush_entry()
  reset_entry()
  desktop_id = FILENAME
  sub(/^.*\//, "", desktop_id)
  sub(/\.desktop$/, "", desktop_id)
}

/^\[Desktop Entry\]$/ {
  in_desktop_entry = 1
  in_other_group = 0
  next
}

/^\[/ {
  if (in_desktop_entry)
    in_other_group = 1
  next
}

!in_desktop_entry || in_other_group {
  next
}

/^Name=/ && name == "" {
  name = substr($0, 6)
  next
}

/^Exec=/ && exec == "" {
  exec = substr($0, 6)
  next
}

/^Icon=/ && icon_name == "" {
  icon_name = substr($0, 6)
  next
}

/^Categories=/ && categories == "" {
  categories = substr($0, 12)
  next
}

/^Keywords=/ && keywords == "" {
  keywords = substr($0, 10)
  next
}

/^NoDisplay=/ && no_display == "" {
  no_display = substr($0, 11)
  next
}

/^Hidden=/ && hidden == "" {
  hidden = substr($0, 8)
  next
}

/^Terminal=/ && terminal == "" {
  terminal = substr($0, 10)
  next
}

END {
  flush_entry()
  print "]"
}
' | jq 'unique_by(.exec)')

echo "$output"
