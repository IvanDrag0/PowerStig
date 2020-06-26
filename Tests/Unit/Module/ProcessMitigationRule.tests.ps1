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
                    Count = 2
                    CheckContent = 'This is NA prior to v1709 of Windows 10.

                    This is applicable to unclassified systems, for other systems this is NA.

                    Run "Windows PowerShell" with elevated privileges (run as administrator).

                    Enter "Get-ProcessMitigation -Name [application name]" with each of the following substituted for [application name]:
                    java.exe, javaw.exe, and javaws.exe
                    (Get-ProcessMitigation can be run without the -Name parameter to get a list of all application mitigations configured.)

                    If the following mitigations do not have the listed status which is shown below, this is a finding:

                    DEP:
                    OverrideDEP: False

                    Payload:
                    OverrideEnableExportAddressFilter: False
                    OverrideEnableExportAddressFilterPlus: False
                    OverrideEnableImportAddressFilter: False
                    OverrideEnableRopStackPivot: False
                    OverrideEnableRopCallerCheck: False
                    OverrideEnableRopSimExec: False


                    The PowerShell command produces a list of mitigations; only those with a required status are listed here. If the PowerShell command does not produce results, ensure the letter case of the filename within the command syntax matches the letter case of the actual filename on the system.'
                }
            )

            foreach ($testRule in $testRuleList)
            {
                It "Should return $true" {
                    $multipleRule = [ProcessMitigationRuleConvert]::HasMultipleRules($testRule.CheckContent)
                    $multipleRule | Should -Be $true
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
