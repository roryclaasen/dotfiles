function ConvertTo-Base64 {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Mandatory = $true)]
        $InputObject
    )

    begin {
        $lines = [System.Collections.Generic.List[object]]::new()
    }

    process {
        $lines.Add($InputObject)
    }

    end {
        if ($lines.Count -eq 1 -and $lines[0] -is [byte[]]) {
            return [Convert]::ToBase64String($lines[0])
        }
        else {
            $isFormatData = $lines[0].GetType().FullName -like 'Microsoft.PowerShell.Commands.Internal.Format.*'
            if ($isFormatData) {
                $inputContents = ($lines | Out-String).TrimEnd()
            }
            else {
                $inputContents = [string]::Join([Environment]::NewLine, $lines)
            }

            return [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($inputContents))
        }
    }
}

function ConvertFrom-Base64 {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Mandatory = $true)]
        $InputObject
    )

    begin {
        $lines = [System.Collections.Generic.List[string]]::new()
    }

    process {
        $lines.Add("$InputObject")
    }

    end {
        $inputContents = [string]::Concat($lines).Trim()
        return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($inputContents))
    }
}

Set-Alias 'base64' 'ConvertTo-Base64'

Export-ModuleMember -Function ConvertTo-Base64
Export-ModuleMember -Function ConvertFrom-Base64
Export-ModuleMember -Alias 'base64'
