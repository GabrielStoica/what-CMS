function _cmsmap_module(){
    local domain=$1

    echo -e "\nAlegeti tipul de atac dorit:\n 1 --> Scanare completa(timp mare)\n 2 --> Listarea plugin-urilor\n 3 --> Atac de tip brute force(rockyou.txt) identificare parola utilizator\n 4 --> Atac de tip brute force(rockyou.txt) identificare parola utilizatori(dintr-un fisier)"
    read tip_atac
    echo "Ati ales: "$tip_atac
    cd CMSmap/
    if [ $tip_atac -eq 1 ]
    then
        python3 cmsmap.py $domain -f W --noedb
    elif [ $tip_atac -eq 2 ]
    then
        python3 cmsmap.py $domain -f W --noedb
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
            python3 cmsmap.py $domain -f W -u $user -p $passwords
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
            python3 cmsmap.py $domain -f W -u $usernames_file -p $passwords
        fi
    fi
}
