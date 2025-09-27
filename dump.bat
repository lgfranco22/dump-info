@echo off

REM -- criar timestamp seguro para filename (robusto para Windows 7)
setlocal enabledelayedexpansion

REM ------------------------------
REM Coletor completo de informações do sistema (Windows)
REM Salva em INFO_<COMPUTERNAME>_<YYYYMMDD_HHMMSS>.txt
REM Execute como Administrador para melhor cobertura.
REM ------------------------------

REM Verifica se o script está sendo executado como administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Execute como administrador.
    ping -n 2 127.0.0.1 > nul
    exit /b
)

cls
echo.
echo Obtendo informacoes do sistema... Por favor aguarde.
echo.

REM tenta WMIC primeiro (formato: YYYYMMDDhhmmss...)
set "LDT="
for /f "tokens=2 delims==." %%I in ('wmic os get LocalDateTime /value 2^>nul ^| findstr /i LocalDateTime') do set "LDT=%%I"

if defined LDT (
    set "YYYY=!LDT:~0,4!"
    set "MM=!LDT:~4,2!"
    set "DD=!LDT:~6,2!"
    set "HH=!LDT:~8,2!"
    set "MN=!LDT:~10,2!"
    set "SS=!LDT:~12,2!"
    set "TS=!YYYY!!MM!!DD!_!HH!!MN!!SS!"
) else (
    REM fallback: normaliza %DATE% e %TIME% removendo caracteres inválidos
    set "d=%DATE%"
    set "t=%TIME%"
    set "d=!d:/=-!"
    set "d=!d:.=-!"
    set "d=!d: =!"
    set "t=!t::=-!"
    set "t=!t:.=-!"
    set "t=!t: =!"
    set "t=!t:,=!"
    set "TS=!d!_!t!"
)

REM preserva o valor fora do setlocal
endlocal & set "TIMESTAMP=%TS%"

set OUTFILE=INFO_%COMPUTERNAME%_%TIMESTAMP%.txt

echo Gerando arquivo: %OUTFILE%
echo.

REM -- cabeçalho
echo ================================================ > "%OUTFILE%"
echo Relatorio de Informacoes do Sistema - %COMPUTERNAME%  >> "%OUTFILE%"
echo Gerado em: %DATE% %TIME%  >> "%OUTFILE%"
echo ================================================ >> "%OUTFILE%"
echo. >> "%OUTFILE%"

REM ---------------- System basics ----------------
echo ----- Informacoes basicas do Sistema ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
systeminfo >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Environment ----------------
echo ----- Variaveis de Ambiente ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
set >> "%OUTFILE%"
echo. >> "%OUTFILE%"

REM ---------------- Hostname / Users ----------------
echo ----- Host / Usuarios / Grupos ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo Hostname: %COMPUTERNAME% >> "%OUTFILE%"
whoami /all >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
net user >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
net localgroup >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Hardware via WMIC ----------------
echo ----- Hardware (WMIC) ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo --- Computador --- >> "%OUTFILE%"
wmic computersystem get /format:list >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo --- CPU --- >> "%OUTFILE%"
wmic cpu get /format:list >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo --- BIOS --- >> "%OUTFILE%"
wmic bios get /format:list >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo --- Memoria (MemoryChip) --- >> "%OUTFILE%"
wmic memorychip get /format:list >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo --- Discos Fisicos --- >> "%OUTFILE%"
wmic diskdrive get Model,InterfaceType,Size,MediaType,SerialNumber /format:list >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo --- Particoes / Logical Disks --- >> "%OUTFILE%"
wmic partition get /format:list >> "%OUTFILE%" 2>&1
wmic logicaldisk get DeviceID,Size,FreeSpace,FileSystem,VolumeName /format:list >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo --- Controladoras e NICs --- >> "%OUTFILE%"
wmic nic get Name,MACAddress,Manufacturer,NetEnabled,AdapterType,Speed /format:list >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Drivers & Services ----------------
echo ----- Drivers e Servicos ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
driverquery /v /fo list >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
sc query state= all >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Processos e Tarefas ----------------
echo ----- Processos e Tarefas ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo Tasklist (com detalhes) --- >> "%OUTFILE%"
tasklist /v /fo list >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo --- Processos via WMIC --- >> "%OUTFILE%"
wmic process get ProcessId,Name,CommandLine,ExecutablePath,WorkingSetSize /format:list >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Rede ----------------
echo ----- Informacoes de Rede ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
ipconfig /all >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
route print >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
arp -a >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
netstat -ano >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
nslookup -type=any localhost >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Wireless (se aplicavel) ----------------
echo ----- Wireless Profiles e Interfaces (se houver) ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
netsh wlan show interfaces >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
netsh wlan show profiles >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Software instalado / Hotfixes ----------------
echo ----- Programas Instalados (Registro) ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
REM consulta o uninstall registry (32+64) - pode demorar
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo ----- Windows Hotfixes (Atualizacoes) ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
wmic qfe list full >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- PowerShell queries mais completos (se PowerShell disponivel) ----------------
echo ----- Consultas via PowerShell (Get-ComputerInfo, Win32_Share, Services, Drivers) ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
powershell -NoProfile -Command "Get-ComputerInfo | Out-String -Width 200" >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
powershell -NoProfile -Command "Get-HotFix | Format-List -Property *" >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
powershell -NoProfile -Command "Get-CimInstance -ClassName Win32_Product | Select-Object Name,Version,Vendor | Out-String -Width 200" >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Event logs (ultimos eventos) ----------------
echo ----- Event Logs (ultimos 50 eventos por canal) ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
echo --- System (ultimos 50) --- >> "%OUTFILE%"
wevtutil qe System /c:50 /f:text /rd:true >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
echo --- Application (ultimos 50) --- >> "%OUTFILE%"
wevtutil qe Application /c:50 /f:text /rd:true >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
echo --- Security (ultimos 50) --- >> "%OUTFILE%"
wevtutil qe Security /c:50 /f:text /rd:true >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Storage / Volumes ----------------
echo ----- Storage / Volumes / SMART (via wmic) ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
wmic logicaldisk get DeviceID,DriveType,ProviderName,FreeSpace,Size,FileSystem /format:list >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
wmic diskdrive get Model,SerialNumber,Status,MediaType >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Final checks / network shares ----------------
echo ----- Shares e Impressoras ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
net share >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"
wmic printer get Name,PortName,Default,Network >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Misc ----------------
echo ----- Rotas IPv6 ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
netsh interface ipv6 show route >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

echo ----- TLS / Cipher Suites (resumo) ----- >> "%OUTFILE%"
echo. >> "%OUTFILE%"
powershell -NoProfile -Command "Get-TlsCipherSuite | Out-String -Width 200" >> "%OUTFILE%" 2>&1
echo. >> "%OUTFILE%"

REM ---------------- Conclusao ----------------
echo.
echo Coleta concluida. Arquivo gerado: %OUTFILE%
echo.

REM opcional: abrir o arquivo no notepad
REM start notepad "%OUTFILE%"

exit /b 0
