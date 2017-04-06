<#
    NOTE FOR AZURE AUTOMATION DSC CLIENTS:

    Partial Configs are NOT supported yet. Same should be true for Composite resources,
    but actually isn't - they work as expected, due to this:

    "(...) However, DSC composite resources can be imported and used in Azure Automation DSC Configurations like in local PowerShell, enabling configuration reuse."

    SOURCE: https://docs.microsoft.com/en-us/azure/automation/automation-dsc-overview

    Anyway, I've added the functionality (partial configs) for future use

    Cheers,
    Rad
#>


[cmdletbinding(SupportsShouldProcess=$True)]
Param 
(
    [Parameter(Mandatory=$True)]
    [String[]]$ConfigurationNames,
    [Parameter(Mandatory=$True)]
    [String]$PullServerRegKey,
    [Parameter(Mandatory=$True)]
    [String]$PullServerURL
) # Params

Set-Location -Path $PSScriptRoot

Write-Verbose 'Constructing SetupLCM DSC Configuration object...'

    #$ConfigurationNames = $($ConfigurationNames.Split(',')).Trim()

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
                ConfigurationModeFrequencyMins = 60
                RebootNodeIfNeeded             = $True
                RefreshFrequencyMins           = 60 
                RefreshMode                    = 'PULL'
            } # Settings

            ConfigurationRepositoryWeb AzureAutomationDSC
            {
                ConfigurationNames = $ConfigurationNames
                RegistrationKey    = $PullServerRegKey
                ServerUrl          = $PullServerURL 
            } # Azure Automatio nDSC Pull Server

            if ($ConfigurationNames.Count -gt 1)
            {
                foreach ($ConfigurationName in $ConfigurationNames)
                {
                    PartialConfiguration $ConfigurationName 
                    {
                        Description         = "$ConfigurationName"
                        ConfigurationSource = @("[ConfigurationRepositoryWeb]AzureAutomationDSC") 
                    } # Partial config
                } # foreach
            } # if

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
Write-Verbose ''
Write-Verbose 'Creating ReRegisterLCM scheduled task...'

    $Command = @"
schtasks /CREATE /RU "SYSTEM" /SC ONEVENT /TN "ReRegisterLCM" /TR "C:\cfn\DSC\ReRegisterLCM.bat" /F /RL HIGHEST /EC "Microsoft-Windows-DSC/Operational" /MO "*[System[Provider[@Name='Microsoft-Windows-DSC'] and EventID=4260]]"
"@
    try
    {
        Set-Content -Path C:\cfn\DSC\ReRegisterLCM.bat -Value 'powershell -command "& {Set-DscLocalConfigurationManager -Path C:\cfn\DSC\SetupLCM\ -Force}"' -Force -ErrorAction Stop
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