[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [Int16]
    $Mode,
    [Parameter(Mandatory=$true)]
    [String]
    $Slots
)

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

$status = Convert-StatusModeEnumToString($Mode)
if($status -ne ""){
    foreach($slot in $Slots.Split(",")){
        $cmd = $status + " " + $slot

        #Send status command
        Send-Command -session $session -cmd $cmd
        #Sleep to give time for processing
        Start-Sleep -Seconds 1
    }
}else{
    #Break; invalid mode parameter passed by user
    Exit 87
}

#Dispose of used resources, disconnect from the instance
Disconnect-FoldingInstance($session)