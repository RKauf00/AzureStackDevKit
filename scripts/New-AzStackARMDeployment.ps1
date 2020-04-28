
#
# Notes
#

    #
    #   Azure Region must host D and E VM sizes supporting nested virtualization
    #
    #   VM Sizing:
    #
    #       Reference: https://docs.microsoft.com/en-us/azure-stack/asdk/asdk-deploy-considerations?view=azs-1910
    #
    #       CPU:       Minimum - 16 Cores     Recommended - 20 Cores
    #       Memory:    Minimum - 192GB        Recommended - 256GB
    #
    #       Recommended VM Size
    #
    #           Standard_E32s_v3    |   32C/256GB
    #
    #       VM Sizes (Minimum Requirements)
    #
    #           Standard_D48s_v3    |   48C/192GB
    #           Standard_E32-16s_v3 |   16C/256GB
    #           Standard_E64-16s_v3 |   16C/432GB
    #
    #       VM Sizes (Exceeds Requirements)
    #
    #          Standard_D64s_v3    |   64C/256GB
    #          Standard_E48s_v3    |   48C/384GB
    #          Standard_E64-32s_v3 |   32C/432GB
    #          Standard_E64s_v3    |   64C/432GB
    #
    #       Tested VM Sizes
    #
    #           Standard_E32s_v3
    #           Standard_E48s_v3
    #


# Function(s)

    function publicDnsNameTest
    {
        do
        {
            $CheckAgain=$NULL

            [string] $publicDnsNameURI = "$($publicDnsName).$($Location).cloudapp.usgovcloudapi.net"
            Write-Verbose "Checking publicDnsName: $($publicDnsName)"

            $UriCheck = Test-NetConnection $publicDnsNameURI -InformationLevel Detailed -Verbose:$FALSE

            if ($UriCheck.RemoteAddress.IPAddressToString)
            {
                Write-Verbose "DNS name in use; updating and rechecking"
                $instanceNumber = $instanceNumber++
                [string] $publicDnsName  =  "$($publicDnsNamePrefix)$($instanceModifier)$($instanceNumber)"
                $CheckAgain=$TRUE
            }
            else
            {
                Write-Verbose "DNS name is available; continuing"
                [string] $publicDnsName  =  "$($publicDnsNamePrefix)$($instanceModifier)$($instanceNumber)"
                $CheckAgain=$FALSE
            }
        }
        while ($CheckAgain -eq $TRUE)

        Write-Verbose "publicDnsTest is complete; publicDnsName is $($publicDnsName)"
        return $publicDnsName
    }


# Import Module(s)

Import-Module AZ


# Parameters

    [string] $instanceModifier =  'RK-C'
    [int]    $instanceNumber   =  1

    [ValidateSet("development","master","RK","NP","TF")] [string] $gitBranch = "master"        # GitHub branch // Case Sensitive

    [string] $Template = "https://raw.githubusercontent.com/RKauf00/AzureStackDevKit/$($gitBranch)/azuredeploy.json"

    [bool]   $GovDeployment  = $TRUE

    if ($GovDeployment -eq $TRUE)
    {
        [string] $AzEnv = 'AzureUSGovernment'
        [string] $Location = 'usgovvirginia' #'usgovtexas'
    }
    else
    {
        [string] $AzEnv = $NULL
        [string] $Location = 'eastus2'
    }

    
# Connect Azure Account

    Disconnect-AzAccount -ErrorAction SilentlyContinue

    if ($AzEnv)
    {
        Connect-AzAccount -Environment $AzEnv
        [ValidateSet("usgovvirginia","usgoviowa","usdodeast","usdodcentral","usgovtexas","usgovarizona")] [string] $location = $Location
    }
    else
    {
        Connect-AzAccount
        [ValidateSet("eastasia","southeastasia","centralus","eastus","eastus2","westus","northcentralus","southcentralus","northeurope","westeurope","japanwest","japaneast","bazilsouth","australiaeast","australiasoutheast","southindia","centralindia","westindia","canadacentral","canadaeast","uksouth","ukwest","westcentralus","wstus2","koreacentral","koreasouth","francecentral","francesouth","australiacentral","australiacentral2","uaecentral","uaenorth","southafricanorth","southaricawest","switzerlandnorth","switzerlandwest","germanynorth","germanywestcentral","norwaywest","norwayeast")][string]$location = $Location
    }


# Set Azure Subscription

    # Collect Azure Subscription Data
    $Subscription = Get-AzSubscription

    # Evaluate Azure Subscription Data
    if (!($Subscription))
    {
        return Write-Host 'Failed to connect to AzAccount; exiting'
        break ; break
    }
    elseif ($Subscription.Id.Count -gt 1)
    {
        $Count             =    0
        $Choice            =    Read-Host "Select Subscription`n $( foreach ($S in $Subscription.Id) { "$($Count): $S`n" ; $Count ++ } )"
        $SubscriptionID    =    ($Subscription.Id)[$Choice]
        $TenantID          =    ($Subscription.TenantId)[$Choice]
    }
    else
    {
        $SubscriptionID    =    $Subscription.Id
        $TenantID          =    $Subscription.TenantId
    }

    # Select Azure Subscription
    Select-AzSubscription -Tenant $TenantID -Subscription $SubscriptionID


# Template Variables

    # Set Azure Values
 
    [string] $AzureADTenant            =  Read-Host "Azure AD Tenant (Format: <AzureADTenant>.onmicrosoft.com)"
    [string] $siteLocation             =  $Location
    [string] $resourceGroupNamePrefix  =  'AzStackPOC'
    [string] $resourceGroupName        =  "$($resourceGroupNamePrefix)-$($instanceModifier)$($instanceNumber)"
    
    # Set Azure Storage File Download Values

    [array] $AzStorage=
    @{
        URL          =    'https://generalstorage.blob.core.usgovcloudapi.net/'
        Container    =    'files/'
        SAS          =    '?sv=2019-02-02&ss=bfqt&srt=sco&sp=rl&se=2022-04-19T23:08:09Z&st=2020-04-20T15:08:09Z&spr=https&sig=wrComGZM21wyOCp%2F%2BzpOVhVSgesAKaPG2CPKd0YYkhA%3D'
        Files        =    @('MicrosoftEdgeEnterpriseX64.msi','Getting_Started_Links.pdf','MSDocs-ASDK-28FEB2020.pdf')
    }
    [array] $AzFileStorageURIs             =  $AzStorage.Files | ForEach-Object { $AzStorage.URL + $AzStorage.Container + $_ + $AzStorage.SAS }

    # Set Azure VM Values
    [String] $adminUsername            =  'AzStackAdmin'    # if successfully deployed, use administrator to log in
    [string] $virtualMachineName       =  'AzStackHost'
    [string] $virtualMachineSize       =  'Standard_E32s_v3'
    [int]    $dataDiskSizeinGB         =  1024
    [int]    $dataDiskCount            =  4
    [bool]   $enableRDSH               =  $TRUE
    [string] $DNSForwarder             =  "1.1.1.1"

    # Set Azure Networking Values
    [string] $virtualNetworkName       =  'AzureStack-VNET'
    [string] $addressPrefix            =  '10.0.0.0/24'
    [string] $subnetName               =  'default'
    [string] $subnetPrefix             =  '10.0.0.0/24'
    [string] $publicIpAddressType      =  'Dynamic'
    [string] $publicDnsNamePrefix      =  'AzStackPOC'
    [string] $publicDnsName            =  "$($publicDnsNamePrefix)$($instanceModifier)$($instanceNumber)"
    [string] $publicDnsName            =  publicDnsNameTest

    # Set Administrator Passwords
    [SecureString] $SecureAdminPassword         =  Read-Host -AsSecureString -Prompt "Provide password for local Administrator ($($adminUsername))"


# Create Resource Group

    New-AzResourceGroup -Name $resourceGroupName -Location $Location


# Deploy GitHub ARM Template

    ## Purge templateParameterObject Variable
    Remove-Variable templateParameterObject -ErrorAction SilentlyContinue

    ## Build templateParameterObject Variable
    $templateParameterObject=@{}
    $templateParameterObject.Add("AzureADTenant",$AzureADTenant)
    $templateParameterObject.Add("siteLocation",$siteLocation)
    $templateParameterObject.Add("adminUsername",$adminUsername)
    $templateParameterObject.Add("adminPassword", $SecureAdminPassword)
    $templateParameterObject.Add("virtualMachineName",$virtualMachineName)
    $templateParameterObject.Add("virtualMachineSize",$virtualMachineSize)
    $templateParameterObject.Add("dataDiskSizeinGB",$dataDiskSizeinGB)
    $templateParameterObject.Add("dataDiskCount",$dataDiskCount)
    $templateParameterObject.Add("enableRDSH",$enableRDSH)
    $templateParameterObject.Add("virtualNetworkName",$virtualNetworkName)
    $templateParameterObject.Add("addressPrefix",$addressPrefix)
    $templateParameterObject.Add("subnetName",$subnetName)
    $templateParameterObject.Add("subnetPrefix",$subnetPrefix)
    $templateParameterObject.Add("publicDnsName",$publicDnsName.ToLower())
    $templateParameterObject.Add("publicIpAddressType",$publicIpAddressType)
    $templateParameterObject.Add("AzureFileStorageURIs",$AzFileStorageURIs)
    $templateParameterObject.Add("DNSForwarder",$DNSForwarder)

    ## Start New Deployment
    New-AzResourceGroupDeployment `
        -Name "$resourceGroupName-POC-Deployment" `
        -ResourceGroupName $resourceGroupName `
        -TemplateUri $Template `
        -TemplateParameterObject $templateParameterObject `
        -Mode Incremental `
        -AsJob



# Open Deployment Blade in Azure Portal

    if ($GovDeployment -eq $TRUE)
    {
        Start-Process microsoft-edge:"https://portal.azure.us/#blade/HubsExtension/DeploymentDetailsBlade/overview/id/%2Fsubscriptions%2F$($SubscriptionID)%2FresourceGroups%2F$($resourceGroupName)%2Fproviders%2FMicrosoft.Resources%2Fdeployments%2F$($resourceGroupName)-POC-Deployment"
    }
    else
    {
        Start-Process microsoft-edge:"https://portal.azure./#blade/HubsExtension/DeploymentDetailsBlade/overview/id/%2Fsubscriptions%2F$($SubscriptionID)%2FresourceGroups%2F$($resourceGroupName)%2Fproviders%2FMicrosoft.Resources%2Fdeployments%2F$($resourceGroupName)-POC-Deployment"
    }
