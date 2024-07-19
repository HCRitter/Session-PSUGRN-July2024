Get-MGuser -UserId '123456' 

Find-MgGraphCommand -Command Get-MGUser

$Scriptblock = {
    $User = get-mguser -UserId '123'
    $Device = Get-MgDevice -DeviceID '654321'
    $Application = Get-MgApplication -ApplicationID '789'
    $Files = Get-Childitem C:\Temp
}

function Get-MGGraphNativeCalls {
    [CmdletBinding()]
    param (
        $ScriptBlock
    )
    
    begin {
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Scriptblock,[ref]$null, [ref]$null)
    }
    
    process {
        $GraphCommandList = new-object System.Collections.Generic.List[pscustomobject]
        $Null = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.AssignmentStatementAst]}, $true) | Where-Object {$(
            try {
                $Command = Get-Command $($_.Right.Extent.Text -split ' ')[0] -ErrorAction SilentlyContinue
                if($Command.Source -notlike 'Microsoft.Graph*'){throw}

                $GraphCommandList.Add($Command)

            }
            catch {
                $false
            }
        )}
        $ID = 0


        $ReturnObject = foreach($GraphCommand in $GraphCommandList){
            $ID++
            $NativeCommand = Find-MgGraphCommand -Command $GraphCommand.Name
            [pscustomobject]@{
                ID = $ID
                url = $NativeCommand[1].URI
                method = $NativeCommand[1].Method
            }
        }
    }
    
    
    end {
        return $ReturnObject
    }
}

Get-MGGraphNativeCalls -ScriptBlock $Scriptblock   