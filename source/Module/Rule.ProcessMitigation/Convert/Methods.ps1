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
        switch ($checkContent)
        {
            { $PSItem -match '-System' }
            {
                return 'System'
            }
            { $PSItem -match '-Name' }
            {
                # Grab all the text that starts on a new line or with whitespace and ends in .exe
                $executableMatches = $checkContent | Select-String -Pattern '(^|\s)\S*?\.exe' -AllMatches
                return ( $executableMatches.Matches.Value.Trim() ) -join ','

            }
        }
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
        $result = @()
        foreach ($line in $checkContent)
        {
            switch ($line)
            {
                {$PSItem -match $regularExpression.MitigationType}
                {
                    $result += (($line | Select-String -Pattern $regularExpression.MitigationType).Matches.Value)
                }
            }
        }
        return $result -join ','
    }
    catch
    {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Mitigation Policy : Not Found"
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
        [string]
        $RawString
    )

    Write-Verbose "[$($MyInvocation.MyCommand.Name)]"

    try
    {
        $result = @()
        $subCheckContent  = @()
        $subCheckContent = ($RawString | select-string -Pattern '(?<=ASLR:\n)(.+[\n\r])+').Matches.Value

        $result = ($subCheckContent | select-String -Pattern $regularExpression.MitigationName -AllMatches).matches.value

        return $result -join ','
    }
    catch
    {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Mitigation Name : Not Found"
        return $null
    }
}

<#
    .SYNOPSIS
        Consumes a list of mitigation targets seperated by a comma and outputs an array
#>
function Split-ProcessMitigationRule
{
    [CmdletBinding()]
    [OutputType([array])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $MitigationType
    )

    return ($MitigationType -split ',')
}

<#
    .SYNOPSIS
        Check if the string (MitigationTarget) contains a comma. If so the rule needs to be split
#>
function Test-MultipleProcessMitigationType
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $MitigationType
    )

    if ($MitigationType -match ',')
    {
        return $true
    }
    return $false
}
#endregion
