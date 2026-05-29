$link = "$env:USERPROFILE\.config\opencode\skills\apa-formatter-skill"
$target = (Get-Item .).FullName

if (Test-Path $link) {
    Write-Host "✓ El junction ya existe: $link → $target"
} else {
    New-Item -ItemType Junction -Path $link -Target $target -Force | Out-Null
    Write-Host "✓ Junction creado: $link → $target"
}
