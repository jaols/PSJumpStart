# PSJumpStart

- [PSJumpStart](#psjumpstart)
  * [Introduction](#introduction)
  * [Features and content](#features-and-content)
  * [Why?](#why-)
  * [Practical usage](#practical-usage)
    + [Using `dfp` files](#using--dfp--files)
      - [Arguments load order](#arguments-load-order)
    + [The art of logging](#the-art-of-logging)
      - [The Task Scheduler problem](#the-task-scheduler-problem)
    + [How to debug](#how-to-debug)
      - [Global debugging](#global-debugging)
      - [Specific script debugging](#specific-script-debugging)
      - [Function debugging](#function-debugging)
    + [The templates](#the-templates)
    + [Local customized functions](#local-customized-functions)
    + [Script signing](#script-signing)
  * [Down the rabbit hole](#down-the-rabbit-hole)
    + [`$PSDefaultParameterValues`](#--psdefaultparametervalues-)
    + [The `Msg` function](#the--msg--function)
    + [The `$CallerInvocation` story](#the---callerinvocation--story)
    + [`Hashtable` type add-on](#-hashtable--type-add-on)
    + [Notes](#notes)
  * [Stolen with pride](#stolen-with-pride)
  * [Contribute](#contribute)

<a name=introduction></a>
## Introduction

The PowerShell PSJumpStart module uses the built-in features in PowerShell to create an environment for the Power Administrator. It is a set of files to jump start PowerShell script creation as well as some ready to use functions. The goal is to provide some simple start-up functions. Search the [PowerShell Gallery](https://www.powershellgallery.com/) or the internet if a more potent function is needed. 
<a name=features-and-content></a>
## Features and content

PSJumpstart uses `$PSDefaultParameterValues` to set local default parameters by using `dfp` files. These are read in a preset order so you may have different defaults for different scenarios.

The package contains one main `psm1` file and a preloaded empty customizable `psm1` file for local usage. One of the core functions in the `PSJumpStart.psm1` file is the `Msg`-function for showing/logging information. A leaf script may call this function and result in different outputs depending on settings or argument use. 

A set of template files is provided to jump start script creation. The templates comes in two main flavors, PSJumpStart and Basic. The basic templates does not load the module and may act as stand alone scripts while the PSJumpStart templates is using the included module. The templates are  `Get-Help` enabled. 

A template `CMD` file is also provided for calling PowerShell scripts with `StdOut` and `StdErr` capturing.  The primary intended use is launching PS-scripts from Task Scheduler as unhandled errors cannot be traced otherwise. It is a generic template and may be used to launch any PowerShell script.

Some fully featured test/sample scripts are included for reference.

One sample `ps1xml` file is included for extending the `HashTable` object type with methods for `Replace` and `AppendValue`.

## Why?

Because we are system administrators that just want to get going with PowerShell using basic supporting functions for common use.

Because we want a jump start for writing a script with `Get-Help` support.

Because we want to be able to copy a script from one environment to another without the need to change them making code signing easier (or less of a hassle).

Because we want to choose how output (messages, verbose and errors) are handled for each site and/or environment without rewriting the scripts. Log to windows eventlog, a log file or only to `StdOut`?

Because we want to be able to set default parameters depending on user, domain or script but be able to override these default parameters by using script arguments. 

Because we want to choose the depth of the PowerShell rabbit hole. Entry level to deep-sea diving.

## Practical usage

Have a look in the `PSJumpStart.dfp`file (in the module folder) using a text editor. Those are the least significant default settings. Use them to set your preferred configurations (see `$PSDefaultParameterValues` for details).

### Using `dfp` files

These files may be used to set default values for script input arguments as well as function call arguments. The syntax for setting default values for standard functions follow the `$PSDefaultParameterValues`

`Function-Name:Argument-Name=value/code`

To use a `dfp` file as a repository for standard input argument values to a `ps1 `  you remove the function name part of the line above

`Argument-Name=value/code`

So if you are using a site name argument in several scripts  ,`[string]$SiteName` , you may create a domain `dfp`file with `SiteName="www.whatever.com"`

#### Arguments load order

The `dfp`files are read in a specific order where the most significant setting will rule over the lower order settings. The order of loading is:

1. Provided arguments will always override any file settings,
2. User logon ID file name in script folder
3. Logon provider file name (domain or local machine) in script folder
4. Script name file in script folder
5. Logon provider file name (domain or local machine) in PSJumpStart module folder
6. Any other loaded module name in the PSJumpStart module folder (for instance an `ActiveDirectory.dfp` file)
7. The `PSJumpStart.dfp`file in the module folder.

Use the `-verbose` for any PSJumpStart template script to see the order of loading.

### The art of logging

The `dfp`files may also be used to setup the logging environment by setting default variables for the `Msg`function. It may write output to log files, event log or output to console only. Please remember to run any PowerShell as Adminstrator the first time to create any custom log name in the event log. The use of the settings files will enable you to set different event log names, but use this carefully as any script registered for a log name cannot write to another event log name.

#### The Task Scheduler problem

This module comes with a `.cmd` file used for calling its corresponding PowerShell. The `runCleanupEmptyGroups.cmd` will launch the `CleanupEmptyGroups.ps1` PowerShell script with any provided arguments. The default behaviour of this template is to catch any output from the PowerShell and dump it to a log file in a `logs` sub folder. If any unhandled exceptions occur they will be put in a separate `ERR_` log file.
The primary use for this is in the Task Scheduler. If you launch a PowerShell script directly from Task Scheduler you will not be able to get the exception data written by the PowerShell script. The `.cmd` file will trap and log the information.
The recomendation for Task Scheduled scripts is using a `.dfp` named after the service account running the job. Then you may turn off any other logging method for `.ps1` files and let the `.cmd` file handle logging to file.

### How to debug

The problem; If you are calling a function in a loaded module and want to see the results from `Write-Verbose` you need to add `-Verbose:$VerbosePrefererence` in the arguments for the call. By using  `dfp` files you may activate debug mode for whatever part you need.

#### Global debugging

Edit the PSJumpStart module `dfp`file to activate debug mode for ALL scripts, modules and function calls: set `*:Verbose=$true`in the file. The next execution session will activate verbose mode across the board. This can be done by using a specific user `dfp`file so only that user will get verbose feedback.

#### Specific script debugging

To debug your script as well as get `Write-Verbose`printouts from ALL used modules and functions;

1. Create a `dfp`file with the same name as your script.
2. Put `*:Verbose=$true`in it.
3. Run the script to load `Verbose` mode in current session.

Using the argument `-Verbose` at the command prompt will override the `dfp`file settings introducing the limits mentioned before, but may be needed at some scenarios.

#### Function debugging

If you only need to get verbose printout from a specific function you can add `Function-Name:Verbose=$true` in any `dfp` file.

### The templates

In the `Templates`folder (living in the module folder) is a set of templates. Use `Find-PSTemplate`in the PSJumpStart module to list the template files. Copy a template to your preferred working space by using `Copy-PSTemplate`.

### Local customized functions

During loading of functions the `PSJumpStart.psm1`file will load any `ps1`function files from the folder `LocalLib` in the modules folder. Customized functions will override any PSJumpStart functions. So you may add any local functions to enhance the module.

### Script signing

There is a little stand alone feature in the `Templates`folder for script signing. It will search for a valid `CodeSigning`  capable certificate on the local computer. If not found a new self signed certificate will be created. The found/new certificate is then used to sign single scripts or all scripts in a folder. 

This feature is **not** dependent on the PSJumpStart module.

## Down the rabbit hole

Let's have a quick look at some of the main features in the package. 

### `$PSDefaultParameterValues`

The use of `dfp` files separates default parameters from the PowerShell scripts. The `dfp` files are loaded in a preset order where the first encountered setting is used. So user preference will override the default settings for the `psm1` module file. The preset order is defined in the `Get-SettingFiles` function. The `Get-GlobalDefaultsFromDfpFiles` populates the PowerShell variable from file content.

 As the `$PSDefaultParameterValues` may be set for all functions it is possible for `Write-Verbose` to present output from functions in `psm1` modules without typing `-Verbose:$VerbosePrefererence` in ALL function calls or the use of `Get-CallerPreference` command (which by the way is included for reference):

[The story behind the `Get-CallerPreference`function](https://blogs.technet.microsoft.com/heyscriptingguy/2014/04/26/weekend-scripter-access-powershell-preference-variables/)

[The code source](https://gallery.technet.microsoft.com/scriptcenter/Inherit-Preference-82343b9d)

More information on the use of `$PSDefaultParameterValus`:
[The Microsoft Docs Tale](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-6)

[Some practical usage samplings](https://www.red-gate.com/simple-talk/sysadmin/powershell/powershell-time-saver-automatic-defaults)


### The `Msg` function

The unified way of writing output information from calling scripts. Do not use this function from any `psm1` functions as it does not support nested environments (yet). Use `Write-Verbose` to debug `psm1` functions instead. 

### The `$CallerInvocation` story

To ensure correct environment the `$CallerInvocation` is used as input parameter by some functions in the `psm1`file. The input should be `$MyInvocation`of the root caller script.

[Some words on the PowerShell module environment](https://www.red-gate.com/simple-talk/dotnet/.net-tools/further-down-the-rabbit-hole-powershell-modules-and-encapsulation/)

### `Hashtable` type add-on

The PSJumpStart module will add two methods to the `Hashtable` variable type.  The `Replace`method will add or replace an existing value in a hashtable. The `AppendValue`will append new values to any existing data by creating an array of values.

[The inspiration for enhancing the `Hashtable` object type by using a `ps1xml` file](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_types.ps1xml?view=powershell-6)

[Some words on `Hashtables`](https://kevinmarquette.github.io/2016-11-06-powershell-hashtable-everything-you-wanted-to-know-about/)

### Notes

[A nice article on the practical use of CustomObjects in PowerShell](https://social.technet.microsoft.com/wiki/contents/articles/7804.powershell-creating-custom-objects.aspx)

## Stolen with pride

Some of the functions included has been found "out-there". The author name and/or a link to the source is provided to give credit where credit is due.

There are some references in the `Get-Help`notes section for some of the basic functions to dive deeper into the rabbit hole. 

## Contribute

Please feel free to suggest improvements or contribute with functions. As the end line from the movie `The Matrix` puts it:

"A world where anything is possible. Where we go from there is a choice I leave to you."

Keep up the good work.
