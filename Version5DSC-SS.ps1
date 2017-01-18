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

[DSCLocalConfigurationManager()]Configuration SetupLCM{    Settings    {        AllowModuleOverwrite  = $True        CertificateID = "$CertThumb"        ConfigurationID = $ConfigurationIDGUID        ConfigurationMode = 'ApplyAndAutoCorrect'        RebootNodeIfNeeded = $True        RefreshFrequencyMins = 15        RefreshMode = 'PULL'    } # Settings    ConfigurationRepositoryWeb PullServerDetails    {        CertificateID = "$CertThumb"        ServerUrl = "$PullServerURL"    } # PullServerDetails} # Configuration SetupLCM

SetupLCM

Set-DscLocalConfigurationManager -Path '.\SetupLCM'
