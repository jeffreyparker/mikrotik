# Inspired by https://forum.mikrotik.com/viewtopic.php?t=168427&sid=2074b0db80a5cc16fafc4bc3d00de97d#

# 'script info' logs should be written to an external disk to preserve them after reboot

# First manually assign all known devices static IPs, and add a comment to each one with its friendly name.

# Create a script that is scheduled to run at midnight
/system script add dont-require-permissions=yes name=ResetMangleCounters owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="put \"hello\""
/system scheduler add interval=1d name=ResetMangleCounters on-event=ResetMangleCounters policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon start-date=nov/01/2020 start-time=00:00:00

# Edit the script to be:
/log info ("Bytes Downloaded Today " . [/ip firewall mangle get [find where comment="Download Global Counter"] bytes])
/log info ("Bytes Uploaded Today " . [/ip firewall mangle get [find where comment="Upload Global Counter"] bytes])

:foreach a in=[/ip firewall mangle find] do={
    :local comment  [/ip firewall mangle get $a comment];
    :local bytes ([/ip firewall mangle get $a bytes]  / 1048576);
    /log info ($comment . " - " . $bytes)
 }

:foreach item in=[ /ip firewall mangle find dynamic=no] do={
    /ip firewall mangle remove $item
}

/ip firewall mangle add action=passthrough chain=forward comment="Download Global Counter" in-interface=ether1
/ip firewall mangle add action=passthrough chain=forward comment="Upload Global Counter" out-interface=ether1

:foreach a in=[/ip dhcp-server lease find] do={
    :local address [/ip dhcp-server lease get $a address]
    :local comment  [/ip dhcp-server lease get $a comment]
    /ip firewall mangle add action=passthrough chain=forward dst-address=$address in-interface=ether1 comment=("Download " . $comment)
    /ip firewall mangle add action=passthrough chain=forward src-address=$address out-interface=ether1 comment=("Upload " . $comment)
}

/log info "IP Firewall Mangle Counters Reset by Script"
