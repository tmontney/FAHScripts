function Send-Command([Net.Sockets.TcpClient]$session, [String]$cmd){
    [Byte[]]$b = [System.Text.ASCIIEncoding]::ASCII.GetBytes($cmd + ([char]10))
    [Net.Sockets.NetworkStream]$wr = $session.GetStream()
    $wr.Write($b, 0, $b.Length)
    $wr.Flush()
}

function Receive-Response([Net.Sockets.TcpClient]$session){
    $b_r = [Byte[]]::new(8192)
    [Net.Sockets.NetworkStream]$ns = $session.GetStream()
    $ns.ReadTimeout = 3000
    $ns.Read($b_r, 0, $b_r.Length)
    $ns.Flush()
    return [System.Text.ASCIIEncoding]::ASCII.GetString($b_r)
}

function Convert-ResponseToObject([String]$response){
    $StartOpenBracket = $SlotInfoStr.IndexOf("[", $SlotInfoStr.IndexOf("PyON"))
    $EndCloseBracket = $SlotInfoStr.LastIndexOf("]")
    $JsonStr = $SlotInfoStr.Substring($StartOpenBracket, ($EndCloseBracket - $StartOpenBracket) + 1).Replace("False", """False""").Replace("True", """True""")
    return ([Newtonsoft.Json.JsonConvert]::DeserializeObject($JsonStr))
}

function Connect-FoldingInstance([String]$addr, [Int32]$port){
    $session = [Net.Sockets.TcpClient]::new()

    $session.ReceiveTimeout = 5000
    $session.SendTimeout = 5000
    $session.Connect($addr, $port)

    return $session
}

function Disconnect-FoldingInstance([Net.Sockets.TcpClient]$session){
    if($session){
        $session.Close()
        $session.Dispose()
    }
}

function Convert-StatusModeEnumToString([Int16]$mode){
    if($mode -eq 0){
        return "pause"
    }elseif($mode -eq 1){
        return "unpause"
    }elseif($mode -eq 2){
        return "finish"
    }else{
        return ""
    }
}