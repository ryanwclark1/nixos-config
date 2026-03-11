# bookmarks.sh - Extract Firefox bookmarks for the launcher

# Find the places.sqlite file (use the first one found)
PLACES_DB=$(find ~/.mozilla/firefox -name "places.sqlite" 2>/dev/null | head -n 1)

if [[ -z "$PLACES_DB" ]]; then
    echo "[]"
    exit 0
fi

# Copy DB to a temp file to avoid lock issues
TEMP_DB=$(mktemp --suffix=.sqlite)
trap 'rm -f "$TEMP_DB"' EXIT
if ! cp "$PLACES_DB" "$TEMP_DB"; then
    echo "[]"
    exit 0
fi

# Query the database
# moz_bookmarks table contains the bookmarks, moz_places contains the URLs
output=$(sqlite3 -separator $'\t' "$TEMP_DB" "
SELECT b.title, p.url
FROM moz_bookmarks b
JOIN moz_places p ON b.fk = p.id
WHERE b.title IS NOT NULL AND p.url NOT LIKE 'place:%'
LIMIT 500;
" | while IFS=$'\t' read -r title url; do
    
    if [[ -n "$title" && -n "$url" ]]; then
        title_esc=$(echo "$title" | jq -R .)
        url_esc=$(echo "$url" | jq -R .)
        echo "{\"name\":$title_esc,\"exec\":$url_esc,\"icon\":\"󰖟\"}"
    fi
done | jq -s '.')

echo "$output"
