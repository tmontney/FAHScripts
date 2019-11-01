# FAHScripts
A collection of Folding@Home scripts.

## NotifySlotStatus.ps1
This script notifies you via email when slots aren't in running status.
### Parameters
Mode 0: If no slots are in running status, send notification

Mode 1: If any slots are paused status, send notification

SlotWhitelist: The slots you want to monitor. For instance, you don't use your CPU slot, so you'd include all slots but the CPU.
### Usage
```
NotifySlotStatus.ps1 -Mode 1 SlotWhitelist "01,02"
```
