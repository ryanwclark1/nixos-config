#!/usr/bin/env bash

pairedDevices() {
osascript << EOF
    use framework "IOBluetooth"
    use scripting additions
    set _results to {}

    repeat with device in (current application's IOBluetoothDevice's pairedDevices() as list)
        if device's isPaired()
            set _address to device's addressString as string
            set _name to device's nameOrAddress as string
            set _isConnected to device's isConnected as string
            if _isConnected = "1"
                set _isConnected to "✔"
            else
                set _isConnected to "✗"
            end if
            set end of _results to {_address, "\t", _name, "\t", _isConnected, "\n"}
        end if
    end repeat

    return _results as string
EOF
}

connect() {
local address=$1
osascript << EOF
    use framework "IOBluetooth"
    use scripting additions

    repeat with device in (current application's IOBluetoothDevice's pairedDevices() as list)
        set _address to device's addressString() as string
        if _address = "${address}"
            if device's isConnected()
                device's closeConnection()
            else
                device's openConnection()
            end if
        end if
    end repeat
EOF
}

main() {
    local selected=("$(pairedDevices \
        | sed '/^$/d' \
        | fzf \
            --delimiter $'\t' --with-nth 2,3 \
            --preview \
                'system_profiler SPBluetoothDataType -json 2>/dev/null \
                    | jq -r ".SPBluetoothDataType[].device_title[]["\"{2}\""]
                    | select(type != \"null\")"' \
    )")
    echo "${selected[@]}" | while read line; do
        local address name
        read address name <<< $(echo "$line" | cut -f1-)
        echo "${name}"
        connect ${address} >/dev/null
    done
}

main "$@"
