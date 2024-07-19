# list all users in our tenant

$UserEntra = Get-EntraUser -all
$UserMGUser = Get-MGUSer -all


#region explaination
# How to tweak the performance of the Get-MGUser function
#   1. Use the -PageSize parameter to specify the number of objects to retrieve in each request.
#       1.1 The default page size is 100, but you can adjust it based on your requirements.
#   2. Use the -Select parameter to specify the properties to include in the response.
#       2.1 By default, all properties are included in the response, but you can limit the properties to reduce the response size.
#   3. Use a custom function to retrieve all objects from the Microsoft Graph API and reduce overhead.
#endregion

# How to see what is the default Pagesize result

$Result = Invoke-MgGraphRequest -Method Get -Uri 'https://graph.microsoft.com/v1.0/users?$select=ID,DisplayName' -OutputType PSObject
$Result.value.Count



function Get-MSGraphAllObjects {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $EndPoint,
        [Parameter(Position = 1)]
        [validaterange(1,999)]
        [int] $ChunkSize = 999,
        [switch] $Beta
    )

    $Route = $beta ? "beta" : "v1.0"

    $URI = 'https://graph.microsoft.com/{0}/{1}?$Top={2}&$select=ID,DisplayName' -f $Route,$EndPoint,$ChunkSize
    $ReturnCollection = new-object System.Collections.Generic.List[pscustomobject]
    
    $Return = (Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject)
    $($Return.value.ForEach({
        $ReturnCollection.Add($_)
    }))
    while(-not([string]::IsnullorEmpty($Return.'@odata.nextlink'))){
        $Return = (Invoke-MgGraphRequest -Method GET -Uri $Return.'@odata.nextlink' -OutputType PSObject)
        $($Return.value.ForEach({
            $ReturnCollection.Add($_)
        }))
    }
    return $ReturnCollection
}

$MeasureTable  = @{
    'Default' = (Measure-Command -Expression {
        $users = Get-MgUser -all
    }).TotalSeconds
    'PageSize' = (Measure-Command -Expression {
        $users = Get-MgUser -all  -PageSize 999 
    }).TotalSeconds
    'Select' = (Measure-Command -Expression {
        $users = Get-MGUser -all -Select ID,DisplayName
    }).TotalSeconds
    'SelectPageSize' = (Measure-Command -Expression {
        $users = Get-MGUser -all -Select ID,DisplayName -PageSize 999
    }).TotalSeconds
    'CustomFunction' = (Measure-Command -Expression {
        $users = Get-MSGraphAllObjects -EndPoint "users" -ChunkSize 999
    }).TotalSeconds
}

$MeasureTable.GetEnumerator() | Sort-Object -property:Value

<#
    Name                           Value
    ----                           -----
    CustomFunction                 4.4028461
    SelectPageSize                 6.0286606
    PageSize                       6.8663974
    Select                         27.753859
    Default                        29.2612907
#>





# How to just count the number of users in the tenant


Invoke-MgGraphRequest -Method Get -Uri 'https://graph.microsoft.com/v1.0/users/$count'  -Headers @{'ConsistencyLevel'='eventual'} -OutputFilePath 'C:\Temp\Out.out' | out-null
Get-MgUser  -CountVariable CountVar  -ConsistencyLevel eventual | out-null

$MeasureTableTotalCount = @{
    'Custom' = (Measure-Command -Expression {
        Invoke-MgGraphRequest -Method Get -Uri 'https://graph.microsoft.com/v1.0/users/$count'  -Headers @{'ConsistencyLevel'='eventual'} -OutputFilePath 'C:\Temp\Out.out' | out-null
    }).TotalSeconds
    'Get-MgUser' = (Measure-Command -Expression {
        Get-MgUser -CountVariable CountVar  -ConsistencyLevel eventual | out-null
    }).TotalSeconds
    'Get-MgUserCount' = (Measure-Command -Expression {
        Get-MgUserCount -ConsistencyLevel eventual
    }).TotalSeconds
}

<#

    Name                           Value    
    ----                           -----    
    Get-MgUser                     0.5989553
    Custom                         1.5430743

#>