  set_display_padding() {
    display="$1"
    metadata="$(yabai -m query --windows --display "$display" \
      | jq '[.[] | select(."is-visible" == true and ."is-floating" == false)]')"

    visible="$(echo "$metadata" | jq 'length')"

    if [ "$visible" -le 1 ]; then
      space="$(echo "$metadata" | jq '.[] | .space')"
      yabai -m space $space --padding abs:0:0:0:0
    else
      yabai -m config  \
        top_padding                  8             \
        bottom_padding               8             \
        left_padding                 8             \
        right_padding                8
    fi
  }

  refresh_padding() {
    yabai -m query --displays | jq '.[].index' | while read -r display; do
      set_display_padding "$display"
    done
  }

refresh_padding
