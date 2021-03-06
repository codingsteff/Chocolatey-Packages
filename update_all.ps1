param($Name = $null)
Set-Location $PSScriptRoot

if (Test-Path update_vars.ps1) { . ./update_vars.ps1 }

$options = [ordered]@{
  Timeout = 200 #  https://push.chocolatey.org Failed to process request. 'Origin Time-out'.  The remote server returned an error: (524) 
  Force   = $false # Force all packages TODO: try out with $Env:au_Force -eq 'true' ?
  Push    = $true  # Push to chocolatey
  Threads = 10

  # Save text report in the local file report.txt
  Report  = @{
    Type = 'text'
    Path = "$PSScriptRoot\report.txt"
  }

  # Then save this report as a gist using your api key and gist id
  Gist    = @{
    ApiKey = $Env:github_api_key
    Id     = $Env:github_gist_id
    Path   = "$PSScriptRoot\report.txt"
  }

  # Persist pushed packages to your repository
  Git     = @{
    User     = ''
    Password = $Env:github_api_key
  }

  # Then save run info which can be loaded with Import-CliXML and inspected
  RunInfo = @{
    Exclude = 'password', 'apikey'
    Path    = "$PSScriptRoot\update_info.xml"
  }

  # Finally, send an email to the user if any error occurs and attach previously created run info
  Mail    = if ($Env:mail_user) {
    @{
      To        = $Env:mail_user
      Server    = $Env:mail_server
      UserName  = $Env:mail_user
      Password  = $Env:mail_pass
      Port      = $Env:mail_port
      EnableSsl = $Env:mail_enablessl -eq 'true'
    }
  }   
}

# GitHub Api requries TLS 1.2 (https://github.com/majkinetor/au/issues/142)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$global:info = updateall -Name $Name -Options $options

#Uncomment to fail the build on AppVeyor on any package error
if ($global:info.error_count.total) { throw 'Errors during update' }