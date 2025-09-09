# Gép Monitoring (PowerShell)

Ez a PowerShell modul figyeli a rendszer CPU és memória terheltségét, naplózza a legfontosabb információkat, és listázza a legtöbb erőforrást használó folyamatokat.  
A script futtatható **egyszeri ellenőrzésként**, vagy **folyamatosan háttérben** (`-auto` kapcsolóval).

---

## Funkciók
- CPU és memória monitorozás
- Folyamatok listázása memória vagy CPU szerint
- Színes konzolos kiírás
- Logolás fájlba (`gep.log`)
- Egyszeri és automatikus (folyamatos) futás

---

## Fájlok
- `gep.psd1` – Konfigurációs fájl (küszöbértékek, log elérési út, top folyamatok száma stb.)
- `gep.psm1` – Modul, benne a függvények (`check-system`, `get-memory`, `get-cpuusage`, stb.)
- `start-gep.ps1` – Indító script (paraméterezhető `-auto` kapcsolóval)
- `README.md` – Dokumentáció
- `LICENSE` – Licenc

---

## Használat

### Egyszeri futtatás:
```powershell
.\start-gep.ps1
### Folyamatos futtatás: .\start-gep.ps1 -auto
