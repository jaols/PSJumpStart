<# 
  .SYNOPSIS 
  Create a random password 
 
  .DESCRIPTION 
  The function creates a random password using a given set of available characters. 
  The password is generated with fixed or random length. 
 
  .PARAMETER MinPasswordLength 
  Minimum password length when generating a random length password 
 
  .PARAMETER MaxPasswordLength 
  Maximum password length when generating a random length password 
 
  .PARAMETER PasswordLength 
  Fixed password length 
 
  .PARAMETER InputStrings 
  String array containing sets of available password characters 
 
  .PARAMETER FirstChar 
  Specifies a string containing a character group from which the first character in the password will be generated 
 
  .PARAMETER Count 
  Number of passwords to generate, default = 1 
 
  .EXAMPLE 
  New-RandomPassword -MinPasswordLength 6 -MaxPasswordLength 12 
  Generates a random password fo minimum length 6 andmaximum length 12 characters 
 
  .EXAMPLE 
  New-RandomPassword -PasswordLength 20 
  Generates a password of 20 characters 
 
  .EXAMPLE 
  New-RandomPassword -InputStrings Value -FirstChar Value -Count Value 
  Describe what this call does 
 
  .NOTES 
  Author of function: Thomas Stensitzki 
  Stolen from: https://github.com/Apoc70/GlobalFunctions/blob/master/GlobalFunctions/GlobalFunctions.psm1
  Based on Simon Wahlin's script published here: https://gallery.technet.microsoft.com/scriptcenter/Generate-a-random-and-5c879ed5 
  Story behind: http://blog.simonw.se/powershell-generating-random-password-for-active-directory/

#>
function New-RandomPassword {
    [CmdletBinding(DefaultParameterSetName='FixedLength')]
    [OutputType([String])] 
    param(
      [Parameter(ParameterSetName='RandomLength')]
      [ValidateScript({$_ -gt 0})]
      [Alias('Min')] 
      [int]$MinPasswordLength = 8,
            
      [Parameter(ParameterSetName='RandomLength')]
      [ValidateScript({
              if($_ -ge $MinPasswordLength){$true}
              else{Throw 'Max value cannot be lesser than min value.'}})]
      [Alias('Max')]
      [int]$MaxPasswordLength = 12,
    
      [Parameter(ParameterSetName='FixedLength')]
      [ValidateRange(1,2147483647)]
      [int]$PasswordLength = 8,
            
      [String[]]$InputStrings = @('abcdefghjkmnpqrstuvwxyz', 'ABCEFGHJKLMNPQRSTUVWXYZ', '23456789', '=+_?!"*@#%&'),
    
      [String] $FirstChar,
            
      # Specifies number of passwords to generate.
      [ValidateRange(1,2147483647)]
      [int]$Count = 1
    )
    
      Function Get-Seed{
                # Generate a seed for randomization
                $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
                $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
                $Random.GetBytes($RandomBytes)
                [BitConverter]::ToUInt32($RandomBytes, 0)
            }
    
      For($iteration = 1;$iteration -le $Count; $iteration++){
        $Password = @{}
        # Create char arrays containing groups of possible chars
        [char[][]]$CharGroups = $InputStrings
    
        # Create char array containing all chars
        $AllChars = $CharGroups | ForEach-Object {[Char[]]$_}
    
        # Set password length
        if($PSCmdlet.ParameterSetName -eq 'RandomLength')
        {
            if($MinPasswordLength -eq $MaxPasswordLength) {
                # If password length is set, use set length
                $PasswordLength = $MinPasswordLength
            }
            else {
                # Otherwise randomize password length
                $PasswordLength = ((Get-Seed) % ($MaxPasswordLength + 1 - $MinPasswordLength)) + $MinPasswordLength
            }
        }
    
        # If FirstChar is defined, randomize first char in password from that string.
        if($PSBoundParameters.ContainsKey('FirstChar')){
            $Password.Add(0,$FirstChar[((Get-Seed) % $FirstChar.Length)])
        }
        # Randomize one char from each group
        Foreach($Group in $CharGroups) {
            if($Password.Count -lt $PasswordLength) {
                $Index = Get-Seed
                While ($Password.ContainsKey($Index)){
                    $Index = Get-Seed                        
                }
                $Password.Add($Index,$Group[((Get-Seed) % $Group.Count)])
            }
        }
    
        # Fill out with chars from $AllChars
        for($i=$Password.Count;$i -lt $PasswordLength;$i++) {
            $Index = Get-Seed
            While ($Password.ContainsKey($Index)){
                $Index = Get-Seed                        
            }
            $Password.Add($Index,$AllChars[((Get-Seed) % $AllChars.Count)])
        }
      }
    
      return $(-join ($Password.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value))
    
    }
    