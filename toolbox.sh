#!/bin/bash
# ═══════════════════════════════════════════════════════════
# toolbox-fixes.sh — Patches failed downloads from toolbox.sh
# Run AFTER toolbox.sh to grab what it missed
# Usage: ./toolbox-fixes.sh [/tools/path]
# ═══════════════════════════════════════════════════════════

TOOLS_DIR="${1:-$HOME/pentest-tools}"
DOWNLOADED=0; FAILED=0

RED='\033[91m' GRN='\033[92m' YEL='\033[93m'
CYN='\033[96m' BLD='\033[1m'  DIM='\033[2m' RST='\033[0m'

echo -e "${CYN}${BLD}[*] toolbox-fixes.sh — patching failed downloads${RST}"
echo -e "    Tools dir: $TOOLS_DIR\n"

grab() {
    local url="$1" dest="$2" desc="$3"
    echo -ne "  ${DIM}[*]${RST} ${desc}..."
    if curl -sL --fail --connect-timeout 10 --max-time 120 -o "$dest" "$url" 2>/dev/null; then
        local size; size=$(stat -c%s "$dest" 2>/dev/null || echo 0)
        if [[ "${size:-0}" -gt 100 ]]; then
            local human; [[ $size -gt 1048576 ]] && human="$(( size/1048576 ))MB" || human="$(( size/1024 ))KB"
            echo -e " ${GRN}OK${RST} (${human})"; ((DOWNLOADED++))
        else
            echo -e " ${RED}EMPTY${RST}"; rm -f "$dest"; ((FAILED++))
        fi
    else
        echo -e " ${RED}FAIL${RST}"; rm -f "$dest"; ((FAILED++))
    fi
}

# ─────────────────────────────────────────────────────────
# PATTERN 1: Ghostpack compiled binaries repo has stale paths
# New source: GhostPack/Ghostpack-CompiledBinaries (capital G)
# ─────────────────────────────────────────────────────────
echo -e "\n  ${BLD}${CYN}── Ghostpack compiled binaries (correct source) ──${RST}"

grab "https://github.com/GhostPack/Ghostpack-CompiledBinaries/raw/master/SharpView.exe" \
    "$TOOLS_DIR/ad/SharpView.exe" "SharpView"

grab "https://github.com/GhostPack/Ghostpack-CompiledBinaries/raw/master/SharpRDP.exe" \
    "$TOOLS_DIR/ad/lateral/SharpRDP.exe" "SharpRDP"

grab "https://github.com/GhostPack/Ghostpack-CompiledBinaries/raw/master/Whisker.exe" \
    "$TOOLS_DIR/ad/adcs/Whisker.exe" "Whisker (Shadow Credentials)"

# ─────────────────────────────────────────────────────────
# PATTERN 2: Tools that moved repos or changed release names
# ─────────────────────────────────────────────────────────
echo -e "\n  ${BLD}${CYN}── Moved / renamed releases ──${RST}"

# PrivescCheck — releases page now has it directly
grab "https://github.com/itm4n/PrivescCheck/releases/latest/download/PrivescCheck.ps1" \
    "$TOOLS_DIR/windows/privesc/PrivescCheck.ps1" "PrivescCheck.ps1"

# Inveigh — no .exe releases, use the PowerShell version
grab "https://raw.githubusercontent.com/Kevin-Robertson/Inveigh/master/Inveigh.ps1" \
    "$TOOLS_DIR/ad/Inveigh.ps1" "Inveigh.ps1 (PowerShell — no .exe release)"

# SharpHound — BloodHound CE moved, grab the zip and extract
grab "https://github.com/BloodHoundAD/SharpHound/releases/latest/download/SharpHound.zip" \
    "$TOOLS_DIR/ad/SharpHound.zip" "SharpHound (zip)"
if [[ -f "$TOOLS_DIR/ad/SharpHound.zip" ]]; then
    unzip -q -o "$TOOLS_DIR/ad/SharpHound.zip" -d "$TOOLS_DIR/ad/" 2>/dev/null && \
        echo -e "  ${DIM}[>] SharpHound.zip extracted${RST}"
fi

# SharpHound.ps1 — also grab the PS1 collector
grab "https://raw.githubusercontent.com/puckiestyle/powershell/master/SharpHound.ps1" \
    "$TOOLS_DIR/ad/SharpHound.ps1" "SharpHound.ps1 (alternate source)"

# RustHound-CE (maintained fork)
echo -ne "  ${DIM}[*]${RST} Detecting RustHound-CE latest..."
RUSTHOUND_VER=$(curl -sI https://github.com/g0h4n/RustHound-CE/releases/latest 2>/dev/null \
    | grep -i 'location:' | grep -oP 'v[\d.]+' | head -1)
RUSTHOUND_VER="${RUSTHOUND_VER:-v2.0.0}"
echo -e " ${RUSTHOUND_VER}"

grab "https://github.com/g0h4n/RustHound-CE/releases/download/${RUSTHOUND_VER}/rusthound-ce-x86_64-unknown-linux-musl" \
    "$TOOLS_DIR/ad/rusthound" "RustHound-CE (Linux)"
grab "https://github.com/g0h4n/RustHound-CE/releases/download/${RUSTHOUND_VER}/rusthound-ce-x86_64-pc-windows-gnu.exe" \
    "$TOOLS_DIR/ad/rusthound.exe" "RustHound-CE (Windows)"
chmod +x "$TOOLS_DIR/ad/rusthound" 2>/dev/null

# SweetPotato — CCob has no releases, use uknowsec fork
grab "https://github.com/uknowsec/SweetPotato/releases/latest/download/SweetPotato.exe" \
    "$TOOLS_DIR/windows/potatoes/SweetPotato.exe" "SweetPotato (uknowsec fork)"

# GMSAPasswordReader — grab from a known compiled source
grab "https://github.com/expl0itabl3/Toolies/raw/master/GMSAPasswordReader.exe" \
    "$TOOLS_DIR/ad/GMSAPasswordReader.exe" "GMSAPasswordReader (compiled)"

# PassTheCert — check release naming
grab "https://github.com/AlmondOffSec/PassTheCert/releases/latest/download/passthecert.exe" \
    "$TOOLS_DIR/ad/adcs/PassTheCert.exe" "PassTheCert"

# LAPSToolkit (replaces failed Invoke-LAPSDumper)
grab "https://raw.githubusercontent.com/leoloobeek/LAPSToolkit/master/LAPSToolkit.ps1" \
    "$TOOLS_DIR/ad/LAPSToolkit.ps1" "LAPSToolkit.ps1 (replaces LAPSDumper)"

# pyGPOAbuse — the script is in the package directory
grab "https://raw.githubusercontent.com/Hackndo/pyGPOAbuse/main/pygpoabuse/gpoabuse.py" \
    "$TOOLS_DIR/ad/pyGPOAbuse.py" "pyGPOAbuse.py"

# unix-privesc-check — correct branch
grab "https://raw.githubusercontent.com/pentestmonkey/unix-privesc-check/1_x/unix-privesc-check" \
    "$TOOLS_DIR/linux/unix-privesc-check.sh" "unix-privesc-check (1_x branch)"
chmod +x "$TOOLS_DIR/linux/unix-privesc-check.sh" 2>/dev/null

# ─────────────────────────────────────────────────────────
# PATTERN 3: nanodump — release asset names changed
# ─────────────────────────────────────────────────────────
echo -e "\n  ${BLD}${CYN}── nanodump (stealthy LSASS dumper) ──${RST}"
echo -ne "  ${DIM}[*]${RST} Detecting nanodump latest..."
NANO_VER=$(curl -sI https://github.com/fortra/nanodump/releases/latest 2>/dev/null \
    | grep -i 'location:' | grep -oP 'v[\d.]+' | head -1)
NANO_VER="${NANO_VER:-v1.3}"
echo -e " ${NANO_VER}"

grab "https://github.com/fortra/nanodump/releases/download/${NANO_VER}/nanodump.x64.exe" \
    "$TOOLS_DIR/post-exploit/nanodump.exe" "nanodump x64 (.exe)"
grab "https://github.com/fortra/nanodump/releases/download/${NANO_VER}/nanodump.x64.dll" \
    "$TOOLS_DIR/post-exploit/nanodump.dll" "nanodump x64 (.dll — for reflective injection)"

# ─────────────────────────────────────────────────────────
# PATTERN 4: Chisel Windows — try zip format fallback
# ─────────────────────────────────────────────────────────
echo -e "\n  ${BLD}${CYN}── Chisel Windows (zip fallback) ──${RST}"
echo -ne "  ${DIM}[*]${RST} Detecting chisel latest..."
CHISEL_VER=$(curl -sI https://github.com/jpillora/chisel/releases/latest 2>/dev/null \
    | grep -i 'location:' | grep -oP 'v[\d.]+' | head -1)
CHISEL_VER="${CHISEL_VER:-v1.10.1}"
echo -e " ${CHISEL_VER}"

# Try .zip first (some chisel versions release Windows as zip)
if ! [[ -f "$TOOLS_DIR/pivoting/chisel.exe" ]]; then
    grab "https://github.com/jpillora/chisel/releases/download/${CHISEL_VER}/chisel_${CHISEL_VER#v}_windows_amd64.gz" \
        "$TOOLS_DIR/pivoting/chisel_windows.gz" "Chisel Windows (.gz)"
    if [[ -f "$TOOLS_DIR/pivoting/chisel_windows.gz" ]]; then
        gunzip -f "$TOOLS_DIR/pivoting/chisel_windows.gz" 2>/dev/null
        mv "$TOOLS_DIR/pivoting/chisel_windows" "$TOOLS_DIR/pivoting/chisel.exe" 2>/dev/null && \
            echo -e "  ${DIM}[>] chisel.exe extracted${RST}"
    fi
fi

# ─────────────────────────────────────────────────────────
# THINGS REMOVED (no working source / use pip instead)
# ─────────────────────────────────────────────────────────
echo -e "\n  ${BLD}${CYN}── Items skipped (use pip/other install) ──${RST}"
echo -e "  ${DIM}pypykatz binary      → pip install pypykatz --break-system-packages${RST}"
echo -e "  ${DIM}PwnKit Go PoC        → use linpeas + CVE-2021-4034.py already grabbed${RST}"
echo -e "  ${DIM}Nishang one-liner    → included in Invoke-PowerShellTcp.ps1 as a comment${RST}"
echo -e "  ${DIM}PS shellcode exec    → use msfvenom for payload generation${RST}"

# ─────────────────────────────────────────────────────────
# EXTRAS — tools not in the original script worth having
# ─────────────────────────────────────────────────────────
echo -e "\n  ${BLD}${CYN}── Extras not in original script ──${RST}"

# SharpEfsPotato — newer potato that bypasses some AV
grab "https://github.com/bugch3ck/SharpEfsPotato/releases/latest/download/SharpEfsPotato.exe" \
    "$TOOLS_DIR/windows/potatoes/SharpEfsPotato.exe" "SharpEfsPotato"

# Watson — Windows vulnerability suggester (checks missing patches vs CVE list)
grab "https://github.com/rasta-mouse/Watson/releases/latest/download/Watson.exe" \
    "$TOOLS_DIR/windows/privesc/Watson.exe" "Watson (missing patch suggester)"

# ADRecon — comprehensive AD audit (PS1)
grab "https://raw.githubusercontent.com/sense-of-security/ADRecon/master/ADRecon.ps1" \
    "$TOOLS_DIR/ad/ADRecon.ps1" "ADRecon.ps1 (full AD audit)"

# SharpHound alternative — AzureHound for cloud environments
grab "https://github.com/BloodHoundAD/AzureHound/releases/latest/download/azurehound-linux-amd64.zip" \
    "$TOOLS_DIR/ad/AzureHound-linux.zip" "AzureHound (Azure/Entra AD)"

# Coercer (Python) — also grab the single-file version
grab "https://raw.githubusercontent.com/p0dalirius/Coercer/main/Coercer.py" \
    "$TOOLS_DIR/ad/coercion/Coercer.py" "Coercer (all coercion methods)"

# DFSCoerce (another coercion method)
grab "https://raw.githubusercontent.com/Wh04m1001/DFSCoerce/main/dfscoerce.py" \
    "$TOOLS_DIR/ad/coercion/DFSCoerce.py" "DFSCoerce (MS-DFSNM coercion)"

# PKINITtools — PKINIT/certificate-based Kerberos attacks
grab "https://raw.githubusercontent.com/dirkjanm/PKINITtools/master/gettgtpkinit.py" \
    "$TOOLS_DIR/ad/adcs/gettgtpkinit.py" "gettgtpkinit (PKINIT → TGT from cert)"
grab "https://raw.githubusercontent.com/dirkjanm/PKINITtools/master/getnthash.py" \
    "$TOOLS_DIR/ad/adcs/getnthash.py" "getnthash (TGT → NTLM hash via U2U)"

# pywhisker (Linux version of Whisker for shadow credentials)
grab "https://raw.githubusercontent.com/ShutdownRepo/pywhisker/main/pywhisker.py" \
    "$TOOLS_DIR/ad/adcs/pywhisker.py" "pywhisker (Shadow Credentials from Linux)"

# TargetedKerberoast
grab "https://raw.githubusercontent.com/ShutdownRepo/targetedKerberoast/main/targetedKerberoast.py" \
    "$TOOLS_DIR/ad/targetedKerberoast.py" "targetedKerberoast (Kerberoast any account via ACL)"

# NetExec (in case not installed)
echo -e "  ${DIM}[~]${RST} NetExec → install via: ${CYN}pip install netexec --break-system-packages${RST}"

chmod +x "$TOOLS_DIR"/ad/coercion/*.py "$TOOLS_DIR"/ad/adcs/*.py \
    "$TOOLS_DIR"/ad/*.py 2>/dev/null

# ─────────────────────────────────────────────────────────
# Update manifest
# ─────────────────────────────────────────────────────────
find "$TOOLS_DIR" -type f | sort > "$TOOLS_DIR/manifest.txt"
echo "Last updated: $(date)" >> "$TOOLS_DIR/manifest.txt"

echo ""
echo -e "  ${GRN}Fixed/Added : ${DOWNLOADED}${RST}  ${RED}Still failed : ${FAILED}${RST}"
echo ""
echo -e "  ${BLD}Still failing after this script?${RST}"
echo -e "  These need manual download from GitHub releases pages:"
echo -e "  ${DIM}  - SweetPotato.exe  (CCob/SweetPotato — no binary releases, compile yourself)"
echo -e "    - SharpRDP.exe     (0xthirteen/SharpRDP — compile from source)"
echo -e "    - nanodump         (fortra — check exact release tag for asset names)${RST}"
echo ""
