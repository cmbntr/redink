<#
.SYNOPSIS
Creates a new self-signed certificate suitable for Authenticode code signing.

.DESCRIPTION
Generates a self-signed certificate with a given subject string (default:
"CN=cmbntr-redink") and exports:
- A PFX file (including private key)
- A CER file (public certificate only)

By default, output files are created in the current directory (Get-Location).
Use -OutputPath to override.

The certificate is created in Cert:\CurrentUser\My with:
- 10-year validity
- Intended purpose: Code Signing (Authenticode)
- Exportable private key

.PARAMETER Subject
The subject string for the certificate.
Defaults to "CN=cmbntr-redink".

.PARAMETER Password
The password used to protect the exported PFX file.

.PARAMETER OutputPath
Directory where the certificate files will be written.
Defaults to the current directory (Get-Location).

.EXAMPLE
.\New-RedinkCert.ps1 -Password (Read-Host -AsSecureString "PFX Password")

.EXAMPLE
.\New-RedinkCert.ps1 -Subject "CN=MyCodeSigningCert" -Password (Read-Host -AsSecureString "PFX Password") -OutputPath "D:\Certs"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Subject = 'CN=cmbntr-redink',

    [Parameter(Mandatory = $true)]
    [SecureString]$Password,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = $(Get-Location)
)

begin {
    # Normalize output path
    try {
        $OutputPath = (Resolve-Path -Path $OutputPath).ProviderPath
    } catch {
        Write-Verbose "Output path does not exist. Attempting to create it: $OutputPath"
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        $OutputPath = (Resolve-Path -Path $OutputPath).ProviderPath
    }

    Write-Verbose "Certificates will be written to: $OutputPath"
}

process {
    try {
        # Create self-signed cert for Authenticode code signing
        $cert = New-SelfSignedCertificate `
            -Subject $Subject `
            -CertStoreLocation "Cert:\CurrentUser\My" `
            -KeyExportPolicy Exportable `
            -KeyLength 2048 `
            -KeyAlgorithm RSA `
            -HashAlgorithm SHA256 `
            -NotAfter (Get-Date).AddYears(10) `
            -Type CodeSigningCert

        if (-not $cert) {
            throw "Failed to create the self-signed certificate."
        }

        Write-Host "Created certificate with thumbprint: $($cert.Thumbprint)"

        # Output filenames
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        # Make a safe base name from the subject (remove non-filename chars)
        $safeSubject = ($Subject -replace '[^a-zA-Z0-9\-_.]+','_')
        $baseName  = "$($safeSubject)-$timestamp"

        $pfxPath = Join-Path $OutputPath "$baseName.pfx"
        $cerPath = Join-Path $OutputPath "$baseName.cer"

        # Export PFX (with private key)
        Export-PfxCertificate `
            -Cert $cert `
            -FilePath $pfxPath `
            -Password $Password `
            -Force | Out-Null

        # Export CER (public only)
        Export-Certificate `
            -Cert $cert `
            -FilePath $cerPath `
            -Force | Out-Null

        Write-Host "PFX exported to: $pfxPath"
        Write-Host "CER exported to: $cerPath"
        Write-Host "Thumbprint: $($cert.Thumbprint)"

        $bytes = [System.IO.File]::ReadAllBytes($pfxPath)
        $base64 = [System.Convert]::ToBase64String($bytes)
        Write-Host "PFX base64`n$base64"

    }
    catch {
        Write-Error $_.Exception.Message
        throw
    }
}
