function _joomscan_module(){
    local domain=$1
    cd joomscan/
    perl joomscan.pl -u $domain -r
}
