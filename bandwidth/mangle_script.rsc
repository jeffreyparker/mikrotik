# From https://forum.mikrotik.com/viewtopic.php?t=168427&sid=2074b0db80a5cc16fafc4bc3d00de97d#

# First add 2 simple Ip Firewall Mangle Rules that will keep track of your Total Internet Data usage.
/ip firewall mangle
add action=passthrough chain=forward comment="Download Global Counter" in-interface=ether1
add action=passthrough chain=forward comment="Upload Global Counter" out-interface=ether1

# Add the code below to your DHCP Server Lease Script. (Edit your DHCP Server, and click on the Script Tab, paste the code below there)
:local hostname [/ip dhcp-server lease get [find where active-mac-address=$leaseActMAC && active-address=$leaseActIP] host-name]

:if ($leaseBound = "1") do={
    /ip firewall mangle add action=passthrough chain=forward dst-address=$leaseActIP in-interface=ether1 comment=("Download " . $hostname)
    /ip firewall mangle add action=passthrough chain=forward src-address=$leaseActIP out-interface=ether1 comment=("Upload " . $hostname)
    /log info ("DHCP Script Mangle Rules Added for HostName " . $hostname . " IP " . $leaseActIP)
} else={
        #delete old Download entry for this ip
    :foreach a in=[/ip firewall mangle find dst-address=$leaseActIP] do={
        /ip firewall mangle remove $a
     }
        #delete old Upload entry for this ip
    :foreach a in=[/ip firewall mangle find src-address=$leaseActIP] do={
        /ip firewall mangle remove $a
     }
    /log info ("DHCP Script Mangle Rules Removed for IP " . $leaseActIP)
}


# Then create a script that is scheduled to run at midnight
/system script
add dont-require-permissions=yes name=ResetMangleCounters owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="/log info (\
    \"Bytes Downloaded Today \" . [/ip firewall mangle get [find where comment=\"Download Global Counter\"] bytes])\r\
    \n/log info (\"Bytes Uploaded Today \" . [/ip firewall mangle get [find where comment=\"Upload Global Counter\"] bytes])\r\
    \n\r\
    \n/ip firewall mangle reset-counters-all\r\
    \n\r\
    \n/log info \"IP Firewall Mangle Counters Reset by Script\""

/system scheduler
add interval=1d name=ResetMangleCounters on-event=ResetMangleCounters policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=nov/01/2020 start-time=00:00:00

# The script above in a easier readable format:
/log info ("Bytes Downloaded Today " . [/ip firewall mangle get [find where comment="Download Global Counter"] bytes])
/log info ("Bytes Uploaded Today " . [/ip firewall mangle get [find where comment="Upload Global Counter"] bytes])

/ip firewall mangle reset-counters-all

/log info "IP Firewall Mangle Counters Reset by Script"
