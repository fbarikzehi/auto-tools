#!/bin/bash

# --- COLORS FOR STYLISH UI ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS_FILE="$SCRIPT_DIR/ssh_hosts"

function check_install() {
  if ! command -v "$1" &> /dev/null; then
    echo -e "${YELLOW}$1 not found. Installing...${NC}"
    sudo apt update && sudo apt install -y "$1"
  else
    echo -e "${GREEN}$1 is already installed.${NC}"
  fi
}

# Check tilix and tmux
check_install tilix
check_install tmux

# Reminder about passwordless SSH
echo -e "${CYAN}For best experience, set up SSH keys for passwordless login:${NC}"
echo -e "  ${YELLOW}ssh-keygen -t ed25519${NC}"
echo -e "  ${YELLOW}ssh-copy-id user@host${NC}"
echo -e ""

# Load saved hosts if file exists
declare -a saved_hosts
declare -a saved_splits
if [[ -f "$HOSTS_FILE" ]]; then
  while IFS='|' read -r host split; do
    saved_hosts+=("$host")
    saved_splits+=("$split")
  done < "$HOSTS_FILE"
fi

declare -a servers
declare -a splits

function show_menu() {
  echo -e "${CYAN}Select an option:${NC}"
  echo "  1) Choose from saved hosts"
  echo "  2) Add new host"
  echo "  3) Exit"
}

function choose_saved_host() {
  if [ ${#saved_hosts[@]} -eq 0 ]; then
    echo -e "${YELLOW}No saved hosts found.${NC}"
    return 1
  fi

  echo -e "${CYAN}Saved hosts:${NC}"
  for i in "${!saved_hosts[@]}"; do
    echo "  $((i+1))) ${saved_hosts[$i]} (split: ${saved_splits[$i]})"
  done
  echo "  0) Back"

  while true; do
    read -rp "Enter number to add host or 0 to go back: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      if [ "$choice" -eq 0 ]; then
        return 1
      elif (( choice >= 1 && choice <= ${#saved_hosts[@]} )); then
        idx=$((choice-1))
        servers+=("${saved_hosts[$idx]}")
        splits+=("${saved_splits[$idx]}")
        return 0
      fi
    fi
    echo -e "${RED}Invalid choice.${NC}"
  done
}

function add_new_host() {
  while true; do
    read -rp $'\nEnter SSH connection (user@hostname or IP): ' ssh_conn
    if [[ ! "$ssh_conn" =~ .+@.+ ]]; then
      echo -e "${RED}Invalid format. Please enter user@host.${NC}"
      continue
    fi

    echo -e "Choose split type for this connection:"
    echo "  1) Horizontal Split"
    echo "  2) Vertical Split"
    echo "  3) New Tab"
    read -rp "Enter choice [1-3]: " split_choice

    case $split_choice in
      1) split_type="horizontal" ;;
      2) split_type="vertical" ;;
      3) split_type="tab" ;;
      *) echo -e "${RED}Invalid choice, defaulting to new tab.${NC}"; split_type="tab" ;;
    esac

    servers+=("$ssh_conn")
    splits+=("$split_type")

    # Save to hosts file if not duplicate
    if ! grep -qxF "$ssh_conn|$split_type" "$HOSTS_FILE" 2>/dev/null; then
      echo "$ssh_conn|$split_type" >> "$HOSTS_FILE"
      echo -e "${GREEN}Saved $ssh_conn with split $split_type.${NC}"
    fi

    read -rp "Add another new host? (y/n): " more
    [[ "$more" =~ ^[Nn]$ ]] && break
  done
}

# Main UI loop
while true; do
  show_menu
  read -rp "Choice: " opt
  case $opt in
    1) choose_saved_host ;;
    2) add_new_host ;;
    3) echo "Exiting."; exit 0 ;;
    *) echo -e "${RED}Invalid option.${NC}" ;;
  esac

  if [ ${#servers[@]} -gt 0 ]; then
    read -rp "Add/select more hosts? (y/n): " morehosts
    [[ "$morehosts" =~ ^[Nn]$ ]] && break
  fi
done

if [ ${#servers[@]} -eq 0 ]; then
  echo -e "${RED}No SSH hosts selected. Exiting.${NC}"
  exit 1
fi

tmux_script=$(mktemp)

cat > "$tmux_script" << EOF
#!/bin/bash
tmux set-option -g status-bg colour235
tmux set-option -g status-fg colour136
tmux set-option -g status-left "#[fg=green]Session: #S #[default]"
tmux set-option -g status-right "#[fg=yellow]%Y-%m-%d #[fg=green]%H:%M:%S"
EOF

echo "tmux new-session -d -s multi_ssh" >> "$tmux_script"

first=true
current_window=0

for i in "${!servers[@]}"; do
  conn=${servers[$i]}
  split=${splits[$i]}

  # Inline reconnect loop per pane
  reconnect_cmd="bash -c 'while true; do clear; echo \"Connecting to $conn. Press Ctrl+C to quit.\"; ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \"$conn\"; echo \"SSH to $conn disconnected. Reconnecting in 10 seconds...\"; sleep 10; done'"

  if $first; then
    echo "tmux send-keys -t multi_ssh \"$reconnect_cmd\" C-m" >> "$tmux_script"
    first=false
  else
    case $split in
      horizontal)
        echo "tmux split-window -h -t multi_ssh" >> "$tmux_script"
        echo "tmux send-keys -t multi_ssh \"$reconnect_cmd\" C-m" >> "$tmux_script"
        ;;
      vertical)
        echo "tmux split-window -v -t multi_ssh" >> "$tmux_script"
        echo "tmux send-keys -t multi_ssh \"$reconnect_cmd\" C-m" >> "$tmux_script"
        ;;
      tab)
        current_window=$((current_window+1))
        echo "tmux new-window -t multi_ssh:$current_window" >> "$tmux_script"
        echo "tmux send-keys -t multi_ssh:$current_window \"$reconnect_cmd\" C-m" >> "$tmux_script"
        ;;
    esac
  fi
done

echo "tmux attach -t multi_ssh" >> "$tmux_script"

chmod +x "$tmux_script"

echo -e "\n${CYAN}Launching Tilix with tmux session...${NC}"
tilix -e "$tmux_script"

rm "$tmux_script"
