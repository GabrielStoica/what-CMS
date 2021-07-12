# what-CMS

## Descriere utilitar
Utilitarul what-CMS a fost conceput pentru testarea si scanarea platformelor de tip CMS: Wordpress, Drupal si Joomla!, impotriva vulnerabilitatilor. 
Utilitarul what-CMS dispune de 3 moduri principale de utilizare:
<ol>
  <li>Modul identificare opțiuni de securitate(-http): Trimite o cerere de tip HTTP către URL-ul dat ca parametru(ținta scanării) și identifică, din header-ul răspunsului primit, dacă platforma respectivă are sau nu setate următoarele opțiuni de securitate:</li>
  <li>Modul scanare web-host (-wh, --web-host): Implementat cu ajutorul API-ului ipinfo.io, oferă informații despre platforma scanată și firma de hosting în cadrul căreia este găzduită.</li>
  <li>Modul scanare completă (-fs, --full-scan):  Presupune detecția tipului de CMS al platformei dată ca parametru și scanarea acesteia, integrând cele două moduri menționate mai sus. De asemenea, modul scanare completă include utilizarea unei serii de utilitare open-source, precum: WPScan, droopescan, joomscan, CMSmap și VulnX, care permit utilizatorului continuarea etapei de scanare. </li>
</ol>

## Dependinte
Pentru a putea functiona la parametrii optimi, scriptul are nevoie de urmatoarele 5 utilitare:

- https://github.com/OWASP/joomscan
- https://github.com/Dionach/CMSmap
- https://github.com/droope/droopescan
- https://github.com/wpscanteam/wpscan
- https://github.com/anouarbensaad/vulnx

## Help mode
   ```sh
             __         __$
           /.-'       `-.\                 _             _             _____  __  __   _____ $
          //             \\               | |           | |           / ____||  \/  | / ____|$
         /j_______________j\    __      __| |__    __ _ | |_  ______ | |     | \  / || (___  $
        /o.-==-. .-. .-==-.o\   \ \ /\ / /| '_ \  / _` || __||______|| |     | |\/| | \___ \ $
        ||      )) ((      ||    \ V  V / | | | || (_| || |_         | |____ | |  | | ____) |$
         \\____//   \\____//      \_/\_/  |_| |_| \__,_| \__|         \_____||_|  |_||_____/  $
          `-==-'     `-==-'             Versiunea: 1.20 (c) Stoica Gabriel-Marius$

                 Script conceput pentru testarea si scanarea platformelor de tip CMS:
                 Wordpress, Drupal si Joomla!, impotriva vulnerabilitatilor, integrand
                o serie de utilitare specifice: CMSmap, Droopescan, Joomscan, VulnX  

                        (c) Stoica Gabriel-Marius <marius_gabriel1998@yahoo.com> 
 
Mod de utilizare: ./what-CMS.sh [-h] [OPTIONS] -u http(s)://(www.)site-to-be-scanned.ro/ 
 
avand semnificatia: 
         -h, --help 
                Ajutor, arata modul de utilizare 
         -http 
                Trimite o cerere de tip HTTP catre o tinta si afiseaza
                header-ul raspunsului, identificand daca optiunile de
                securitate sunt activate sau nu
         -fs, --full-scan
                Realizeaza scanarea completa a platformei tinta, oferind
                o serie de utilitare specifice, precum: WPScan, droopescan,
                joomscan, in functie de tipul CMS-ului identificat
         -u URL, --url URL
                Parametru folosit pentru specificarea adresei tinta ce urmeaza a fi scanata 
                Sintaxa URL valida: 
                http(s)://(www.)site-de-scanat.ro sau 192.168.10.0/wordpress
         -wh, --web-host
                Ofera informatii aditionale despre platforma scanata si despre
                firma de hosting pe care este gazduita

   ```
