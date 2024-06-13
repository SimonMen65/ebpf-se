#!/bin/bash

# Source the necessary paths
echo "Source paths.sh"
source ../tool/paths.sh

# Change to the fw directory
cd fw || { echo "Failed to enter directory: fw"; exit 1; }

# Run the make libbpf command
echo "Running make libbpf in fw"
make libbpf
if [ $? -ne 0 ]; then
  echo "Error occurred while running make libbpf. Exiting."
  exit 1
fi

# Return to the original directory
cd - || { echo "Failed to return to the original directory"; exit 1; }


# List of directories containing the test programs
directories=("fw" "crab" "katran" "hercules" "fluvia")

for dir in "${directories[@]}"; do
  echo "++ Entering directory: $dir"
  cd "$dir" || { echo "Failed to enter directory: $dir"; exit 1; }
  
  echo "Running make xdp-target in $dir"
  make xdp-target
  if [ $? -ne 0 ]; then
    echo "Error occurred in $dir. Exiting."
    exit 1
  fi
  
  echo "++ Returning to the original directory"
  cd - || { echo "Failed to return to the original directory"; exit 1; }
done

echo "++ Entering directory: dae"
cd dae || { echo "Failed to enter directory: dae"; exit 1; }

echo "Running make target CGROUP in dae"
make target PROG=CGROUP
if [ $? -ne 0 ]; then
  echo "Error occurred in dae. Exiting."
  exit 1
fi

echo "Running make target RELEASE in dae"
make target PROG=RELEASE
if [ $? -ne 0 ]; then
  echo "Error occurred in dae. Exiting."
  exit 1
fi

echo "++ Returning to the original directory"
cd - || { echo "Failed to return to the original directory"; exit 1; }

# ---> Falco
echo "++ Entering directory: Falco"
cd falco || { echo "Failed to enter directory: falco"; exit 1; }

make sched_switch_target
if [ $? -ne 0 ]; then
  echo "Error occurred in falco. Exiting."
  exit 1
fi

echo "++ Returning to the original directory"
cd - || { echo "Failed to return to the original directory"; exit 1; }
# <--- Leaving Falco

echo "All tasks completed successfully."