# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#region Method Functions
<#
    .SYNOPSIS
        Retreives the mitigation target name from the check-content element in the xccdf

    .PARAMETER CheckContent
        Specifies the check-content element in the xccdf
#>
function Get-MitigationTargetName
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]
        $CheckContent
    )

    Write-Verbose "[$($MyInvocation.MyCommand.Name)]"

    try
    {
        $executableMatch = ($checkContent | Select-String -Pattern $regularExpression.MitigationTargetName -CaseSensitive).Matches.Value
        return $executableMatch
    }
    catch
    {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Mitigation Target Name : Not Found"
        return $null
    }
}

<#
    .SYNOPSIS
        Retreives the mitigation policy name from the check-content element in the xccdf

    .PARAMETER CheckContent
        Specifies the check-content element in the xccdf
#>
function Get-MitigationType
{
    [CmdletBinding()]
    [OutputType([string[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]
        $CheckContent
    )

    Write-Verbose "[$($MyInvocation.MyCommand.Name)]"

    try
    {
        $mitigationType = ($CheckContent | Select-String -Pattern $regularExpression.MitigationType).Matches.Value
        return $mitigationType
    }
    catch
    {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Mitigation Types : Not Found"
        return $null
    }
}

<#
    .SYNOPSIS
        Retreives the mitigation policy name from the check-content element in the xccdf

    .PARAMETER CheckContent
        Specifies the check-content element in the xccdf
#>
function Get-MitigationName
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]
        $CheckContent
    )

    Write-Verbose "[$($MyInvocation.MyCommand.Name)]"

    try
    {
        $mitigationName = ($CheckContent | Select-String -Pattern $regularExpression.MitigationName).Matches.Value
        return $mitigationName
    }
    catch
    {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Mitigation Name : Not Found"
        return $null
    }
}

<#
    .SYNOPSIS
        Retreives the mitigation policy name from the check-content element in the xccdf

    .PARAMETER CheckContent
        Specifies the check-content element in the xccdf
#>
function Get-MitigationValue
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]
        $CheckContent
    )

    Write-Verbose "[$($MyInvocation.MyCommand.Name)]"

    try
    {
        $mitigationValue = ($CheckContent | Select-String -Pattern $regularExpression.MitigationValue).Matches.Value
        return $mitigationValue
    }
    catch
    {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Mitigation Value : Not Found"
        return $null
    }
}

<#
    .SYNOPSIS
        Check if the string (MitigationTarget) contains a comma. If so the rule needs to be split
#>

function Test-MultipleProcessMitigations
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [psobject]
        $CheckContent
    )

    $matchTargets = ($CheckContent | Select-String -Pattern $regularExpression.MitigationTarget -AllMatches).Matches.Value | Select-Object -Unique
    $matchTypes = ($CheckContent | Select-String -Pattern $regularExpression.MitigationType -AllMatches).Matches.Value | Select-Object -Unique
    $matchNames = ($CheckContent | Select-String -Pattern $regularExpression.MitigationName -AllMatches).Matches.Value | Select-Object -Unique

    if (($matchTargets.count -gt 1) -or ($matchTypes.count -gt 1) -or ($matchNames.count -gt 1))
    {
        return $true
    }
    return $false
}



<#
    .SYNOPSIS
        Consumes a list of mitigation targets seperated by a comma and outputs an array
#>
function Split-MultipleProcessMitigations
{
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param
    (
        [Parameter(Mandatory = $true)]
        [psobject]
        $CheckContent
    )

    $trimMatchTypes = @()
    $trimMatchNames = @()
    $matchNamesGroup = @()
    $processMitigations = @()
    $matchTargets = ($CheckContent | Select-String -Pattern $regularExpression.MitigationTarget -AllMatches).Matches.Value | Select-Object -Unique
    $matchTypes = ($CheckContent | Select-String -Pattern $regularExpression.MitigationType -AllMatches).Matches.Value | Select-Object -Unique
    $matchNames = ($CheckContent | Select-String -Pattern $regularExpression.MitigationName -AllMatches).Matches.Value | Select-Object -Unique

    foreach($mitigationTarget in $matchTargets)
    {
        foreach ($mitigationType in $MatchTypes)
        {
            $matchNamesGroup = ($CheckContent | Select-String -Pattern "(?<=$($mitigationType):\n)(.+[\n\r])+" -AllMatches).Matches.Value
            $matchNamesGroupSplit = ($matchNamesGroup.trim()).Split("`n")
            foreach($matchName in $matchNamesGroupSplit)
            {
                $mitigationNames = ($matchName | Select-String -Pattern $regularExpression.MitigationName).Matches.Value
                foreach($mitigationName in $mitigationNames)
                {
                    $mitigationValue = ($matchName | Select-String -Pattern "(?<=$($mitigationName):\s)(\w+)" -AllMatches).Matches.Value
                    $processMitigations += '{0}:{1}:{2}:{3}' -f $mitigationTarget,$mitigationType,$mitigationName,$mitigationValue
                }
            }
        }
    }

    return $processMitigations
}

#endregion
