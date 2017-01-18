[cmdletbinding()]

Param (
    # Parameter that defines the configuration ID to be used by the client
    [Parameter(Mandatory=$True)]
    [string]$ConfigurationIDGUID,

    # Parameter that defines the Pull server the client will use
    [Parameter(Mandatory=$True)]
    [string]$PullServerURL,
    [Parameter(Mandatory=$True)]
    [string]$CertThumb
)

Set-Location "$PSScriptRoot"

Configuration SetupLCM
{
    LocalConfigurationManager {          AllowModuleOverwrite  = $True
        CertificateID = "$CertThumb"
        ConfigurationID = $ConfigurationIDGUID
        ConfigurationMode = "ApplyAndAutoCorrect"
        ConfigurationModeFrequencyMins = 30
        DownloadManagerCustomData = @{
            ServerUrl = "$PullServerURL"
            }
        DownloadManagerName = "WebDownloadManager"        RefreshFrequencyMins = 30        RefreshMode = "PULL"              RebootNodeIfNeeded = $True    } # LCM
} # Configuration SetupLCM

SetupLCM #-Output "."

Set-DSCLocalConfigurationManager –ComputerName localhost –Path .\SetupLCM –Verbose
