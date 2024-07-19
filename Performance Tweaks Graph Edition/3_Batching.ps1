# basic explaination url: https://learn.microsoft.com/en-us/graph/json-batching

# The Microsoft Graph API supports batching, which allows you to send multiple HTTP requests in a single network call. This can help you improve the performance of your app by reducing the number of network calls you need to make. Batching is supported in Microsoft Graph API version 1.0 and later.

#region Setup Transform to batch request

class JSONTransform : System.Management.Automation.ArgumentTransformationAttribute{
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics,[object]$InputData){
        $batchGraphRequestSchema = @{
            '$schema' = 'http://json-schema.org/draft-07/schema#'
            'type' = 'object'
            'properties' = @{
                'requests' = @{
                    'type' = 'array'
                    'items' = @{
                        'type' = 'object'
                        'properties' = @{
                            'id' = @{
                                'type' = 'string'
                            }
                            'method' = @{
                                'type' = 'string'
                                'enum' = @('GET', 'PUT', 'PATCH', 'POST', 'DELETE')
                            }
                            'url' = @{
                                'type' = 'string'
                                'pattern' = '^\/[a-zA-Z0-9\/$&=?,]+$'
                            }
                            'headers' = @{
                                'type' = 'object'
                                # Additional properties for headers schema if needed
                            }
                            'body' = @{
                                'type' = 'object'
                                # Additional properties for body schema if needed
                            }
                        }
                        'required' = @('id', 'method', 'url')
                        'propertyNames' = @{
                            'enum' = @('id', 'method', 'url', 'headers', 'body')
                        }
                    }
                }
            }
            'required' = @('requests')
        }
        $counter = [pscustomobject] @{ Value = 0 }
        $BatchSize = 20
        $Batches = $InputData | Group-Object -Property { [math]::Floor($counter.Value++ / $BatchSize) }
        $ReturnBatches = foreach($Batch in $Batches){
            $ReturnObject = @{
                requests = $Batch.Group
            } | ConvertTo-Json -Depth 6
    
            try {
                $Null = $ReturnObject | Test-Json -Schema $($batchGraphRequestSchema | Convertto-Json -Depth 6) -ErrorAction Stop
            }
            catch {
                write-host $ReturnObject
                
                Throw "$($_.Exception.Message). JSON Schema did not match"
            }
            $ReturnObject
        }
        return $ReturnBatches
    }
}
function ConvertTo-MSGraphBatchRequest {
    [CmdletBinding()]
    param (
        [jsontransform()]$Requests
    )
    
    begin {

    }
    
    process {
        
    }
    
    end {
        return $Requests
    }
}

#endregion


#region Sample Usage

$Ht1 = @{
    id = '1'
    method = 'GET'
    url = '/users'
}
$Ht2 = @{
    id = '2'
    method = 'GET'
    url = '/devices'
}

$Ht3 = @{
    id = '3'
    method = 'GET'
    url = '/groups'
}

$PSCO1 =[PSCustomObject]@{
    id = '4'
    method = 'GET'
    url = '/users'
}

ConvertTo-MSGraphBatchRequest -Requests @($Ht1,$Ht2,$Ht3,$PSCO1)

#endregion