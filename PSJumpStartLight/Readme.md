# PSJumpStartLight

## Introduction
This is **NOT** a PowerShell module. PSJumpStartLight is a set of files to jumpstart the creation of a solution environment. The principal for the environment is;

- Scripts to launch by a user is placed in a main folder.
- Script templates for main scripts is placed in the main folder.
- PowerShell common function scripts called by main scripts is places in a `Functions` subfolder.

The provided templates will load all functions found in the `Functions` subfolder.

### Why?
Because we want to create a PowerShell solution without any module dependency but still want to have access to common functions.

Because we want to have a custom set of functions cherry picked from GitHub

Because we want to jumpstart the PowerShell script solution authoring

## Installation
Download `Get-PSJumpStartLightFromGitHub.ps1` and `GetJumpStartFiles.json` to a local solution folder. Edit the `json` file to cherry pick PowerShell files from GitHub (or any other WEB source). Launch `Get-PSJumpStartLightFromGitHub.ps1` to create a new solution environment.

### JSON file syntax
This is a descriptive syntax sample `json` file:
```json
{
    "Solution Name":{
        "Url":"base download url",
        "Files":["File1.ps1","File1.ps1"],
        "LocalFolder":"Local target folder"
    }
}
```
The **"base download url"** is the source url at GitHub for example the url `https://raw.githubusercontent.com/jaols/PSJumpStart/refs/heads/master/PSJumpStart/Templates` will download files from [the PSJumpStart template folder](https://github.com/jaols/PSJumpStart/tree/master/PSJumpStart/Templates). The url `https://github.com/jaols/ServiceAccountHandler/archive/refs/heads` will get the `master.zip` zip file from the Code download button at [ServiceAccountHandler](https://github.com/jaols/ServiceAccountHandler).
The **Files** list is the cherry picking list of functions to get or the `zip` file name for the full code download.
**LocalFolder** is the local target subfolder. It is possible to use `($libraryName)` which is the command argument value for `Get-PSJumpStartLightFromGitHub.ps1`.

[This article describes how to retreive base Urls from GitHub](https://blog.ironmansoftware.com/daily-powershell/powershell-download-github/)

## Usage
Copy one of the provided templates to a new name and edit the header and input parameter section. 

Add code. 
Test. 
Repeat.

## Down the rabbit hole
The provided templates is based on the same principles as the [PSJumpStart templates](https://github.com/jaols/PSJumpStart/tree/master/PSJumpStart/Templates) but without loading the module. This code will load all `ps1` files fromn the `Functions`folder:
```powershell
foreach($Import in @(Get-ChildItem -Path "$scriptPath\Functions\*.ps1" -ErrorAction SilentlyContinue)) {
    try {
        Write-Verbose "Load $($Import.FullName)"
        . $Import.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}
```
Most features are available according to the [PSJumpstart documentation](https://github.com/jaols/PSJumpStart/tree/master/PSJumpStart). The following features are **NOT** available:
- Automatic DLL file loading
- Format files loading
- TypeData files loading (`Hashtable` will not have the methods `AppendValue` or `Replace`)

## Contribute
Please post an issue for any feedback


