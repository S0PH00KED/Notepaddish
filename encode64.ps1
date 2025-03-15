$scriptContent = Get-Content -Path "Notepaddish.ps1" -Raw
$encodedContent = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($scriptContent))
$encodedContent
