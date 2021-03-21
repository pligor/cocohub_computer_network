# RouterOS 6.48.1
# software id = Z746-UCFY
#
# model = RBcAPGi-5acD2nD
# serial number = BECD0CB182F0
/interface bridge
add admin-mac=48:8F:5A:D0:23:07 auto-mac=no comment=defconf name=bridgeLocal

/interface list
add comment=defconf name=WAN
add comment=defconf name=LAN

/interface wireless security-profiles
set [ find default=yes ] authentication-types=wpa2-psk mode=\
    dynamic-keys supplicant-identity=MikroTik wpa2-pre-shared-key=6956775925
add authentication-types=wpa2-psk mode=dynamic-keys name=\
    Cocohub-Alpha-Security-Profile supplicant-identity="" wpa2-pre-shared-key=6956775925

/interface wireless
# default-forwarding is set to "no" because we want CLIENT ISOLATION
# WiFi 2GHz
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=20/40mhz-XX \
    country=greece disabled=no distance=indoors frequency=auto installation=\
    indoor mode=ap-bridge ssid=Cocohub-George wireless-protocol=802.11 name=wlan_2GHZ default-forwarding=no
# WiFi 5GHz
set [ find default-name=wlan2 ] band=5ghz-a/n/ac channel-width=\
    20/40/80mhz-XXXX country=greece disabled=no distance=indoors frequency=\
    auto installation=indoor mode=ap-bridge ssid=Cocohub-George \
    wireless-protocol=802.11 name=wlan_5GHZ default-forwarding=no

# Cocohub-Alpha 2GHz
add master-interface=wlan_2GHZ name=Cocohub-Alpha \
    security-profile=Cocohub-Alpha-Security-Profile ssid=Cocohub-Alpha wds-cost-range=0 \
    wds-default-cost=0 wps-mode=disabled
# Cocohub-Alpha 5GHz
add master-interface=wlan_5GHZ multicast-buffering=disabled name=Cocohub-Alpha_5GHz \
    security-profile=Cocohub-Alpha ssid=Cocohub-Alpha wds-cost-range=0 \
    wds-default-cost=0 wps-mode=disabled

/ip pool
add name=dhcp_pool ranges=192.168.5.10-192.168.5.254

/ip dhcp-server
add address-pool=dhcp_pool disabled=no interface=bridgeLocal name=dhcp_server

/ip firewall layer7-protocol
add name=p2p regexp="^(\\x13bittorrent protocol|azver\\x01\$|get /scrape\\\?info_hash=get /announce\\\?info_hash=|get /client/bitcomet/|GET /data\\\?fid=)|d1:ad2:id20:|\\x08'7P\\)[RP]"
add name=p2p_old regexp="^(\13bittorrent protocol|azver\01\$|get /scrape\\\?info_hash=)|d1:ad2:id20:|\08'7P\\)[RP]"
add name=skypetoskype regexp="^..\02............."
add name=facebook regexp="^.+(facebook.com|facebook.net|fbcdn.com|fbsbx.com|fbcdn.net|fb.com|tfbnw.net).*\$"
add name=youtube regexp="^.+\\.(youtube.com|googlevideo.net|googlevideo.com|akamaihd.net).*\$"

/queue tree
#global
add max-limit=17M name=all_bandwidth packet-mark="" parent=global priority=1

#all download
add max-limit=14M name=download packet-mark=client-dw-pk parent=all_bandwidth priority=2

#all upload
add max-limit=3M name=upload packet-mark=client-up-pk parent=all_bandwidth

#video and audio calls
add max-limit=14M name=video-audio-call-download packet-mark=skype_by_port-dw-pk parent=download priority=1 queue=pcq-download-default
add max-limit=3M name=video-audio-call-upload packet-mark=skype_by_port-upload-packet parent=upload priority=1 queue=pcq-upload-default

#http
add max-limit=14M name=http-download packet-mark=http-dw-pk parent=download \
    priority=2 queue=pcq-download-default
add max-limit=3M name=http-upload packet-mark=http-up-pk parent=upload \
    priority=2 queue=pcq-upload-default

#low priority http traffic
add max-limit=3M name=http-upload-low-prio packet-mark=facebook-upload-packet parent=upload priority=3 queue=pcq-upload-default
add max-limit=14M name=http-download-low-prio packet-mark=facebook-download-packet parent=download priority=3 queue=pcq-download-default

#streaming traffic
add max-limit=14M name=streaming-download packet-mark=youtube-download-packet parent=download priority=4 queue=pcq-download-default
add max-limit=3M name=streaming-upload packet-mark=youtube-upload-packet parent=upload priority=4 queue=pcq-upload-default

#other downloads
add max-limit=14M name=other-download packet-mark=other-dw-pk parent=download \
    priority=6 queue=pcq-download-default

#other uploads
add max-limit=3M name=other-upload packet-mark=other-up-pk parent=upload \
    priority=6 queue=pcq-upload-default

# p2p download and upload
add max-limit=7M name=p2p-download-queue packet-mark=p2p-dw-pk,p2p-old-dw-pk parent=download queue=pcq-download-default
add max-limit=1500k name=p2p-upload-queue packet-mark=p2p-up-pk,p2p-old-up-pk parent=upload queue=pcq-upload-default

/interface bridge port
add bridge=bridgeLocal comment=defconf hw=no interface=ether2
add bridge=bridgeLocal interface=wlan_5GHZ
add bridge=bridgeLocal interface=wlan_2GHZ
add bridge=bridgeLocal interface=Cocohub-Alpha
add bridge=bridgeLocal interface=Cocohub-Alpha_5GHz

/interface detect-internet
set detect-interface-list=all

/interface list member
add interface=ether1 list=WAN
add interface=bridgeLocal list=LAN

/ip address
add address=192.168.5.1/24 interface=bridgeLocal network=192.168.5.0

/ip dhcp-client
add comment=defconf disabled=no interface=ether1

/ip dhcp-server network
add address=192.168.5.0/24 gateway=192.168.5.1 netmask=24

/ip dns
set allow-remote-requests=yes

#this is more to just help with the router
/ip dns static
add address=192.168.5.1 comment=defconf name=router.lan

/ip firewall address-list
add address=192.168.5.1 list=Routers

/ip firewall mangle
#accept anything going to the router
add action=accept chain=prerouting comment=Routers dst-address-list=Routers
#accept dns
add action=accept chain=forward comment="DNS tcp" port=53 protocol=tcp
add action=accept chain=forward comment="DNS udp" port=53 protocol=udp

#mark download connection
add action=mark-connection chain=forward comment=client-dw-con in-interface=\
    ether1 new-connection-mark=client-dw-con passthrough=yes

#mark download packets
add action=mark-packet chain=forward comment=client-dw-pk connection-mark=\
    client-dw-con new-packet-mark=client-dw-pk passthrough=yes

#mark upload connection
add action=mark-connection chain=prerouting comment=client-up-con \
    in-interface=bridgeLocal new-connection-mark=client-up-con passthrough=\
    yes

#mark upload packets
add action=mark-packet chain=prerouting comment=client-up-pk connection-mark=\
    client-up-con new-packet-mark=client-up-pk passthrough=yes

#facebook
add action=mark-packet chain=forward comment=facebook-download-packet in-interface=ether1 layer7-protocol=facebook new-packet-mark=facebook-download-packet \
    passthrough=yes
add action=mark-packet chain=forward comment=facebook-upload-packet in-interface=bridgeLocal layer7-protocol=facebook new-packet-mark=facebook-upload-packet \
    passthrough=yes

#youtube
add action=mark-connection chain=forward comment=youtube-download-connection in-interface=ether1 layer7-protocol=youtube new-connection-mark=\
    youtube-download-connection passthrough=yes
add action=mark-packet chain=forward comment=youtube-download-packet connection-mark=youtube-download-connection new-packet-mark=youtube-download-packet \
    passthrough=yes
add action=mark-connection chain=prerouting comment=youtube-upload-connection in-interface=bridgeLocal layer7-protocol=youtube new-connection-mark=\
    youtube-upload-connection passthrough=yes
add action=mark-packet chain=forward comment=youtube-upload-packet connection-mark=youtube-upload-connection new-packet-mark=youtube-upload-packet passthrough=yes

#skype
add action=mark-packet chain=forward comment=skype_by_port-dw-pk new-packet-mark=skype_by_port-dw-pk packet-mark=client-dw-pk passthrough=yes port=3478-3481,50000-60000 protocol=udp
add action=mark-packet chain=forward comment=skype_by_port-upload-packet new-packet-mark=skype_by_port-upload-packet packet-mark=client-up-pk passthrough=yes port=3478-3481,50000-60000 protocol=udp

#mark http download packets
add action=mark-packet chain=forward comment=http-dw-pk new-packet-mark=\
    http-dw-pk packet-mark=client-dw-pk passthrough=yes port=\
    80,443,5222,5223,5228 protocol=tcp

#mark http upload packets
add action=mark-packet chain=forward comment=http-up-pk new-packet-mark=\
    http-up-pk packet-mark=client-up-pk passthrough=yes port=\
    80,443,5222,5223,5228 protocol=tcp

#mark p2p download packets
add action=mark-packet chain=forward comment=p2p-dw-pk layer7-protocol=p2p new-packet-mark=p2p-dw-pk packet-mark=client-dw-pk passthrough=yes
add action=mark-packet chain=forward comment=p2p-old-dw-pk layer7-protocol=p2p new-packet-mark=p2p-old-dw-pk packet-mark=client-dw-pk passthrough=yes


#mark p2p upload packets
add action=mark-packet chain=forward comment=p2p-up-pk layer7-protocol=p2p new-packet-mark=p2p-up-pk packet-mark=client-up-pk passthrough=yes
add action=mark-packet chain=forward comment=p2p-old-up-pk layer7-protocol=*7 new-packet-mark=p2p-old-up-pk packet-mark=client-up-pk passthrough=yes


#mark all the other download packets
add action=mark-packet chain=forward comment=other-dw-pk new-packet-mark=\
    other-dw-pk packet-mark=client-dw-pk passthrough=yes

#mark all the other upload packets
add action=mark-packet chain=forward comment=other-up-pk new-packet-mark=\
    other-up-pk packet-mark=client-up-pk passthrough=yes

/ip route
add disabled=yes distance=1 gateway=192.168.1.1

# TODO see about radius in the future
#/radius
#add accounting-port=17721 address=130.211.138.166 authentication-port=17721 \
#    disabled=yes secret=8z5rZcGHEu3AtUFJ service=wireless timeout=3s
#add accounting-port=17721 address=104.198.250.153 authentication-port=17721 \
#    disabled=yes secret=8z5rZcGHEu3AtUFJ service=wireless timeout=3s
#/radius incoming
#set accept=yes port=17721

/system clock
set time-zone-name=Europe/Athens

/system identity
set name=MikroTik_cAP_ac_main_room

/system ntp client
set enabled=yes primary-ntp=62.169.217.225 secondary-ntp=62.169.217.225

/system ntp server
set broadcast=yes enabled=yes

/ip hotspot profile
set [ find default=yes ] html-directory=hotspot

/ip firewall nat
add action=masquerade chain=srcnat comment="defconf: masquerade" \
    ipsec-policy=out,none out-interface-list=WAN

/ip upnp
set enabled=yes

/ip upnp interfaces
add interface=bridge type=internal
add interface=ether1 type=external


/system routerboard mode-button
set enabled=yes on-event=dark-mode

#apparently default configuration to do something about the leds. Not super important
/system script
add comment=defconf dont-require-permissions=no name=dark-mode owner=*sys \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon \
    source="\r\
    \n   :if ([system leds settings get all-leds-off] = \"never\") do={\r\
    \n     /system leds settings set all-leds-off=immediate \r\
    \n   } else={\r\
    \n     /system leds settings set all-leds-off=never \r\
    \n   }\r\
    \n "

#Essential Firewall Filter Rules - https://www.youtube.com/watch?v=78jhP62VvwI&ab_channel=TKSJa
/ip firewall address-list
add address=0.0.0.0/8 comment="Self-Identification [RFC 3330]" list=Bogons
add address=10.0.0.0/8 comment="Private[RFC 1918] - CLASS A # Check if you nee\
 d this subnet before enable it" list=Bogons
add address=127.0.0.0/8 comment="Loopback [RFC 3330]" list=Bogons
add address=169.254.0.0/16 comment="Link Local [RFC 3330]" list=Bogons
add address=172.16.0.0/12 comment="Private[RFC 1918] - CLASS B # Check if you \
 need this subnet before enable it" list=Bogons
add address=192.0.2.0/24 comment="Reserved - IANA - TestNet1" list=Bogons
add address=192.88.99.0/24 comment="6to4 Relay Anycast [RFC 3068]" list=\
 Bogons
add address=198.18.0.0/15 comment="NIDB Testing" list=Bogons
add address=198.51.100.0/24 comment="Reserved - IANA - TestNet2" list=Bogons
add address=203.0.113.0/24 comment="Reserved - IANA - TestNet3" list=Bogons
add address=224.0.0.0/4 comment=\
 "MC, Class D, IANA # Check if you need this subnet before enable it" \
 list=Bogons
/ip firewall filter
add action=accept chain=forward comment="defconf: accept in ipsec policy" ipsec-policy=in,ipsec
add action=accept chain=forward comment="defconf: accept out ipsec policy" ipsec-policy=out,ipsec
add action=accept chain=forward comment="defconf: accept established,related, untracked" connection-state=established,related,untracked
add action=drop chain=forward comment="defconf: drop invalid" connection-state=invalid
add action=drop chain=forward comment="defconf: drop all from WAN not DSTNATed" connection-nat-state=!dstnat connection-state=new in-interface-list=WAN
add action=drop chain=forward comment="defconf:  drop all from WAN not DSTNATed. Almost the same as above" connection-nat-state=!dstnat connection-state=new in-interface=ether1
add action=accept chain=forward comment="defconf: accept established,related" connection-state=established,related
add action=drop chain=forward comment="defconf: drop invalid" connection-state=invalid
add action=accept chain=input port=69 protocol=udp
add action=accept chain=forward port=69 protocol=udp
add action=drop chain=forward comment="Drop to bogon list" dst-address-list=Bogons
add action=accept chain=input protocol=icmp
add action=accept chain=input connection-state=established
add action=accept chain=input connection-state=related
add action=drop chain=forward comment="drop anything else that was not accepted above. Keep this rule always at the bottom" in-interface=ether1

# CLIENT ISOLATION
# makes all the communication to the bridge pass from firewall
/interface bridge settings
set use-ip-firewall=yes

#typically all the clients need to be isolated among themselves, so use here the same as the ip pool above
/ip firewall address-list
add address=192.168.5.10-192.168.5.254 list=all_clients

# reject any packet going from one of the clients to any other of the clients
/ip firewall filter
add action=reject chain=forward comment="Client Isolation" dst-address-list=all_clients reject-with=icmp-network-unreachable src-address-list=all_clients
