# __Deploy Azure Stack on an Azure VM__

## __Description__

Creates a new VM and installs prerequisites to install AzureStack Development kit (ASDK) to run PoC


## __Intent__

Facilitate [Azure Stack](https://azure.microsoft.com/en-us/overview/azure-stack/) learning and [Azure Stack Operator](https://azure.microsoft.com/en-us/blog/why-your-team-needs-an-azure-stack-operator/) training


## __Process__

### __Visualize ARM Template__

[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FRKauf00%2FAzureStackDevKit%2Fmaster%2Fazuredeploy.json)


### __Deploy ARM template__

[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FRKauf00%2FAzureStackDevKit%2Fmaster%2Fazuredeploy.json)

[![Deploy to Azure Gov](https://azuredeploy.net/AzureGov.png)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FRKauf00%2FAzureStackDevKit%2Fmaster%2Fazuredeploy.json)


### __Deployment Process__

  - Deploy the template
    - [recommended] Update variables and Run *New-AzStackARMDeployment.ps1*
    - [Azure Commercial](https://aka.ms/Azure-AzStackPOC)
    - [Azure US Government](https://aka.ms/AzureGov-AzStackPOC)
  - Log on to Azure VM (default username is _administrator_)
  - Run desktop shortcut 1_Install-ASDK as **administrator**
    - When prompted; complete Azure AD authentication
  - Following automatic restart; log on to the server
    - Account updates to use AzureStack domain account
    - Acount Name: _AzureStack\AzureStackAdmin_
    - Account Password: Same as _Administrator_ account
  - [optional] Update Default Browser to Edge (Chromium)
    - [optional] Configure default settings
      - [optional] *Page Layout*: *Custom* with *Content*: *Off*
      - [optional] *Settings* > *On Startup* > *Specific Page* > *Add a New Page* > *https://adminportal.local.azurestack.external/*
      - [optional] *Settings* > *On Startup* > *Specific Page* > *Add a New Page* > *https://portal.local.azurestack.external/*
  - Launch Azure Stack Admin Portal shortcut on desktop
    - Validate Portal authentication / launch
    - Close browser
  - Run PowerShell with Administrative privileges
    - Run *& C:\AzSPoC\AzSPoC.ps1*
    - Provide Azure AD Account Name at prompt
    - Provide Azure AD Account Password at prompt


### __ISO Download URIs__

 - [Windows Server 2019 (Evaluation)](https://software-download.microsoft.com/download/17763.253.190108-0006.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso)
 - [Windows Server 2016 (Evaluation)](http://download.microsoft.com/download/1/4/9/149D5452-9B29-4274-B6B3-5361DBDA30BC/14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO)
 - [Windows 10 Enterprise (Evaluation)](https://software-download.microsoft.com/download/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso)

### __Pending Checks, Tests, Updates__

 - Windows Server 2016 and Windows 10 eval ISO download timeout
  - Windows Server 2016 Eval ISO
    - Validated URI works
    - Need to validate it works in deployment
    - [Download URI](http://download.microsoft.com/download/1/4/9/149D5452-9B29-4274-B6B3-5361DBDA30BC/14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO)
  - Windows 10 Enterprise Eval ISO
    - Validated URI works
    - Need to validate it works in deployment
    - [Download URI](https://software-download.microsoft.com/download/18363.418.191007-0143.19h2_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso)


### __Example__

`
PS C:\Temp> & "<PathToFile>\New-AzStackARMDeployment.ps1"
`


## __Included Reference Material__

### __Microsoft Docs ASDK PDF__

`
C:\_GettingStarted\MSDocs-ASDK-28FEB2020.pdf
`

### __Getting Start with Azure Stack Links__

`
C:\_GettingStarted\MSDocs-ASDK-28FEB2020.pdf
`

## __Updates / Change log__

### __08.04.2019__
- Tested with ASDK 1.1907.0.20


## **Enjoy!**
