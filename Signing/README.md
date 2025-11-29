## Generate Certificate

```powershell
./New-RedingCert.ps1
```

## Trust Certificate

```powershell
$cert = Get-Item ./CN_cmbntr-redink-*.cer
Import-Certificate -CertStoreLocation 'Cert:\CurrentUser\Root' $cert
Import-Certificate -CertStoreLocation 'Cert:\CurrentUser\TrustedPublisher' $cert
```
