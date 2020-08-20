# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
# Header

<#
    .SYNOPSIS
        Automatically creates a STIG Viewer checklist from DSC results (DscResults) or a compiled MOF (MofFile) parameter for a single endpoint. 
        The function will test based upon the passed in STIG file (XccdfPath) or files (ChecklistSTIGFiles) parameter.
        Manual entries in the checklist can be injected from a ManualCheckListEntries file.

    .PARAMETER MofFile
        A MOF that was compiled with a PowerStig composite.

    .PARAMETER DscResults
        The results of Test-DscConfiguration or DSC report server output for a node.

    .PARAMETER XccdfPath
        The path to a DISA STIG .xccdf file. PowerSTIG includes the files in the /PowerShell/StigData/Archive folder.

    .PARAMETER ChecklistSTIGFiles 
        A file that contains a list of STIG Xccdf files to use for the checklist output. This is a simple list of the paths to STIGs that should be checked.
        See a sample at /PowerShell/StigData/Samples/ChecklistSTIGFiles.txt.
        
    .PARAMETER OutputPath
        The location where the checklist .ckl file will be created.

    .PARAMETER ManualChecklistEntries
        Location of a .psd1 file containing the input for Vulnerabilities unmanaged via DSC/PowerSTIG.

        This file can be created manually or by exporting an Excel worksheet as XML. The file format should look like the following:

        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <ManualChecklistEntries xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <VulID id="V-79119" Status="NotAFinding">
                <Details>See System Security Document.</Details>
                <Comments>This is a test of a manual check file entry.</Comments>
            </VulID>
        </ManualChecklistEntries>
        
        See a sample at /PowerShell/StigData/Samples/ManualCheckListEntriesExcelExport.xml.

    .EXAMPLE
        Generate a checklist for single STIG using a .MOF file:
        
        $MofFile = 'C:\contoso.local.mof'
        $xccdfPath = 'C:\SQL Server\U_MS_SQL_Server_2016_Instance_STIG_V1R7_Manual-xccdf.xml'
        $outputPath = 'C:\SqlServerInstance_2016_V1R7_STIG_config_mof.ckl'
        $ManualChecklistEntriesFile = 'C:\ManualCheckListEntriesExcelExport.xml'
        New-StigCheckList -MofFile $MofFile -XccdfPath $XccdfPath -OutputPath $outputPath -ManualChecklistEntries $ManualChecklistEntriesFile
    
    .EXAMPLE
        Generate a checklist for a single STIG using DSC results obtained from Test-DscConfiguration:

        $audit = Test-DscConfiguration -ComputerName localhost -MofFile 'C:\Dev\Utilities\SqlServerInstance_config\localhost.mof'
        $xccdfPath = 'C:\U_MS_SQL_Server_2016_Instance_STIG_V1R7_Manual-xccdf.xml'
        $outputPath = 'C:\SqlServerInstance_2016_V1R7_STIG_config_dscresults.ckl'
        $ManualChecklistEntriesFile = 'C:\ManualCheckListEntriesSQL2016Instance.xml'
        New-StigCheckList -DscResult $audit -XccdfPath $xccdfPath -OutputPath $outputPath -ManualChecklistEntries $ManualChecklistEntriesFile 

    .EXAMPLE
        Generate a checklist for multiple STIGs for an endpoint using a .MOF file:

        $MofFile = 'C:\contoso.local.mof'
        $ChecklistSTIGFiles = 'C:\ChecklistSTIGFiles.txt'
        $outputPath = 'C:\SqlServer01_mof.ckl'
        $ManualChecklistEntriesFile = 'C:\ManualCheckListEntriesSqlServer01ExcelExport.xml'
        New-StigCheckList -DscResults $auditRehydrated -XccdfPath $XccdfPath -OutputPath $outputPath -ManualChecklistEntries $ManualChecklistEntriesFile

    .EXAMPLE
        Generate a checklist for multiple STIGs for an endpoint using DSC results obtained from Test-DscConfiguration, dehydrated/rehydrated using CLIXML:

        $audit = Test-DscConfiguration -ComputerName localhost -MofFile 'C:\localhost.mof'
        $audit | Export-Clixml 'C:\TestDSC.xml'
        
        $auditRehydrated = import-clixml C:\TestDSC.xml
        $ChecklistSTIGFiles = 'C:\ChecklistSTIGFiles.txt'
        $outputPath = 'C:\SqlServer01_dsc.ckl'
        $ManualChecklistEntriesFile = 'C:\ManualCheckListEntriesSqlServer01ExcelExport.xml'

        New-StigCheckList -DscResults $auditRehydrated -ChecklistSTIGFiles $ChecklistSTIGFiles -OutputPath $outputPath -ManualChecklistEntries $ManualChecklistEntriesFile
#>
function New-StigCheckList
{
    [CmdletBinding()]
    [OutputType([XML])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'single-mof')]
        [Parameter(Mandatory = $true, ParameterSetName = 'multi-mof')]
        [String]
        $MofFile,

        [Parameter(Mandatory = $true, ParameterSetName = 'single-dsc')]
        [Parameter(Mandatory = $true, ParameterSetName = 'multi-dsc')]
        [PSObject]
        $DscResults,

        [Parameter(Mandatory = $true, ParameterSetName = 'single-mof')]
        [Parameter(Mandatory = $true, ParameterSetName = 'single-dsc')]
        [String]
        $XccdfPath,

        [Parameter(Mandatory = $true, ParameterSetName = 'multi-mof')]
        [Parameter(Mandatory = $true, ParameterSetName = 'multi-dsc')]
        [String]
        $ChecklistSTIGFiles,

        [Parameter()]
        [String]
        $ManualChecklistEntries,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        $OutputPath
    )

    # Validate parameters before continuing
    if ($ManualChecklistEntries)
    {
        if (-not (Test-Path -Path $ManualChecklistEntries))
        {
            throw "$($ManualChecklistEntries) is not a valid path to a ManualChecklistEntries.xml file. Provide a full valid path."
        }

        [XML]$manualCheckData = Get-Content -Path $ManualChecklistEntries
    }

    if ($XccdfPath)
    {
        if (-not (Test-Path -Path $XccdfPath))
        {
            throw "$($XccdfPath) is not a valid path to a DISA STIG .xccdf file. Provide a full valid path."
        }

        $checklistSTIGs = $XccdfPath
    }

    if ($ChecklistSTIGFiles)
    {
        if (-not (Test-Path -Path $ChecklistSTIGFiles))
        {
            throw "$($ChecklistSTIGFiles) is not a valid path to a ChecklistSTIGFiles.txt file. Provide a full valid path."
        }

        $checklistSTIGs = Get-Content -Path $ChecklistSTIGFiles
    }

    if (-not (Test-Path -Path $OutputPath.DirectoryName))
    {
        throw "$($OutputPath.DirectoryName) is not a valid directory. Please provide a valid directory."
    }

    if ($OutputPath.Extension -ne '.ckl')
    {
        throw "$($OutputPath.FullName) is not a valid checklist extension. Please provide a full valid path ending in .ckl"
    }

    # Values for some of these fields can be read from the .mof file or the DSC results file
    if ($PSCmdlet.ParameterSetName -eq 'single-mof' -or $PSCmdlet.ParameterSetName -eq 'multi-mof')
    {
        if (-not (Test-Path -Path $MofFile))
        {
            throw "$($MofFile) is not a valid path to a configuration (.mof) file. Please provide a valid entry."
        }

        $mofString = Get-Content -Path $MofFile -Raw
        $targetNode = Get-TargetNodeFromMof -MofString $mofString

    }
    elseif ($PSCmdlet.ParameterSetName -eq 'single-dsc' -or $PSCmdlet.ParameterSetName -eq 'multi-dsc')
    {
        # Check the returned object
        if ($null -eq $DscResults)
        {
            throw 'Passed in $DscResults parameter is null. Please provide a valid result using Test-DscConfiguration.'
        }

        $targetNode = $DscResults.PSComputerName
    }

    $statusMap = @{
        NotReviewed   = 'Not_Reviewed'
        Open          = 'Open'
        NotAFinding   = 'NotAFinding'
        NotApplicable = 'Not_Applicable'
    }

    $targetNodeType = Get-TargetNodeType -TargetNode $targetNode

    switch ($targetNodeType)
    {
        "MACAddress"
        {
            $HostnameMACAddress = $targetNode
            Break
        }
        "IPv4Address"
        {
            $HostnameIPAddress = $targetNode
            Break
        }
        "IPv6Address"
        {
            $HostnameIPAddress = $targetNode
            Break
        }
        "FQDN"
        {
            $HostnameFQDN = $targetNode
            Break
        }
        default
        {
            $Hostname = $targetNode
        }
    }

    $xmlWriterSettings = [System.Xml.XmlWriterSettings]::new()
    $xmlWriterSettings.Indent = $true
    $xmlWriterSettings.IndentChars = "`t"
    $xmlWriterSettings.NewLineChars = "`n"
    $writer = [System.Xml.XmlWriter]::Create($OutputPath.FullName, $xmlWriterSettings)

    $writer.WriteStartElement('CHECKLIST')

    #region ASSET

    $writer.WriteStartElement("ASSET")

    $assetElements = [ordered] @{
        'ROLE'            = 'None'
        'ASSET_TYPE'      = 'Computing'
        'HOST_NAME'       = "$Hostname"
        'HOST_IP'         = "$HostnameIPAddress"
        'HOST_MAC'        = "$HostnameMACAddress"
        'HOST_FQDN'       = "$HostnameFQDN"
        'TECH_AREA'       = ''
        'TARGET_KEY'      = '2350'
        'WEB_OR_DATABASE' = 'false'
        'WEB_DB_SITE'     = ''
        'WEB_DB_INSTANCE' = ''
    }

    foreach ($assetElement in $assetElements.GetEnumerator())
    {
        $writer.WriteStartElement($assetElement.name)
        $writer.WriteString($assetElement.value)
        $writer.WriteEndElement()
    }

    $writer.WriteEndElement(<#ASSET#>)

    #endregion ASSET

    #region STIGS
    $writer.WriteStartElement("STIGS")

    #region STIG_iteration
    foreach ($XccdfPath in $checklistSTIGs)
    {

        $writer.WriteStartElement("iSTIG")

        #region iSTIG/STIG_INFO

        $writer.WriteStartElement("STIG_INFO")

        $xccdfBenchmarkContent = Get-StigXccdfBenchmarkContent -Path $XccdfPath

        $stigInfoElements = [ordered] @{
            'version'        = $xccdfBenchmarkContent.version
            'classification' = 'UNCLASSIFIED'
            'customname'     = ''
            'stigid'         = $xccdfBenchmarkContent.id
            'description'    = $xccdfBenchmarkContent.description
            'filename'       = Split-Path -Path $XccdfPath -Leaf
            'releaseinfo'    = $xccdfBenchmarkContent.'plain-text'.InnerText
            'title'          = $xccdfBenchmarkContent.title
            'uuid'           = (New-Guid).Guid
            'notice'         = $xccdfBenchmarkContent.notice.InnerText
            'source'         = $xccdfBenchmarkContent.reference.source
        }

        foreach ($stigInfoElement in $stigInfoElements.GetEnumerator())
        {
            $writer.WriteStartElement("SI_DATA")
            $writer.WriteStartElement('SID_NAME')
            $writer.WriteString($stigInfoElement.name)
            $writer.WriteEndElement(<#SID_NAME#>)
            $writer.WriteStartElement('SID_DATA')
            $writer.WriteString($stigInfoElement.value)
            $writer.WriteEndElement(<#SID_DATA#>)
            $writer.WriteEndElement(<#SI_DATA#>)
        }

        $writer.WriteEndElement(<#STIG_INFO#>)

        #endregion STIGS/iSTIG/STIG_INFO

        #region STIGS/iSTIG/VULN[]

        # Parse out the STIG file name for lookups
        $stigPathFileName = $XccdfPath.Split('\\')
        $stigFileName = $stigPathFileName[$stigPathFileName.Length-1]

        # Pull in the processed XML file to check for duplicate rules for each vulnerability
        [XML]$xccdfBenchmark = Get-Content -Path $XccdfPath -Encoding UTF8
        $fileList = Get-PowerStigFileList -StigDetails $xccdfBenchmark -Path $XccdfPath
        $processedFileName = $fileList.Settings.FullName
        [XML]$processed = Get-Content -Path $processedFileName

        $vulnerabilities = Get-VulnerabilityList -XccdfBenchmark $xccdfBenchmarkContent

        foreach ($vulnerability in $vulnerabilities)
        {
            $writer.WriteStartElement("VULN")

            foreach ($attribute in $vulnerability.GetEnumerator())
            {
                $status = $null
                $findingDetails = $null
                $comments = $null
                $manualCheck = $null

                if ($attribute.Name -eq 'Vuln_Num')
                {
                    $vid = $attribute.Value
                }

                $writer.WriteStartElement("STIG_DATA")

                $writer.WriteStartElement("VULN_ATTRIBUTE")
                $writer.WriteString($attribute.Name)
                $writer.WriteEndElement(<#VULN_ATTRIBUTE#>)

                $writer.WriteStartElement("ATTRIBUTE_DATA")
                $writer.WriteString($attribute.Value)
                $writer.WriteEndElement(<#ATTRIBUTE_DATA#>)

                $writer.WriteEndElement(<#STIG_DATA#>)
            }

            if ($PSCmdlet.ParameterSetName -eq 'single-mof' -or $PSCmdlet.ParameterSetName -eq 'multi-mof')
            {
                $setting = Get-SettingsFromMof -MofFile $MofFile -Id $vid
                $manualCheck = $manualCheckData.stigManualChecklistData.stigRuleData | Where-Object {$_.STIG -eq $stigFileName -and $_.ID -eq $vid}

                if ($setting)
                {
                    $status = $statusMap['NotAFinding']
                    $comments = "To be addressed by PowerStig MOF via $setting"
                    $findingDetails = Get-FindingDetails -Setting $setting

                }
                elseif ($manualCheck)
                {
                    $status = $statusMap["$($manualCheck.Status)"]
                    $findingDetails = $manualCheck.Details
                    $comments = $manualCheck.Comments
                }
                else
                {
                    $status = $statusMap['NotReviewed']
                }
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'single-dsc' -or $PSCmdlet.ParameterSetName -eq 'multi-dsc')
            {
                $manualCheck = $manualCheckData.stigManualChecklistData.stigRuleData | Where-Object {$_.STIG -eq $stigFileName -and $_.ID -eq $vid}
                if ($manualCheck)
                {
                    $status = $statusMap["$($manualCheck.Status)"]
                    $findingDetails = $manualCheck.Details
                    $comments = $manualCheck.Comments
                }
                else
                {
                    $setting = Get-SettingsFromResult -DscResults $DscResults -Id $vid
                    if ($setting)
                    {
                        if ($setting.InDesiredState -eq $true)
                        {
                            $status = $statusMap['NotAFinding']
                            $comments = "Addressed by PowerStig MOF via $setting"
                            $findingDetails = Get-FindingDetails -Setting $setting
                        }
                        elseif ($setting.InDesiredState -eq $false)
                        {
                            $status = $statusMap['Open']
                            $comments = "Configuration attempted by PowerStig MOF via $setting, but not currently set."
                            $findingDetails = Get-FindingDetails -Setting $setting
                        }
                        else
                        {
                            $status = $statusMap['Open']
                        }
                    }
                    else
                    {
                        $status = $statusMap['NotReviewed']
                    }
                }
            }

            # Test to see if this rule is managed as a duplicate
            $convertedRule = $processed.SelectSingleNode("//Rule[@id='$vid']")

            if ($convertedRule.DuplicateOf)
            {
                # How is the duplicate rule handled? If it is handled, then this duplicate should have the same status
                if ($PSCmdlet.ParameterSetName -eq 'mof')
                {
                    $originalSetting = Get-SettingsFromMof -MofFile $MofFile -Id $convertedRule.DuplicateOf

                    if ($originalSetting)
                    {
                        $status = $statusMap['NotAFinding']
                        $findingDetails = 'See {0} for Finding Details.' -f $convertedRule.DuplicateOf
                        $comments = 'Managed via PowerStigDsc - this rule is a duplicate of {0}' -f $convertedRule.DuplicateOf
                    }
                }
                elseif ($PSCmdlet.ParameterSetName -eq 'result')
                {
                    $originalSetting = Get-SettingsFromResult -DscResults $DscResults -id $convertedRule.DuplicateOf

                    if ($originalSetting.InDesiredState -eq 'True')
                    {
                        $status = $statusMap['NotAFinding']
                        $findingDetails = 'See {0} for Finding Details.' -f $convertedRule.DuplicateOf
                        $comments = 'Managed via PowerStigDsc - this rule is a duplicate of {0}' -f $convertedRule.DuplicateOf
                    }
                    else
                    {
                        $status = $statusMap['Open']
                        $findingDetails = 'See {0} for Finding Details.' -f $convertedRule.DuplicateOf
                        $comments = 'Managed via PowerStigDsc - this rule is a duplicate of {0}' -f $convertedRule.DuplicateOf
                    }
                }
            }

            $writer.WriteStartElement("STATUS")
            $writer.WriteString($status)
            $writer.WriteEndElement(<#STATUS#>)

            $writer.WriteStartElement("FINDING_DETAILS")
            $writer.WriteString($findingDetails)
            $writer.WriteEndElement(<#FINDING_DETAILS#>)

            $writer.WriteStartElement("COMMENTS")
            $writer.WriteString($comments)
            $writer.WriteEndElement(<#COMMENTS#>)

            $writer.WriteStartElement("SEVERITY_OVERRIDE")
            $writer.WriteString('')
            $writer.WriteEndElement(<#SEVERITY_OVERRIDE#>)

            $writer.WriteStartElement("SEVERITY_JUSTIFICATION")
            $writer.WriteString('')
            $writer.WriteEndElement(<#SEVERITY_JUSTIFICATION#>)

            $writer.WriteEndElement(<#VULN#>)
        }

        #endregion STIGS/iSTIG/VULN[]

        $writer.WriteEndElement(<#iSTIG#>)
    }

    #endregion STIG_iteration

    $writer.WriteEndElement(<#STIGS#>)

    #endregion STIGS

    $writer.WriteEndElement(<#CHECKLIST#>)
    $writer.Flush()
    $writer.Close()

}

<#
    .SYNOPSIS
        Gets the vulnerability details from the rule description
#>
function Get-VulnerabilityList
{
    [CmdletBinding()]
    [OutputType([XML])]
    param
    (
        [Parameter()]
        [PSObject]
        $XccdfBenchmark
    )

    [System.Collections.ArrayList] $vulnerabilityList = @()

    foreach ($vulnerability in $XccdfBenchmark.Group)
    {
        [XML]$vulnerabiltyDiscussionElement = "<discussionroot>$($vulnerability.Rule.description)</discussionroot>"

        [void] $vulnerabilityList.Add(
            @(
                [PSCustomObject]@{Name = 'Vuln_Num'; Value = $vulnerability.id},
                [PSCustomObject]@{Name = 'Severity'; Value = $vulnerability.Rule.severity},
                [PSCustomObject]@{Name = 'Group_Title'; Value = $vulnerability.title},
                [PSCustomObject]@{Name = 'Rule_ID'; Value = $vulnerability.Rule.id},
                [PSCustomObject]@{Name = 'Rule_Ver'; Value = $vulnerability.Rule.version},
                [PSCustomObject]@{Name = 'Rule_Title'; Value = $vulnerability.Rule.title},
                [PSCustomObject]@{Name = 'Vuln_Discuss'; Value = $vulnerabiltyDiscussionElement.discussionroot.VulnDiscussion},
                [PSCustomObject]@{Name = 'IA_Controls'; Value = $vulnerabiltyDiscussionElement.discussionroot.IAControls},
                [PSCustomObject]@{Name = 'Check_Content'; Value = $vulnerability.Rule.check.'check-content'},
                [PSCustomObject]@{Name = 'Fix_Text'; Value = $vulnerability.Rule.fixtext.InnerText},
                [PSCustomObject]@{Name = 'False_Positives'; Value = $vulnerabiltyDiscussionElement.discussionroot.FalsePositives},
                [PSCustomObject]@{Name = 'False_Negatives'; Value = $vulnerabiltyDiscussionElement.discussionroot.FalseNegatives},
                [PSCustomObject]@{Name = 'Documentable'; Value = $vulnerabiltyDiscussionElement.discussionroot.Documentable},
                [PSCustomObject]@{Name = 'Mitigations'; Value = $vulnerabiltyDiscussionElement.discussionroot.Mitigations},
                [PSCustomObject]@{Name = 'Potential_Impact'; Value = $vulnerabiltyDiscussionElement.discussionroot.PotentialImpacts},
                [PSCustomObject]@{Name = 'Third_Party_Tools'; Value = $vulnerabiltyDiscussionElement.discussionroot.ThirdPartyTools},
                [PSCustomObject]@{Name = 'Mitigation_Control'; Value = $vulnerabiltyDiscussionElement.discussionroot.MitigationControl},
                [PSCustomObject]@{Name = 'Responsibility'; Value = $vulnerabiltyDiscussionElement.discussionroot.Responsibility},
                [PSCustomObject]@{Name = 'Security_Override_Guidance'; Value = $vulnerabiltyDiscussionElement.discussionroot.SeverityOverrideGuidance},
                [PSCustomObject]@{Name = 'Check_Content_Ref'; Value = $vulnerability.Rule.check.'check-content-ref'.href},
                [PSCustomObject]@{Name = 'Weight'; Value = $vulnerability.Rule.Weight},
                [PSCustomObject]@{Name = 'Class'; Value = 'Unclass'},
                [PSCustomObject]@{Name = 'STIGRef'; Value = "$($XccdfBenchmark.title) :: $($XccdfBenchmark.'plain-text'.InnerText)"},
                [PSCustomObject]@{Name = 'TargetKey'; Value = $vulnerability.Rule.reference.identifier}

                # Some Stigs have multiple Control Correlation Identifiers (CCI)
                $(
                    # Extract only the cci entries
                    $CCIREFList = $vulnerability.Rule.ident |
                    Where-Object {$PSItem.system -eq 'http://iase.disa.mil/cci'} |
                    Select-Object 'InnerText' -ExpandProperty 'InnerText'

                    foreach ($CCIREF in $CCIREFList)
                    {
                        [PSCustomObject]@{Name = 'CCI_REF'; Value = $CCIREF}
                    }
                )
            )
        )
    }

    return $vulnerabilityList
}

<#
    .SYNOPSIS
        Converts the mof into an array of objects
#>
function Get-MofContent
{
    [CmdletBinding()]
    [OutputType([PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $MofFile
    )

    if (-not $script:mofContent)
    {
        $script:mofContent = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportInstances($MofFile, 4)
    }

    return $script:mofContent
}

<#
    .SYNOPSIS
        Gets the stig details from the mof
#>
function Get-SettingsFromMof
{
    [CmdletBinding()]
    [OutputType([PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $MofFile,

        [Parameter(Mandatory = $true)]
        [String]
        $Id
    )

    $mofContent = Get-MofContent -MofFile $MofFile

    $mofContentFound = $mofContent.Where({$PSItem.ResourceID -match $Id})

    return $mofContentFound
}

<#
    .SYNOPSIS
        Gets the stig details from the Test\Get-DscConfiguration output
#>
function Get-SettingsFromResult
{
    [CmdletBinding()]
    [OutputType([PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $DscResults,

        [Parameter(Mandatory = $true)]
        [String]
        $Id
    )

    if (-not $script:allResources)
    {
        $script:allResources = $DscResults.ResourcesNotInDesiredState + $DscResults.ResourcesInDesiredState
    }

    return $script:allResources.Where({$PSItem.ResourceID -match $id})
}

<#
    .SYNOPSIS
        Gets the value from a STIG setting
#>
function Get-FindingDetails
{
    [OutputType([String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [AllowNull()]
        [PSObject]
        $Setting
    )

    switch ($setting.ResourceID)
    {
        # Only add custom entries if specific output is more valuable than dumping all properties
        {$PSItem -match "^\[None\]"}
        {
            return "No DSC resource was leveraged for this rule (Resource=None)"
        }
        {$PSItem -match "^\[(x)?Registry\]"}
        {
            return "Registry Value = $($setting.ValueData)"
        }
        {$PSItem -match "^\[UserRightsAssignment\]"}
        {
            return "UserRightsAssignment Identity = $($setting.Identity)"
        }
        default
        {
            return Get-FindingDetailsString -Setting $setting
        }
    }
}

<#
    .SYNOPSIS
        Formats properties and values with standard string format.

#>
function Get-FindingDetailsString
{
    [OutputType([String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [AllowNull()]
        [PSObject]
        $Setting
    )

    foreach ($property in $setting.PSobject.properties) {
        if ($property.TypeNameOfValue -Match 'String')
        {
            $returnString += $($property.Name) + ' = '
            $returnString += $($setting.PSobject.properties[$property.Name].Value) + "`n"
        }
    }
    return $returnString
}
<#
    .SYNOPSIS
        Extracts the node targeted by the MOF file

#>
function Get-TargetNodeFromMof
{
    [OutputType([String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $mofString
    )

    $pattern = "((?<=@TargetNode=')(.*)(?='))"
    $targetNodeSearch = $mofString | Select-String -Pattern $pattern
    $targetNode = $targetNodeSearch.matches.value
    return $targetNode
}
<#
    .SYNOPSIS
        Determines the type of node address

#>
function Get-TargetNodeType
{
    [OutputType([String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [String]
        $targetNode
    )

    switch ($targetNode)
    {
        # Do we have a MAC address?
        {
            $_ -match '(([0-9a-f]{2}:){5}[0-9a-f]{2})'
        }
        {
            return 'MACAddress'
        }

        # Do we have an IPv6 address?
        {
            $_ -match '(([0-9a-f]{0,4}:){7}[0-9a-f]{0,4})'
        }
        {
            return 'IPv4Address'
        }

        # Do we have an IPv4 address?
        {
            $_ -match '(([0-9]{1,3}\.){3}[0-9]{1,3})'
        }
        {
            return 'IPv6Address'
        }

        # Do we have a Fully-qualified Domain Name?
        {
            $_ -match '([a-zA-Z0-9-.\+]{2,256}\.[a-z]{2,256}\b)'
        }
        {
            return 'FQDN'
        }
    }

    return ''
}

