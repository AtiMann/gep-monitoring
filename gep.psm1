# Beolvassuk a konfigurációt a gep.psd1 fájlból
$config = Import-PowerShellDataFile -Path .\gep.psd1

# Script szintű számláló inicializálása log-üzenetekhez
if (-not $script:LogID) { $script:LogID = 0 }

# ---------------------------------------
# LOGOLÓ FUNKCIÓ
# ---------------------------------------
function write-log {
    param (
        [string]$message,
        [ValidateSet("INFO","WARNING","ERROR")] [string]$warning = "INFO", # Log szint
        [switch]$notimestamp # Ha igaz, akkor nincs időbélyeg
    )

    # Egyedi log ID növelése
    $script:LogID++
    $id = $script:LogID

    # Konzol kimenet színezve
    switch ($warning) {
        "INFO"    { Write-Host "[$id] $message" -ForegroundColor White }
        "WARNING" { Write-Host "[$id] $message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "[$id] $message" -ForegroundColor Red }
    }

    # Időbélyeg előállítása (ha szükséges)
    if ($notimestamp) {
        $entry = "$message"
    } else {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $entry = "$timestamp -[$warning] -ID:$id $message"
    }

    # Log könyvtár és fájl létrehozása, ha nem léteznek
    if (-not (Test-Path $config.logdir)) { New-Item -ItemType Directory -Path $config.logdir | Out-Null }
    if (-not (Test-Path $config.logfile)) { New-Item -ItemType File -Path $config.logfile | Out-Null }

    # Log üzenet írása fájlba
    $entry | Out-File -FilePath $config.logfile -Append

    return $entry
}

# ---------------------------------------
# CPU HASZNÁLAT LEKÉRÉSE
# ---------------------------------------
function get-cpuusage {
    try {
        # Processzor terheltség lekérése CIM objektummal
        Get-CimInstance -ClassName Win32_Processor | Select-Object LoadPercentage
        $avgcpu = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        [pscustomobject]@{
            avgload = $avgcpu
        }
    } catch {
        write-log -message $_.Exception.Message -warning "ERROR"
    }
}

# ---------------------------------------
# MEMÓRIA HASZNÁLAT LEKÉRÉSE
# ---------------------------------------
function get-memory {
    try {
       $os = Get-CimInstance -ClassName Win32_OperatingSystem
       $total = [math]::round($os.TotalVisibleMemorySize / 1MB,2)         # Teljes memória GB-ban
       $usedGB = [math]::round($total - ($os.FreePhysicalMemory)/1MB,2)   # Használt memória GB-ban
       $free = [math]::round($os.FreePhysicalMemory / 1mb,2)              # Szabad memória GB-ban
       $memoryprecentage = [math]::round(($usedGB / $total) * 100,2)      # Használt memória %
       $unsedprecentage = [math]::round(($free / $total) * 100,2)         # Szabad memória %
       return [pscustomobject]@{
           TotalGB = $total
           UsedGB = $usedGB
           FreeGB = $free
           UsedPercent = $memoryprecentage
           FreePercent = $unsedprecentage
       }
    } catch {
        write-log -message $_.Exception.Message -warning "ERROR"
    }
}

# ---------------------------------------
# FOLYAMATOK VIZSGÁLATA
# ---------------------------------------
function check-process {
    param(
        [validateset("cpu","memory","name")][string]$sortby, # Rendezési szempont
        [int]$top = 5                                        # Top folyamat száma
    )   
    [validateset("Descending","Ascending")][string]$sort = "Descending"

    # Folyamatok lekérdezése és csoportosítása név alapján
    $processes = Get-Process | Group-Object -Property ProcessName | ForEach-Object {
        $proc = $_.name
        $mem  = [math]::round(($_.group | Measure-Object -Property WorkingSet -Sum).Sum /1MB,2)
        [pscustomobject]@{
            Name = $proc
            UsedMemoryMB = $mem
            UsedCPU = [math]::round(($_.group | Measure-Object -Property CPU -Sum).Sum,2)
        }
    }

    # Rendezés kiválasztott szempont szerint
    switch ($sortby){
        "cpu"    { $processes = $processes | Sort-Object -Property UsedCPU -Descending }
        "memory" { $processes = $processes | Sort-Object -Property UsedMemoryMB -Descending }
        "name"   { $processes = $processes | Sort-Object -Property Name -Ascending }
    }

    # Konfig frissítése és top X folyamat visszaadása
    $config.top = $top
    $config.sortby = $sortby
    if ($top -gt 0) {
        $processes = $processes | Select-Object -First $top
        return $processes
    }
}

# ---------------------------------------
# RENDSZER ELLENŐRZÉSE
# ---------------------------------------
function check-system {
    param([pscustomobject]$config)

    $mem = get-memory
    $cpu = get-cpuusage
    $today = Get-Date -Format "yyyy-MM-dd"

    # Napi log szeparátor
    if (Test-Path $config.logfile) {
        $last = (Get-Item -Path $config.logfile).LastWriteTime.ToString("yyyy-MM-dd")
    }
    if ($today -ne $last ) {
        write-log "---------------------------------$(get-date)-------------------------------------------------------" -notimestamp
    }

    # Ellenőrzés indul
    write-log -message "---------------------------------A rendszer ellenőrzése elindult.------------------------------------------" -warning "INFO" -notimestamp

    # CPU kiértékelés
    if ($cpu.avgload -lt $config.cputhresholdlow ){
        write-log -message "A CPU terheltsége alacsony: $($cpu.avgload)%" -warning "INFO"
    }
    elseif($cpu.avgload -lt $config.cputhresholdmid){
        write-log -message "A CPU terheltsége közepes: $($cpu.avgload)%" -warning "INFO"
    }
    elseif($cpu.avgload -gt $config.cputhresholdhigh){
        write-log -message "A CPU terheltsége magas: $($cpu.avgload)%" -warning "WARNING"
    }

    # Memória kiértékelés
    if ($mem.UsedPercent -lt $config.memthresholdlow){
        write-log -message "A memória terheltsége alacsony: $($mem.UsedPercent)%" -warning "INFO"
    }
    elseif($mem.UsedPercent -lt $config.memthreshold){
        write-log -message "A memória terheltsége közepes: $($mem.UsedPercent)%" -warning "INFO"
    }
    else {
        write-log -message "A memória terheltsége magas: $($mem.UsedPercent)%" -warning "WARNING"
        write-log -message "Az $($config.top) legmagasabb memória használatú folyamat:" -warning "INFO"

        # Top folyamatok kiírása
        check-process -sortby $config.sortby -top $config.top | ForEach-Object {
            write-log -message "Folyamat: $($_.Name) - Memória használat: $($_.UsedMemoryMB) MB - CPU használat: $($_.UsedCPU) sec" -warning "INFO"
        }
    }
}

# Exportált modul függvények
Export-ModuleMember -Function write-log, get-cpuusage, get-memory, check-process, check-system
