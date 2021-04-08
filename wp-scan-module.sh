function _wp_scan_module(){
    local domain=$1

    echo -e "\nAlegeti tipul de atac dorit:\n 1 --> Listarea utilizatorilor\n 2 --> Atac de tip brute force identificare parole utilizatori \n 3 --> Listarea tuturor plugin-urilor\n 4 --> Listarea plugin-urilor vulnerabile\n 5 --> Listarea temelor instalate care prezinta vulnerabilitati\n 6 --> Cautarea fisierelor de backup pentru configurari"
    read tip_atac
    echo "Ati ales: "$tip_atac
    if [ $tip_atac -eq 1 ]
    then
        wpscan --url $domain --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --random-user-agent --ignore-main-redirect --no-banner --no-update -e u
    elif [ $tip_atac -eq 3 ]
    then
        wpscan --url $domain --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --random-user-agent --ignore-main-redirect --no-banner --no-update -e ap
    elif [ $tip_atac -eq 2 ]
    then
        echo -e "Introduceti username-ul/username-urile despartite prin ',':"
        read users
        if [ -z "$users" ]
        then
            echo -e "$WARNING Camp completat incorect!\n Pentru ajutor utilizati ./what-CMS.sh -help"
        else
            wpscan --url $domain --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --random-user-agent --ignore-main-redirect --no-banner --no-update --passwords rockyou.txt --usernames $users
        fi
    elif [ $tip_atac -eq 4 ]
    then
        wpscan --url $domain --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --ignore-main-redirect --no-banner --no-update -e vp
    elif [ $tip_atac -eq 5 ]
    then
        wpscan --url $domain --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --random-user-agent --ignore-main-redirect --no-banner --no-update -e vt
    elif [ $tip_atac -eq 6 ]
    then
        wpscan --url $domain --api-token tGDh4yker9qe4Scp1IaionL0JmVq1Dna6EjCTzCl8Qg --random-user-agent --ignore-main-redirect --no-banner --no-update -e cb
    fi
}
