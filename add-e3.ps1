# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    [string] $name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
    return (Join-Path $parent $name)
}

# Temp file locations
$pfxpath = (Join-Path (Get-Location).Path "Certificate.pfx")
$keypath = (Join-Path (Get-Location).Path "privatekey.key")
$certpath =(Join-Path (Get-Location).Path "certificate.crt")
$r3path =(Join-Path (Get-Location).Path "r3path.pem")
$certwithrootpath =(Join-Path (Get-Location).Path "certwithroot.crt")
$outputpfxpath =(Join-Path (Get-Location).Path "certwithroot.pfx")




# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

$SourceSubscription = "xxxx-xxxx-xxxx-xxxx" #dev
$DstSubscription = "xxxx-xxxx-xxxx-xxxx" #sandbox
$CertName = "xxx"
$SrcVault = "xxx"
$DstVault = "xxx"
#$tempfolder = New-TemporaryDirectory
$password = "Import%%%Password##!1234213" #-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})

Select-AzSubscription -SubscriptionId $SourceSubscription

$SrcThumbprint = (Get-AzKeyVaultCertificate -VaultName $SrcVault -Name $CertName).Thumbprint

Select-AzSubscription -SubscriptionId $DstSubscription

$DstThumbprint = (Get-AzKeyVaultCertificate -VaultName $DstVault -Name $CertName).Thumbprint

if($SrcThumbprint -ne $DstThumbprint -or $DstSubscription -eq "") {
    # If destination keyvault is not updated or does not have the certificate
    Select-AzSubscription -SubscriptionId $SourceSubscription

    # Download certificate as pfx
    $pfxSecret = Get-AzKeyVaultSecret -VaultName $SrcVault -Name $CertName -AsPlainText
    $secretByte = [Convert]::FromBase64String($pfxSecret)
    $x509Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($secretByte, "", "Exportable,PersistKeySet")
    $type = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx
    $pfxFileByte = $x509Cert.Export($type, $password);
    [System.IO.File]::WriteAllBytes($pfxpath, $pfxFileByte);
   
    # E3 certificate found here https://letsencrypt.org/certificates/
    $letsencryptr3 = @"
-----BEGIN CERTIFICATE-----
MIIFFjCCAv6gAwIBAgIRAJErCErPDBinU/bWLiWnX1owDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMjAwOTA0MDAwMDAw
WhcNMjUwOTE1MTYwMDAwWjAyMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNTGV0J3Mg
RW5jcnlwdDELMAkGA1UEAxMCUjMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQC7AhUozPaglNMPEuyNVZLD+ILxmaZ6QoinXSaqtSu5xUyxr45r+XXIo9cP
R5QUVTVXjJ6oojkZ9YI8QqlObvU7wy7bjcCwXPNZOOftz2nwWgsbvsCUJCWH+jdx
sxPnHKzhm+/b5DtFUkWWqcFTzjTIUu61ru2P3mBw4qVUq7ZtDpelQDRrK9O8Zutm
NHz6a4uPVymZ+DAXXbpyb/uBxa3Shlg9F8fnCbvxK/eG3MHacV3URuPMrSXBiLxg
Z3Vms/EY96Jc5lP/Ooi2R6X/ExjqmAl3P51T+c8B5fWmcBcUr2Ok/5mzk53cU6cG
/kiFHaFpriV1uxPMUgP17VGhi9sVAgMBAAGjggEIMIIBBDAOBgNVHQ8BAf8EBAMC
AYYwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMBIGA1UdEwEB/wQIMAYB
Af8CAQAwHQYDVR0OBBYEFBQusxe3WFbLrlAJQOYfr52LFMLGMB8GA1UdIwQYMBaA
FHm0WeZ7tuXkAXOACIjIGlj26ZtuMDIGCCsGAQUFBwEBBCYwJDAiBggrBgEFBQcw
AoYWaHR0cDovL3gxLmkubGVuY3Iub3JnLzAnBgNVHR8EIDAeMBygGqAYhhZodHRw
Oi8veDEuYy5sZW5jci5vcmcvMCIGA1UdIAQbMBkwCAYGZ4EMAQIBMA0GCysGAQQB
gt8TAQEBMA0GCSqGSIb3DQEBCwUAA4ICAQCFyk5HPqP3hUSFvNVneLKYY611TR6W
PTNlclQtgaDqw+34IL9fzLdwALduO/ZelN7kIJ+m74uyA+eitRY8kc607TkC53wl
ikfmZW4/RvTZ8M6UK+5UzhK8jCdLuMGYL6KvzXGRSgi3yLgjewQtCPkIVz6D2QQz
CkcheAmCJ8MqyJu5zlzyZMjAvnnAT45tRAxekrsu94sQ4egdRCnbWSDtY7kh+BIm
lJNXoB1lBMEKIq4QDUOXoRgffuDghje1WrG9ML+Hbisq/yFOGwXD9RiX8F6sw6W4
avAuvDszue5L3sz85K+EC4Y/wFVDNvZo4TYXao6Z0f+lQKc0t8DQYzk1OXVu8rp2
yJMC6alLbBfODALZvYH7n7do1AZls4I9d1P4jnkDrQoxB3UqQ9hVl3LEKQ73xF1O
yK5GhDDX8oVfGKF5u+decIsH4YaTw7mP3GFxJSqv3+0lUFJoi5Lc5da149p90Ids
hCExroL1+7mryIkXPeFM5TgO9r0rvZaBFOvV2z0gp35Z0+L4WPlbuEjN/lxPFin+
HlUjr8gRsI3qfJOQFy/9rKIJR0Y/8Omwt/8oTWgy1mdeHmmjk7j1nYsvC9JSQ6Zv
MldlTTKB3zhThV1+XWYp6rjd5JW1zbVWEkLNxE7GJThEUG3szgBVGP7pSWTUTsqX
nLRbwHOoq7hHwg==
-----END CERTIFICATE-----
"@
    Set-Content -Path $r3path -Value $letsencryptr3 -Force
    
    # Extract and store certificate from pfx
    openssl pkcs12 -in $pfxpath -nodes -nocerts -out $keypath -passin pass:$password
    
    # Extract and store private key from pfx
    openssl pkcs12 -in $pfxpath -clcerts -nokeys -out $certpath -passin pass:$password
    
    # Add root certificate to certificate file
    Get-Content $r3path, $certpath | Set-Content -Path $certwithrootpath
    
    #Create new PFX with certificate, root certificate and private key
    openssl pkcs12 -out $outputpfxpath -in $certpath -inkey $keypath -passin pass:$password -export -passout pass:$password
    
    Select-AzSubscription -SubscriptionId $DstSubscription
    
    $SecPassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    # Upload new PFX certificate to keyvault
    Import-AzKeyVaultCertificate -VaultName $DstVault -Name $CertName -FilePath $outputpfxpath -Password $SecPassword
    
    
    # Clean up temp files
    Remove-Item $pfxpath -Force
    Remove-Item $keypath -Force
    Remove-Item $certpath -Force
    Remove-Item $r3path -Force
    Remove-Item $certwithrootpath -Force
    Remove-Item $outputpfxpath -Force

}
