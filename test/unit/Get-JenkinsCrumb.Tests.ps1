[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
[CmdletBinding()]
param (
)

$moduleManifestName = 'Jenkins.psd1'
$moduleRootPath = "$PSScriptRoot\..\..\src\"
$moduleManifestPath = Join-Path -Path $moduleRootPath -ChildPath $moduleManifestName

Import-Module -Name $ModuleManifestPath -Force
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\TestHelper') -Force

$testURI        = 'https://jenkins.contoso.com'
$testUsername   = 'DummyUser'
$testPassword   = 'DummyPassword'
$testCredential = New-Object -TypeName System.Management.Automation.PSCredential `
    -ArgumentList $testUsername, ( ConvertTo-SecureString -String $testPassword -AsPlainText -Force)
$testCommand    = 'CommandTest'
$Bytes          = [System.Text.Encoding]::UTF8.GetBytes($testUsername + ':' + $testPassword)
$Base64Bytes    = [System.Convert]::ToBase64String($Bytes)
$testAuthHeader = "Basic $Base64Bytes"
$testJobName    = 'TestJob'

Describe 'Get-JenkinsCrumb' {
    $GetJenkinsCrumbSplat = @{
        Uri        = $testURI
        Credential = $testCredential
    }

    Context 'When uri passed, credentials passed, standard crumb returned' {
        Mock -CommandName Set-JenkinsTLSSupport -ModuleName Jenkins

        Mock -CommandName Invoke-WebRequest -ModuleName Jenkins `
            -MockWith { Throw 'Invoke-RestMethod called with incorrect parameters' }

        Mock -CommandName Invoke-WebRequest -ModuleName Jenkins `
            -ParameterFilter {
                $Uri -eq ('{0}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' -f $testURI) -and `
                $Headers.Count -eq 1 -and `
                $Headers['Authorization'] -eq $testAuthHeader
            } `
            -MockWith { [pscustomobject] @{ Content = 'Jenkins-Crumb:1234567890' } }
        $Splat = $GetJenkinsCrumbSplat.Clone()
        $Result = Get-JenkinsCrumb @Splat
        It "Should return '1234567890'" {
            $Result | Should -Be '1234567890'
        }
        It "Should return call expected mocks" {
            Assert-MockCalled -CommandName Set-JenkinsTLSSupport -ModuleName Jenkins -Exactly 1

            Assert-MockCalled -CommandName Invoke-WebRequest -ModuleName Jenkins `
                -ParameterFilter {
                    $Uri -eq ('{0}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' -f $testURI) -and `
                    $Headers.Count -eq 1 -and `
                    $Headers['Authorization'] -eq $testAuthHeader
                } `
                -Exactly 1
        }
    } # Context

    Context 'When uri passed, credentials passed, internal crumb returned' {
        Mock -CommandName Set-JenkinsTLSSupport -ModuleName Jenkins

        Mock -CommandName Invoke-WebRequest -ModuleName Jenkins `
            -MockWith { Throw 'Invoke-RestMethod called with incorrect parameters' }

        Mock -CommandName Invoke-WebRequest -ModuleName Jenkins `
            -ParameterFilter {
                $Uri -eq ('{0}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' -f $testURI) -and `
                $Headers.Count -eq 1 -and `
                $Headers['Authorization'] -eq $testAuthHeader
            } `
            -MockWith { [pscustomobject] @{ Content = '.crumb:1234567890' } }
        $Splat = $GetJenkinsCrumbSplat.Clone()
        $Result = Get-JenkinsCrumb @Splat
        It "Should return '1234567890'" {
            $Result | Should -Be '1234567890'
        }
        It "Should return call expected mocks" {
            Assert-MockCalled -CommandName Set-JenkinsTLSSupport -ModuleName Jenkins -Exactly 1

            Assert-MockCalled -CommandName Invoke-WebRequest -ModuleName Jenkins `
                -ParameterFilter {
                    $Uri -eq ('{0}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' -f $testURI) -and `
                    $Headers.Count -eq 1 -and `
                    $Headers['Authorization'] -eq $testAuthHeader
                } `
                -Exactly 1
        }
    } # Context

    Context 'When uri passed, credentials passed, invalid crumb returned' {
        Mock -CommandName Set-JenkinsTLSSupport -ModuleName Jenkins

        Mock -CommandName Invoke-WebRequest -ModuleName Jenkins `
            -MockWith { Throw 'Invoke-RestMethod called with incorrect parameters' }

        Mock -CommandName Invoke-WebRequest -ModuleName Jenkins `
            -ParameterFilter {
                $Uri -eq ('{0}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' -f $testURI) -and `
                $Headers.Count -eq 1 -and `
                $Headers['Authorization'] -eq $testAuthHeader
            } `
            -MockWith { [pscustomobject] @{ Content = 'Invalid Crumb' } }
        $Splat = $GetJenkinsCrumbSplat.Clone()
        It "Should throw exception" {
            { $Result = Get-JenkinsCrumb @Splat } | Should -Throw 'Invalid Crumb'
        }
        It "Should return call expected mocks" {
            Assert-MockCalled -CommandName Set-JenkinsTLSSupport -ModuleName Jenkins -Exactly 1

            Assert-MockCalled -CommandName Invoke-WebRequest -ModuleName Jenkins `
                -ParameterFilter {
                    $Uri -eq ('{0}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' -f $testURI) -and `
                    $Headers.Count -eq 1 -and `
                    $Headers['Authorization'] -eq $testAuthHeader
                } `
                -Exactly 1
        }
    } # Context
}
