#tzutil.exe /L list all timezones

if (Test-Path -Path '.\NonStandardTimeZone.txt')
{
    $servers = Import-Csv -Path '.\NonStandardTimeZone.txt' -Delimiter ";"
    Invoke-Command -ComputerName $servers.name -ScriptBlock {  tzutil.exe /s "UTC" } 
}
else 
{
    Write-Warning 'Please run TimezoneReport.ps1 to create NonStandardTimeZone.txt file'
}