BeforeAll {        
    Import-Module "$PSScriptRoot/../PSJumpstart.psd1" -Force        
    $samplesFolder="$PSScriptRoot/../Samples"
    $tempFolder = [System.IO.Path]::GetTempPath() + "_Tests" + $([Guid]::NewGuid())
    md $tempFolder
    Copy-Item -Path "$samplesFolder\*.*" -Destination $tempFolder -Container
}


Describe "Add-ScriptHeader" -Tag "Add-ScriptHeader" {
    

    It 'Test if the function Add-ScriptHeader exists' {
        $actual = Get-Command Add-ScriptHeader -ErrorAction SilentlyContinue
        $actual | Should -Not -BeNullOrEmpty
    }   
    
    It 'Generate missing header for a sample file' {
        $file="HashTableExplorer.ps1"
        Add-ScriptHeader -FullName "$tempFolder\$file" -Synopsis "Usage demo of Hashtables"
        $actual =  Compare-Object -ReferenceObject (Get-Content "$samplesFolder\$file") -DifferenceObject (Get-content "$tempFolder\$file")
        $actual.Count | Should -Be 7
    }

    It 'Generate missing argument for a sample file' {
        $file="ArgDemo.ps1"
        Add-ScriptHeader -FullName "$samplesFolder\$file" -Synopsis "Argument demo"
        $actual =  Compare-Object -ReferenceObject (Get-Content "$samplesFolder\$file") -DifferenceObject (Get-content "$tempFolder\$file")
        $actual.Count | Should -Be 16
    }

    It 'Enumerate sample folder to check for headers' {        
        $Ref = Get-ChildItem $samplesFolder | Add-ScriptHeader -WhatIf
        $actual = Get-ChildItem $tempFolder | Add-ScriptHeader -WhatIf
        $Ref.Count - $actual.Count | Should -Be 2
    }
}

AfterAll { 
    #Cleanup file system items
    rd $tempFolder -Recurse -Force
}