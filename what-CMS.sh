#! /usr/bin/bash

#SOURCES
source wp-scan-module.sh
source cmsmap-module.sh

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
WHITE="tput setaf 7"
RED_BG="tput setab 1"
YELLOW="tput setab 3"
GREEN_BG="tput setab 2"
RESET="tput sgr 0"
BOLD="tput bold"

#DEFINE MESSAGES AREA
WARNING="$($RED_BG)ATENTIE!$($RESET) $($WHITE)"

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
    
    usage="\n\tScript conceput pentru testarea si scanarea platformelor de tip CMS:\n\tWordpress, Drupal si Joomla!, impotriva vulnerabilitatilor, integrand\n\to serie de utilitare specifice, precum: CMSmap, Droopescan, Joomscan \n\n\t\t(c) Stoica Gabriel-Marius <marius_gabriel1998@yahoo.com> \n \nMod de utilizare: ./$(basename "$0") [-h] [http(s)://(www.)site-to-be-scanned.ro/] \n \navand semnificatia: \n \t -h, --help \n \t\tAjutor, arata modul de utilizare \n\t -http \n\t\tTrimite o cerere de tip HTTP catre o tinta si afiseaza\n\t\theader-ul raspunsului, identificand daca optiunile de\n\t\tsecuritate sunt activate sau nu\nSintaxa URL valida: \n \t\thttp(s)://(www.)site-de-scanat.ro sau 192.168.10.0/wordpress"
    $RED
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
    echo -e "\nSe trimite request-ul HTTP..."
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
    echo -e "\e[1mDate extrase din header-ul HTTP:\e[0m\n"
    echo -e "\e[1mTinta scanata: \e[0m"$1
    echo -e "\e[1mServer: \e[0m"$server_check
    echo -e "\e[1mX-Frame-Options: \e[0m"$x_frame_check
    echo -e "\e[1mStrict-Transport-Security: \e[0m"$strict_transpor_security
    echo -e "\e[1mX-XSS-Protection: \e[0m"$x_xss_protection
    echo -e "\e[1mX-Content-Security-Policy: \e[0m"$x_csp
    echo -e "\e[1mX-Content-Type-Options: \e[0m"$x_content_type_options
}
function main(){
    
    local help_mode=0
    local http_mode=0
    local full_scan_mode=0
    local undefined_mode=0
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
                -d)
                    shift;
                    domain=${!arg};
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
            cat -e $logo_file
            $RESET
            
            _http_request $domain
            _print_http_response $domain
            
            echo -e "\nVerificarea tipului CMS a inceput... \n"
            
            temp_name=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
            echo "Scriere cod sursa al paginii in "$temp_name".log"
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
                    echo -e "Versiune CMS identificata partial: Posibil Wordpress\n Puteti rula urmatoarele utilitare pentru testare:\n"
                else
                    echo -e "Versiune CMS identificata: $wordpress_check\nUrmatoarele utilitare pot fi folosite pentru testare:\n "
                fi
                echo -e "1 --> WPScan\n2 --> CMSmap"
                echo -e "\nFurnizati numarul utilitarului dorit:"
                read choice
                echo "Ati introdus:"$choice
                if [ $choice -eq 1 ]
                then
                    _wp_scan_module $domain
                elif [ $choice -eq 2 ]
                then
                    _cmsmap_module $domain
                fi
            elif [[ ( "$joomla_check" == "found" ||  $joomla_check == "not_sure" ) ]]
            then
                if [ $joomla_check == "not_sure" ]
                then
                    echo -e "Versiune  CMS identificata partial: Joomla! \n Urmatoarele utilitare pot fi folosite pentru testare:\n"
                else
                    echo -e "Versiune  CMS identificata: Joomla! \n Urmatoarele utilitare pot fi folosite pentru testare:\n"
                fi
                echo -e "1 --> joomscan by OWASP\n2--> CMSmap\n"
                echo -e "Furnizati numarul utilitarului dorit:"
                read choice
                echo "Ati introdus: "$choice
                if [ $choice -eq 1 ]
                then
                    cd joomscan/
                    perl joomscan.pl -u $domain -r
                elif [ $choice -eq 2 ]
                then
                    _cmsmap_module $domain
                fi
            elif [ "$drupal_check" != "not_found" ]
            then
                echo -e "Versiune CMS identificata: $drupal_check\nUrmatoarele utilitare pot fi folosite pentru testare:\n "
                echo -e "1 --> droopescan\n2 --> CMSmap\n"
                echo -e "Furnizati numarul utilitarului dorit:"
                read choice
                echo "Ati introdus: "$choice
                if [ $choice -eq 1 ]
                then
                    cd droopescan/ && droopescan scan drupal -u $domain
                elif [ $choice -eq 2 ]
                then
                    _cmsmap_module $domain
                fi
            else echo "Nu am putut identifica versiunea CMS a platformei!"
            fi
        fi
        rm -Rf $logsdir/$temp_name".log"
    fi
}

main "$@"
