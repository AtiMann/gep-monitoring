param(
    [switch]$auto       # ha megadod, folyamatosan fut
)

$config = Import-PowerShellDataFile .\gep.psd1
Import-Module .\gep.psm1 -Force

# Indítási üzenet logolása és kiírása
if ($auto) {
    write-log -message "Automata mód: a monitorozás folyamatosan fut $interval másodpercenként." -warning "INFO"
    Write-Host ">>> Automata mód: a monitorozás folyamatosan fut $($config.interval) másodpercenként <<<" -ForegroundColor Cyan

    # Folyamatos futtatás végtelen ciklusban
    while ($true) {
        check-system -config $config
        Start-Sleep -Seconds $config.interval
    }
} else {
    write-log -message "Egyszeri futtatás: a monitorozás egyszer lefut." -warning "INFO"
    Write-Host ">>> Egyszeri futtatás: a monitorozás egyszer lefut <<<" -ForegroundColor Cyan

    # Egyszeri futtatás
    check-system -config $config
}
