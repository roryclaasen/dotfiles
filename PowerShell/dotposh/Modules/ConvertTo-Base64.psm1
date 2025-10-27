function ConvertTo-Base64 {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Mandatory = $true)]
        $InputObject
    )

    return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($InputObject))
}

Set-Alias 'base64' 'ConvertTo-Base64'

Export-ModuleMember -Function ConvertTo-Base64
Export-ModuleMember -Alias 'base64'
