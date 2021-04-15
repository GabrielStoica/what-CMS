#! /usr/bin/bash

api_url="https://ipinfo.io"
json_filename="host.json"
domain_ip_api=""
target_ip=""
target_hostname=""
target_city=""
target_country=""
target_org=""
target_loc=""

function _check_dependencies(){
    local jq=$(command -v jq)
    if [ -z "$jq" ]
    then
        echo -e "Instalarea dependintelor a inceput..."
        sudo apt-get install jq
        echo -e "Instalarea dependintelor a fost finalizata!"
    fi
}
function _create_api_request(){
    
    _check_dependencies
    
    domain_ip_api=$1
    api_url=$api_url"/"$domain_ip_api"/json"
    wget -qnv $api_url -O $json_filename
    
    _parse_json_data
    
    rm $json_filename
}

function _parse_json_data(){
    
    target_ip=$(jq '.ip' $json_filename)
    target_hostname=$(jq '.hostname' $json_filename)
    target_city=$(jq '.city' $json_filename)
    target_country=$(jq '.country' $json_filename)
    target_org=$(jq '.org' $json_filename)
    target_loc=$(jq '.loc' $json_filename)
    
}
