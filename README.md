# FAHScripts
A collection of Folding@Home scripts.

## Configuration
Since these scripts will share many of the same functions, the ```Folding@Home``` module has been created. Ensure it's in the same directory as the other scripts.

## NotifySlotStatus.ps1
This script notifies you via email when slots aren't in running status.
### Parameters
* Mode 0: If no slots are in running status, send notification
* Mode 1: If any slots are paused status, send notification
* SlotWhitelist: The slots you want to monitor. To specify multiple slots, separate by comma. For instance, you don't use your CPU slot, so you'd include all slots but the CPU.
### Usage
```
NotifySlotStatus.ps1 -Mode 1 SlotWhitelist "01,02"
```
### Configuration
To setup email notifications, configure the block that starts with
```
#Define the Send-MailMessage variables to receive notifications
```

## ControlSlot.ps1
This script provides an easier interface to set slot(s) to pause, unpause, or finish.
### Parameters
* Mode: An integer that maps to a slot status string: 0 = pause, 1 = unpause, 2 = finish.
* Slots: The slots you want to control. To specify multiple slots, separate by comma.
### Usage
```
ControlSlot.ps1 -Mode 1 Slots "01,02"
```

## Automation
If you're on Windows, running this script should be no issue. If you're on Linux, you'll need to install Powershell first.
Ideally, this script should be used with Task Scheduler (Windows) or Crontab (Linux).
### Windows Task Scheduler
An example of how to configure an action in Task Scheduler, to run a Powershell script.

* Filename: powershell.exe
* Arguments: -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Scripts\ControlSlot.ps1" -Mode 1 -Slot "00,01"
* Start in: C:\Scripts

Be sure to adjust the "Start In" value to fit your environment. Specifying this value is important as Powershell will default to another directory (and will throw errors about not being able to find files).
