# daemon-tracker
## Introduction
daemon-tracker is a tool used to track the status of processes. The processes may be tracked by launching them through daemon-tracker or attaching them to the daemon-tracker.

## Usage
* ```daemon-tracker ps```
  * List the currently tracked processes and their statuses.
* ```daemon-tracker [COMMAND]```
  * Launch [COMMAND] and attach the process launched by the [COMMAND] to the daemon-tracker.
* ```daemon-tracker -a [PID]```
  * Attach the process with PID [PID] to be tracked by the daemon-tracker.
