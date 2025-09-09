@{
    # Általános beállítások
    interval = 1
    logdir = ".\"                     # Log könyvtár
    logfile = ".\gep.log"             # Log fájl

    # CPU és memória küszöbértékek
    cputhresholdlow = 50              # CPU alacsony terheltség %
    cputhresholdmid = 75              # CPU közepes terheltség %
    cputhresholdhigh = 90             # CPU magas terheltség %
    memthresholdlow = 40              # Memória alacsony terheltség %
    memthreshold = 50                 # Memória közepes terheltség % |< magas

    # Folyamatok vizsgálata
    top = 5                           # Legnagyobb erőforrás-fogyasztók száma
    sortby = "memory"                 # Rendezési alap: memory | cpu | name
}
