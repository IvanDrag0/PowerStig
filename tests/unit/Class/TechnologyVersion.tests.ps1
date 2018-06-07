using module .\..\..\..\src\Class\Technology.psm1
using module .\..\..\..\src\Class\TechnologyVersion.psm1
using module .\..\..\..\src\Class\TechnologyRole.psm1

$TechnologyVersion1 = 'All'
$TechnologyVersion2 = '2012R2'
$TechnologyVersion3 = 'Server2012'

$Technology1 = [Technology]::new('Windows')
$Technology2 = [Technology]::new('SQL')

$TestValidateSet = @"
Windows = All, 2012R2
SQL = Server2012
"@

$TestValidSetData = ConvertFrom-StringData -StringData $TestValidateSet

$InvalidName = 'Cheeseburger'

Describe "TechnologyVersion Class" {

    Context "Constructor" {

        It "Should create an TechnologyVersion class instance using Technology1 and TechnologyVersion1 data" {
            $TechnologyVersion = [TechnologyVersion]::new($TechnologyVersion1, $Technology1)
            $TechnologyVersion.Name | Should Be $TechnologyVersion1
            $TechnologyVersion.Technology | Should Be $Technology1
        }

        It "Should create an TechnologyRole class instance using TechnologyRole2 and TechnologyVersion2 data" {
            $TechnologyVersion = [TechnologyVersion]::new($TechnologyVersion2, $Technology1)
            $TechnologyVersion.Name | Should Be $TechnologyVersion2
            $TechnologyVersion.Technology | Should Be $Technology1
        }

        It "Should create an TechnologyRole class instance using TechnologyRole3 and TechnologyVersion3 data" {
            $TechnologyVersion = [TechnologyVersion]::new($TechnologyVersion3, $Technology2)
            $TechnologyVersion.Name | Should Be $TechnologyVersion3
            $TechnologyVersion.Technology | Should Be $Technology2
        }

        It "Should throw an exception for TechnologyRole not being available for TechnologyVersion: Windows -> Cheeseburger" {
            { [TechnologyVersion]::new($InvalidName, $Technology1) } | Should Throw
        }
    }

    Context "Static Properties" {
        It "ValidateSet: Should match TestValidateSet to static ValidateSet property" {
            [TechnologyVersion]::ValidateSet | Should Be $TestValidateSet
        }
    }

    Context "Instance Methods" {
        It "Validate: Should be able to validate a TechnologyVersion. Valid property config." {
            $TechnologyVersion = [TechnologyVersion]::new()
            $TechnologyVersion.Name = $TechnologyVersion1
            $TechnologyVersion.Technology = $Technology1
            $TechnologyVersion.Validate() | Should Be $true
        }

        It "Validate: Should be able to validate a TechnologyVersion. Invalid property config." {
            $TechnologyVersion = [TechnologyVersion]::new()
            $TechnologyVersion.Name = $InvalidName
            $TechnologyVersion.Technology = $Technology1
            $TechnologyVersion.Validate() | Should Be $false
        }
    }

    Context "Static Methods" {
        It "Available: Should be able to return available roles. Valid TechnologyVersion parameter." {
            $ValidVersion = $Technology1.Name
            [TechnologyVersion]::Available($ValidVersion) | Should Be $TestValidSetData.$ValidVersion.Split(',').Trim()
        }

        It "Available: Should throw an exception that no roles are available for an unsupported version." {
            $InvalidTechnology = $InvalidName
            { [TechnologyVersion]::Available($InvalidTechnology) } | Should Throw
        }
    }
}
