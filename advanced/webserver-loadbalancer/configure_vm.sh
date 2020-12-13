result="$(az vm list -o tsv | cut -f15)"
for vmname in $result; do
    echo Configuring VM $vmname   
    az vm run-command invoke -g "advanced-webserver-loadbalancer" \
        --name $vmname  \
        --command-id RunPowerShellScript \
        --scripts 'param([string]$vmname)' \
        'Add-WindowsFeature Web-Server;' \
        'Set-Content -Path "C:\\inetpub\\wwwroot\\iisstart.htm" -Value "Hello World! from $vmname"' \
        --parameters "vmname=$vmname"

done