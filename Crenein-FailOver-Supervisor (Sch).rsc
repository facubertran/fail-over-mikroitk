:if ([/system script job find script="Crenein-FailOver"]) do={
} else={
    :log info "Crenein-FailOver started";
    [/system script run "Crenein-FailOver"];
}