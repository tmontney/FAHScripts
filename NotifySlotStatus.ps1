[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [Int16]
    $Mode,
    [Parameter(Mandatory=$false)]
    [String]
    $SlotWhitelist
)

function Send-Command($cmd){
    [Byte[]]$b = [System.Text.ASCIIEncoding]::ASCII.GetBytes($cmd + ([char]10))
    [Net.Sockets.NetworkStream]$wr = $tClient.GetStream()
    $wr.Write($b, 0, $b.Length)
    $wr.Flush()
}

function Receive-Response(){
    $b_r = [Byte[]]::new(8192)
    [Net.Sockets.NetworkStream]$ns = $tClient.GetStream()
    $ns.ReadTimeout = 3000
    $ns.Read($b_r, 0, $b_r.Length)
    $ns.Flush()
    return [System.Text.ASCIIEncoding]::ASCII.GetString($b_r)
}

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

#Ensure this package is installed
Import-Module newtonsoft.json

#Connect to local instance
$tClient = [Net.Sockets.TcpClient]::new("127.0.0.1", 36330)

#Send slot-info command
Send-Command("slot-info")
#Sleep to give time for processing; only banner displayed otherwise
Start-Sleep -Seconds 1

#Receive slot-info command response
[String]$SlotInfoStr = Receive-Response

#Convert slot-info response into object
$StartOpenBracket = $SlotInfoStr.IndexOf("[", $SlotInfoStr.IndexOf("PyON"))
$EndCloseBracket = $SlotInfoStr.LastIndexOf("]")
$JsonStr = $SlotInfoStr.Substring($StartOpenBracket, ($EndCloseBracket - $StartOpenBracket) + 1).Replace("False", """False""").Replace("True", """True""")
$SlotInfo = [Newtonsoft.Json.JsonConvert]::DeserializeObject($JsonStr)

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

if($tClient){
    $tClient.Close()
    $tClient.Dispose()
}