#! /usr/bin/bash

#SOURCES
source modules/vulnx-module.sh
source modules/wp-scan-module.sh
source modules/cmsmap-module.sh
source modules/joomscan-module.sh
source modules/droopescan-module.sh
source api/ipinfo_api.sh

#DEFINE LOGS, DATA FILES
logsdir="logs"
content="da"
filename="check.log"
curl_response_file="curl_temp_response.txt"
logo_file="logo.txt"

#DEFINE ANY OTHER VARIABLES
dependencies=0
user_agent=""

#DEFINE COLORS AREA
RED="tput setaf 1"
GREEN="tput setaf 2"
YELLOW="tput setaf 3"
WHITE="tput setaf 7"
RED_BG="tput setab 1"
YELLOW_BG="tput setab 3"
GREEN_BG="tput setab 2"
RESET="tput sgr 0"
BOLD="tput bold"

#DEFINE MESSAGES AREA
WARNING="$($RED_BG)ATENTIE!$($RESET) $($WHITE)"
PLUS="$($GREEN) $($BOLD) [+] $($RESET)"
MINUS="$($RED) $($BOLD) [-] $($RESET)"
INFO="$($YELLOW) $($BOLD) [!] $($RESET)"

#DEFINE HTTP PARAMETERS
server_check=""
x_frame_check=""
strict_transport_security=""
x_xss_protection=""
x_csp=""
x_content_type_options=""

#DEFINE REGEX
regex="(https?|ftp|file)://([www.])?[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]"
regex_ip="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"

function check_wordpress_cms(){
    
    local directory_check=$(grep -i $2'/wp-' $logsdir/$1".log")
    local meta_check=$(grep -i '<meta name="generator" content="WordPress' $logsdir/$1".log")
    local version_check=$(echo $meta_check | grep -o -P 'WordPress.{0,6}' | cut -d 's' -f 3)
    local admin_check=$(curl -w "%{http_code}\n" -sLI --url $2'/wp-admin' | tail -n 1 | grep "200\|403")
    local login_check=$(curl -w "%{http_code}\n" -sLI --url $2'/wp-login' | tail -n 1 | grep "200\|403")
    local not_sure_check=$(grep 'wordpress' $logsdir/$1".log")
    
    if [[ ( ! -z "$meta_check" || ! -z "$admin_check" || ! -z "$login_check" || ! -z "$directory_check" ) ]]
    then
        if [ ! -z "$version_check" ]
        then
            echo "Wordpress $version_check"
        else
            echo "Wordpress"
        fi
    elif [ ! -z $not_sure_check ]
    then
        echo "not_sure"
    else
        echo "not_found"
    fi
    
}

function check_joomla_cms(){
    
    local meta_check=$(grep -i '<meta name="generator" content="Joomla!' $logsdir/$1".log")
    local admin_check=$(curl -w "%{http_code}\n" -sLI --url $2'/administrator' | tail -n 1 | grep "200\|403")
    local directory_check=$(grep '<link href="/media\|<link href="/templates\|<link src="/templates' $logsdir/$1".log")
    local script_check=$(grep -i '<script src="/media/jui' $logsdir/$1".log")
    local not_sure_check=$(grep -i 'joomla' $logsdir/$1".log")
    
    if [[ ( ! -z $meta_check || ! -z $admin_check ) ]]
    then
        echo "found"
    elif [[ ( ! -z $directory_check || ! -z $script_check || ! -z $not_sure_check ) ]]
    then
        echo "not_sure"
    else
        echo "not_found"
    fi
    
}

function check_drupal_cms(){
    
    local meta_check=$(grep -i '<meta name="generator" content="Drupal' $logsdir/$1".log")
    local admin_check=$(curl -w "%{http_code}\n" -sLI --url $2'/admin' | tail -n 1 | grep "200")
    local drupal_js=$(grep -i -o "drupal.js" $logsdir/$1".log")
    local version_check=$(echo $meta_check | grep -o -P 'Drupal.{0,3}' | cut -d 'l' -f 2)
    
    if [[ ( ! -z $meta_check || ! -z $admin_check || ! -z $drupal_js ) ]]
    then
        if [ ! -z "$version_check" ]
        then
            echo "Drupal $version_check"
        else
            echo "Drupal"
        fi
    else
        echo "not_found"
    fi
    
}

function _help(){
    
    usage="\n\t\t$($BOLD)    Script conceput pentru testarea si scanarea platformelor de tip CMS:\n\t\t   Wordpress, Drupal si Joomla!, impotriva vulnerabilitatilor, integrand\n\t\to serie de utilitare specifice: CMSmap, Droopescan, Joomscan, VulnX $($RESET) \n\n\t\t\t$($BOLD)(c) Stoica Gabriel-Marius <marius_gabriel1998@yahoo.com> $($RESET)\n \nMod de utilizare: ./$(basename "$0") [-h] [http(s)://(www.)site-to-be-scanned.ro/] \n \navand semnificatia: \n \t -h, --help \n \t\tAjutor, arata modul de utilizare \n\t -http \n\t\tTrimite o cerere de tip HTTP catre o tinta si afiseaza\n\t\theader-ul raspunsului, identificand daca optiunile de\n\t\tsecuritate sunt activate sau nu\n\t         -fs, --full-scan\n\t\tRealizeaza scanarea completa a platformei tinta, oferind\n\t\to serie de utilitare specifice, precum: WPScan, droopescan,\n\t\tjoomscan, in functie de tipul CMS-ului identificat\n\t -u URL, --url URL\n\t\tParametru folosit pentru specificarea adresei tinta ce urmeaza a fi scanata \n\t\tSintaxa URL valida: \n \t\thttp(s)://(www.)site-de-scanat.ro sau 192.168.10.0/wordpress\n\t -wh, --web-host\n\t\tOfera informatii aditionale despre platforma scanata si despre\n\t\tfirma de hosting pe care este gazduita"
    $RED
    $BOLD
    cat -e $logo_file
    $RESET
    echo -e $usage
}

function _check_for_dependencies(){
    if [[ -d "CMSmap" && -d "droopescan" && -d "joomscan" ]]
    then
        dependencies=1
    else
        if [ ! -d "CMSmap" ]
        then
            echo -e "$WARNING"
            echo "Utilitarul CMSmap nu este instalat!"
        fi
        if [ ! -d "droopescan" ]
        then
            echo -e "$WARNING"
            echo "Utilitarul droopescan nu este instalat!"
        fi
        if [ ! -d "joomscan" ]
        then
            git clone https://github.com/rezasp/joomscan.git
        fi
    fi
}

function _http_request(){
    
    echo -e "\n${INFO}\e[1mTinta scanata: \e[0m"$1
    echo -e "${PLUS}Se trimite request-ul HTTP..."
    curl -sLI --url $1 >> $curl_response_file
    
    server_check=$(cat $curl_response_file | grep -i "Server" | head -n 1 | sed 's/^.*: //')
    x_frame_check=$(cat $curl_response_file | grep -i "X-Frame-Options" | head -n 1 | sed 's/^.*: //')
    strict_transport_security=$(cat $curl_response_file | grep -i "Strict-Transport-Security" | head -n 1 | sed 's/^.*: //')
    x_xss_protection=$(cat $curl_response_file | grep -i "X-XSS-Protection" | head -n 1 | sed 's/^.*: //')
    x_csp=$(cat $curl_response_file | grep -i "Content-Security-Policy" | head -n 1 | sed 's/^.*: //')
    x_content_type_options=$(cat $curl_response_file | grep -i "X-Content-Type-Options" | head -n 1 | sed 's/^.*: //')
    
    rm -f $curl_response_file
    
    if [ -z "$x_frame_check" ]
    then x_frame_check="Nesetat"
    fi
    if [ -z $strict_transpor_security ]
    then strict_transpor_security="Nesetat"
    fi
    if [ -z "$x_xss_protection" ] || [ "$x_xss_protection"=="0" ]
    then x_xss_protection="Nesetat"
    fi
    if [ -z "$x_csp" ]
    then x_csp="Nesetat"
    fi
    if [ -z $x_content_type_options ]
    then x_content_type_options="Nesetat"
    fi
}

function _print_http_response(){
    
    echo -e "${INFO}\e[1mDate extrase din header-ul HTTP:\e[0m\n"
    echo -e "- - - - - - - - - - - - - - - - - - - - - - - - -"
    echo -e "${PLUS}\e[1mServer: \e[0m"$server_check
    echo -e "${PLUS}\e[1mX-Frame-Options: \e[0m"$x_frame_check
    echo -e "${PLUS}\e[1mStrict-Transport-Security: \e[0m"$strict_transpor_security
    echo -e "${PLUS}\e[1mX-XSS-Protection: \e[0m"$x_xss_protection
    echo -e "${PLUS}\e[1mX-Content-Security-Policy: \e[0m"$x_csp
    echo -e "${PLUS}\e[1mX-Content-Type-Options: \e[0m"$x_content_type_options
}

function _web_host_informations(){
    
    local url=$1
    local domain_name=""
    local domain_ip=""
    
    if [[ $url =~ $regex_ip ]]
    then
        _help
    elif [[ $url =~ $regex ]]
    then
        domain_name=$(echo $url | awk -F/ '{print $3}')
        local host=$(host $domain_name | grep -o '[0-9]\+[.][0-9]\+[.][0-9]\+[.][0-9]\+')
        if [ ! -z $host ]
        then
            domain_ip=$(echo ${host##* })
            _create_api_request $domain_ip
            echo -e "${PLUS} $($BOLD)IP:$($RESET) "$target_ip
            echo -e "${PLUS} $($BOLD)Hostname:$($RESET) "$target_hostname
            echo -e "${PLUS} $($BOLD)Oras:$($RESET) "$target_city
            echo -e "${PLUS} $($BOLD)Tara:$($RESET) "$target_country
            echo -e "${PLUS} $($BOLD)Firma de hosting:$($RESET) "$target_org
            echo -e "${PLUS} $($BOLD)Locatie:$($RESET) "$target_loc
        else
            _help
        fi
    else
        _help
    fi
    
}


function main(){
    
    local help_mode=0
    local http_mode=0
    local full_scan_mode=0
    local undefined_mode=0
    local web_host_mode=0
    local domain=""
    
    if [ $# -eq 0 ]
    then
        _help
    else
        _check_for_dependencies
        if [ $dependencies -eq 0 ]
        then
            exit 1
        fi
        
        for (( arg=1; arg<=$#; arg++ ))
        do
            case ${!arg} in
                -http)
                    http_mode=1;
                ;;
                -h|--help)
                    _help;
                ;;
                -fs|--full_scan)
                    full_scan_mode=1;
                ;;
                -u|--url)
                    shift;
                    domain=${!arg};
                ;;
                -wb|--web-host)
                    web_host_mode=1;
                ;;
                *)
                    undefined_mode=1;
                ;;
            esac
        done
    fi
    
    if [ $undefined_mode -eq 1 ]
    then
        echo -e "Scanare esuata! Parametru invalid. Consultati ./what-CMS --help"
    elif [ $help_mode -eq 1 ]
    then
        _help
    elif [ $http_mode -eq 1 ]
    then
        if [[ ! $domain =~ $regex && ! $domain =~ $regex_ip ]]
        then
            _help
            echo -e "$WARNING Adresa tinta nu respecta formatul valid!"
        else
            _http_request $domain
            _print_http_response $domain
        fi
    elif [ $full_scan_mode -eq 1 ]
    then
        if [[ ! $domain =~ $regex && ! $domain =~ $regex_ip ]]
        then
            _help
        else
            $RED
            $BOLD
            cat -e $logo_file
            $RESET
            
            _http_request $domain
            _print_http_response $domain
            _web_host_informations $domain
            
            echo -e "\n${INFO}$($BOLD)Verificarea tipului CMS a inceput... $($RESET)\n"
            
            temp_name=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
            echo "${PLUS}Scriere cod sursa al paginii in "$temp_name".log"
            wget -qnv $domain -O $logsdir/$temp_name".log"
            
            wordpress_check=$(check_wordpress_cms $temp_name $domain)
            if [ "$wordpress_check" == "not_found" ]
            then
                joomla_check=$(check_joomla_cms $temp_name $domain)
                if [ "$joomla_check" == "not_found" ]
                then
                    drupal_check=$(check_drupal_cms $temp_name $domain)
                fi
            fi
            
            if [ "$wordpress_check" != "not_found" ]
            then
                if [ "$wordpress_check" == "not_sure" ]
                then
                    echo -e "${INFO}$($BOLD)Versiune CMS identificata partial: Posibil Wordpress\n${INFO}Puteti rula urmatoarele utilitare pentru testare:\n$($RESET)"
                else
                    echo -e "${PLUS}$($BOLD)Versiune CMS identificata: $wordpress_check\n${INFO}Urmatoarele utilitare pot fi folosite pentru testare:\n$($RESET) "
                fi
                echo -e "$($BOLD)  [1] --> WPScan\n  [2] --> CMSmap\n  [3] --> VulnX$($RESET)\n"
                read -p "${INFO}$($BOLD)Furnizati numarul utilitarului dorit: $($RESET)" choice
                echo -e "\n${PLUS}$($BOLD)Ati introdus:$($RESET)"$choice
                if [ $choice -eq 1 ]
                then
                    _wp_scan_module $domain
                elif [ $choice -eq 2 ]
                then
                    _cmsmap_module $domain
                elif [ $choice -eq 3 ]
                then
                    _vulnx_module $domain
                fi
            elif [[ ( "$joomla_check" == "found" ||  $joomla_check == "not_sure" ) ]]
            then
                if [ $joomla_check == "not_sure" ]
                then
                    echo -e "${INFO}$($BOLD)Versiune CMS identificata partial: Joomla!\n${INFO}Urmatoarele utilitare pot fi folosite pentru testare:\n$($RESET)"
                else
                    echo -e "${PLUS}$($BOLD)Versiune CMS identificata: Joomla!\n${INFO}Urmatoarele utilitare pot fi folosite pentru testare:\n$($RESET)"
                fi
                echo -e "$($BOLD)  [1] --> joomscan by OWASP\n  [2]--> CMSmap\n  [3] --> VulnX$($RESET)"
                read -p "${INFO}$($BOLD)Furnizati numarul utilitarului dorit: $($RESET)" choice
                echo -e "\n${PLUS}$($BOLD)Ati introdus: "$choice
                if [ $choice -eq 1 ]
                then
                    _joomscan_module $domain
                elif [ $choice -eq 2 ]
                then
                    _cmsmap_module $domain
                elif [ $choice -eq 3 ]
                then
                    _vulnx_module $domain
                fi
            elif [ "$drupal_check" != "not_found" ]
            then
                echo -e "${INFO}$($BOLD)Versiune CMS identificata: $drupal_check\n${INFO}Urmatoarele utilitare pot fi folosite pentru testare:\n $($RESET)"
                echo -e "$($BOLD)  [1] --> droopescan\n  [2] --> CMSmap\n  [3] --> VulnX$($RESET)\n"
                read -p "${INFO}$($BOLD)Furnizati numarul utilitarului dorit: $($RESET)" choice
                echo -e "\n${PLUS}$($BOLD)Ati introdus: $($RESET)"$choice
                if [ $choice -eq 1 ]
                then
                    _droopescan_module $domain
                elif [ $choice -eq 2 ]
                then
                    _cmsmap_module $domain
                elif [ $choice -eq 3 ]
                then
                    _vulnx_module $domain
                fi
            else echo "${MINUS}$($BOLD)Nu am putut identifica versiunea CMS a platformei!$($RESET)"
            fi
        fi
        rm -Rf $logsdir/$temp_name".log"
    elif [ $web_host_mode -eq 1 ]
    then
        echo -e "\n${INFO}\e[1mTinta scanata: \e[0m"$domain"\n"
        _web_host_informations $domain
    fi
}

main "$@"
