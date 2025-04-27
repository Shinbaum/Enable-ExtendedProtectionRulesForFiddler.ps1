-Install Fiddler Classic on workstation<br>
-By default no custom rules file exists<br>
-Open Fiddler -> Rules -> Customize Rules, will create a new custom rules file that can be modified by this script<br>
<br>
-With Fiddler closed run Enable-ExtendedProtectionRulesForFiddler.ps1 from PowerShell<br>
<br>
Example:<br>
**Enable-ExtendedProtectionRulesForFiddler.ps1**<br>
-This will prompt the user to enter the root domain that need Extended Protection handled for<br>
-Script will update the Custom Rules file<br>
-Script will start Fiddler<br>
-Script will wait for Fiddler to close<br>
-Script will restore the Custom Rules file<br>
<br>
-Or<br>
<br>
**Enable-ExtendedProtectionRulesForFiddler.ps1 -NamespaceToHandle Contoso.com**<br>
-Script will update the Custom Rules file<br>
-Script will start Fiddler<br>
-Script will wait for Fiddler to close<br>
-Script will restore the Custom Rules file<br>
<br>
-Or<br>
<br>
**Enable-ExtendedProtectionRulesForFiddler.ps1 -NamespaceToHandle Contoso.com -UpdateCustomRulesOnly**<br>
-Script will update the Custom Rules file<br>
-Changes to the Custom Rules file will stay<br>
