#V5
#----------------Peers-Declaration--------------------#
:global peer1; global peer2;
:local peers {$peer1;$peer2};
#------------------------------------#
:foreach peer in=$peers do={
  :if (($peer->"enabled") = 1) do={
      /ip route enable [/ip route find routing-mark=($peer->"name")];
      /ip route enable [/ip route find comment=($peer->"name")];
      /system note set note="";
  }
}