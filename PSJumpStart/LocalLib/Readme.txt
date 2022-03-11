This folder contains locally customized functions. 

A function with the same name as a function in the ordinary functions folder will take over from the supplied one. Local functions will always rule.

If you have a "LocalLib" subfolder in the same folder as your PowerShell file it will override any functions found here or in the main functions folder when calling Import-Module.
