#! /usr/bin/bash

logsdir="/home/kali/Desktop/licenta/logs"
content="da"
filename="check.log"
curl_response_file="curl_temp_response.txt"

function check_wordpress_cms(){

local directory_check=$(grep -i $2'/wp-' $logsdir/$1".log")
local meta_check=$(grep -i '<meta name="generator" content="WordPress' $logsdir/$1".log")
local admin_check=$(curl -w "%{http_code}\n" -sLI --url $2'/wp-admin' | tail -n 1 | grep "200\|403")
local login_check=$(curl -w "%{http_code}\n" -sLI --url $2'/wp-login' | tail -n 1 | grep "200\|403")
local not_sure_check=$(grep 'wordpress' $logsdir/$1".log")

if [[ ( ! -z "$meta_check" || ! -z "$admin_check" || ! -z "$login_check" || ! -z "$directory_check" ) ]] 
	then
		echo "found"
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

if [[ ( ! -z $meta_check || ! -z $admin_check ) ]] 
	then
		echo "found"
	else
		echo "not_found"
fi

}

if [ $# -eq 0 ] || [ $# -ne 1 ]
	then
		echo -e "Numar de parametri inadecvat!\nMod de utilizare: ./test.sh URL"
else
regex="(https?|ftp|file)://[www.][-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]"
regex_ip="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"

if [[ ! $1 =~ $regex && ! $1 =~ $regex_ip ]]
	then 
		echo -e "URL invalid! \n Exemplu: http(s)://www.domeniu.ro"
else
echo -e "\e[1mDate extrase din header-ul HTTP:\e[0m\n"

curl -sLI --url $1 >> $curl_response_file

server_check=$(cat $curl_response_file | grep -i "Server" | head -n 1 | sed 's/^.*: //')
x_frame_check=$(cat $curl_response_file | grep -i "X-Frame-Options" | head -n 1 | sed 's/^.*: //')
strict_transport_security=$(cat $curl_response_file | grep -i "Strict-Transport-Security" | head -n 1 | sed 's/^.*: //')
x_xss_protection=$(cat $curl_response_file | grep -i "X-XSS-Protection" | head -n 1 | sed 's/^.*: //')
x_csp=$(cat $curl_response_file | grep -i "Content-Security-Policy" | head -n 1 | sed 's/^.*: //')
x_content_type_options=$(cat $curl_response_file | grep -i "X-Content-Type-Options" | head -n 1 | sed 's/^.*: //')

rm -f $curl_response_file

if [ -z $x_frame_check ]
	then x_frame_check="Nesetat"
fi
if [ -z $strict_transpor_security ]
	then strict_transpor_security="Nesetat"
fi
if [ -z $x_xss_protection ] || [ $x_xss_protection -eq 0 ]
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
	
	if [[ ( "$wordpress_check" == "found" || $wordpress_check == "not_sure" ) ]]
		then
			if [ $wordpress_check == "not_sure" ]
				then
					echo -e "Versiune CMS identificata partial: Posibil Wordpress\n Puteti rula urmatoarele utilitare pentru testare:\n"	
				else 
					echo -e "Versiune CMS identificata: Wordpress\nUrmatoarele utilitare pot fi folosite pentru testare:\n "						
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
							wpscan --url $1 --random-user-agent --no-banner --no-update -e u
					elif [ $tip_atac -eq 3 ]
						then
							wpscan --url $1 --random-user-agent --no-banner --no-update -e ap
					elif [ $tip_atac -eq 2 ]
						then
							echo -e "Introduceti username-ul/username-urile despartite prin ',':"
							read users
							wpscan --url $1 --random-user-agent --no-banner --no-update --passwords rockyou.txt --usernames $users
					elif [ $tip_atac -eq 4 ] 
						then
							wpscan --url $1 --random-user-agent --no-banner --no-update -e vp	
					elif [ $tip_atac -eq 5 ] 
						then
							wpscan --url $1 --random-user-agent --no-banner --no-update -e vt	
					elif [ $tip_atac -eq 6 ] 
						then
							wpscan --url $1 --random-user-agent --no-banner --no-update -e cb					
					fi
			elif [ $choice -eq 2 ]
				then
					echo -e "\nAlegeti tipul de atac dorit:\n 1 --> Scanare completa(timp mare)\n 2 --> Listarea plugin-urilor\n 3 --> Atac de tip brute force(rockyou.txt) identificare parola utilizator\n 4 --> Atac de tip brute force(rockyou.txt) identificare parola utilizatori(dintr-un fisier)" 
					read tip_atac
					echo "Ati ales: "$tip_atac
					cd CMSmap/
					if [ $tip_atac -eq 1 ]
						then
							python3 cmsmap.py $1 -f W
					elif [ $tip_atac -eq 2 ]
						then	
							python3 cmsmap.py $1 -f W --noedb
					elif [ $tip_atac -eq 3 ]
						then
							echo -e "Introduceti username-ul:"
							read user
							python3 cmsmap.py $1 -f W -u $user -p ../passwords.txt
					elif [ $tip_atac -eq 4 ]
						then
							echo -e "Introduceti numele fisierului cu username-uri:"
							read usernames_file
							python3 cmsmap.py $1 -f W -u $usernames_file -p ../passwords.txt
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
							python3 cmsmap.py $1 -f J -u $user -p ../passwords.txt
					elif [ $tip_atac -eq 4 ]
						then
							echo -e "Introduceti numele fisierului cu username-uri:"
							read usernames_file
							python3 cmsmap.py $1 -f J -u $usernames_file -p ../passwords.txt
					fi						
			fi
	elif [[ ( "$drupal_check" == "found" || $drupal_check == "not_sure" ) ]]
		then 
			if [ $drupal_check == "not_sure" ]
				then
					echo -e "Versiune  CMS identificata partial: Drupal \n Urmatoarele utilitare pot fi folosite pentru testare:\n"
				else
					echo -e "Versiune  CMS identificata: Drupal \n Urmatoarele utilitare pot fi folosite pentru testare:\n"
			fi
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
							echo -e "Introduceti username-ul:"
							read user
							python3 cmsmap.py $1 -f D -u $user -p ../passwords.txt
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
