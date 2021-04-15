function _vulnx_module(){
    local domain=$1
    cd vulnx/

    echo -e "\n${INFO}$($BOLD)Sunt disponibile urmatoarele optiuni:\n\n  [1] --> Scanare port-uri\n  [2] --> Testare vulnerabilitati posibile\n  [3] --> Afisare informatii platforma CMS(tema, plugin-uri, versiune...)\n  [4] --> Afisare informatii subdomenii\n$($RESET)"
    read -p "${INFO}$($BOLD)Introduceti optiunea aleasa: $($RESET)" tip_atac
    
    if [ $tip_atac -eq 1 ]
    then
        read -p "${INFO}$($BOLD)Introduceti portul ce urmeaza a fi scanat: " port
        python3 vulnx.py -u $domain -p $port
    elif [ $tip_atac -eq 2 ]
    then
        python3 vulnx.py -u $domain --exploit
    elif [ $tip_atac -eq 3 ]
    then
        python3 vulnx.py -u $domain --cms
    elif [ $tip_atac -eq 4 ]
    then
        python3 vulnx.py -u $domain --dns
    else
        echo -e "$($RED) $($BOLD) Atentie! Optiunea selectata nu exista! $($RESET)"
    fi
}
