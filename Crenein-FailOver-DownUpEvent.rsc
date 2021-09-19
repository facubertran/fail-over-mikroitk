#V5
#----------------Peers-Declaration--------------------#
:global peer1; global peer2;
:local peers {$peer1;$peer2};
##-----------------Telegram-Notification-----------------##
:local telegrambot "";
:local telegramchatid "";
#------------------------------------#
:global foicmpprobedst ;
#------------------------------------#
:foreach peer in=$peers do={
  :if (($peer->"enabled") = 1) do={
    :if (($peer->"peersfail") = 1 and ($peer->"beforepeersfail") = 0) do={
      :local message ("Peer Fail " .($peer->"name")." || "."Peer Fail Reason " .($peer->"peersfailreason"));
      :log warning $message;
      #----------------Que hacer al estar caido--------------------#
      /ip route disable [/ip route find routing-mark=($peer->"name") and dst-address!=($foicmpprobedst."/32")];
      /ip route disable [/ip route find comment=($peer->"name")];
      /system note set note="1";
      do {
        /tool fetch url="https://api.telegram.org/bot$telegrambot/sendMessage\?chat_id=$telegramchatid&text=$message" keep-result=no
      } on-error={}
    } 
    if (($peer->"peersfail") = 0 and ($peer->"beforepeersfail") = 1) do={
      :local message ("Peer Recover " .($peer->"name"));
      :log warning $message;
      #----------------Que hacer al recuperarse--------------------#
      /ip route enable [/ip route find routing-mark=($peer->"name")];
      /ip route enable [/ip route find comment=($peer->"name")];
      /system note set note="";
      do {
        /tool fetch url="https://api.telegram.org/bot$telegrambot/sendMessage\?chat_id=$telegramchatid&text=$message" keep-result=no
      } on-error={}
    }
  }
}