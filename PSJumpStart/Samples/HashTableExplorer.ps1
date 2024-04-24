[CmdletBinding(SupportsShouldProcess = $True)]
Param(    
)
#region localfunctions
function ShowHash($hash) {
    foreach($key in $hash.Keys) {
        Msg("$key -> " + $hash[$key])
    }
}
function localAppendValue($this,$key,$value) {

            if ($this.ContainsKey($key)) {
		        $currentData = $this[$key]                
		        $this.Remove($key)
                $this.Add($key,@($currentData,$value))
                
                #OLD code
                #switch ($currentData.GetType()) {
                #    "String" {
                #        $this.Add($key,$currentData + $data)
                #        break        
                #    }
                #    "Int*" {
                #        $this.Add($key,$currentData + $data)
                #        break
                #    }
                #    default {
                #        $newData = @($currentData,$value)
                #        $this.Add($key,$newData)
                #        break
                #    }
                #}		        
	        } else {
		        $this.Add($key,$data)
	        }
}
#end region

#Load the module
get-module PSJumpStart | Remove-Module;
Import-Module PSJumpStart -Force

Msg "Start Execution"    

Msg "Create a std HashTable"
$hashis = @{
    "Apple"="Green"
    "Lemon"="Yellow"
    "Banana"="Yellow"
    "MyNum" = 3
}

Msg "---------- Init ---------"
ShowHash $hashis

localAppendValue $hashis "Banana" "Green"
$hashis.AppendValue("MyNum",8)
$hashis.Replace("Apple","Red")

Msg "------ Changed --------"
ShowHash $hashis


Msg "------ Add hash to Hash --------"
$hashis.Add("SubHash",$hashis)
ShowHash $hashis


Msg "------ Append hash to key 'SubHash' --------"
$hashis.AppendValue("SubHash",$hashis)
ShowHash $hashis

Msg "------ Object added --------"
$hashis.Add("web",([net.WebRequest]::Create("https://www.powershellgallery.com")))
ShowHash $hashis


Msg "------ Object appended to key 'web' --------"
$hashis.AppendValue("web",(New-Object Net.WebClient))
ShowHash $hashis


Msg "End Execution"
