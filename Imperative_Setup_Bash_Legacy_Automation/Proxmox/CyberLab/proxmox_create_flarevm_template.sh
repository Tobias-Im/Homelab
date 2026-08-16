#!/bin/bash
# =========================================================================
# proxmox_create_flarevm_template.sh
# 100% Zero-Touch Automated Windows 10 & FLARE-VM Template Generator
# =========================================================================

TEMPLATE_ID=201
TEMPLATE_NAME="FLARE-VM-Template"
STORAGE="local"
ISO_STORAGE="local"
# Official Microsoft Windows 10 Enterprise Evaluation Direct Download Link
WIN_ISO_URL="https://software-static.download.prss.microsoft.com/dbazure/988969d5-f34g-4e03-ac9d-1f9786c66750/19045.2006.220908-0225.22h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
WIN_ISO_NAME="windows10-eval.iso"
ISO_PATH="/var/lib/vz/template/iso/$WIN_ISO_NAME"
UNATTEND_ISO_PATH="/var/lib/vz/template/iso/flare-unattend.iso"

echo "========================================================"
echo "🚀 FULLY AUTOMATED FLARE-VM TEMPLATE GENERATOR"
echo "========================================================"

# Step 1: Check if template already exists
if qm status $TEMPLATE_ID > /dev/null 2>&1; then
    echo "❌ Error: VM/Template $TEMPLATE_ID already exists. Destroy it first if you want to recreate it."
    exit 1
fi

# Step 2: Download Windows 10 ISO
# Check if file exists AND is larger than 1GB (to avoid 0-byte corrupt downloads)
if [ -f "$ISO_PATH" ]; then
    FILESIZE=$(stat -c%s "$ISO_PATH" 2>/dev/null || stat -f%z "$ISO_PATH" 2>/dev/null)
    if [ "$FILESIZE" -lt 1073741824 ]; then
        echo ">> Existing Windows 10 ISO is corrupt or incomplete ($FILESIZE bytes). Deleting it..."
        rm -f "$ISO_PATH"
    fi
fi

if [ ! -f "$ISO_PATH" ]; then
    echo ">> Downloading official Windows 10 Evaluation ISO (5GB)..."
    echo ">> This will take several minutes depending on your internet speed."
    wget -O "$ISO_PATH" "$WIN_ISO_URL"
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to download Windows 10 ISO."
        exit 1
    fi
else
    echo ">> Windows 10 ISO already exists and is valid, skipping download."
fi

# Step 3: Install genisoimage if missing (required to build the answer file ISO)
if ! command -v genisoimage &> /dev/null; then
    echo ">> Installing genisoimage..."
    apt-get update > /dev/null && apt-get install -y genisoimage > /dev/null
fi

# Step 4: Create Unattend Files
echo ">> Generating Answer Files for Zero-Touch Installation..."
mkdir -p /tmp/flarevm_unattend
cd /tmp/flarevm_unattend

# Generate autounattend.xml
cat << 'EOF' > autounattend.xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <SetupUILanguage><UILanguage>en-US</UILanguage></SetupUILanguage>
            <InputLocale>0409:00000409</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <DiskConfiguration>
                <Disk wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Type>Primary</Type>
                            <Extend>true</Extend>
                        </CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Active>true</Active>
                            <Format>NTFS</Format>
                            <Label>OS</Label>
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                        </ModifyPartition>
                    </ModifyPartitions>
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>1</PartitionID>
                    </InstallTo>
                    <InstallToAvailablePartition>false</InstallToAvailablePartition>
                </OSImage>
            </ImageInstall>
            <UserData>
                <AcceptEula>true</AcceptEula>
            </UserData>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
                    <Order>1</Order>
                    <Path>cmd.exe /c reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
                    <Order>2</Order>
                    <Path>cmd.exe /c reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
                    <Order>3</Order>
                    <Path>cmd.exe /c reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ComputerName>FLARE-VM</ComputerName>
            <TimeZone>UTC</TimeZone>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>3</ProtectYourPC>
                <SkipUserOOBE>true</SkipUserOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
                        <Description>Admin</Description>
                        <DisplayName>flarevm</DisplayName>
                        <Group>Administrators</Group>
                        <Name>flarevm</Name>
                        <Password>
                            <Value>malware</Value>
                            <PlainText>true</PlainText>
                        </Password>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <AutoLogon>
                <Password>
                    <Value>malware</Value>
                    <PlainText>true</PlainText>
                </Password>
                <Username>flarevm</Username>
                <Enabled>true</Enabled>
                <LogonCount>999</LogonCount>
            </AutoLogon>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
                    <Order>1</Order>
                    <CommandLine>cmd.exe /c powershell -ExecutionPolicy Bypass -Command "foreach($letter in (Get-Volume).DriveLetter){ $path = \"$letter`:\install-flare.ps1\"; if(Test-Path $path){ &amp; $path; break; } }"</CommandLine>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
</unattend>
EOF

# Generate install-flare.ps1
cat << 'EOF' > install-flare.ps1
Write-Host "FLARE-VM Zero-Touch Installer Bootstrapped!"

# Disable Execution Policy restrictions for FLARE-VM
Set-ExecutionPolicy Unrestricted -Force

# Disable Defender and UAC
Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
Set-MpPreference -DisablePrivacyMode $true -ErrorAction SilentlyContinue
Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableArchiveScanning $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableIntrusionPreventionSystem $true -ErrorAction SilentlyContinue
Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue

# Disable Windows Updates Services
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue

# Disable Sleep
powercfg.exe /hibernate off
powercfg.exe /x -standby-timeout-ac 0

# Wait for Internet Connection
while (!(Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet)) {
    Start-Sleep -Seconds 5
}

$watchdogScript = @'
$idleCount = 0
while ($true) {
    Start-Sleep -Seconds 60
    
    # Check if Boxstarter or Chocolatey are currently running
    $boxstarter = Get-Process -Name *boxstarter* -ErrorAction SilentlyContinue
    $choco = Get-Process -Name *choco* -ErrorAction SilentlyContinue
    
    # If they are NOT running, and the chocolatey directory exists, increment idle counter
    if (!$boxstarter -and !$choco -and (Test-Path "C:\ProgramData\chocolatey")) {
        $idleCount++
    } else {
        $idleCount = 0
    }
    
    # If Boxstarter has been inactive for 15 straight minutes, the installation is completely finished!
    if ($idleCount -ge 15) {
        Unregister-ScheduledTask -TaskName "FlareVMWatchdog" -Confirm:$false -ErrorAction SilentlyContinue
        Stop-Computer -Force
        break
    }
}
'@
Set-Content -Path "C:\Users\flarevm\Documents\watchdog.ps1" -Value $watchdogScript

# Register Watchdog as a Scheduled Task to survive reboots
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\flarevm\Documents\watchdog.ps1"'
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "FlareVMWatchdog" -User "flarevm" -Password "malware" -RunLevel Highest -Force
Start-ScheduledTask -TaskName "FlareVMWatchdog"

# Download FLARE-VM installer
(New-Object net.webclient).DownloadFile('https://raw.githubusercontent.com/mandiant/flare-vm/main/install.ps1', "C:\Users\flarevm\Desktop\install.ps1")
Unblock-File C:\Users\flarevm\Desktop\install.ps1

# Disable QuickEdit mode so accidental mouse clicks don't pause the installation
if (!(Test-Path "HKCU:\Console")) { New-Item -Path "HKCU:\Console" -Force }
Set-ItemProperty -Path "HKCU:\Console" -Name "QuickEdit" -Value 0

# Schedule it to run visibly on the next boot (when UAC is fully disabled)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "InstallFlareVM" -Value "powershell.exe -ExecutionPolicy Bypass -NoExit -Command `"Set-ExecutionPolicy Unrestricted -Force; cd C:\Users\flarevm\Desktop; .\install.ps1 -password 'malware' -noChecks -noWait -noGui`""

# Force a reboot to apply UAC/Defender changes and trigger the visible installation
Restart-Computer -Force
EOF

# Package into an ISO so Windows Setup can find it
echo ">> Packaging answer files into ISO..."
genisoimage -J -l -R -V "Oemdrv" -iso-level 4 -o $UNATTEND_ISO_PATH autounattend.xml install-flare.ps1 > /dev/null 2>&1

# Step 5: Create the VM
echo ">> Creating Virtual Machine (ID: $TEMPLATE_ID)..."
qm create $TEMPLATE_ID --name $TEMPLATE_NAME --memory 8192 --cores 4 --cpu kvm64 --net0 e1000,bridge=vmbr0,firewall=1 --machine q35 --ostype win10
qm set $TEMPLATE_ID --sata0 $STORAGE:120,discard=on,ssd=1,format=qcow2
qm set $TEMPLATE_ID --ide0 $ISO_STORAGE:iso/$WIN_ISO_NAME,media=cdrom
qm set $TEMPLATE_ID --ide1 $ISO_STORAGE:iso/flare-unattend.iso,media=cdrom

# Set the correct boot order (CD-ROM first, then Disk)
qm set $TEMPLATE_ID --boot order=ide0\;sata0
qm set $TEMPLATE_ID --vga virtio
qm set $TEMPLATE_ID --agent enabled=1

# Step 6: Start the VM and wait
echo ">> Starting VM and beginning zero-touch installation..."
qm start $TEMPLATE_ID

echo "========================================================"
echo ">> FLARE-VM INSTALLATION IS NOW RUNNING IN THE BACKGROUND!"
echo ">> Phase 1: Windows 10 is installing itself (10 mins)"
echo ">> Phase 2: FLARE-VM scripts are downloading tools (2-3 hours)"
echo ">> DO NOT MANUALLY REBOOT OR TOUCH THE VM."
echo ">> The watchdog script will automatically shut it down when finished."
echo "========================================================"

# Infinite loop checking if VM has stopped
while [[ "$(qm status $TEMPLATE_ID)" == *"running"* ]]; do
    echo ">> [$(date '+%Y-%m-%d %H:%M:%S')] VM is still running. Checking again in 5 minutes..."
    sleep 300
done

echo "========================================================"
echo ">> VM HAS SHUT DOWN! FLARE-VM INSTALLATION IS COMPLETE!"
echo ">> Converting VM to Template..."
echo "========================================================"

# Remove CD-ROMs
qm set $TEMPLATE_ID --delete ide0
qm set $TEMPLATE_ID --delete ide1

# Set the boot disk back to the hard drive for future clones
qm set $TEMPLATE_ID --boot order=sata0

# Convert to template
qm template $TEMPLATE_ID

# Cleanup
rm -rf /tmp/flarevm_unattend
rm -f $UNATTEND_ISO_PATH

echo "🎉 SUCCESS: FLARE-VM Golden Image Template ($TEMPLATE_ID) is ready!"
echo "   You can now clone this template with Terraform instantly."
echo "========================================================"
