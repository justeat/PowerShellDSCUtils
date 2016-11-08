[cmdletbinding()]

Param (
    # Parameter that defines the configuration ID to be used by the client
    [Parameter(Mandatory=$True)]
    [string]$ConfigurationIDGUID,

    # Parameter that defines the Pull server the client will use
    [Parameter(Mandatory=$True)]
    [string]$PullServerURL
)

Set-Location "$PSScriptRoot"

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
        AllowModuleOverwrite = $true
        DownloadManagerCustomData = @{ServerUrl = "$PullServerURL"; AllowUnsecureConnection = “FALSE”}
    } 
} 
SimpleMetaConfigurationForPull -Output ".\."

Set-DscLocalConfigurationManager -Path ".\."
