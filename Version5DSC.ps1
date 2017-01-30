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
<#
Write-Verbose ''
Write-Verbose 'Setting culture to en-GB for proper date format...'

    try
    {
        Set-WinSystemLocale -SystemLocale en-GB -ErrorAction Stop
        Set-Culture -CultureInfo en-GB -ErrorAction Stop
    } # try

    catch
    {
        Write-Host -ForegroundColor Red "`tFailed to set culture to en-GB!"
        Write-Host -ForegroundColor Red "`tError details: $($Error[0].Exception)"
    } # catch

Write-Verbose 'DONE!'
Write-Verbose ''
#>
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
Write-Verbose ''
Write-Verbose 'Creating ReRegisterLCM scheduled task...'

    $Command = @"
schtasks /CREATE /RU "SYSTEM" /SC ONEVENT /TN "ReRegisterLCM" /TR "C:\cfn\DSC\ReRegisterLCM.bat" /F /RL HIGHEST /EC "Microsoft-Windows-DSC/Operational" /MO "*[System[Provider[@Name='Microsoft-Windows-DSC'] and EventID=4260]]"
"@
    try
    {
        #Set-Content -Path C:\cfn\DSC\ReRegisterLCM.bat -Value "powershell -command `"& {Stop-DscConfiguration -Force; `$Stages = 'Current', 'Previous', 'Pending'; foreach (`$Stage in `$Stages) {Remove-DscConfigurationDocument -Stage `$Stage -Force}; Set-DscLocalConfigurationManager -Path C:\cfn\DSC\SetupLCM\ -Force}`"" -Force -ErrorAction Stop
        Set-Content -Path C:\cfn\DSC\ReRegisterLCM.bat -Value 'powershell -command "& {Set-DscLocalConfigurationManager -Path C:\cfn\DSC\SetupLCM\ -Force; Remove-DscConfigurationDocument -Stage Current -Force}"' -Force -ErrorAction Stop
    } # try

    catch
    {
        Write-Host -ForegroundColor Red "`tFailed to create ReRegisterLCM scheduled task's script file!"
        Write-Host -ForegroundColor Red "`tError details: $($Error[0].Exception)"
        Write-Host -ForegroundColor Red "`tABORTING!"
        break
    } # catch

    try
    {
        Invoke-Expression -Command $Command -ErrorAction Stop
    } # try

    catch
    {
        Write-Host -ForegroundColor Red "`tFailed to create ReRegisterLCM scheduled task!"
        Write-Host -ForegroundColor Red "`tError details: $($Error[0].Exception)"
    } # catch

Write-Verbose 'DONE!'

<#
Write-Verbose 'Waiting for the initial DSC registration and config apply to complete...'
Write-Verbose ''
    Write-Verbose "`tInitializing 'Microsoft-Windows-DSC/Operational' EventLog for this PoSh session..."

        try
        {
            New-EventLog -LogName 'Microsoft-Windows-DSC/Operational' -Source 'Desired State Configuration' -ErrorAction Stop
        } # try

        catch
        {
            Write-Host -ForegroundColor Red "`tFailed to initialize 'Microsoft-Windows-DSC/Operational' EventLog!"
            Write-Host -ForegroundColor Red "`tError details: $($Error[0].Exception)"
            Write-Host -ForegroundColor Red "`tABORTING!"
            break
        } # catch

    Write-Verbose "`tDONE!"
Write-Verbose ''

    do
    {
        Start-Sleep -Seconds 1
    } # do

    while
    (
        [bool]!(Get-EventLog -LogName 'Microsoft-Windows-DSC/Operational' -InstanceId 1 -Message *complete* -Newest 1)
    ) # while

    $CurrentTime = $(Get-EventLog -LogName 'Microsoft-Windows-DSC/Operational' -InstanceId 1 -Message *complete* -Newest 1).TimeWritten

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
<#
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
    #>
    <#
    try
    {
        Set-DSCLocalConfigurationManager –Path .\SetupLCM -Force –Verbose -ErrorAction Stop
    } # try

    catch
    {
        Write-Host -ForegroundColor Red "`tFailed to re-register with DSC!"
        Write-Host -ForegroundColor Red "`tError details: $($Error[0].Exception)"
    } # catch
#>
#Write-Verbose 'DONE!'

# The below is to give some breathing space for config to be properly pulled down from Automation DSC
#Start-Sleep -Seconds 30