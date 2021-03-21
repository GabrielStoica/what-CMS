#! /usr/bin/bash

logsdir="logs"
content="da"
filename="check.log"
curl_response_file="curl_temp_response.txt"
logo_file="logo.txt"

#DEFINE COLORS AREA
RED="tput setaf 1"
WHITE="tput setaf 7"
RED_BG="tput setab 1"
GREEN_BG="tput setab 2"
RESET="tput sgr 0"
BOLD="tput bold"

#DEFINE MESSAGES AREA
WARNING="$($RED_BG)ATENTIE!$($RESET) $($WHITE)"

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
    
    usage="\nwhat-CMS – Script conceput pentru testarea si scanarea platformelor de tip CMS: Wordpress, Drupal si Joomla!, \nimpotriva vulnerabilitatilor, integrand o serie de utilitare specifice, precum: CMSmap, Droopescan, Joomscan \n(c) Stoica Gabriel-Marius <marius_gabriel1998@yahoo.com> \n \nMod de utilizare: ./$(basename "$0") [-h] [http(s)://(www.)site-to-be-scanned.ro/] \n \navand semnificatia: \n \t -h, -help \n \t\tAjutor, arata modul de utilizare \nSintaxa URL valida: \n \t\thttp(s)://(www.)site-de-scanat.ro sau 192.168.10.0/wordpress"
    cat $logo_file
    echo -e $usage
}

function _check_for_dependencies(){
    if [ ! -d "CMSmap" ]
    then
        echo "Directorul CMSmap nu exista!"
    elif [ ! -d "droopescan" ]
    then 
        echo "Directorul droopescan nu exista!"
    elif [ ! -d "joomscan" ]
    then
        git clone https://github.com/rezasp/joomscan.git
    fi
}
function main(){
    
    if [ $# -eq 0 ] || [ $# -ne 1 ]
    then
        _help
    elif [ $1 == "-h" ] || [ $1 == "-help" ]
    then
        _help
    else
        cat $logo_file
        _check_for_dependencies
        regex="(https?|ftp|file)://([www.])?[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]"
        regex_ip="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"
        
        if [[ ! $1 =~ $regex && ! $1 =~ $regex_ip ]]
        then
            _help
        else
            echo -e "\n"
            echo -e "\e[1mDate extrase din header-ul HTTP:\e[0m\n"
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
            if [ -z $x_csp ]
            then x_csp="Nesetat"
            fi
            if [ -z $x_content_type_options ]
            then x_content_type_options="Nesetat"
            fi
            
            echo -e "\e[1mTinta scanata: \e[0m"$1
            echo -e "\e[1mServer: \e[0m"$server_check
            echo -e "\e[1mX-Frame-Options: \e[0m"$x_frame_check
            echo -e "\e[1mStrict-Transport-Security: \e[0m"$strict_transpor_security
            echo -e "\e[1mX-XSS-Protection: \e[0m"$x_xss_protection
            echo -e "\e[1mX-Content-Security-Policy: \e[0m"$x_csp
            echo -e "\e[1mX-Content-Type-Options: \e[0m"$x_content_type_options
            
            echo -e "\nVerificarea tipului CMS a inceput... \n"
            
            temp_name=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
            echo "Scriere cod sursa al paginii in "$temp_name".log"
            wget -qnv $1 -O $logsdir/$temp_name".log"
            
            wordpress_check=$(check_wordpress_cms $temp_name $1)
            joomla_check=$(check_joomla_cms $temp_name $1)
            drupal_check=$(check_drupal_cms $temp_name $1)
            
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
                    echo -e "\nAlegeti tipul de atac dorit:\n 1 --> Listarea utilizatorilor\n 2 --> Atac de tip brute force identificare parole utilizatori \n 3 --> Listarea tuturor plugin-urilor\n 4 --> Listarea plugin-urilor vulnerabile\n 5 --> Listarea temelor instalate care prezinta vulnerabilitati\n 6 --> Cautarea fisierelor de backup pentru configurari"
                    read tip_atac
                    echo "Ati ales: "$tip_atac
                    if [ $tip_atac -eq 1 ]
                    then
                        wpscan --url $1 --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --random-user-agent --ignore-main-redirect --no-banner --no-update -e u
                    elif [ $tip_atac -eq 3 ]
                    then
                        wpscan --url $1 --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --random-user-agent --ignore-main-redirect --no-banner --no-update -e ap
                    elif [ $tip_atac -eq 2 ]
                    then
                        echo -e "Introduceti username-ul/username-urile despartite prin ',':"
                        read users
                        if [ -z "$users" ]
                        then
                            echo -e "$WARNING Camp completat incorect!\n Pentru ajutor utilizati ./what-CMS.sh -help"
                        else
                            wpscan --url $1 --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --random-user-agent --ignore-main-redirect --no-banner --no-update --passwords rockyou.txt --usernames $users
                        fi
                    elif [ $tip_atac -eq 4 ]
                    then
                        wpscan --url $1 --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --random-user-agent --ignore-main-redirect --no-banner --no-update -e vp
                    elif [ $tip_atac -eq 5 ]
                    then
                        wpscan --url $1 --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --random-user-agent --ignore-main-redirect --no-banner --no-update -e vt
                    elif [ $tip_atac -eq 6 ]
                    then
                        wpscan --url $1 --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --random-user-agent --ignore-main-redirect --no-banner --no-update -e cb
                    fi
                elif [ $choice -eq 2 ]
                then
                    echo -e "\nAlegeti tipul de atac dorit:\n 1 --> Scanare completa(timp mare)\n 2 --> Listarea plugin-urilor\n 3 --> Atac de tip brute force(rockyou.txt) identificare parola utilizator\n 4 --> Atac de tip brute force(rockyou.txt) identificare parola utilizatori(dintr-un fisier)"
                    read tip_atac
                    echo "Ati ales: "$tip_atac
                    cd CMSmap/
                    if [ $tip_atac -eq 1 ]
                    then
                        python3 cmsmap.py $1 -f W --noedb
                    elif [ $tip_atac -eq 2 ]
                    then
                        python3 cmsmap.py $1 -f W --noedb
                    elif [ $tip_atac -eq 3 ]
                    then
                        echo -e "Introduceti username-ul:"
                        read user
                        echo -e "Introduceti calea catre fisierul cu parole (ex: rockyou.txt)"
                        read passwords
                        if [ ! -f $passwords ]
                        then
                            echo -e "$WARNING Fisier invalid! Pentru ajutor utilizati ./what-CMS.sh -help"
                        elif [ -z "$user" ]
                        then
                            echo -e "$WARNING Username completat incorect!\n Pentru ajutor utilizati ./what-CMS.sh -help"
                        else
                            python3 cmsmap.py $1 -f W -u $user -p $passwords
                        fi
                    elif [ $tip_atac -eq 4 ]
                    then
                        echo -e "Introduceti numele fisierului cu username-uri:"
                        read usernames_file
                        echo -e "Introduceti calea catre fisierul cu parole (ex: /director/rockyou.txt)"
                        read passwords
                        if [ ! -f $passwords ] || [ ! -f $usernames_file ]
                        then
                            echo -e "$WARNING Unul din cele doua fisiere introduse este invalid!\n Pentru ajutor utilizati ./what-CMS.sh -help"
                        else
                            python3 cmsmap.py $1 -f W -u $usernames_file -p $passwords
                        fi
                    fi
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
                    perl joomscan.pl -u $1 -r
                elif [ $choice -eq 2 ]
                then
                    echo -e "\nAlegeti tipul de atac dorit:\n 1 --> Scanare completa(timp mare)\n 2 --> Listarea plugin-urilor\n 3 --> Atac de tip brute force(rockyou.txt) identificare parola utilizator\n 4 --> Atac de tip brute force(rockyou.txt) identificare parola utilizatori(dintr-un fisier)"
                    read tip_atac
                    echo "Ati ales: "$tip_atac
                    cd CMSmap/
                    if [ $tip_atac -eq 1 ]
                    then
                        python3 cmsmap.py $1 -f J
                    elif [ $tip_atac -eq 2 ]
                    then
                        python3 cmsmap.py $1 -f J --noedb
                    elif [ $tip_atac -eq 3 ]
                    then
                        echo -e "Introduceti username-ul:"
                        read user
                        echo -e "Introduceti calea catre fisierul cu parole (ex: /director/rockyou.txt)"
                        read passwords
                        if [ ! -f $passwords ]
                        then
                            echo -e "$WARNING Fisier invalid! Pentru ajutor utilizati ./what-CMS.sh -help"
                        elif [ -z "$user" ]
                        then
                            echo -e "$WARNING Username completat incorect!\n Pentru ajutor utilizati ./what-CMS.sh -help"
                        else
                            python3 cmsmap.py $1 -f J -u $user -p $passwords
                        fi
                    elif [ $tip_atac -eq 4 ]
                    then
                        echo -e "Introduceti calea catre fisierul cu username-uri (ex: /director/usernames.txt)"
                        read usernames_file
                        echo -e "Introduceti calea catre fisierul cu parole (ex: /director/rockyou.txt):"
                        read passwords
                        if [ ! -f $usernames_file ] || [ ! -f $passwords ]
                        then
                            echo -e "$WARNING Unul din cele doua fisiere introduse este invalid!\n Pentru ajutor utilizati ./what-CMS.sh -help"
                        else
                            python3 cmsmap.py $1 -f J -u $usernames_file -p $passwords
                        fi
                    fi
                fi
            elif [ "$drupal_check" != "not_found" ]
            then
                echo -e "Versiune CMS identificata: $drupal_check\nUrmatoarele utilitare pot fi folosite pentru testare:\n "
                echo -e "1 --> DroopScan\n2 --> CMSmap\n"
                echo -e "Furnizati numarul utilitarului dorit:"
                read choice
                echo "Ati introdus: "$choice
                if [ $choice -eq 1 ]
                then
                    cd joomscan/ && perl joomscan.pl -u $1
                elif [ $choice -eq 2 ]
                then
                    echo -e "\nAlegeti tipul de atac dorit:\n 1 --> Scanare completa(timp mare)\n 2 --> Listarea plugin-urilor\n 3 --> Atac de tip brute force(rockyou.txt) identificare parola utilizator\n 4 --> Atac de tip brute force(rockyou.txt) identificare parola utilizatori(dintr-un fisier)"
                    read tip_atac
                    echo "Ati ales: "$tip_atac
                    cd CMSmap/
                    if [ $tip_atac -eq 1 ]
                    then
                        python3 cmsmap.py $1 -f D
                    elif [ $tip_atac -eq 2 ]
                    then
                        python3 cmsmap.py $1 -f D --noedb
                    elif [ $tip_atac -eq 3 ]
                    then
                        echo -e "Introduceti username-ul (ex: marius_cristian):"
                        read user
                        echo -e "Introduceti calea catre fisierul cu parole (ex: /director/rockyou.txt):"
                        read passwords
                        if [ ! -f $passwords ]
                        then
                            echo -e "$WARNING Fisier invalid! Pentru ajutor utilizati ./what-CMS.sh -help"
                        elif [ -z $user ]
                        then
                            echo -e "$WARNING Username completat incorect!\n Pentru ajutor utilizati ./what-CMS.sh -help"
                        else
                            python3 cmsmap.py $1 -f D -u $user -p $passwords
                        fi
                    elif [ $tip_atac -eq 4 ]
                    then
                        echo -e "Introduceti numele fisierului cu username-uri:"
                        read usernames_file
                        python cmsmap.py $1 -f D -u $usernames_file -p ../passwords.txt
                    fi
                fi
            else echo "Nu am putut identifica versiunea CMS a platformei!"
            fi
        fi
        rm -Rf $logsdir/$temp_name".log"
    fi
}

main "$@"
