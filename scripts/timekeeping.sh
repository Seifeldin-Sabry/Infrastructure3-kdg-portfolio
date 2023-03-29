#!/bin/bash
start=$(udate +"%s%N")

# Author: Seifeldin Sabry
# Function: track time spent on scripts
function error() {
  echo "Error: $1"
}

function checkDependencies() {
  local dependencies=("$@") # Store all arguments in an array
  local missing=() # Initialize an empty array to store missing dependencies

  for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then # Check if the dependency is installed
      missing+=("$dep") # Add to missing array if not installed
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then # Check if the missing array is not empty
    error "The following dependencies are missing: ${missing[*]}"
    exit 1
  fi
}

checkDependencies "dialog"
dialog --title "Hello" --msgbox "$(date)" 7 40

end=$(udate +"%s%N")

# Calculate the difference between the start and end times in nanoseconds
diff=$((end-start))
# Calculate the seconds
seconds=$((diff / 1000000000))

# Calculate the remaining milliseconds after subtracting the seconds
milliseconds=$((diff / 1000000 % 1000))

# Calculate the remaining nanoseconds after subtracting the milliseconds
remaining_nanoseconds=$((diff % 1000000))

# Print the output in the desired format using the calculated values
echo "The script took $seconds seconds, $milliseconds ms, $remaining_nanoseconds ns."




