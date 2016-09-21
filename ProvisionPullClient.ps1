<#
.SYNOPSIS
    Configures a machine to be a pull client in a DSC environment

.DESCRIPTION
    Takes the parameters of a configuration GUID and pull server address, determines which version of PowerShell is installed and applies the relevant configuration to act as a pull server client.

.PARAMETER ConfigurationIDGUID
    The GUID of the configuration that the client will apply.

.PARAMETER PullServerURL
    The full URL of the pull server that will be used by the client

.EXAMPLE
    Provision client to look at pullserver.example.com and use a configuration GUID

    ProvisionPullClient.ps1 e7d38156-02b2-42d3-ad0a-4457fe8cf380 https://pullserver.example.com:8080/PSDSCPullServer.svc
#>

Param (
    # Parameter that defines the configuration ID to be used by the client
    [Parameter(Mandatory=$True)]
    [string]$ConfigurationIDGUID,

    # Parameter that defines the Pull server the client will use
    [Parameter(Mandatory=$True)]
    [string]$PullServerURL
)

# Temp folder used for outputting the MOF files so they are in a known location
If (!(Test-Path 'C:\Temp'))
{
    New-Item 'C:\Temp' -ItemType Directory
}

# Work from the temp folder
Set-Location 'C:\Temp'

# Use switch to configure the pull client dependant on version of PS installed
# PS v5 https://msdn.microsoft.com/en-us/powershell/dsc/pullclientconfigid
# PS v4 https://msdn.microsoft.com/en-us/powershell/dsc/pullclientconfigid4
Switch ($PSVersionTable.PSVersion.Major){
    5 {
        [DSCLocalConfigurationManager()]
        configuration PullClientConfigID
        {
            Node localhost
            {
                Settings
                {
                    RefreshMode = 'Pull'
                    ConfigurationID = $ConfigurationIDGUID
                    RefreshFrequencyMins = 30 
                    RebootNodeIfNeeded = $true
                    ConfigurationMode = "ApplyAndAutoCorrect"
                }
                ConfigurationRepositoryWeb PullSrv
                {
                    ServerURL = $PullServerURL
                }      
            }
        }
        PullClientConfigID

        Set-DscLocalConfigurationManager -Path ".\PullClientConfigID"
    }
    4 {
            Configuration SimpleMetaConfigurationForPull 
            { 
                LocalConfigurationManager 
                { 
                    ConfigurationID = $ConfigurationIDGUID;
                    RefreshMode = "PULL";
                    DownloadManagerName = "WebDownloadManager";
                    RebootNodeIfNeeded = $true;
                    RefreshFrequencyMins = 30;
                    ConfigurationModeFrequencyMins = 30; 
                    ConfigurationMode = "ApplyAndAutoCorrect";
                    DownloadManagerCustomData = @{ServerUrl = "$PullServerURL"; AllowUnsecureConnection = “FALSE”}
                } 
            } 
            SimpleMetaConfigurationForPull -Output ".\."

            Set-DscLocalConfigurationManager -Path ".\SimpleMetaConfigurationForPull"
    }
    # Graceful exit if PS Version doesnt mach above
    default { exit }
}
