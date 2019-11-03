[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [Int16]
    $Mode,
    [Parameter(Mandatory=$false)]
    [String]
    $SlotWhitelist
)

function Get-WhitelistedSlots(){
    $WhitelistedSlots = [System.Collections.ArrayList]::new()
    $_SlotWhitelist = $SlotWhitelist.Split(",")
    if($_SlotWhitelist){
        foreach ($slot in $SlotInfo){
            if($_SlotWhitelist | Where-Object {$_ -eq $slot.id.value.ToString()}){
                [Void]$WhitelistedSlots.Add($slot)
            }
        }    
    }else{
        $WhitelistedSlots = $SlotInfo
    }

    return ,($WhitelistedSlots)
}

#Define the Send-MailMessage variables to receive notifications
$SendFromEmail = "myemail@domain.com"
$SendFromEmailPassword = "mypassword"
$SendFromCredential = [PSCredential]::new($SendFromEmail, (ConvertTo-SecureString $SendFromEmailPassword -AsPlainText -Force))
$SendToEmail = "myemail@domain.com"
$SmtpServer = "mail.domain.com"
$SmtpPort = 587

#Ensure this module is installed
Import-Module newtonsoft.json
#Ensure this module is in the same directory
Import-Module ".\Folding@Home.psm1"

#Connect to local instance
$session = Connect-FoldingInstance -addr "127.0.0.1" -port 36330
if($session.Connected -eq $false){
    #Break; connection failed
    Exit 233
}
#Send slot-info command
Send-Command -session $session -cmd "slot-info"
#Sleep to give time for processing; only banner displayed otherwise
Start-Sleep -Seconds 1

#Receive slot-info command response
[String]$SlotInfoStr = Receive-Response($session)

#Convert slot-info response into object
$SlotInfo = Convert-ResponseToObject($SlotInfoStr)

#Include only the slots provided by the user; if no whitelist, use entire list
$WhitelistedSlots = Get-WhitelistedSlots

#Notify based on the mode user selected
if($Mode -eq 0){
    #If no running slots found, send notification
    $FilteredSlots = $WhitelistedSlots | Where-Object {$_.status.ToString().ToLower() -eq "running" -or $_.status.ToString().ToLower() -eq "download"}
    if($null -eq $FilteredSlots){
        $Subject = "No running slots found on " + [Environment]::MachineName
        Send-MailMessage -From $SendFromEmail -To $SendToEmail -Subject $Subject -Credential $SendFromCredential -UseSsl -SmtpServer $SmtpServer -Port $SmtpPort
    }
}elseif($Mode -eq 1){
    #If any idle slots found, send notification
    $FilteredSlots = $WhitelistedSlots | Where-Object {$_.status.ToString().ToLower() -eq "paused"}
    if($FilteredSlots){
        $Subject = "Idle slots detected on " + [Environment]::MachineName
        Send-MailMessage -From $SendFromEmail -To $SendToEmail -Subject $Subject -Credential $SendFromCredential -UseSsl -SmtpServer $SmtpServer -Port $SmtpPort
    }
}

#Dispose of used resources, disconnect from the instance
Disconnect-FoldingInstance($session)