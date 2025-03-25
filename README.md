-Install Fiddler Classic on workstation

-By default no custom rules file exists
-Open Fiddler -> Rules -> Customize Rules, will create a new custom rules file that can be modified by this script

-With Fiddler closed run Enable-ExtendedProtectionRulesForFiddler.ps1 from PowerShell

Example:
Enable-ExtendedProtectionRulesForFiddler.ps1
-This will prompt the user to enter the root domain that need Extended Protection handled for
-Script will update the Custom Rules file
-Script will start Fiddler
-Script will wait for Fiddler to close
-Script will restore the Custom Rules file

-Or

Enable-ExtendedProtectionRulesForFiddler.ps1 -NamespaceToHandle Contoso.com
-Script will update the Custom Rules file
-Script will start Fiddler
-Script will wait for Fiddler to close
-Script will restore the Custom Rules file

-Or

Enable-ExtendedProtectionRulesForFiddler.ps1 -NamespaceToHandle Contoso.com -UpdateCustomeRulesOnly
-Script will update the Custom Rules file
-Changes to the Custom Rules file will stay
