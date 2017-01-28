[cmdletbinding(SupportsShouldProcess=$True)]
Param 
(
    [Parameter(Mandatory=$True)]
    [String]$ConfigurationNames,
    [Parameter(Mandatory=$True)]
    [String]$PullServerRegKey,
    [Parameter(Mandatory=$True)]
    [String]$PullServerURL
) # Params

Set-Location -Path $PSScriptRoot

Write-Verbose 'Constructing SetupLCM DSC Configuration object...'

    $ConfigurationNames = $($ConfigurationNames.Split(',')).Trim()

    [DscLocalConfigurationManager()]
    Configuration SetupLCM 
    {
        Node $env:COMPUTERNAME
        {
            Settings 
            {
                ActionAfterReboot              = 'ContinueConfiguration'
                AllowModuleOverwrite           = $True
                ConfigurationMode              = 'ApplyAndAutoCorrect'
                ConfigurationModeFrequencyMins = 15
                RebootNodeIfNeeded             = $True
                RefreshFrequencyMins           = 30 
                RefreshMode                    = 'PULL'
            } # Settings

            ConfigurationRepositoryWeb AzureAutomationDSC
            {
                ConfigurationNames = $ConfigurationNames
                RegistrationKey    = $PullServerRegKey
                ServerUrl          = $PullServerURL 
            } # Azure Automatio nDSC Pull Server

            ResourceRepositoryWeb AzureAutomationDSC
            {
                RegistrationKey = $PullServerRegKey
                ServerUrl       = $PullServerURL
            } # Azure Automation DSC Respository

            ReportServerWeb AzureAutomationDSC
            {
                RegistrationKey = $PullServerRegKey
                ServerUrl       = $PullServerURL
             
            } # Azure Automation DSC Report Server
        } # Node
    } # Configuration SetupLCM

Write-Verbose 'DONE!'
Write-Verbose ''
Write-Verbose 'Executing SetupLCM DSC Configuration object...'

    if ($PSCmdlet.ShouldProcess('SetupLCM DSC Configuration', 'Executing'))
    {
        try
        {
            SetupLCM
        } # try

        catch
        {
            Write-Host -ForegroundColor Red "`tFailed to execute SetupLCM DSC Configuration!"
            Write-Host -ForegroundColor Red "`tError details: $($Error[0].Exception)"
            Write-Host -ForegroundColor Red "`tABORTING!"
            break
        } # catch
    } # if

Write-Verbose 'DONE!'
Write-Verbose ''
Write-Verbose 'Applying SetupLCM DSC Configuration to self...'

    if ($PSCmdlet.ShouldProcess('SetupLCM DSC Configuration', 'Applying'))
    {
        try
        {
            Set-DSCLocalConfigurationManager –Path .\SetupLCM –Verbose -ErrorAction Stop
        } # try

        catch
        {
            Write-Host -ForegroundColor Red "`tFailed to apply SetupLCM DSC Configuration to self!"
            Write-Host -ForegroundColor Red "`tError details: $($Error[0].Exception)"
            Write-Host -ForegroundColor Red "`tABORTING!"
            break
        } # catch
    } # if

Write-Verbose 'DONE!'

# The below is to give some breathing space for config to be properly pulled down from Automation DSC
Start-Sleep -Seconds 30