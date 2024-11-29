# Author : Steve0ro
# Inspiration from heapbytes

PROMPT='
<-[%F{red}$USER%f%F{yellow}@%f%F{red}$HOST%f] [%F{green}👽 $(get_ip_address)%f]
-> '

RPROMPT='[%F{red}%?%f]'

get_ip_address() {
  device=$(nmcli device status | awk '$3 == "connected" || $3 == "UP" {print $1; exit}')
  tun0=$(nmcli device status | awk '$1 == "tun0" {print $1; exit}')
  output=""

  if [[ -n "$device" ]]; then
    ip_addr=$(ip -4 addr show dev "$device" | awk '/inet / {print $2}')
    if [[ -n "$ip_addr" ]]; then
      output="$ip_addr"
    fi
  fi

  if [[ -n "$tun0" ]]; then
    tun0_ip_addr=$(ip -4 addr show dev "$tun0" | awk '/inet / {print $2}')
    if [[ -n "$tun0_ip_addr" ]]; then
      if [[ -n "$output" ]]; then
        output="$output | "
      fi
      output="${output}VPN: $tun0_ip_addr"
    fi
  fi

  if [[ -z "$output" ]]; then
    output="No IP - ❌"
  fi

  echo "$output"
}