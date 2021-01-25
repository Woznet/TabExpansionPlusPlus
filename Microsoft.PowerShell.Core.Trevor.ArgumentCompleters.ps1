#
# .SYNOPSIS
#
#    Complete the -ArgumentList parameter value for the PowerShell New-Object cmdlet.
#
# .NOTES
#
#    Created by Trevor Sullivan <trevor@trevorsullivan.net>
#    http://trevorsullivan.net
#    http://twitter.com/pcgeek86
#
function NewObject_ArgumentListCompleter
{
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    function Get-TypeConstructor {
        <#
        .Synopsis
        Returns PowerShell-friendly constructor parameters for the New-Object -ArgumentList parameter.

        .Outputs
        [System.String[]]
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [System.Type] $Type
        )

        $ConstructorList = $Type.GetConstructors();

        foreach ($Constructor in $ConstructorList) {
            $ParameterList = $Constructor.GetParameters();
            $ParamString = '@(';
            foreach ($Parameter in $ParameterList) {
                $ParamString += '[{0}] ${1}, ' -f $Parameter.ParameterType, $Parameter.Name;
            }
            $ParamString = ($ParamString -replace ',\s*$', '') + ')';
            Write-Output -InputObject $ParamString;
        }
    }

    ### Attempt to read results from the cache
    $CacheKey = 'NewObject_ArgumentListCache'
    $Cache = Get-CompletionPrivateData -Key $CacheKey

    ### If there is a valid cache, then go ahead and return it
    if ($Cache -and (Get-Date) -gt $Cache.ExpirationTime) {
        #return $Cache
    }

    ### Create fresh completion results
    $ItemList = Get-TypeConstructor -Type $fakeBoundParameter['TypeName'] | ForEach-Object {
        $CompletionResult = @{
            CompletionText = $PSItem
            ToolTip = $PSItem
            ListItemText = $PSItem
            CompletionResultType = [System.Management.Automation.CompletionResultType]::ParameterValue
            NoQuotes = $true
            }
        New-CompletionResult @CompletionResult
    }

    ### If the object has no constructors, then return an object indicating such
    if (!$ItemList) {
        $CompletionResult = @{
            CompletionText = 'No constructors.' -f $fakeBoundParameter['TypeName']
            ToolTip = 'No constructors found for {0} type.' -f $fakeBoundParameter['TypeName']
            ListItemText = 'No constructors ({0})' -f $fakeBoundParameter['TypeName'];
            CompletionResultType = [System.Management.Automation.CompletionResultType]::ParameterValue
            NoQuotes = $false
            }
        New-CompletionResult @CompletionResult
    }

    ### Update the cache
    Set-CompletionPrivateData -Key $CacheKey -Value $ItemList

    ### Return the fresh completion results
    return $ItemList
}

Register-ArgumentCompleter `
    -Command @('New-Object') `
    -Parameter ArgumentList `
    -ScriptBlock $function:NewObject_ArgumentListCompleter

