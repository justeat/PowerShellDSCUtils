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
    <#
    $Helper = '@('

        foreach ($ConfigurationName in $ConfigurationNames)
        {
            $Helper += "'$ConfigurationName',"
        } # foreach

    $Helper += ')'
    
    $ConfigurationNames = $null
    $ConfigurationNames = $Helper.Replace(',)',')')
    $ConfigurationNames | Out-File -FilePath C:\DSC\helper.txt
    #>
    [DscLocalConfigurationManager()]
    Configuration SetupLCM 
    {
        Settings 
        {
            ActionAfterReboot              = 'ContinueConfiguration'
            AllowModuleOverwrite           = $True
            ConfigurationMode              = 'ApplyAndAutoCorrect'
            ConfigurationModeFrequencyMins = 30
            RebootNodeIfNeeded             = $True
            RefreshFrequencyMins           = 30 
            RefreshMode                    = 'PULL'
        } # Settings

        ConfigurationRepositoryWeb AzureAutomationDSCPullServer
        {
            ConfigurationNames = $ConfigurationNames
            RegistrationKey    = $PullServerRegKey
            ServerUrl          = $PullServerURL 
        } # AzureAutomationDSCPullServer

        ResourceRepositoryWeb AzureAutomationDSCReportServer
        {
            RegistrationKey = $PullServerRegKey
            ServerUrl       = $PullServerURL
        } # AzureAutomationDSCReportServer
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