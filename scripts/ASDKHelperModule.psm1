function DownloadWithRetry([string] $Uri, [string] $DownloadLocation, [int] $Retries = 5, [int]$RetryInterval = 10)
{
    while($true)
    {
        try
        {
            Start-BitsTransfer -Source $Uri -Destination $DownloadLocation -DisplayName $Uri
            break
        }
        catch
        {
            $exceptionMessage = $_.Exception.Message
            Write-Host "Failed to download '$Uri': $exceptionMessage"
            if ($retries -gt 0) {
                $retries--
                Write-Host "Waiting $RetryInterval seconds before retrying. Retries left: $Retries"
                Clear-DnsClientCache
                Start-Sleep -Seconds $RetryInterval
 
            }
            else
            {
                $exception = $_.Exception
                throw $exception
            }
        }
    }
}
function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
}

function Write-Log ([string]$Message, [string]$LogFilePath, [switch]$Overwrite)
{
    $t = Get-Date -Format "yyyy-MM-dd hh:mm:ss"
    Write-Verbose "$Message - $t" -Verbose
    if ($Overwrite)
    {
        Set-Content -Path $LogFilePath -Value "$Message - $t"
    }
    else
    {
        Add-Content -Path $LogFilePath -Value "$Message - $t"
    }
}

function ASDKDownloader
{
    [CmdletBinding()]
    param
    (
        [System.Collections.ArrayList]
        $AsdkFileList,
    
        [string]
        $ASDKURIRoot = "https://azurestackhub.azureedge.net/PR/download/ASDK_",

        [string]
        $asdkVersion = '1.2102.0.9',

        [string]
        $Destination = "D:\"
    )

    if (!($AsdkFileList))
    {
        $AsdkFileList = @("AzureStackDevelopmentKit.exe")
        1..13 | ForEach-Object {$AsdkFileList += "AzureStackDevelopmentKit-$_" + ".bin"}
    }

    Write-Verbose -Message "Downloading ASDK_$asdkVersion" -Verbose
    
    $AsdkFileList | ForEach-Object {Start-BitsTransfer -Source ($asdkURIRoot + $asdkVersion + '/' + $_) -DisplayName $_ -Destination $Destination}      
}

function extractASDK ($File, $Destination)
{
    Start-Process -FilePath $File -ArgumentList "/dir=`"$destination`"", "/SILENT", "/NOCANCEL" -Wait
}

function workaround1
{
    Write-Verbose "Applying workaround to tweak baremetal detection for Azure VM" -Verbose
    $baremetalFilePath = "C:\CloudDeployment\Roles\PhysicalMachines\Tests\BareMetal.Tests.ps1"
    $baremetalFile = Get-Content -Path $baremetalFilePath
    $baremetalFile = $baremetalFile.Replace('$isVirtualizedDeployment = ($Parameters.OEMModel -eq ''Hyper-V'')','$isVirtualizedDeployment = ($Parameters.OEMModel -eq ''Hyper-V'') -or $isOneNode') 
    Set-Content -Value $baremetalFile -Path $baremetalFilePath -Force
}

function workaround2
{
    Write-Verbose "Applying workaround to tweak long path issues started appear after 1802" -Verbose
    $HelpersFilePath = "C:\CloudDeployment\Common\Helpers.psm1" 
    $HelpersFile = Get-Content -Path $HelpersFilePath
    $HelpersFile = $HelpersFile.Replace('C:\tools\NuGet.exe install $NugetName -Source $NugetStorePath -OutputDirectory $DestinationPath -packagesavemode "nuspec" -Prerelease','C:\tools\NuGet.exe install $NugetName -Source $NugetStorePath -OutputDirectory $DestinationPath -packagesavemode "nuspec" -Prerelease -ExcludeVersion') 
    Set-Content -Value $HelpersFile -Path $HelpersFilePath -Force
}

function workaround3
{
    Write-Verbose "Applying workaround to tackle installation from PS remoting" -Verbose
    $DeploySingleNodeCommonFilePath = "C:\CloudDeployment\Setup\Common\DeploySingleNodeCommon.ps1"
    $DeploySingleNodeCommonFile = Get-Content -Path $DeploySingleNodeCommonFilePath
    $DeploySingleNodeCommonFile = $DeploySingleNodeCommonFile.Replace('$credentialSuccess = Invoke-Command -ComputerName ''LocalHost'' -Credential $builtInAdminCredential -ErrorAction ''SilentlyContinue'' { $true }','$credentialSuccess = $true') 
    Set-Content -Value $DeploySingleNodeCommonFile -Path $DeploySingleNodeCommonFilePath -Force
}

function createDesktopShortcuts
{
    # Create all user desktop shotcuts

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$env:ALLUSERSPROFILE\Desktop\2_Demo_Config.lnk")
    $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $Shortcut.WorkingDirectory = "C:\AzureStackOnAzureVM"
    $Shortcut.Arguments = "-Noexit -command & {.\Run-ConfigASDK.ps1}"
    $Shortcut.Save()
    $Shell = New-Object -ComObject ("WScript.Shell")
            
    $fileName = $env:ALLUSERSPROFILE + "\Desktop\Azure Stack Admin Portal.url"
    if (!(Test-Path -Path $fileName))
    {
        $Favorite = $Shell.CreateShortcut($fileName)
        $Favorite.TargetPath = "https://adminportal.local.azurestack.external";
        $Favorite.Save()
        Write-Log @writeLogParams -Message "Desktop shorcut $fileName created."
    }

    $fileName = $env:ALLUSERSPROFILE + "\Desktop\Azure Stack Tenant Portal.url"
    if (!(Test-Path -Path $fileName))
    {
        $Favorite = $Shell.CreateShortcut($fileName)
        $Favorite.TargetPath = "https://portal.local.azurestack.external";
        $Favorite.Save()
        Write-Log @writeLogParams -Message "Desktop shorcuts $fileName created."
    }

    $fileName = $env:ALLUSERSPROFILE + "\Desktop\Azure Portal.url"
    if (!(Test-Path -Path $fileName))
    {
        $Favorite = $Shell.CreateShortcut($fileName)
        $Favorite.TargetPath = "https://portal.azure.com";
        $Favorite.Save()
        Write-Log @writeLogParams -Message "Desktop shorcuts $fileName created."
    }

    $fileName = $env:ALLUSERSPROFILE + "\Desktop\Service Fabric Explorer.url"
    if (!(Test-Path -Path $fileName))
    {
        $Favorite = $Shell.CreateShortcut($fileName)
        $Favorite.TargetPath = "http://azs-xrp01:19007";
        $Favorite.Save()
        Write-Log @writeLogParams -Message "Desktop shorcuts $fileName created."
    }
}


function Enable-ICS ($PublicAdapterName, $PrivateAdapterName)
{
    # Register the HNetCfg library (once)
    regsvr32 /s hnetcfg.dll

    # Create a NetSharingManager object
    $m = New-Object -ComObject HNetCfg.HNetShare

    # Find connection
    $publicAdapter = $m.EnumEveryConnection | Where-Object { $m.NetConnectionProps.Invoke($_).Name -eq $publicAdapterName }
    $privateAdapter = $m.EnumEveryConnection | Where-Object { $m.NetConnectionProps.Invoke($_).Name -eq $privateAdapterName }


    # Get sharing configuration
    $publicAdapter = $m.INetSharingConfigurationForINetConnection.Invoke($publicAdapter)
    $privateAdapter = $m.INetSharingConfigurationForINetConnection.Invoke($privateAdapter)
        
    Start-Sleep -Seconds 2

    # Disable sharing
    $publicAdapter.DisableSharing()
    $privateAdapter.DisableSharing()

    # Enable sharing (0 - public, 1 - private)

    # Enable sharing public on Network_1
    $publicAdapter.EnableSharing(0)

    # Enable sharing private on Network_2
    $privateAdapter.EnableSharing(1)

}
    
function Disable-ICS ($PublicAdapterName, $PrivateAdapterName)
{
    # Register the HNetCfg library (once)
    regsvr32 /s hnetcfg.dll

    # Create a NetSharingManager object
    $m = New-Object -ComObject HNetCfg.HNetShare

    # Find connection
    $publicAdapter = $m.EnumEveryConnection | Where-Object { $m.NetConnectionProps.Invoke($_).Name -eq $publicAdapterName }
    $privateAdapter = $m.EnumEveryConnection | Where-Object{ $m.NetConnectionProps.Invoke($_).Name -eq $privateAdapterName }


    # Get sharing configuration
    $publicAdapter = $m.INetSharingConfigurationForINetConnection.Invoke($publicAdapter)
    $privateAdapter = $m.INetSharingConfigurationForINetConnection.Invoke($privateAdapter)
        
    # Disable sharing
    $publicAdapter.DisableSharing()
    $privateAdapter.DisableSharing()
}

function Start-SleepWithProgress($seconds)
{

    $doneDT = (Get-Date).AddSeconds($seconds)

    while($doneDT -gt (Get-Date)) {

        $secondsLeft = $doneDT.Subtract((Get-Date)).TotalSeconds

        $percent = ($seconds - $secondsLeft) / $seconds * 100

        Write-Progress -Activity "Sleeping" -Status "Sleeping..." -SecondsRemaining $secondsLeft -PercentComplete $percent

        [System.Threading.Thread]::Sleep(500)

    }

    Write-Progress -Activity "Sleeping" -Status "Sleeping..." -SecondsRemaining 0 -Completed

}

function Copy-ASDKContent 
{
[CmdletBinding()]    
    param (
        $vhdxFullPath
    )
    
    $foldersToCopy = @('CloudDeployment', 'fwupdate', 'tools')

        try {
            Write-Verbose "Mounting the following file $vhdxFullPath"
            $driveLetter = (Mount-DiskImage -ImagePath $vhdxFullPath -StorageType VHDX -Access ReadWrite -Passthru -ErrorAction Stop | Get-DiskImage | Get-Disk | Get-Partition | Where-Object size -gt 500MB | Get-Volume).DriveLetter
            Write-Verbose "Source Drive is now mounted as $driveLetter"
            Write-Verbose "Mounting the drive as psDrive as a workaround"
            $psDrive = New-PSDrive -Name $driveLetter -PSProvider FileSystem -Root "$($driveLetter):\"
        }
        catch {
            throw "an error occured while mounting cloudbuilder.vhdx file"
        }
        Write-Verbose "List of folder to be copied are $foldersToCopy"
        foreach ($folder in $foldersToCopy)
        {
            Write-Verbose "Copying source folder $folder to C:\"
            $path = "$driveLetter" + ":\" + "$folder"
            Write-Verbose "Copy source path is now $path\"
            Copy-Item -Path $path -Destination C:\ -Recurse -Force -PassThru | Write-Verbose
        }
        Write-Verbose "Removing psDrive $psDrive"
        $psDrive | Remove-PSDrive
        Write-Verbose "Dismounting the drive $driveLetter"
        Dismount-DiskImage -ImagePath $vhdxFullPath -PassThru | Write-Verbose
}

function ConvertTo-HashtableFromPsCustomObject { 
    param ( 
        [Parameter(  
            Position = 0,   
            Mandatory = $true,   
            ValueFromPipeline = $true,  
            ValueFromPipelineByPropertyName = $true  
        )] [object[]]$psCustomObject 
    ); 
    
    process { 
        foreach ($myPsObject in $psCustomObject) { 
            $output = @{}; 
            $myPsObject | Get-Member -MemberType *Property | ForEach-Object { 
                $output.($_.name) = $myPsObject.($_.name); 
            } 
            $output; 
        } 
    } 
}
