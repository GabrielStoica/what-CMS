function _droopescan_module(){
    local domain=$1
    cd droopescan/ && droopescan scan drupal -u $domain
}
