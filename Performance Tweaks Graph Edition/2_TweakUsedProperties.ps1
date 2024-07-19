#region Function Definition

<#
.SYNOPSIS
    Retrieves improvements for Microsoft Graph property parameters in a scriptblock.

.DESCRIPTION
    The Get-MSGraphPropertyParameterImprovements function parses a scriptblock and identifies property parameters used in Microsoft Graph commands. It then compares the used properties with the available property parameters and determines if there are any improvements that can be made.

.PARAMETER Scriptblock
    The scriptblock to be parsed and analyzed.

.OUTPUTS
    System.Management.Automation.PSCustomObject
    The function returns a custom object with the following properties:
    - Command: The Microsoft Graph command found in the scriptblock.
    - VariableName: The name of the variable used in the scriptblock.
    - UsedProperties: The properties used in the scriptblock.
    - PropertyParameter: The property parameters found in the scriptblock.
    - hasImprovement: Indicates if there are any improvements that can be made.
    - Improvement: The improved command with updated property parameters, if applicable.

.EXAMPLE
    $Scriptblock = {
        $User = get-mguser -UserId '123456'
        $RandomObject =[PSCustomObject]@{
            Foo = 'Bar'
            UserID = $User.ID
            Mail = $User.Mail
        }
        $Device = Get-MgDevice -DeviceID '654321' -Select 'DisplayName'
        $RandomObject2 =[PSCustomObject]@{
            Bar = 'Foo'
            DeviceID = $Device.ID
            DisplayName = $Device.DisplayName
        }
        $Application = Get-MgApplication -Select ID -ApplicationID '789'
        $RandomObject3 =[PSCustomObject]@{
            Foo = 'Bar'
            ApplicationID = $Application.ID
            DisplayName = $Application.DisplayName
            Random = $Application.Random

        }
        $Summary = Get-MgDeviceManagementSoftwareUpdateStatusSummary -Select 'DisplayName','Status' -Filter "DisplayName eq 'Windows 10'"
        $RandomObject4 =[PSCustomObject]@{
            Foo = 'Bar'
            DisplayName = $Summary.DisplayName
            Status = $Summary.Status
        }
        $Files = Get-Childitem -Path 'C:\' -File
        $Files.FullName
    }

    Get-MSGraphPropertyParameterImprovements -Scriptblock $scriptblock

    This example demonstrates how to use the Get-MSGraphPropertyParameterImprovements function to analyze a scriptblock containing Microsoft Graph commands. It retrieves the improvements for property parameters used in the scriptblock.

#>
function Get-MSGraphPropertyParameterImprovements {
    param (
        $Scriptblock
    )

    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Scriptblock,[ref]$null, [ref]$null)
    $UsedPropertys = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.MemberExpressionAst]}, $true)
    return $ast.FindAll({$args[0] -is [System.Management.Automation.Language.AssignmentStatementAst]}, $true) | Where-Object { $(
            try {
                $Command = Get-Command $($_.Right.Extent.Text -split ' ')[0] -ErrorAction SilentlyContinue
                if($Command.Source -notlike 'Microsoft.Graph*'){throw}
                $true
            }
            catch {
                $false
            }
        ) 
    } | ForEach-Object { 
        [PSCustomObject]@{
            Command             = $Command = $_.Right.Extent.Text
            VariableName        = $VariableName = '${0}' -f $_.Left.VariablePath.UserPath
            UsedProperties      = $UsedProperty = ($UsedPropertys.Member |  Where-Object{ 
                "$($_.Parent.Expression.Extent.Text)" -eq "$($VariableName)"
            }).value
            PropertyParameter   = $PropertyParameter= $($ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst]
            }, $true) | Where-Object{
                $_.CommandElements[0].Value -eq $Command.split(' ')[0] 
            }| ForEach-Object {
                $parameters = for ($i = 0; $i -lt $_.CommandElements.Count; $i++) {
                    $element = $_.CommandElements[$i]
                    if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {
                        $nextElement = if ($i -lt $_.CommandElements.Count - 1) { $_.CommandElements[$i + 1] } else { $null }
                        [PSCustomObject]@{
                            ParameterName = $element.ParameterName
                            Argument = if ($nextElement -and $nextElement -isnot [System.Management.Automation.Language.CommandParameterAst]) { ($nextElement.Extent.Text.Trim().replace("'","")).replace('"','') } else { $null }
                        }
                    }
                }
                $PropertyParameter = ($Parameters | Where-Object ParameterName -eq 'Select')
                if([string]::IsNullOrEmpty($PropertyParameter.Argument)){return $null}
                return $($PropertyParameter.Argument -split ',')
            })
            hasImprovement      = $HasImprovments = $(if([string]::isNullOrEmpty($PropertyParameter)){$true}else{
                -not [string]::IsNullOrEmpty($(Compare-Object -ReferenceObject $PropertyParameter -DifferenceObject $UsedProperty))
            })
            Improvement         = $( if($HasImprovments){
                if([string]::isNullOrEmpty($PropertyParameter)){
                    "$Command -Select $($UsedProperty -join ',')"
                }else{
                    $Command -replace "(?<=-Select\s)(\b[^ ]*\b|'[^']*')(?=\s|$)", $($UsedProperty -join ',')
                }
            }

            )
        }
    }   
}

#endregion


#region Sample Usage

$Scriptblock = {
    $User = get-mguser -UserId '123456'
    $RandomObject =[PSCustomObject]@{
        Foo = 'Bar'
        UserID = $User.ID
        Mail = $User.Mail
    }
    $Device = Get-MgDevice -DeviceID '654321' -Select 'DisplayName'
    $RandomObject2 =[PSCustomObject]@{
        Bar = 'Foo'
        DeviceID = $Device.ID
        DisplayName = $Device.DisplayName
    }
    $Application = Get-MgApplication -Select ID -ApplicationID '789'
    $RandomObject3 =[PSCustomObject]@{
        Foo = 'Bar'
        ApplicationID = $Application.ID
        DisplayName = $Application.DisplayName
        Random = $Application.Random

    }
    $Summary = Get-MgDeviceManagementSoftwareUpdateStatusSummary -Select 'DisplayName','Status' -Filter "DisplayName eq 'Windows 10'"
    $RandomObject4 =[PSCustomObject]@{
        Foo = 'Bar'
        DisplayName = $Summary.DisplayName
        Status = $Summary.Status
    }
    $Files = Get-Childitem -Path 'C:\' -File
    $Files.FullName
}

Get-MSGraphPropertyParameterImprovements -Scriptblock $scriptblock
#endregion