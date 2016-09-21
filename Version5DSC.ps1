[cmdletbinding()]

Param (
    # Parameter that defines the configuration ID to be used by the client
    [Parameter(Mandatory=$True)]
    [string]$ConfigurationIDGUID,

    # Parameter that defines the Pull server the client will use
    [Parameter(Mandatory=$True)]
    [string]$PullServerURL
)

Set-Location "$PSScriptRoot\DSC"

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

    Set-DscLocalConfigurationManager -Path ".\."