<#
.SYNOPSIS
    Retrieves application permissions for Microsoft Graph API registered applications.

.DESCRIPTION
    This script imports the Microsoft.Graph.Application module and retrieves the application permissions for registered applications in Microsoft Graph API.
    It iterates through each application and retrieves the display name, application ID, ID, service principal ID, and scopes.

.PARAMETER None

.EXAMPLE
    Get-AppRegistrationApplicationPermission.ps1
    - This example runs the script and retrieves the application permissions for registered applications.

.NOTES
    - This script requires the Microsoft.Graph.Application module to be installed.
    - The script requires appropriate permissions to access the Microsoft Graph API.
#>

$AppRoles = (Get-MgServicePrincipal -All | Where-Object AppId -eq '00000003-0000-0000-c000-000000000000').AppRoles

Get-MgApplication | Foreach-Object {
    [PSCustomObject]@{
        DisplayName         = $_.DisplayName
        AppId               = $_.AppId
        ID                  = $_.ID
        ServicePrincipalID  = $ServicePrincipalID = (Get-MgServicePrincipalByAppId -AppId $_.AppId).ID
        Scopes              = $((Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipalID).AppRoleId.ForEach({
                                ($AppRoles | Where-Object Id -eq $_).Value
                            }))
    }
}
