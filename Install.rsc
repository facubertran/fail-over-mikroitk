/system script
add dont-require-permissions=no name=Crenein-FailOver owner=admin policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#V5\r\
    \n##----------------Peers Configurations----------------##\r\
    \n:global peer1 {\r\
    \n  name=\"IZ\";\r\
    \n  enabled=1;\r\
    \n  ifname=\"pppoe-out1\";\r\
    \n  minthroughput=12000000;\r\
    \n  srcaddicmp=\"\";\r\
    \n  upeventscript=\"Crenein-FailOver-DownUpEvent\";\r\
    \n  downeventscript=\"Crenein-FailOver-DownUpEvent\";\r\
    \n  peersfail=0;\r\
    \n  peersfailreason=\"\";\r\
    \n  downsupscount=0;\r\
    \n  beforepeersfail=0;\r\
    \n}\r\
    \n:global peer2 {\r\
    \n  name=\"Compus\";\r\
    \n  enabled=0;\r\
    \n  ifname=\"ether2\";\r\
    \n  minthroughput=0;\r\
    \n  srcaddicmp=\"\";\r\
    \n  upeventscript=\"Crenein-FailOver-DownUpEvent\";\r\
    \n  downeventscript=\"Crenein-FailOver-DownUpEvent\";\r\
    \n  peersfail=0;\r\
    \n  peersfailreason=\"\";\r\
    \n  downsupscount=0;\r\
    \n  beforepeersfail=0;\r\
    \n}\r\
    \n#------------------------------------#\r\
    \n:local peers {\$peer1;\$peer2};\r\
    \n##----------------ICMP Configuration----------------##\r\
    \n:global foicmpprobedst \"1.0.0.1\"; #Destino al que se le hace ping\r\
    \n:local foicmpprobesend \"10\"; #Cantidad de paquetes a enviar\r\
    \n:local foicmpproberecibe \"8\"; #Cantidad de paquetes que debo recibir\r\
    \n:local foicmpprobesize \"64\"; #Tama\F1o de paquete\r\
    \n##----------------Iterations Configuration----------------##\r\
    \nlocal downsups \"3\"; #Iteraciones antes de marcar como down o up.\r\
    \n##----------------Delay Configuration----------------##\r\
    \nlocal loopdelay \"15\"; #Tiempo de espera para pr\F3xima iteracion.\r\
    \n#-----------------Control de peers-------------------#\r\
    \n:while (true)  do={ \r\
    \n\t:foreach peer in=\$peers do={\r\
    \n\t\t:if ((\$peer->\"enabled\") = 1) do={\r\
    \n\t\t\t#Peer info.\r\
    \n\t\t\t:put (\"--------------------\".(\$peer->\"name\").\"-Config.---------------------\");\r\
    \n\t\t\t:put (\"Peer enabled \". \"--> \" .(\$peer->\"enabled\"));\r\
    \n\t\t\t:put (\"Interface name \". \"--> \" .(\$peer->\"ifname\"));\r\
    \n\t\t\t:put (\"Default route comment \". \"--> \" .(\$peer->\"name\"));\r\
    \n\t\t\t:put (\"Min. Throughput --> \" .(\$peer->\"minthroughput\"));\r\
    \n\t\t\t:put (\"Ping src-address --> \" .(\$peer->\"srcaddicmp\"));\r\
    \n\t\t\t:put (\"UpEvent Script --> \" .(\$peer->\"upeventscript\"));\r\
    \n\t\t\t:put (\"DownEvent Script --> \" .(\$peer->\"downeventscript\"));\r\
    \n\t\t\t:put (\". . . . . . . . . \".(\$peer->\"name\").\"-Status . . . . . . . . . .\");\r\
    \n\t\t\t:put (\"Peer fail --> \" .(\$peer->\"peersfail\"));\r\
    \n\t\t\t:put (\"Peer fail reason --> \" .(\$peer->\"peersfailreason\"));\r\
    \n\t\t\t:put (\"Downs UPs counts --> \" .(\$peer->\"downsupscount\"));\r\
    \n\t\t\t:put (\"Before fail --> \" .(\$peer->\"beforepeersfail\"));\r\
    \n\t\t\t:put (\"............................................\");\r\
    \n\t\t\t##Probes.\r\
    \n\t\t\t##---------------------IFRun-Probe----------------------##\r\
    \n\t\t\t:if ([interface get (\$peer->\"ifname\") running]) do={\r\
    \n\t\t\t:put \"IFRun-Probe --> OK\";\r\
    \n\t\t\t##---------------------Traffic-Probe----------------------##\r\
    \n\t\t\t\t:local trafficmonitor [/interface monitor-traffic (\$peer->\"ifname\") as-value once];\r\
    \n\t\t\t\t:put (\"Traffic-Probe result is \" . (\$trafficmonitor->\"rx-bits-per-second\"));\r\
    \n\t\t\t\t:if ((\$trafficmonitor->\"rx-bits-per-second\") < (\$peer->\"minthroughput\")) do={\r\
    \n\t\t\t\t\t:put \"Traffic-Probe --> FAIL\";\r\
    \n\t\t\t\t\t##---------------------Gateway-Probe----------------------##\t\r\
    \n\t\t\t\t\t:if ([/ip route get [/ip route find routing-mark=(\$peer->\"name\") and dst-address=(\$foicmpprobedst.\"/32\")] gateway-status] ~ \"unreachable\") do={\r\
    \n\t\t\t\t\t\t:put \"Gateway-Probe --> FAIL\";\r\
    \n\t\t\t\t\t\t:set (\$peer->\"peersfailreason\") \"Gateway-Probe --> FAIL\";\r\
    \n\t\t\t\t\t\t:if ((\$peer->\"downsupscount\") < \$downsups) do={\r\
    \n\t\t\t\t\t\t\t:set (\$peer->\"downsupscount\") ((\$peer->\"downsupscount\") + 1);\r\
    \n\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t} else={\r\
    \n\t\t\t\t\t\t:put \"Gateway-Probe --> OK\";\r\
    \n\t\t\t\t\t\t##---------------------ICMP-Probe----------------------##\r\
    \n\t\t\t\t\t\t:local pingrouting ;\r\
    \n\t\t\t\t\t\t:if ((\$peer->\"srcaddicmp\") = \"\") do={\r\
    \n\t\t\t\t\t\t\t:put \"Ejecucion de prueba ping sin src-address\";\r\
    \n\t\t\t\t\t\t\t:set pingrouting [ping \$foicmpprobedst count=\$foicmpprobesend routing-table=(\$peer->\"name\") size=\$foicmpprobesize];\r\
    \n\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t\t:if ((\$peer->\"srcaddicmp\") ~ \".\") do={\r\
    \n\t\t\t\t\t\t\t:put \"Ejecucion de prueba ping con src-address\";\r\
    \n\t\t\t\t\t\t\t:set pingrouting [ping \$foicmpprobedst count=\$foicmpprobesend routing-table=(\$peer->\"name\") size=\$foicmpprobesize src-address=(\$peer->\"srcaddic\
    mp\")];\r\
    \n\t\t\t\t\t\t} \r\
    \n\t\t\t\t\t\t:put (\"ICMP-Probe result is send --> \".\$foicmpprobesend.\" received --> \".\$pingrouting);\r\
    \n\t\t\t\t\t\t:if (\$pingrouting < \$foicmpproberecibe) do={\r\
    \n\t\t\t\t\t\t\t:put \"ICMP-Probe --> FAIL\";\r\
    \n\t\t\t\t\t\t\t:set (\$peer->\"peersfailreason\") \"ICMP-Probe --> FAIL\";\r\
    \n\t\t\t\t\t\t\t:if ((\$peer->\"downsupscount\") < \$downsups) do={\r\
    \n\t\t\t\t\t\t\t\t:set (\$peer->\"downsupscount\") ((\$peer->\"downsupscount\") + 1);\r\
    \n\t\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t\t} else={\r\
    \n\t\t\t\t\t\t\t:put \"ICMP-Probe --> OK\";\r\
    \n\t\t\t\t\t\t\t:if ((\$peer->\"downsupscount\") > 0) do={\r\
    \n\t\t\t\t\t\t\t\t:set (\$peer->\"downsupscount\") ((\$peer->\"downsupscount\") - 1);\r\
    \n\t\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t\t}\r\
    \n\t\t\t\t\t}\r\
    \n\t\t\t\t} else={\r\
    \n\t\t\t\t\t:put \"Traffic-Probe --> OK\";\r\
    \n\t\t\t\t\t:if ((\$peer->\"downsupscount\") > 0) do={\r\
    \n\t\t\t\t\t\t:set (\$peer->\"downsupscount\") ((\$peer->\"downsupscount\") - 1);\r\
    \n\t\t\t\t\t}\r\
    \n\t\t\t\t}\r\
    \n\t\t\t} else={\r\
    \n\t\t\t\t:put \"IFRUN-Probe --> FAIL\";\r\
    \n\t\t\t\t:set (\$peer->\"peersfailreason\") \"IFRUN-Probe --> FAIL\";\r\
    \n\t\t\t\t:if ((\$peer->\"downsupscount\") < \$downsups) do={\r\
    \n\t\t\t\t\t:set (\$peer->\"downsupscount\") ((\$peer->\"downsupscount\") + 1);\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\t\t\t##Control de estado\r\
    \n\t\t\t:if ((\$peer->\"downsupscount\") >= \$downsups and (\$peer->\"peersfail\") = 0) do={\r\
    \n\t\t\t\t:set (\$peer->\"beforepeersfail\") 0;\r\
    \n\t\t\t\t:set (\$peer->\"peersfail\") 1;\r\
    \n\t\t\t\t[/system script run (\$peer->\"downeventscript\")];\r\
    \n\t\t\t}\r\
    \n\t\t\t##Control de estado\r\
    \n\t\t\t:if ((\$peer->\"downsupscount\") = 0 and (\$peer->\"peersfail\") = 1) do={\r\
    \n\t\t\t\t:set (\$peer->\"beforepeersfail\") 1;\r\
    \n\t\t\t\t:set (\$peer->\"peersfail\") 0;\r\
    \n\t\t\t\t[/system script run (\$peer->\"upeventscript\")];\r\
    \n\t\t\t}\r\
    \n\t\t} else={\r\
    \n\t\t\t#:put (\"Peer \". (\$peer->\"name\"). \" disabled\");\r\
    \n\t\t}\r\
    \n\t}\r\
    \n\t:put \"...\";\r\
    \n\t:delay \$loopdelay;\r\
    \n}"
add dont-require-permissions=no name=Crenein-FailOver-DownUpEvent source="#V5\r\
    \n#----------------Peers-Declaration--------------------#\r\
    \n:global peer1; global peer2;\r\
    \n:local peers {\$peer1;\$peer2};\r\
    \n##-----------------Telegram-Notification-----------------##\r\
    \n:local telegrambot \"\";\r\
    \n:local telegramchatid \"\";\r\
    \n:local ispname \"\";\r\
    \n#------------------------------------#\r\
    \n:global foicmpprobedst ;\r\
    \n#------------------------------------#\r\
    \n:foreach peer in=\$peers do={\r\
    \n  :if ((\$peer->\"enabled\") = 1) do={\r\
    \n    :if ((\$peer->\"peersfail\") = 1 and (\$peer->\"beforepeersfail\") = 0) do={\r\
    \n      :local message (\$ispname . \" -> \" . \"Peer Fail \" .(\$peer->\"name\").\" || \".\"Peer Fail Reason \" .(\$peer->\"peersfailreason\"));\r\
    \n      :log warning \$message;\r\
    \n      #----------------Que hacer al estar caido--------------------#\r\
    \n      /ip route disable [/ip route find routing-mark=(\$peer->\"name\") and dst-address!=(\$foicmpprobedst.\"/32\")];\r\
    \n      /ip route disable [/ip route find comment=(\$peer->\"name\")];\r\
    \n      /system note set note=\"1\";\r\
    \n      do {\r\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$telegrambot/sendMessage\\\?chat_id=\$telegramchatid&text=\$message\" keep-result=no\r\
    \n      } on-error={}\r\
    \n    } \r\
    \n    if ((\$peer->\"peersfail\") = 0 and (\$peer->\"beforepeersfail\") = 1) do={\r\
    \n      :local message (\$ispname . \" -> \" . \"Peer Recover \" .(\$peer->\"name\"));\r\
    \n      :log warning \$message;\r\
    \n      #----------------Que hacer al recuperarse--------------------#\r\
    \n      /ip route enable [/ip route find routing-mark=(\$peer->\"name\")];\r\
    \n      /ip route enable [/ip route find comment=(\$peer->\"name\")];\r\
    \n      /system note set note=\"\";\r\
    \n      do {\r\
    \n        /tool fetch url=\"https://api.telegram.org/bot\$telegrambot/sendMessage\\\?chat_id=\$telegramchatid&text=\$message\" keep-result=no\r\
    \n      } on-error={}\r\
    \n    }\r\
    \n  }\r\
    \n}"
/system scheduler
add disabled=yes interval=5m name=Crenein-FailOver-Supervisor on-event=":if ([/system script job find script=\"Crenein-FailOver\"]) do={\r\
    \n} else={\r\
    \n    :log info \"Crenein-FailOver started\";\r\
    \n    [/system script run \"Crenein-FailOver\"];\r\
    \n}" start-date=sep/14/2021 start-time=00:00:00
add disabled=yes name=Crenein-FailOver-Startup on-event="#V5\r\
    \n#----------------Peers-Declaration--------------------#\r\
    \n:global peer1; global peer2;\r\
    \n:local peers {\$peer1;\$peer2};\r\
    \n#------------------------------------#\r\
    \n:foreach peer in=\$peers do={\r\
    \n  :if ((\$peer->\"enabled\") = 1) do={\r\
    \n      /ip route enable [/ip route find routing-mark=(\$peer->\"name\")];\r\
    \n      /ip route enable [/ip route find comment=(\$peer->\"name\")];\r\
    \n      /system note set note=\"\";\r\
    \n  }\r\
    \n}" start-time=startup
