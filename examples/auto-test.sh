#!/bin/bash

# Source the necessary paths
echo "Source paths.sh"
source ../tool/paths.sh

# ---> make libbpf
cd fw || { echo "Failed to enter directory: fw"; exit 1; }

# Run the make libbpf command
echo "Running make libbpf in fw"
make libbpf
if [ $? -ne 0 ]; then
  echo "Error occurred while running make libbpf. Exiting."
  exit 1
fi

cd - || { echo "Failed to return to the original directory"; exit 1; }
# <-----


# ---> run xdp-target on these programs
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
# <---- 

# ---> run xdp-target on dae
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
# <----


# ---> Falco
# List of BPF hooks used by Falco
attached_hooks=(
  "sys_enter"
  "sys_exit"
  "page_fault_kernel"
  "page_fault_user"
  "sched_process_fork"
  "sched_switch"
  "signal_deliver"
)

echo "++ Entering directory: Falco"
cd falco || { echo "Failed to enter directory: falco"; exit 1; }

echo " ---> Testing attached programs"
for hook in "${attached_hooks[@]}"; do
  echo "Testing ${hook}"
  make "${hook}_target"
  if [ $? -ne 0 ]; then
    echo "Error occurred while running make ${hook}_target. Exiting."
    exit 1
  fi
done


echo "++ Returning to the original directory"
cd - || { echo "Failed to return to the original directory"; exit 1; }
# <--- Leaving Falco

echo "All tasks completed successfully."