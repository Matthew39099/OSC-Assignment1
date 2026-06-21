#!/bin/bash
#
ps aux --sort=-%cpu | head -n 6
N=${1:-10}
#I have made 10% cpu usage the threshold for what is considered high cpu usage in the $2 > 10 block of code
output=$(ps -eo pid,%cpu,%mem,cmd --sort=-%cpu | head -n "$N" | \
awk -v n="$N" '$2 > 0 && count < n { 
	pid = $1; cpu = $2; mem = $3;
	$1 = ""; $2 = ""; $3 = "";
	cmd = $0;
	gsub(/^[ \t]+/, "", cmd);
	printf "PID: %s | CPU: %s%% | MEM: %s%% | CMD: %s\n", pid, cpu, mem, cmd
	total += cpu
	count++
}
END{
	if(count == 0){
		printf "No processes have been found"
	}
	else{
		printf "\nTotal CPU usage: %.1f%%\n", total
	}
}')

echo "$output"

# Pull just the PID values back out of the saved output
pids=$(echo "$output" | grep '^PID:' | awk '{print $2}')

# Nothing to kill if no processes matched the threshold
if [ -z "$pids" ]; then
        exit 0
fi

read -p "Terminate them all? (y/N): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for pid in $pids; do
                kill -9 "$pid"
        done
        echo "Processes terminated."
else
        echo "Exiting without terminating processes."
fi
#top 5 memory consuming processes
ps -eo pid,cmd,%mem --sort=-%mem | head -n "6"
# Check total system memory usage
mem_usage=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

if [ "$mem_usage" -gt 80 ]; then
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Memory usage at ${mem_usage}%" >> /var/log/ops_monitor.log
else
	echo "Memory usage is at ${mem_usage}%"
fi
while true; do
	read -p "Enter PID to act on or press enter to exit:" target_pid
	if [ -z "$target_pid" ]; then
		exit 0
	fi
	if ! [[ "$target_pid" =~ ^[0-9]+$ ]]; then
		echo "invalid PID: must be numeric."
		continue
	fi
	if ! kill -0 "$target_pid" 2>/dev/null; then
                echo "PID $target_pid is not running."
                continue
        fi
	read -p "Choose an action --[t] Terminate, [n]renice: " action
	case "$action" in
		t|T)
			kill -15 "$target_pid" && echo "sent SIGTERM to $target_pid. Waiting 3 seconds"
			sleep 3
			if kill -0 "$target_pid" 2>/dev/null; then
				kill -9 "$target_pid"
				echo "Process $target_pid did not stop -- sent SIGKILL."
			else
				echo "Process $target_pid stopped gracefully."
			fi
			;;
		n|N)
			read -p "Enter a new niceness value (0..19): " nice_val
			if ! [[ "$nice_val" =~ ^[0-9]+$ ]] || [ "$nice_val" -lt 0]|| [ "$nice_val" -gt 19 ]; then
				echo "Error: nice value must be in 0..19"
				continue
			fi
			renice -n  "$nice_val" -p "$target_pid" && echo "Process $target_pid reniced to $nice_val."
			;;
		*)
			echo "invalid action no changes made"
			;;
	esac
done
