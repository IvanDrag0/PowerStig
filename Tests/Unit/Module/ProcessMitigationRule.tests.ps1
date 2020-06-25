#region Header
. $PSScriptRoot\.tests.header.ps1
#endregion

try
{
    InModuleScope -ModuleName "$($global:moduleName).Convert" {
        #region Test Setup
        $testRuleList = @(
            @{
                MitigationTarget = 'System'
                MitigationType = 'Heap'
                MitigationName = 'TerminateOnError'
                MitigationValue = 'true'
                OrganizationValueRequired = $false
                CheckContent = ' This is NA prior to v1709 of Windows 10.

                Run "Windows PowerShell" with elevated privileges (run as administrator).

                Enter "Get-ProcessMitigation -System".

                If the status of "Heap: TerminateOnError" is "OFF", this is a finding.

                Values that would not be a finding include:
                ON
                NOTSET'
            },
            @{
                MitigationTarget = 'wordpad.exe'
                MitigationType = 'DEP'
                MitigationName = 'Enable'
                MitigationValue = 'true'
                OrganizationValueRequired = $false
                CheckContent = 'wordpad.exe:DEP:Enable:ON'
            }
        )
        #endregion

        foreach ($testRule in $testRuleList)
        {
            . $PSScriptRoot\Convert.CommonTests.ps1
        }

        #region Add Custom Tests Here
        Describe 'MultipleRules' {
            # TODO move this to the CommonTests
            $testRuleList = @(
                @{
                    Count = 21
                    CheckContent = 'This is NA prior to v1709 of Windows 10.

                    Run "Windows PowerShell" with elevated privileges (run as administrator).

                    Enter "Get-ProcessMitigation -Name [application name]" with each of the following substituted for [application name]:
                    java.exe, javaw.exe, and javaws.exe
                    (Get-ProcessMitigation can be run without the -Name parameter to get a list of all application mitigations configured.)

                    If the following mitigations do not have a status of "ON" for each, this is a finding:

                    DEP:
                    Enable: ON

                    Payload:
                    EnableExportAddressFilter: ON
                    EnableExportAddressFilterPlus: ON
                    EnableImportAddressFilter: ON
                    EnableRopStackPivot: ON
                    EnableRopCallerCheck: ON
                    EnableRopSimExec: ON

                    The PowerShell command produces a list of mitigations; only those with a required status of "ON" are listed here.'
                }
            )

            foreach ($testRule in $testRuleList)
            {
                It "Should return $true" {
                    $multipleRule = [ProcessMitigationRuleConvert]::HasMultipleRules($testRule.CheckContent)
                    $multipleRule | Should -Be $true
                }
                It "Should return $($testRule.Count) rules" {
                    $multipleRule = [ProcessMitigationRuleConvert]::SplitMultipleRules($testRule.CheckContent)
                    $multipleRule.count | Should -Be $testRule.Count
                }
            }
        }
        #endregion
    }
}
finally
{
    . $PSScriptRoot\.tests.footer.ps1
}
