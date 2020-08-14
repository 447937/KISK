<# 
Tiskař štítků pro Zebru na Křižovatce
Knihovna na Křižovatce
Ondřej Kadlec 2020
Kdo za to může: 447937@mail.muni.cz
Využívá ZPL (Zebra Programming Language), víc info třeba tu: https://www.zebra.com/content/dam/zebra/manuals/printers/common/programming/zpl-zbi2-pm-en.pdf
Je nutný mít správně nastavenou tiskárnu ve Windows, tak aby brala surová data.
Pro čárové kódy používáme CODE_128 i EAN-13 (záleží jak na co).
#>

#testovací fígl:
$kam='./out.txt' #kde se má tisknout, resp kam má jít textový výstup? - správně to má být tiskárna, nikoliv soubor

## KOHA autorizační údaje
# Vyžaduje povolený BasicAuth pro REST API v KOHA
$k_user="--uzivatel--"
$k_pass="--heslo--"
$k_uri="--KOHA STAFF URL--/api/v1/patrons"
#############################

Clear-Host
Write-Host "`t`t`t>>> Zebrový tiskař štítků <<<"

FUNCTION Write-Menu {
    Write-Host "`n> MENU:"
    Write-Host "  0: Tisk čtenářské průkazky"
    Write-Host "  1: Dávkový tisk čárových kódů na průkazky"
    Write-Host "  2: Dávkový tisk čárových kódů na knihy"
    # Write-Host "  m: Tisk  MVS štítku" #chcete mě?
    # Write-Host "  adm: Nastavení tiskárny / disater recovery?
    Write-Host "  d: Diagnostika spojení"
    Write-Host "  q: Ukončit skript"

    $volba = Read-Host -Prompt "`n~ Volba"
        switch ( $volba )
        {
            0 { tisk-ctenare }
            1 { vytvor-barcode -b_typ p }
            2 { vytvor-barcode -b_typ k }
            #m { MVS }
            #adm { nastveni-zebry }
            d { probe-KOHA }
            q { pac-a-pusu }
        }
    Write-Menu <# Zachycení neplatné volby a taky doběhlé funkce...nechť rekurze vládne světu #>
}

FUNCTION tisk($tdata) {
    ## víc info na https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-printer?view=powershell-7
    # Write-Output $data | Out-Printer -Name '--název tiskárny--' 

    if ( $tdata -ne $null ) {
        Write-Host "@func tisk"
        Write-Output $tdata #>> $kam #> $pf  NEBO přímo ROZHRANÍ USBfň     #tiskárna baští
        # CMD cesta vede skrze soubor copy $pf \\localhost\tiskarna
        Clear-Variable -Name tdata
    }
    else { Write-Host "`n@func tisk Error: Žádná data k tisku."}
}

FUNCTION pac-a-pusu {
    Write-Host "Pac a pusu :*"
    Start-Sleep -s 0.5
    exit
}


FUNCTION vytvor-barcode ($b_typ, [long]$bdata) { #k = knihy; p = průkazky
    if ( $bdata -eq 0 ) {    
        switch ( $b_typ )
        {
            k { Write-Host "`n> DÁVKOVÝ tisk čárových kódů na knihy" }
            p { Write-Host "`n> DÁVKOVÝ tisk čárových kódů na průkazky" }
        }
    }

    if ( $bdata -ne 0 ) { [long]$kod = $bdata; Write-Host "~ Začátek generovaného rozsahu je $kod" }
    else { 
        TRY {
            [long]$kod = Read-Host -Prompt "~ Začátek generovaného rozsahu"
        }
        CATCH {
            [int]$b_error = 1
            $ErrorMessage = $_.Exception.Message
            Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`nChybové hlášení: $ErrorMessage"
        }
    }

    if ( $kod -ne $null ) {
        TRY {
            [int]$kolik = Read-Host -Prompt "~ Počet tisknutých štítků"
            [int]$b_error=0
        }
        CATCH {
            [int]$b_error=1
            Write-Host "> Neplatná hodnota! Opakujte zadání..."
            vytvor-barcode -b_typ $b_typ -bdata $kod
        }
    }

    if ( $b_error -ne 1 ) { 
        switch ( $b_typ )
        {
            k { $b_fill = "^FO60,10^BY3 ^BEN,80,Y,N" } #EAN-13
            p { $b_fill = "^FO15,10^BY3 ^BCN,80,Y,N,N" } #CODE_128
        }

        do {
            $a= "^XA ^CI28 $b_fill ^FD$kod^FS ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS ^XZ"
            #write-host "@func tisk-carkod-na-knihu Data: $i, $kod"
            tisk -tdata $a
            $i++ ; $kod++
        } while ( $i -lt $kolik )
    }

    Clear-Variable -Name bdata, b_error 2>&1 | Out-Null
}

FUNCTION tisk-ctenare {
    Write-Host "`n> Tisk čtenářské průkazky"

    TRY {
        [long]$prukazka = Read-Host -Prompt "~ Číslo průkazky" }
    CATCH { 
        [int]$p_error=1
        $ErrorMessage = $_.Exception.Message
        Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`nChybové hlášení: $ErrorMessage"
    }

    if ( $p_error -ne 1 ) {
        TRY {
            $ErrorMessage="Zadaná hodnota NEodpovídá právě jednomu čtenáři." #Tohle vyteče jinde, když to bude třeba :)
            $script:cdata= Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI "$k_uri`?cardnumber=$prukazka"

            [string]$c_jmeno = $cdata.firstname
            [string]$c_prijmeni = $cdata.surname
            $ctenar_rok = $cdata.date_of_birth -split '-'; [string]$c_rok = $ctenar_rok[0]
            [string]$c_ulice = $cdata | Select-Object -ExpandProperty address
            [string]$c_cp = $cdata.street_number
            [string]$c_mesto = $cdata.city
            [string]$c_psc = $cdata.postal_code
        }
        CATCH {
            [int]$k_error=1
            $ErrorMessage = $_.Exception.Message
            Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`nChybové hlášení: $ErrorMessage"
        }
    }

    if ( $k_error -eq 1 -OR $cdata.count -ne 1 ) { Write-Host "`n@func tisk-ctenare Error: $ErrorMessage" }
    elseif ( $cdata.category_id -eq "D" ) { 
        $a="  
        ^XA
            ^CI28
            ^FT^A0N,30,20^FO10,10^FDJméno:^FS
            ^FT^A0N,30,23^FO75,10^FD$c_jmeno $c_prijmeni^FS
            ^FT^A0N,30,20^FO10,50^FDRok narození:^FS
            ^FT^A0N,30,23^FO125,50^FD$c_rok^FS
            ^FT^A0N,30,20^FO10,90^FDBydlište:^FS
            ^FT^A0N,30,23^FO85,90^FD$c_ulice $c_cp^FS
            ^FT^A0N,30,23^FO85,120^FD$c_mesto $c_psc^FS
        ^XZ"

        <# DRUHÁ VARIANTA
            ^XA
                ^FT^A0N,30,20^FO10,10^FDCTENARSKY PRUKAZ c.:^FS
                ^FT^A0N,30,23^FO215,10^FD$prukazka^FS
                ^FT^A0N,30,20^FO10,50^FDJmeno:^FS
                ^FT^A0N,30,23^FO75,50^FD$ctenar_jmeno ($ctenar_rok)^FS
                ^FT^A0N,30,20^FO10,90^FDBydliste:^FS
                ^FT^A0N,30,23^FO85,90^FD$ctenar_bydlo^FS
                ^FT^A0N,30,23^FO85,120^FD$ctenar_bydlo2^FS
            ^XZ
        #>

    }
    elseif ( $cdata.category_id -ne $null ) {
        $a= "
        ^XA
            ^CI28
            ^FT^A0N,30,20^FO10,10^FDČTENAŘSKY PRŮKAZ č.:^FS
            ^FT^A0N,30,23^FO215,10^FD$prukazka^FS
            ^FT^A0N,30,20^FO10,50^FDJméno:^FS
            ^FT^A0N,30,23^FO75,50^FD$c_jmeno^FS
            ^FT^A0N,30,20^FO10,90^FDBydlište:^FS
            ^FT^A0N,30,23^FO85,90^FD$c_ulice $c_cp^FS
            ^FT^A0N,30,23^FO85,120^FD$c_mesto $c_psc^FS
        ^XZ"
    }
    else { Write-Host "`n@func tisk-ctenare Error: Staršlivá chyba, která teoreticky může nastat, ale programátora zrovna nenapadla...Na všechno totiž musí(m) mít odpověď :P" }

    if ( $a -ne $null ) { tisk -tdata $a ; $k_error }

    Clear-Variable -Name prukazka, p_error, k_error, ErrorMessage, cdata, a 2>&1 | Out-Null
}

<#  TECH INFO
1 mm = 8 Zebra dots 
Lepítka: šířka 5 cm = ^PW400

Pokladní rolka (continuous media ^MNxxx ^LL): 7,5 cm = ^PW600
zkošuíme: ^MNV,0

#>

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
#                        **  DIAGNOSTIKA A NASTAVENÍ **                        #

FUNCTION set-Xprinter {
    #ZPL kód pro tovární factory reset a nastavení základních parametrů tisku
    Write-Host "Informace k ZPL: https://www.zebra.com/content/dam/zebra/manuals/printers/common/programming/zpl-zbi2-pm-en.pdf"
        # kde nic, tu nic
    #Write-Host "`t`t~~ UKONČENÍ KONFIGURACE TISKÁRNY ~~"
}

FUNCTION probe-KOHA {
    Write-Host "`n!!> DIAGNOSTIKA SPOJENÍ SE SYSTÉMEM KOHA`n ~ Výpis základních údajů..."
    Write-Host "`tVýchozí URI: $k_uri`n`tUživatel: $k_user`n`tHeslo: $k_pass"
    Write-Host " ~ Dojde k pokusu o stažení dat pro patron_id = 2 (--jmeno--)"; pause
    Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI $k_uri/2
    Write-Host "`n ~ Dojde k pokusu o stažení dat pro cardnumber = 26000138 (--jmeno2--)"; pause
    Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI "$k_uri`?cardnumber=26000138"
    Write-Host "`t`t~~ KONEC DIAGNOSTIKY ~~"
}

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
Write-Menu  #tady to vlastně začíná, ale musí to být na samotném konci
