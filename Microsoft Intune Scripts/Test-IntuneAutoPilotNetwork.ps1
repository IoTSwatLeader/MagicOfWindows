#Description: Writes a message including Timestamp and Severity to a log file
#Function Data:
#   Name:           Write-Log
#   Parameters:     LogFile, Level, Message
#   Returns:        None
Function Write-Log 
{
    <#
        .SYNOPSIS
        Write Log File

        .DESCRIPTION
        Writes a message including Timestamp and Severity to a log file.

        .PARAMETER Level
        Specifies the Severity of the Message.
        Possible Values: INFO, WARN, ERROR, FATAL, DEBUG, TRACE

        .PARAMETER LogFile
        Specifies the LogFile Path

        .PARAMETER Message
        Specifies the Message

        .INPUTS
        None.

        .OUTPUTS
        None.
        Log File Appended

        .LINK
        None.

        .EXAMPLE
        Write-Log -Message "Text" 

        .EXAMPLE
        Write-Log -Message "Text" -Level WARN 

        .EXAMPLE
        Write-Log -Message "Text" -Level WARN -LogFile "%Temp%\Logfile.log"
    #>

    [CmdletBinding()]

    Param(
        [Parameter(Mandatory=$False)]
        [string]
        $LogFile = $global:LogFile,

        [Parameter(Mandatory=$False)]
        [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG","TRACE")]
        [String]
        $Level = "INFO",

        [Parameter(Mandatory=$True)]
        [string]
        $Message
    )

    #Internal Declarations and Definition Updates
    $private:Stamp        = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $private:HeaderString = "Timestamp".PadRight(22, ' ') + "Level".PadRight(10, ' ')  + "Message".PadRight(60,' ')
    $private:LineString   = $private:Stamp.PadRight(22, ' ') + $Level.PadRight(10, ' ') + $Message.PadRight(60,' ')

    #Verify if Log File already exists
    try 
    {
        If(Test-Path $LogFile) 
        {
            #Writing to Log File
            Add-Content -Path $LogFile -Value $private:LineString
        }
        Else 
        {
            #Writing to Log File including Header Line
            Add-Content -Path $LogFile -Value $private:HeaderString -ErrorAction Stop
            Add-Content -Path $LogFile -Value $private:LineString -ErrorAction Stop
        }
    }
    catch
    { 
        #Debug Output
        Write-Log -Level FATAL DEBUG -Message  "  -> Log File Issue" 
        Write-Log -Level FATAL DEBUG -Message ("     Exception: " + $_.Exception.Message)   
    }        

    #Writing to Debug Window
    if($global:DebugMode)
    {
        Write-Host $private:LineString
    }
}

#Description: Test the network connection to the endpoint
#Function Data:
#   Name:           Test-NetworkConnection
#   Parameters:     Endpoint
#   Returns:        None
Function Test-NetworkConnection
{
    <#
        .SYNOPSIS
        Test the network connection to the endpoint 

        .DESCRIPTION
        Test the network connection to the endpoint

        .PARAMETER Endpoint
        Endpoint definition

        .INPUTS
        None.

        .OUTPUTS
        None.
        Log File Appended

        .LINK
        None.

        .EXAMPLE
        Test-NetworkConnection -Endpoint <$EndpointEntry>
    #>

    [CmdletBinding()]

    Param(
        [Parameter(Mandatory=$True)]
        $Endpoint 
    )

    foreach($URL in $Endpoint.urls)
    {
        if ($URL.Length -gt 0)
        {
            $URL = $URL -replace "^[-=*.]*",""

            if($Endpoint.tcpPorts.length -gt 0)
            {
                foreach($TCP in $Endpoint.tcpPorts.split(","))
                {
                    $TestContainer = Test-NetworkPortTCP -URL $URL -Port $TCP
                    if($TestContainer.ReturnCode -eq 0)
                    {
                        Write-Log -Level INFO -Message ("PASS: " + $TestContainer.URL + " [TCP Port: " + $TestContainer.Port + "]")
                    }
                    elseif ($TestContainer.ReturnCode -eq 1)
                    {
                        Write-Log -Level ERROR -Message ("FAIL: " + $TestContainer.URL + " [TCP Port: " + $TestContainer.Port + "]  [Warning Message: " + $TestContainer.WarningMessage + "]")
                        Write-Log -Level ERROR -LogFile $global:LogFile_FAILED -Message ("FAIL: " + $TestContainer.URL + " [TCP Port: " + $TestContainer.Port + "]  [Warning Message: " + $TestContainer.WarningMessage + "]")
                    }
                    else 
                    {
                        Write-Log -Level ERROR -Message ("CRITICAL: " + $TestContainer.URL + " [TCP Port: " + $TestContainer.Port + "]  [Exception Message: " + $TestContainer.ExceptionMessage + "]")
                        Write-Log -Level ERROR -LogFile $global:LogFile_CRITICAL -Message ("CRITICAL: " + $TestContainer.URL + " [TCP Port: " + $TestContainer.Port + "]  [Exception Message: " + $TestContainer.ExceptionMessage + "]")
                    }
                }
            }

            if($Endpoint.UDPPorts.Length -gt 0)
            {
                Write-Log -Level WARN -Message "UDP verification not implemented!"
            }
        }
    }
}


#Description: Test the network port (TCP)
#Function Data:
#   Name:           Test-NetworkPortTCP
#   Parameters:     URL, Port
#   Returns:        None
Function Test-NetworkPortTCP
{
    <#
        .SYNOPSIS
        Test the network port

        .DESCRIPTION
        Test the network port for availability

        .PARAMETER URL
        URL of the endpoint location

        .PARAMETER Port
        Port to be used for testing

        .INPUTS
        None.

        .OUTPUTS
        Returns the message

        .LINK
        None.

        .EXAMPLE
        Test-NetworkPort -URL <$URL> -Port <$Port>
    #>
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory=$True)]
        [string]
        $URL,

        [Parameter(Mandatory=$True)]
        [int]
        $Port
    )

    #Internal Declarations and Definition Updates
    $WarnMsg = [String]::Empty
    $ExceptionMsg = [String]::Empty
    $ReturnCode = 0

    #Evaluation process
    try
    {
        
        if (Test-NetConnection -ComputerName $URL -Port $Port -InformationLevel Quiet -ErrorAction Stop -WarningVariable WarnMsg -WarningAction SilentlyContinue)
        {
            $ReturnCode = 0
        }
        else
        {
            $ReturnCode = 1
        }
    }
    catch 
    { 
        $ReturnCode = 2
        $ExceptionMsg = $_.Exception.Message
    }
    finally {}

    #Prepare the Custom PSObject for Returning the Validation Data
    $private:Result = [pscustomobject]@{
        URL              = $URL
        Port             = $Port
        ExceptionMessage = $ExceptionMsg
        WarningMessage   = $WarnMsg
        ReturnCode       = $ReturnCode
        }

    #Returning Value
    return $private:Result
}

#Description: Add a Custom Connection Endpoint
#Function Data:
#   Name:           Add-ConnectionEndpoint
#   Parameters:     ID
#                   ServiceArea
#                   ServiceAreaDisplayName
#                   URLs
#                   TCPPorts (separated by ",")
#                   UDPPorts (separated by ",")
#                   Notes
#   Returns:        Custom PSObject
Function Add-ConnectionEndpoint
{
    <#
        .SYNOPSIS
        Add a Custom Connection Endpoint

        .DESCRIPTION
        Add a Custom Connection Endpoint

        .PARAMETER ID
        ID of the Entry

        .PARAMETER ServiceArea
        ServiceArea definition

        .PARAMETER ServiceAreaDisplayName
        Display Name of the entries area

        .PARAMETER URL
        URL to monitor

        .PARAMETER TCPPorts
        TCP Ports separated by ","

        .PARAMETER UDPPorts
        UDPPorts separated by ","

        .PARAMETER Notes
        Notes for this entry

        .OUTPUTS
        Custom Object with the custom connection endpoint

        .LINK
        None.

        .EXAMPLE
        Add-ConnectionEndpoint -ID <...> -ServiceArea <...> -ServiceAreaDisplayName <...> -URL <...> -TCPPorts <...> -UDPPorts <...> -Notes <...>
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [int]
        $ID,

        [Parameter(Mandatory=$True)]
        [String]
        $ServiceArea,

        [Parameter(Mandatory=$True)]
        [String]
        $ServiceAreaDisplayName,

        [Parameter(Mandatory=$True)]
        [string]
        $URLs,

        [Parameter(Mandatory=$True)]
        [string]
        [AllowEmptyString()]
        $TCPPorts,

        [Parameter(Mandatory=$True)]
        [string]
        [AllowEmptyString()]
        $UDPPorts,

        [Parameter(Mandatory=$True)]
        [string]
        [AllowEmptyString()]
        $Notes
    )

    #internal declarations
    $private:data = New-Object PSCustomObject

    #adding the values
    $private:data | Add-Member -type NoteProperty -Name ID -Value $ID
    $private:data | Add-Member -type NoteProperty -Name ServiceArea -Value $ServiceArea
    $private:data | Add-Member -type NoteProperty -Name ServiceAreaDisplayName -Value $ServiceAreaDisplayName
    $private:data | Add-Member -type NoteProperty -Name URLs -Value $URLs
    $private:data | Add-Member -type NoteProperty -Name TCPPorts -Value $TCPPorts
    $private:data | Add-Member -type NoteProperty -Name UDPPorts -Value $UDPPorts
    $private:data | Add-Member -type NoteProperty -Name Notes -Value $Notes
    
    #Return Data
    return $private:data
}

#########################################################################################################################################
####                                               P R O G R A M    I N T E R N A L S                                                 ###
#########################################################################################################################################

#Error Handling 
$ErrorActionPreference              = "Stop"                                                        # Stop on every error

#Script Information
$global:ScriptVersion               = "1.0"


#########################################################################################################################################
####                                                P R O G R A M    P A R A M E T E R S                                              ###
#########################################################################################################################################

#Debug Mode
$global:DebugMode                   = $true                                                         # Show Errors in Console ($true)

#Log File Paths
$global:LogFilePath                 = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\"  # log file path
$global:LogFile                     = (Join-Path -Path ([System.Environment]::ExpandEnvironmentVariables(($global:LogFilePath))).toString() -ChildPath ((Get-Date).ToString('yyyy-MM-dd') + "-Test-AutopilotNetwork.log").toString())
$global:LogFile_FAILED              = (Join-Path -Path ([System.Environment]::ExpandEnvironmentVariables(($global:LogFilePath))).toString() -ChildPath ((Get-Date).ToString('yyyy-MM-dd') + "-Test-AutopilotNetwork-FAILED.log").toString())
$global:LogFile_CRITICAL            = (Join-Path -Path ([System.Environment]::ExpandEnvironmentVariables(($global:LogFilePath))).toString() -ChildPath ((Get-Date).ToString('yyyy-MM-dd') + "-Test-AutopilotNetwork-CRITICAL.log").toString())


#########################################################################################################################################
####                                      P R O G R A M    S T A R T U P   S P O T L I G H T                                          ###
#########################################################################################################################################

#Program Start
$Starttime = Get-Date

#Debug Output of Program Start
Write-Log -Level INFO -Message "##########################################################################################################################################################"
Write-Log -Level INFO -Message "####                                            P R O G R A M    S E Q U E N C E   S T A R T                                                           ###"
Write-Log -Level INFO -Message "##########################################################################################################################################################"
Write-Log -Level INFO -Message "Microsoft Intune Connection Tester"
Write-Log -Level INFO -Message ("  --> Script Version                : " + $global:ScriptVersion)
if ([string]::IsNullOrWhiteSpace($global:ProcessInfo.ParentProcessName)) 
{
    Write-Log -Level INFO -Message ("  --> Script Calling Instance       : Direct / Commandline")
}
else
{      
    Write-Log -Level INFO -Message ("  --> Script Calling Instance       : " + $global:ProcessInfo.ParentProcessName + " [ID: " + $global:ProcessInfo.ParentProcessID + "]")
}
Write-Log -Level INFO -Message ("  --> Logging Capabilities")
Write-Log -Level INFO -Message ("      --> Central Log File          : " + $global:LogFile)

#Get the CSV with Connection Endpoints
Write-Log -Level DEBUG -Message "##########################################################################################################################################################"
Write-Log -Level DEBUG -Message "####                                                       Custom Connection Endpoints                                                                 ###"
Write-Log -Level DEBUG -Message "##########################################################################################################################################################"
$ConnectionEndpoints = @()
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 001 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Autopilot Deployment Service" -URLs "ztd.dds.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 002 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Autopilot Deployment Service" -URLs "cs.dds.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 003 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Autopilot Deployment Service" -URLs "login.live.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 004 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Activation" -URLs "activation.sls.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 005 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Activation" -URLs "crl.microsoft.com/pki/crl/products/MicProSecSerCA_2007-12-04.crl" -TCPPorts "80" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 006 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Activation" -URLs "validation.sls.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 007 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Activation" -URLs "validation-v2.sls.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 008 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Activation" -URLs "activation-v2.sls.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 009 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Activation" -URLs "displaycatalog.mp.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 010 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Activation" -URLs "displaycatalog.md.mp.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 011 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Activation" -URLs "licensing.mp.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 012 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Activation" -URLs "licensing.md.mp.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 013 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Activation" -URLs "purchase.mp.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 014 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Activation" -URLs "purchase.md.mp.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 015 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Update for Business" -URLs "tsfe.trafficshaping.dsp.mp.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 016 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Windows Time" -URLs "time.windows.com" -TCPPorts "" -UDPPorts "123" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 017 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Diagnostic Data" -URLs "settings-win.data.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 018 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Store for Business" -URLs "login.windows.net" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 019 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Store for Business" -URLs "account.live.com" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 020 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Store for Business" -URLs "clientconfig.passport.net" -TCPPorts "443" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 021 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Store for Business" -URLs "www.msftncsi.com" -TCPPorts "80" -UDPPorts "" -Notes ""
$ConnectionEndpoints += Add-ConnectionEndpoint -ID 022 -ServiceArea "Custom Connection Endpoint" -ServiceAreaDisplayName "Store for Business" -URLs "www.msftconnecttest.com/connecttest.txt" -TCPPorts "80" -UDPPorts "" -Notes ""
#$ConnectionEndpoints | Select-Object id,serviceArea,serviceAreaDisplayName,urls,tcpPorts,udpPorts | FT
foreach ($ConnectionEndpoint in $ConnectionEndpoints)
{
    Write-Log -Level INFO -Message "##########################################################################################################################################################"
    Write-Log -Level INFO -Message ("Rule " + $ConnectionEndpoint.id.ToString() + ": " + $ConnectionEndpoint.serviceArea + " / " + $ConnectionEndpoint.serviceAreaDisplayName)
    Test-NetworkConnection $ConnectionEndpoint
}

#Get the CSV with Windows 11 Endpoints
#https://learn.microsoft.com/en-us/windows/privacy/manage-windows-11-endpoints
Write-Log -Level DEBUG -Message "##########################################################################################################################################################"
Write-Log -Level DEBUG -Message "####                                                    Windows 11 Connection Endpoints                                                                ###"
Write-Log -Level DEBUG -Message "##########################################################################################################################################################"
$Win11Endpoints = @()
$Win11Endpoints += Add-ConnectionEndpoint -ID 001 -ServiceArea "Windows 11 Connection Endpoint" -ServiceAreaDisplayName "Windows 11 Endpoint" -URLs "ztd.dds.microsoft.com" -TCPPorts "443" -UDPPorts "" -Notes ""
#$ConnectionEndpoints | Select-Object id,serviceArea,serviceAreaDisplayName,urls,tcpPorts,udpPorts | FT
foreach ($Win11Endpoint in $Win11Endpoints)
{
    Write-Log -Level INFO -Message "##########################################################################################################################################################"
    Write-Log -Level INFO -Message ("Rule " + $Win11Endpoint.id.ToString() + ": " + $Win11Endpoint.serviceArea + " / " + $Win11Endpoint.serviceAreaDisplayName)
    Test-NetworkConnection $Win11Endpoint
}

#Get the Intune Endpoints
Write-Log -Level DEBUG -Message "##########################################################################################################################################################"
Write-Log -Level DEBUG -Message "####                                                   Microsoft Intune Endpoints Rules                                                                ###"
Write-Log -Level DEBUG -Message "##########################################################################################################################################################"
$IntuneEndpoints = (invoke-restmethod -Uri ("https://endpoints.office.com/endpoints/WorldWide?ServiceAreas=MEM`&`clientrequestid=" + ([GUID]::NewGuid()).Guid))
#$IntuneEndpoints | Select-Object id,serviceArea,serviceAreaDisplayName,urls,tcpPorts,udpPorts | FT
foreach ($IntuneEndpoint in $IntuneEndpoints)
{
    Write-Log -Level INFO -Message "##########################################################################################################################################################"
    Write-Log -Level INFO -Message ("Rule " + $IntuneEndpoint.id.ToString() + ": " + $IntuneEndpoint.serviceArea + " / " + $IntuneEndpoint.serviceAreaDisplayName)
    Test-NetworkConnection $IntuneEndpoint
}

#Get the M365 Endpoints (https://learn.microsoft.com/en-us/autopilot/networking-requirements)
Write-Log -Level DEBUG -Message "##########################################################################################################################################################"
Write-Log -Level DEBUG -Message "####                                                    Microsoft M365 Endpoints Rules                                                                 ###"
Write-Log -Level DEBUG -Message "##########################################################################################################################################################"
$M365Endpoints   = (invoke-restmethod -Uri ("https://endpoints.office.com/endpoints/worldwide?clientrequestid=b10c5ed1-bad1-445f-b386-b919946339a7"))
#$M365Endpoints | Select-Object id,serviceArea,serviceAreaDisplayName,urls,tcpPorts,udpPorts | FT
foreach ($M365Endpoint in $M365Endpoints)
{
    Write-Log -Level INFO -Message "##########################################################################################################################################################"
    Write-Log -Level INFO -Message ("Rule " + $M365Endpoint.id.ToString() + ": " + $M365Endpoint.serviceArea + " / " + $M365Endpoint.serviceAreaDisplayName)
    Test-NetworkConnection $M365Endpoint
}

#Program End
$Endtime = Get-Date
$Duration = $Endtime - $Starttime
Write-Log -Level INFO -Message "Program Sequence End [Duration: $Duration]" 