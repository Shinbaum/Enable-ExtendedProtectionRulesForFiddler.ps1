<#
    MIT License

    Copyright (c) Microsoft Corporation.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE
#>

# Version 1.0

param ([string]$NamespaceToHandle="",[switch]$UpdateCustomRulesOnly)

###Auto Locate
#Check that Fiddler is insalled
#Get Fiddler location
#HKEY_CURRENT_USER\Software\Microsoft\Fiddler2\InstallerSettings
#C:\Users\jashinba\AppData\Local\Programs\Fiddler\
If (Get-ItemProperty -Path HKCU:\Software\Microsoft\Fiddler2\InstallerSettings -Name "InstallPath" -ErrorAction SilentlyContinue)
  {
  $FiddlerInstallPath = (Get-ItemProperty -Path HKCU:\Software\Microsoft\Fiddler2\InstallerSettings -Name "InstallPath").InstallPath
  $FiddlerInstallVersion = (Get-ItemProperty -Path HKCU:\Software\Microsoft\Fiddler2\InstallerSettings -Name "InstalledVersion").InstalledVersion
  Write-Host "Fiddler install path: $FiddlerInstallPath"
  Write-Host "Fiddler version: $FiddlerInstallVersion"
  }
Else
  {
  Write-host "Fiddler install not found"
  #Exit
  }

#Find Fiddler Cutome Rules file to edit
$CustomRulesFilePath = Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath "Fiddler2\Scripts\CustomRules.js"
If (Get-ChildItem $CustomRulesFilePath -ErrorAction SilentlyContinue)
  {
  Write-Host "Fiddler custom rules file to edit: $CustomRulesFilePath"
  }
Else
  {
  Write-host "Fiddler Custome Rules file not found. This is what is edited to allow for EP. File path that is being looked for is: $CustomRulesFilePath"
  Write-host "To create a new defalut rules file, open Fiddler -> Rules -> Customize Rules, will create a new default rules file. Exit Fiddler and restart this script"
  Exit
  }

#Ask users for Domain to handle if not supplied from param
If (!$NamespaceToHandle)
  {
  $NamespaceToHandle = Read-Host -Prompt "Enter Namespace to handle Extended Protection for, Example: contoso.com or FourthStreetCoffee.com"
  }

#Backup Custome Rules File
$CustomRulesBackupFilePath = $CustomRulesFilePath + ".Backup_$((Get-Date).ToString('yyyyMMddHHmmss'))"
Copy-Item -Path $CustomRulesFilePath -Destination $CustomRulesBackupFilePath
Write-Host "Backed up file $CustomRulesFilePath to $CustomRulesBackupFilePath"

#Time to inject Fiddler EP Rules
#Ref: https://docs.telerik.com/fiddler/configure-fiddler/tasks/authenticatewithcbt
$LinesToAddToCustomRules = @'
    // Added by Enable-ExtendedProtectionRulesForFiddler.ps1 script
    // To avoid problems with Channel-Binding-Tokens, this block allows Fiddler Classic 
    // itself to respond to Authentication challenges from HTTPS Intranet sites. 
    if (oSession.isHTTPS && 
        (oSession.responseCode == 401) && 
        // Only permit auto-auth for local apps (e.g. not devices or remote PCs) 
        (oSession.LocalProcessID > 0) && 
        // Only permit auth to sites we trust 
        (Utilities.isPlainHostName(oSession.hostname) 
      // Replace telerik.com with whatever servers Fiddler Classic should release credentials to.
      || oSession.host.EndsWith("
'@
$LinesToAddToCustomRules += $NamespaceToHandle
$LinesToAddToCustomRules += @'
"))  
        ) 
    { 
        // To use creds other than your Windows login credentials, 
        // set X-AutoAuth to "domain\\username:password" 
        // Replace default with specific credentials in this format:
      // domain\\username:password. 
        oSession["X-AutoAuth"] = "(default)";    
        oSession["ui-backcolor"] = "pink"; 
    }
    // End Added by Enable-ExtendedProtectionRulesForFiddler.ps1 script
'@
#$LinesToAddToCustomRules

#Read Custome Rules File into variable
$CustomRulesText = Get-Content -Path $CustomRulesFilePath -Raw
#Locate Function in Rules File
$FunctionLine = "static function OnPeekAtResponseHeaders(oSession: Session) {"
If ($CustomRulesText.ToLower().Contains($FunctionLine.ToLower()))
  {
  #Write-Host "Found $FunctionLine"
  }
Else
  {
  Write-Host "NOT Found $FunctionLine in $CustomRulesFilePath"
  Exit
  }

#Make sure we dont already have the EP code in the Fiddler Custom Rules
If ($CustomRulesText.ToLower().Contains("// Added by Enable-ExtendedProtectionRulesForFiddler.ps1 script".ToLower()) -or
   $CustomRulesText.ToLower().Contains("// To avoid problems with Channel-Binding-Tokens, this block allows Fiddler Classic".ToLower()))
  {
  Write-Host 'Custom Rules File already has the code for EP. Edit line || oSession.host.EndsWith("...") to change the domain if needed'
  Write-Host 'Or to reset Custom Rules to default, delete the Custom Rules file. Then open Fiddler -> Rules -> Customize Rules, will create a new default rules file. Exit Fiddler and restart this script'
  Write-Host "Custom Rules file: $CustomRulesFilePath"
  Exit
  }

#Insert EP rules into Custom Rules file
$StringToInsert = $FunctionLine + "`r`n" + $LinesToAddToCustomRules + "`r`n"
$UpdatedCustomRulesText = $CustomRulesText.Replace($FunctionLine,$StringToInsert)
Out-File -FilePath $CustomRulesFilePath -InputObject $UpdatedCustomRulesText -Force
Write-Host "Custom Rules file updated: $CustomRulesFilePath"

#If not UpdateCustomRulesOnly
If (!$UpdateCustomRulesOnly.IsPresent)
  {
  #Start Fiddler and wait for Fiddler to exit
  $FiddlerEXEPath = "$FiddlerInstallPath\Fiddler.exe"
  Write-Host "Starting Fiddler: $FiddlerEXEPath"
  Start-Process -FilePath $FiddlerEXEPath -Wait
  #Wait for Fiddler to exit
  
  #Restore Fiddler Rules File
  Move-Item -Path $CustomRulesBackupFilePath -Destination $CustomRulesFilePath -Force
  Write-Host "Restored file $CustomRulesBackupFilePath to $CustomRulesFilePath"
  #We're done
  }
