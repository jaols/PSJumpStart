# Content
## [AdScripts](https://github.com/jaols/PSJumpStart/tree/master/ADscripts)
Sample implementation scripts for PSJumpStart module

## [PSJumpStart](https://github.com/jaols/PSJumpStart/tree/master/PSJumpStart)
The PSJumpStart module files with usage and feature documentation

## [PSJumpStartLight](https://github.com/jaols/PSJumpStart/tree/master/PSJumpStartLight)
PSJumpStartLight is a stand alone set of templates and functions NOT dependent on any extra module(s)

## Release notes
v 2.0.1

 - The birth of PSJumpStartLight. A module independent cherry picking solution (not part of PSJumpStart module).

### The future?
- Improved script signing framework with automated certificate renewal
- Small tutorial on different types of PowerShell files. Main scripts, function scripts and Main script "wrappers".
- Explore the idea of `Get-ValuesFromJsonMapping`
- Any other provided suggestion!!

### History

v 1.0.2

- Correction for Verbose argument override by Get-GlobalDefaultsFromDfpFiles
- "Template" for self-signing PowerShell scripts. 

v 1.0.3

- Correction of file logging in MSG-function
- Improved PSJumpStart templates
- Write-Verbose included in the dfp file processing.
- Improved ScriptSigner.ps1 
  
v 1.0.4

- Improved description.
- Improved AppendValue method for Hastable type add-on in ps1xml 

v 1.0.5

- Small bug correction in the Get-GlobalDefaultsFromDfpFiles
- New function Send-MailMessageUsingHtmlTemplate
- EPS template implementation planned but not in play yet
- Improved documentation ReadMe.md
  
v 1.1.0

- Code structure change and naming cleanup. Separate ps1-files for each function.
 
- Renamed functions:
  ExportDataTableToFile -> Out-DataTableToFile
  QuerySQL -> Invoke-SqlQuery
 
- Correction and cleanup in the ps1xml file for the HashTable extension methods.
- Improved Send-MailMessageUsingHtmlTemplate function.

v 1.1.1

- Msg-function will now support both Eventlog-writing AND File-log writing. If non is used it will send output to Std-out and Std-Err to be captured by calling entity.

v 1.1.2

- Improved documentation. Support for array argument input when running PS-files from generic CMD-file.
- Small changesd in test-code.

v 1.2.0

- Added support for JSON setting files along with the DFP-files. 

v 1.2.1

- New function for handling credentials - Get-AccessCredential

v 1.2.2

- Bugs correction of the old functions for template handling.

v 1.2.3 - 1.2.9

- Support for LocalLib in current script location OR current directory $PWD.Path (this may get removed)
- Added support for sendlist in the send mail function
- Added Pipeline script template
- New functions html handling (for general use or part of html-mail content)
- Small fixes and improved doc as well as a shell enviroment script
- Improved Get-ModuleHelp and new PS-header handlers 
- Bug correction in PSJumpstart.ps1xml
- Support for DLL Add-Type in same fasion as functions (load from script localLib folder or localLib module folder). Improved Get-ModuleHelp to include Available modules.
- Support for computer name settings files (long overdue) + Mutex support

v 1.3.0

- Support for dynamic loading (PSJumpStart style) of TypeData and Format files (.ps1xml). New module folder structure as well as expected local one.
- Script template improvements and a few new functions - Set-ValuesFromExpressions + Compare-PSObjects
- Some housekeeping in samples folder and new folder for Pester tests.

v 2.0.0

- `DFP` files are no longer supported. Only `JSON` files may be used.
- Removed usage of `$CallerInvocation` in `Get-SettingsFiles` function (root script `$MyInvocation` environment)
- `Msg` is now an alias for `Write-Message` 
- New functions for named environment in `.json` files
- Some `*Format.ps1xml` files included in module (script local `Format` folder will override)
- First template in place for as a starting point for function scripts to use in `localLib` folders
- Improved function loading in `.psm1` file with verbose printout for each function location
- Improved `Get-ModuleHelp` function with object list output and support for `Format-*` commands
