# PSJumpStart

- [PSJumpStart](#psjumpstart)
  * [Introduction](#introduction)
    + [Features and content](#features-and-content)
    + [Why?](#why)
  * [Practical usage of setting files](#practical-usage-of-setting-files)
    + [Using `dfp` files](#using-dfp-files)
    + [Using `json` files](#using-json-files)
    + [Arguments load order](#arguments-load-order)
  * [Locally customized functions](#locally-customized-functions)
  * [The art of logging](#the-art-of-logging)
  * [Loading DLL files](#loading-dll-files)
  * [How to debug](#how-to-debug)
    + [Global debugging](#global-debugging)
    + [Specific script debugging](#specific-script-debugging)
    + [Function debugging](#function-debugging)
  * [The templates](#the-templates)
  * [Script signing](#script-signing)
  * [The Task Scheduler problem](#the-task-scheduler-problem)
  * [Down the rabbit hole](#down-the-rabbit-hole)
    + [`$PSDefaultParameterValues`](#psdefaultparametervalues)
    + [The `Msg` function](#the-msg-function)
    + [The birth of the `Get-AccessCredential` function](#the-birth-of-the-get-accesscredential-function)
    + [The `$CallerInvocation` story](#the-callerinvocation-story)
    + [`Hashtable` type add-on](#hashtable-type-add-on)
    + [Notes/Tips](#notestips)
  * [Contribute](#contribute)

## Introduction

The PowerShell PSJumpStart module is a multi-purpose module targeted to create an environment for running, creating and editing PowerShell scripts. The environment is highly customizable for different usages and the module comes with some simple but usefull start-up functions. Search the [PowerShell Gallery](https://www.powershellgallery.com/) or the internet to add functionallity or override included functions.

A template folder is included to provide a set of files to jump start PowerShell programming.

### Features and content

- One of the most useful features is the setting files solution. You can use either `.json` or `.dfp` files to populate variables and/or the standard PowerShell feature `$PSDefaultParameterValues`. The files are read in a preset order so you may have different defaults for different scenarios.

- The package contains a `Functions` folder and an empty customizable `LocalLib` folder for local usage found in the module folder. Functions in the local folder will override any existing functions in the `Functions` folder, so you can copy a function and improve it for local usage. The `LocalLib` feature also extends to the current running scripts folder. So you can have the same function name in different versions at each script folders `LocalLib` location. The correct set of function files will be loaded by the `Import-Module` call.

- Any DLL-files found in any `LocalLib` folders will be loaded by an `Add-Type` call. 

- The `Msg`-function provides a generic handling of showing/logging information. It can be pre-configured using `.json` or `.dfp` files as described below.

- The function `Add-ScriptHeader` will add a [comment-based help PowerShell header](https://learn.microsoft.com/en-us/powershell/scripting/developer/help/examples-of-comment-based-help?view=powershell-7.3) from the `param()` content and `Update-ScriptHeader` checks and fixes any missing parameter(s) in existing headers. Use `-WhatIf` option to see suggested header(s).

- Another noteworthy function is the `Get-ModuleHelp`-function for getting module information. Try it with or without arguments.

- A feature for cached `PSCredentials` for named systems is included. Run `Get-Help Get-AccessCredential` for details.

- A set of template files is provided to jump start script creation. The templates comes in two main flavors, PSJumpStart and Basic. The basic templates does not load the module and may act as stand alone scripts while the PSJumpStart templates is using the included module. All templates are  `Get-Help` enabled. The `Template` folder also holds the `ScriptSigner.ps1` file that will sign your files with an existing code signing certificate (or create a new one).

- A template `CMD` file is also provided for calling PowerShell scripts with `StdOut` and `StdErr` capturing.  The primary intended use is launching PS-scripts from Task Scheduler as unhandled errors cannot be traced otherwise. It is a generic template and may be used to launch any PowerShell script.

- The `Tests` folder in the module folder contains some fully featured test/sample scripts are included for reference.

- One sample `ps1xml` file is included for extending the `HashTable` object type with methods for `Replace` and `AppendValue`.

- A script signing feature is included that is not dependent on the module. The script signing feature will use an existing certificate if found or create a new one at run-time.

### Why?

Because we are system administrators that just want to get going with PowerShell using basic supporting functions for common use.

Because we want a jump start for writing a script with `Get-Help` support by using included templates.

Because we want to be able to copy a script from one environment to another without the need to change them making code signing easier (or less of a hassle). Default input arguments are read from settings files.

Because we want to choose how output (messages, verbose and errors) are handled for each site and/or environment without rewriting the scripts. Log to windows eventlog, a log file or only to `StdOut`?

Because we want to be able to set default parameters depending on user, domain or script but be able to override these default parameters by using the script arguments. 

Because we would like to have local PS functions to expand/replace the PSJumpStart base features without risking override by PSJumpStart updates.

## Practical usage of setting files

Have a look in the `PSJumpStart.dfp` or `PSJumpStart.json` file (in the module `Functions` folder) using a text editor. Those are the least significant default settings. Use them to set your preferred configurations (see `$PSDefaultParameterValues` for details).

It is also possible to call `Get-SettingFiles` to retreive a string array of file names with any given suffix.

### Using `dfp` files

These files may be used to set default values for script input arguments as well as function call arguments. The syntax for setting default values for standard functions follow the `$PSDefaultParameterValues`

`Function-Name:Argument-Name=value/code`

To use a `dfp` file as a repository for standard input argument values to a `.ps1` you remove the function name part of the line above

`Argument-Name=value/code`

So if you are using a site name argument in several scripts  ,`[string]$SiteName` , you may create a logon domain named `dfp`file with content `SiteName="www.whatever.com"`

Call the function `Get-GlobalDefaultsFromDfpFiles` to get content for `$PSDefaultParameterValues` and the local function `GetLocalDefaultsFromDfpFiles` to set local script variables. Or simply use the template file `PSJumpStartStdTemplateWithArgumentsDfp.ps1` as a starting point.

### Using `json` files

The `.json` flawor works the same waay as the `.dfp` files. The syntax for setting default values for standard functions looks like this

`"Function-Name:Argument-Name":"value/code"`

To populate standard input argument values to a `.ps1` you remove the function name part of the line above

`"Argument-Name":"value/code"`

So if you want `$PSpids` to contain currently running PowerShell sessions, you may use `"PSpids":  "(Get-Process -Name \"PowerShell\" | Select-Object -ExpandProperty Id)"` in a `json`file.

Call the function `Get-GlobalDefaultsFromJsonFiles` to get content for `$PSDefaultParameterValues`. Copy the `GetLocalDefaultsFromFiles` function from the template file `PSJumpStartStdTemplateWithArguments.ps1`. Or use the template.

### Arguments load order

The `json` or `dfp` files are read in a specific order where the most significant setting will rule over the lower order settings. The order of loading is:

1. Provided arguments will always override any default file settings.
2. User logon ID (`[System.Security.Principal.WindowsIdentity]::getCurrent()`) file name in script folder.
3. Logon provider file name (domain or local machine) in script folder.
4. Script name file in script folder.
5. Logon provider file name (domain or local machine) in PSJumpStart module folder.
6. Any other loaded module name in the PSJumpStart module `Functions` subfolder (for instance an `ActiveDirectory.json` file).
7. The `PSJumpStart.json` file in the module `Functions` subfolder.

Use the `-verbose` for any PSJumpStart template script to see the order of loading.

### The art of logging

The `json` or `dfp` files may also be used to setup the logging environment by setting default variables for the `Msg`function. It may write output to log files, event log or output to console only. Please remember to run any PowerShell as Adminstrator the first time to create any custom log name in the event log. The use of the settings files will enable you to set different event log names, but use this carefully as any script registered for a log name cannot write to another event log name without removing the source using `Remove-Eventlog`.

## Locally customized functions

During loading of functions the `PSJumpStart.psm1` file will load any `ps1` function files from the folder `LocalLib` in the modules folder. Customized functions will override any PSJumpStart functions. So you may add any local functions to enhance the module.

It is also possible to create a `LocalLib` folder in any location containing PSJumpStart enabled `ps1` files. This makes it possible to have a set of `ps1` files targeted for a specific purpose with their own set of local functions. These functions will of course override any existing functions in the module folders.

## Loading DLL files

The `PSJumpStart.psm1` file will use the `Add-Type` command to load any `.dll` files found in a `LocalLib` folder. The load order follow customized funktion loading. For example;

A script is created in `C:\MuppetLabb` to read items from a Sharepoint list using CSOM. This requires the dll `Microsoft.SharePoint.Client.dll`. This dll file may be placed in the `C:\MuppetLabb\LocalLib` folder for exclusive use by scripts in `C:\MuppetLabb` or in the PSJumpStart module `LocalLib` folder for access by all PSJumpStart scripts. Only the `C:\MuppetLabb\LocalLib\Microsoft.SharePoint.Client.dll` will be lodaed for scripts in `C:\MuppetLabb` if the dll file is located in both folders.

## How to debug

The problem; If you are calling a function in a loaded module and want to see the results from `Write-Verbose` you need to add `-Verbose:$VerbosePrefererence` in the arguments for the call. By using `json` or `dfp` files you may activate debug mode for whatever part you need.
Please note that the global variable `$PSDefaultParameterValues` is lost in nested `psm1` function calls. So if you call a sub-function from a `psm1` function you need to retreive the content of `$PSDefaultParameterValues` into the calling `psm1` function using `$PSDefaultParameterValues = (Get-Variable -Name PSDefaultParameterValues -Scope Global).Value`

### Global debugging

Edit the PSJumpStart module `json` and `dfp`files to activate debug mode for ALL scripts, modules and function calls: set `"*:Verbose":true`and `*:Verbose=$true`in the files. The next execution session will activate verbose mode across the board. This can be done by using a specific user `json` and/or `dfp`file so only that user will get verbose feedback.

### Specific script debugging

To debug your script as well as get `Write-Verbose`printouts from ALL used modules and functions;

1. Create a `json` or `dfp`file (depending on what the script uses) with the same name as your script.
2. Put `"*:Verbose":true` or `*:Verbose=$true`in it.
3. Run the script to load `Verbose` mode in current session.

Using the argument `-Verbose` when starting the script will set verbose mode for hte script itself, not only the called functions. Add `"Verbose":true` or `Verbose=$true` to your file if you don't want to user the argument switch.

### Function debugging

If you only need to get verbose printout from a specific function you can add `"Function-Name:Verbose":true` in any `json` file, or `Function-Name:Verbose=$true` in any `dfp` file.

## The templates

In the `Templates`folder (living in the module folder) is a set of templates. Use `Find-PSTemplate`in the PSJumpStart module to list the template files. Copy a template to your preferred working space by using `Copy-PSTemplate`.

## Script signing

There is a little stand alone feature in the `Templates` folder for script signing. It will search for a valid `CodeSigning` capable certificate on the local computer. If not found a new self signed certificate will be created. The found/new certificate is then used to sign single scripts or all scripts in a folder. 

This feature is **not** dependent on the PSJumpStart module.

## The Task Scheduler problem

This module comes with a `.cmd` file used for calling its corresponding PowerShell. The `runCleanupEmptyGroups.cmd` will launch the `CleanupEmptyGroups.ps1` PowerShell script with any provided arguments. The default behaviour of this template is to catch any output from the PowerShell and dump it to a log file in a `logs` sub folder. If any unhandled exceptions occur they will be put in a separate `ERR_` log file.
The primary use for this is in the Task Scheduler. If you launch a PowerShell script directly from Task Scheduler you will not be able to get the exception data written by the PowerShell script. The `.cmd` file will trap and log the information.
The recomendation for Task Scheduled scripts is using a `.json` or `.dfp` named after the service account running the job. Then you may turn off any other logging method for `.ps1` files and let the `.cmd` file handle logging to file.

## Down the rabbit hole

Let's dive in to look at some of the main features in the package.

### Script arguments and variable population
The function `GetLocalDefaultsFromDfpFiles` is a local script function for using `dfp` files to populate default arguments. So the `param($ArgOne)` will be populatated from the line `ArgOne="This is the default value if the user does not provide a command line value"` in any found `dfp` file.

The corresponding local function for `json` files is named `Get-LocalDefaultVariables` and has two extra arguments. The switch `-defineNew` will create local variables for all found variables in `json` files, not only existing empoty variables (input arguments) in the local script. The other switch is `-overWriteExisting` that will reverse the load order making the module `json` files override any user provided command arguments or settings.

### `$PSDefaultParameterValues`

The use of `json` or `dfp` files separates default parameters from the PowerShell scripts. The files are loaded in a preset order using the `Get-SettingsFiles` function where the first encountered setting is used. So user preference will override the default settings for the `psm1` module file. The `Get-GlobalDefaultsFromJsonFiles` function is used for loading `json` file content into the PowerShell variable `$PSDefaultParameterValues` the corresponding function for `dfp` files is of course `Get-GlobalDefaultsFromDfpFiles`.

 As the `$PSDefaultParameterValues` may be set for all functions it is possible for `Write-Verbose` to present output from directly called functions in `psm1` modules without typing `-Verbose:$VerbosePrefererence` in ALL function calls. To ensure debugging in nested `psm1` function calls you need to add the command `$PSDefaultParameterValues = (Get-Variable -Name PSDefaultParameterValues -Scope Global).Value` in the calling `psm1` function.

[The story behind the `Get-CallerPreference`function](https://blogs.technet.microsoft.com/heyscriptingguy/2014/04/26/weekend-scripter-access-powershell-preference-variables/)

[The code source](https://gallery.technet.microsoft.com/scriptcenter/Inherit-Preference-82343b9d)

More information on the use of `$PSDefaultParameterValus`:
[The Microsoft Docs Tale](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-6)

[Some practical usage samplings](https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-time-saver-automatic-defaults)


### The `Msg` function

The unified way of writing output information from calling scripts. There are a number of arguments available when calling this function making it possible to write output to log file as well as windows Eventlog. Use the `.json` files framework to set default values for input arguments. This example will write information to a log file (in script folder with same name as script + year and month) AND to the Windows Eventlog `PSJumpStart`:
```json
{
    "Msg:useFileLog":  true,
    "Msg:useEventLog":  true,
    "Msg:logFile":  "($(Split-Path -Parent $MyInvocation.PSCommandPath) + '\\' + $(Split-Path -Leaf $MyInvocation.PSCommandPath) + '.' + (Get-Date -Format 'yyyy-MM') + '.Log')",
    "Msg:EventLogName":  "PSJumpStart"    
}
```
The `Msg`-function will write messages using  `Write-Output` or `Write-Error` if it does not write output to a log file or eventlog. This will write messages to the std-out or std-err pipe. As PowerShell does not have a separated function output pipe you need to have this in mind when using `Msg`in called functions who returns data. If any logging is enabled (eventlog or file) the `Msg` will use `Write-Host` to present output. If this is not what you want, just copy the function to a `localLib` folder and change it according to current needs.

To use this function from any `psm1` (loaded) function or nested functions, you may need to retrieve the global content of `$PSDefaultParameterValues` adding the following code line:

 `$PSDefaultParameterValues = (Get-Variable -Name PSDefaultParameterValues -Scope Global).Value`

### The birth of the `Get-AccessCredential` function
There are times when you just want to run your admin task PowerShell without typing the password at every run time. And one morning I just got tired of it, so I wrote this function. It is based on the commonly used `PSCredential` object and this loaded by `Import-Clixml` and saved using `Export-Clixml`. If a file is missing the function will call itself with the `-renew` option presenting a dialog for getting new credentials. The saved `xml` file is protected by both current user and computer context. It is only possible for the correct user to retreive the password in clear text.

So the name of the cashed credential file will be `$env:ComputerName + "." + $env:UserName + "$AccessName.xml"`. The AccessName may be used to identify access files for different systems/purposes.

### The `$CallerInvocation` story

To ensure correct environment the `$CallerInvocation` is used as input parameter by some functions in the `psm1` file. The input should be `$MyInvocation` of the root caller script.

[Some words on the PowerShell module environment](https://www.red-gate.com/simple-talk/dotnet/.net-tools/further-down-the-rabbit-hole-powershell-modules-and-encapsulation/)

### `Hashtable` type add-on

The PSJumpStart module will add two methods to the `Hashtable` variable type.  The `Replace`method will add or replace an existing value in a hashtable. The `AppendValue`will append new values to any existing data by creating an array of values.

[The inspiration for enhancing the `Hashtable` object type by using a `ps1xml` file](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_types.ps1xml?view=powershell-6)

[Some words on `Hashtables`](https://kevinmarquette.github.io/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/)

### Notes/Tips

It is possible to use `-defineNew` and/or `-overWriteExisting` when calling the function `Get-LocalDefaultValues` to load all variable definitions in all setting files. The function will normally only add values to existing empty variables (typically defined in the `param()` section). The `-overWriteExisting` option will turn the tables on the load order making setting files king of data.

The folder `Tests` included in this package has some code samples for calling functions in the module. For example `SQLqueryTest.ps1` where the local function `dumpDBresult` explores the result from calling `Invoke-SqlQuery`. 

The template folder also include the file `Set-PSJumpStartCommandPromtEnvironment.ps1`. This file will create variables according to the current set of `json` files with verbose output. This is very useful in some test and/or development scenarios.

[A nice article on the practical use of CustomObjects in PowerShell](https://social.technet.microsoft.com/wiki/contents/articles/7804.powershell-creating-custom-objects.aspx)


## Contribute

Please feel free to add an issue and suggest improvements or contribute with functions. As the end line from the movie `The Matrix` puts it:

"A world where anything is possible. Where we go from there is a choice I leave to you."

Keep up the good work.
