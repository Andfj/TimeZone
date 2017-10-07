$ErrorActionPreference = "SilentlyContinue"
$tcpTimeout = 1000
$port = 5985

$allServers = Get-ADComputer -Filter { (Enabled -eq $true) -and  (operatingSystem -like "Windows*" )  } -SearchBase "OU=Servers,DC=domain,DC=local" -SearchScope Subtree


"name;timezone" | Out-File -FilePath "NonStandardTimeZone.txt"

$report= @"
<html>
<link href='tablesort.css' rel='stylesheet'>
<script src='tablesort.js'></script>
<body>
<h3>Time Zone Report</h3>
<br><br>
<table border=1 id='sort'>
<tr>
<th><b>Computer Name</b></th><th><b>Timezone or Status</b></th>
<tbody>
"@

foreach($server in $allServers)
{

    $tcpobject = New-Object system.Net.Sockets.TcpClient 
    $connect = $tcpobject.BeginConnect($server.Name,$port,$null,$null) 
    $wait = $connect.AsyncWaitHandle.WaitOne($tcpTimeout,$false) 

    if (!$wait) 
    {
        $report += "<tr bgcolor='#f9c0c0'><td>$($server.Name)</td><td>WinRM port not open</td>"
        $tcpobject.Close()
    } 
    else 
    {
        $error.clear()
        $tcpobject.EndConnect($connect) | Out-Null 
        if ($error[0])
        {
            $report += "<tr bgcolor='#fca1a1'><td>$($server.Name)</td><td>connecting to host failed</td>"
        } 
        else
        {
            #Port open
            $timezone = Invoke-Command -ComputerName $server.Name -ScriptBlock { ([System.TimeZone]::CurrentTimeZone).StandardName }
            if (!$timezone)
            {
                $report += "<tr bgcolor='#fcf8ab'><td>$($server.Name) </td><td>Probably computer was removed</td>"
            }
            else
            {
                $report += "<tr><td>$($server.Name) </td><td>$timezone</td>"
                if ($timezone -ne 'Coordinated Universal Time') { "$($server.Name);$timezone" | Out-File -FilePath "NonStandardTimeZone.txt" -Append } 
            }
        }
        $tcpobject.Close()
    }


}


$report+="</tbody></table></body>
<script>
table = document.getElementById('sort');
new Tablesort(table);
</script>
</html>"

$report | Out-File -FilePath 'ReportTimeZone.htm' -Encoding ascii

Write-Output "Script ends at $(Get-Date)" 