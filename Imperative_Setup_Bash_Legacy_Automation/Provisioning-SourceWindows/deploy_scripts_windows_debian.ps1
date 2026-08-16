# <# 
# ==============================================================================
# SCRIPT HEADER
# ==============================================================================
# This section is a "Block Comment". PowerShell ignores everything inside <# #>.
# It is used here just to describe what the script does for humans reading it.
# ==============================================================================
# #>

# ------------------------------------------------------------------------------
# SECTION 1: SETTING UP VARIABLES
# ------------------------------------------------------------------------------

# Resolve the base directory dynamically (one folder up from where this script is located)

$SourcePath = Join-Path (Split-Path -Parent $PSScriptRoot) "Debian"

# We create another variable named $RemoteDir for the destination on the Linux server.
$RemoteDir = "~/Scripts/Debian"

# ------------------------------------------------------------------------------
# SECTION 2: GETTING USER INPUT
# ------------------------------------------------------------------------------

# 'Clear-Host' wipes the terminal screen clean.
Clear-Host

# 'Write-Host' prints text to the screen.
Write-Host "Debian Script Deployer" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan

# Here we print the paths we defined earlier so you can double-check them.
Write-Host "Source: $SourcePath"
Write-Host "Target: $RemoteDir"
Write-Host ""  # Prints an empty line for better spacing.

# 'Read-Host' pauses the script and waits for you to type something.
$Username = Read-Host "Enter SSH Username (e.g. Saturday)"
$ServerIP = Read-Host "Enter Server IP (e.g. 192.168.X.X)"

# ------------------------------------------------------------------------------
# SECTION 3: CHECKING FOR ERRORS
# ------------------------------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($ServerIP)) {
    Write-Host "❌ Error: IP Address cannot be empty." -ForegroundColor Red
    exit
}

if ([string]::IsNullOrWhiteSpace($Username)) {
    Write-Host "❌ Error: Username cannot be empty." -ForegroundColor Red
    exit
}

# ------------------------------------------------------------------------------
# SECTION 4: CREATING THE FOLDER ON THE SERVER
# ------------------------------------------------------------------------------

Write-Host ""
Write-Host "[1/2] Connecting to $ServerIP to create folder..." -ForegroundColor Yellow

# We run the 'ssh' command.
ssh ${Username}@$ServerIP "mkdir -p $RemoteDir"

# Check if SSH worked (Exit code 0 means success).
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Connection failed. Check IP, Username, or Password." -ForegroundColor Red
    exit
}

# ------------------------------------------------------------------------------
# SECTION 5: UPLOADING THE FILES
# ------------------------------------------------------------------------------

Write-Host ""
Write-Host "[2/2] Uploading scripts..." -ForegroundColor Yellow

# We run the 'scp' command.
scp "$SourcePath\*" "${Username}@${ServerIP}:$RemoteDir/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Upload failed." -ForegroundColor Red
    exit
}

# ------------------------------------------------------------------------------
# SECTION 6: FINISHING UP
# ------------------------------------------------------------------------------

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "✅ SUCCESS! All files uploaded to $RemoteDir" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Step:"
Write-Host "1. SSH into server: ssh ${Username}@$ServerIP"
Write-Host "2. Go to folder:    cd $RemoteDir"
Write-Host "3. Make executable: chmod +x *.sh"
Write-Host "4. Run master:      sudo ./main_debian_fresh_install.sh"
Write-Host ""
