[cmdletbinding(SupportsShouldProcess=$True)]
Param 
(
    [Parameter(Mandatory=$True)]
    [string]$ConfigurationIDGUID,
    [Parameter(Mandatory=$True)]
    [string]$PullServerURL,
    [Parameter(Mandatory=$True)]
    [string]$ThumbPrint
) # Params

Set-Location "$PSScriptRoot"

Write-Verbose 'Constructing SetupLCM DSC Configuration object...'

    [DSCLocalConfigurationManager()]    Configuration SetupLCM    {        Settings        {            AllowModuleOverwrite  = $True            CertificateID = "$ThumbPrint"            ConfigurationID = $ConfigurationIDGUID            ConfigurationMode = 'ApplyAndAutoCorrect'            RebootNodeIfNeeded = $True            RefreshFrequencyMins = 15            RefreshMode = 'PULL'        } # Settings        ConfigurationRepositoryWeb PullServerDetails        {            CertificateID = "$ThumbPrint"            ServerUrl = "$PullServerURL"        } # PullServerDetails    } # Configuration SetupLCM

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