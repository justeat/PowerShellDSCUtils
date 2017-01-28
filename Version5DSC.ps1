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
        $CurrentTime = Get-Date
        
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
Write-Verbose ''
Write-Verbose 'Waiting for the initial DSC registration to complete...'

    do
    {
        Start-Sleep -Seconds 1
    } # do

    while
    (
        [bool]!(Get-EventLog -LogName 'Microsoft-Windows-DSC/Operational' -InstanceId 4270 -Newest 1 -After $CurrentTime)
    ) # while

Write-Verbose 'DONE!'
Write-Verbose ''
Write-Verbose 'Re-registering with DSC to ensure proper workflow from now on...'

    if (Test-Path -Path 'C:\Windows\System32\Configuration\DSCEngineCache.mof')
    {
        Write-Verbose ''
        Write-Verbose "`tCached DSC Engine MOF found, going to remove it..."
        
            try
            {
                Remove-Item -Path 'C:\Windows\System32\Configuration\DSCEngineCache.mof' -Force -ErrorAction Stop
            } # try

            catch
            {
                Write-Host -ForegroundColor Red "`tFailed to remove cached DSC Engine MOF!"
                Write-Host -ForegroundColor Red "`tError details: $($Error[0].Exception)"
                Write-Host -ForegroundColor Red "`tABORTING!"
                break
            } # catch

        Write-Verbose "`tDONE!"
        Write-Verbose ''
    } # if

    try
    {
        Set-DSCLocalConfigurationManager –Path .\SetupLCM -Force –Verbose -ErrorAction Stop
    } # try

    catch
    {
        Write-Host -ForegroundColor Red "`tFailed to re-register with DSC!"
        Write-Host -ForegroundColor Red "`tError details: $($Error[0].Exception)"
    } # catch

Write-Verbose 'DONE!'

# The below is to give some breathing space for config to be properly pulled down from Automation DSC
#Start-Sleep -Seconds 30