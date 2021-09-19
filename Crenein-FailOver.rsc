#V5
##----------------Peers Configurations----------------##
:global peer1 {
  name="IZ";
  enabled=1;
  ifname="pppoe-out1";
  gateway="";
  minthroughput=12000000;
  srcaddicmp="";
  upeventscript="Crenein-FailOver-DownUpEvent";
  downeventscript="Crenein-FailOver-DownUpEvent";
  peersfail=0;
  peersfailreason="";
  downsupscount=0;
  beforepeersfail=0;
}
:global peer2 {
  name="Compus";
  enabled=0;
  ifname="ether2";
  gateway="";
  minthroughput=0;
  srcaddicmp="";
  upeventscript="Crenein-FailOver-DownUpEvent";
  downeventscript="Crenein-FailOver-DownUpEvent";
  peersfail=0;
  peersfailreason="";
  downsupscount=0;
  beforepeersfail=0;
}
#------------------------------------#
:local peers {$peer1;$peer2};
##----------------ICMP Configuration----------------##
:local foicmpprobedst "1.0.0.1"; #Destino al que se le hace ping
:local foicmpprobesend "10"; #Cantidad de paquetes a enviar
:local foicmpproberecibe "8"; #Cantidad de paquetes que debo recibir
:local foicmpprobesize "64"; #Tamaño de paquete
##----------------Iterations Configuration----------------##
local downsups "2"; #Iteraciones antes de marcar como down o up.
##----------------Delay Configuration----------------##
local loopdelay "15"; #Tiempo de espera para próxima iteracion.
#-----------------Control de peers-------------------#
:while (true)  do={ 
	:foreach peer in=$peers do={
		:if (($peer->"enabled") = 1) do={
			#Peer info.
			:put ("--------------------".($peer->"name")."-Config.---------------------");
			:put ("Peer enabled ". "--> " .($peer->"enabled"));
			:put ("Interface name ". "--> " .($peer->"ifname"));
			:put ("Default route comment ". "--> " .($peer->"name"));
			:put ("Gateway --> " .($peer->"gateway"));
			:put ("Min. Throughput --> " .($peer->"minthroughput"));
			:put ("Ping src-address --> " .($peer->"srcaddicmp"));
			:put ("UpEvent Script --> " .($peer->"upeventscript"));
			:put ("DownEvent Script --> " .($peer->"downeventscript"));
			:put (". . . . . . . . . ".($peer->"name")."-Status . . . . . . . . . .");
			:put ("Peer fail --> " .($peer->"peersfail"));
			:put ("Peer fail reason --> " .($peer->"peersfailreason"));
			:put ("Downs UPs counts --> " .($peer->"downsupscount"));
			:put ("Before fail --> " .($peer->"beforepeersfail"));
			:put ("............................................");
			##Probes.
			##---------------------IFRun-Probe----------------------##
			:if ([interface get ($peer->"ifname") running]) do={
			:put "IFRun-Probe --> OK";
			##---------------------Traffic-Probe----------------------##
				:local trafficmonitor [/interface monitor-traffic ($peer->"ifname") as-value once];
				:put ("Traffic-Probe result is " . ($trafficmonitor->"rx-bits-per-second"));
				:if (($trafficmonitor->"rx-bits-per-second") < ($peer->"minthroughput")) do={
					:put "Traffic-Probe --> FAIL";
					##---------------------Gateway-Probe----------------------##	
					:if ([/ip route get [/ip route find routing-mark=($peer->"name") and dst-address="0.0.0.0/0"] gateway-status] ~ "unreachable")) do={
						:put "Gateway-Probe --> OK"
						##---------------------ICMP-Probe----------------------##
						:local pingrouting ;
						:if (($peer->"srcaddicmp") = "") do={
							:put "Sin SRC";
							:set pingrouting [ping $foicmpprobedst count=$foicmpprobesend routing-table=($peer->"name") size=$foicmpprobesize];
						}
						:if (($peer->"srcaddicmp") ~ ".") do={
							:put "Con SRC";
							:set pingrouting [ping $foicmpprobedst count=$foicmpprobesend routing-table=($peer->"name") size=$foicmpprobesize src-address=($peer->"srcaddicmp")];
						} 
						:put ("ICMP-Probe result is send --> ".$foicmpprobesend." received --> ".$pingrouting);
						:if ($pingrouting < $foicmpproberecibe) do={
							:put "ICMP-Probe --> FAIL";
							:set ($peer->"peersfailreason") "ICMP-Probe --> FAIL";
							:if (($peer->"downsupscount") < $downsups) do={
								:set ($peer->"downsupscount") (($peer->"downsupscount") + 1);
							}
						} else={
							:put "ICMP-Probe --> OK";
							:if (($peer->"downsupscount") > 0) do={
								:set ($peer->"downsupscount") (($peer->"downsupscount") - 1);
								
							}
						}
					} else={
						:put "Gateway-Probe --> FAIL";
						:set ($peer->"peersfailreason") "Gateway-Probe --> FAIL";
						:if (($peer->"downsupscount") < $downsups) do={
							:set ($peer->"downsupscount") (($peer->"downsupscount") + 1);
						}
					}
				} else={
					:put "Traffic-Probe --> OK";
					:if (($peer->"downsupscount") > 0) do={
						:set ($peer->"downsupscount") (($peer->"downsupscount") - 1);
					}
				}
			} else={
				:put "IFRUN-Probe --> FAIL";
				:set ($peer->"peersfailreason") "IFRUN-Probe --> FAIL";
				:if (($peer->"downsupscount") < $downsups) do={
					:set ($peer->"downsupscount") (($peer->"downsupscount") + 1);
				}
			}
			##Control de estado
			:if (($peer->"downsupscount") >= $downsups and ($peer->"peersfail") = 0) do={
				:set ($peer->"beforepeersfail") 0;
				:set ($peer->"peersfail") 1;
				[/system script run ($peer->"downeventscript")];
			}
			##Control de estado
			:if (($peer->"downsupscount") = 0 and ($peer->"peersfail") = 1) do={
				:set ($peer->"beforepeersfail") 1;
				:set ($peer->"peersfail") 0;
				[/system script run ($peer->"upeventscript")];
			}
		} else={
			#:put ("Peer ". ($peer->"name"). " disabled");
		}
	}
	:put "...";
	:delay $loopdelay;
}