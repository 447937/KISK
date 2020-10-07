<# 
Tiskař štítků pro Zebru na Křižovatce
Knihovna na Křižovatce
Ondřej Kadlec 2020
Kdo za to může: 447937@mail.muni.cz
Využívá ZPL (Zebra Programming Language), víc info třeba tu: https://www.zebra.com/content/dam/zebra/manuals/printers/common/programming/zpl-zbi2-pm-en.pdf
Je nutný mít správně nastavenou tiskárnu ve Windows, tak aby brala surová data.
Pro čárové kódy používáme CODE_128 i EAN-13 (záleží jak na co).
#>

<# Batch pro obejití powershell security politiky
@echo off
powershell -ExecutionPolicy Bypass -Command "& '%~d0%~p0%~n0.ps1'
#>

## ## ## ## ## ## ## ## ## ## NASTAVENÍ ## ## ## ## ## ## ## ## ## ##
# KOHA login a URI (Nutný povolit BasicAuth pro REST API v KOHA)
$k_user="--uzivatel--"
$k_pass="--heslo--"
$k_uri="--KOHA STAFF URL--/api/v1"
# Další nastavení
$zebra="--tiskárna--"       # Nastavení výstupu
[int]$i_max=100             # Maximální počet generovaných štítků
$l_path="./x-printer.log"   # Umístění logu
$f_xlokace="./x-lokace.csv" # CSV soubor obsahující zkratky a popisky lokací (fronta-rezervaci), oddělovačem je ";" -- jednou snad bude dostupné API
$f_xknihy="./x-biblio_report-reportresults.csv" # CSV soubor s potřebnými daty o knihách -- jednou snad bude dostupné API
# Ceny pro účtenky
$cenik=@()
$cenik+=[PSCustomObject]@{ id=0; nazev="Čtenářský poplatek: Dospělý";       cena=50}
$cenik+=[PSCustomObject]@{ id=1; nazev="Čtenářský poplatek: Dítě";          cena=90}
$cenik+=[PSCustomObject]@{ id=2; nazev="Barevný tisk/kopírování";           cena=5}
$cenik+=[PSCustomObject]@{ id=3; nazev="Černobílý tisk/kopírování";         cena=2}

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

Clear-Host
Write-Host "`t`t`t>>> Zebrový tiskař štítků <<<"

FUNCTION Write-Menu {
    Write-Host "`n> MENU"
    Write-Host "  0: Tisk čtenářské průkazky"
    Write-Host "  1: Dávkový tisk čárových kódů na průkazky"
    Write-Host "  2: Dávkový tisk čárových kódů na knihy"
    Write-Host "  3: Fronta rezervací"
    Write-Host "  4: Tisk účtenek" 
    # Write-Host "  m: Tisk  MVS štítku" #chcete mě?
    # Write-Host "  adm: Nastavení tiskárny / disaster recovery?
    Write-Host "  d: Diagnostika spojení"
    Write-Host "  q: Ukončit skript"

    $volba = Read-Host -Prompt "`n~ Volba"
        SWITCH ( $volba )
        {
            0 { tisk-ctenare }
            1 { vytvor-barcode -b_typ p }
            2 { vytvor-barcode -b_typ k }
            3 { fronta-rezervaci }
            4 { vytvor-uctenku }
            #m { MVS }
            #adm { nastveni-zebry }
            d { probe-KOHA }
            q { pac-a-pusu }
            #f { Fix-Menu } #
        }
    Write-Menu # Zachycení neplatné volby a taky doběhlé funkce...nechť rekurze vládne světu
}

FUNCTION tisk ($tdata) {
    if ( $tdata -ne $null ) {
        Write-Host "`n@func tisk INFO: Data se odesílají do tiskárny..."
        Write-Output $tdata #>> $kam #> $pf  NEBO přímo ROZHRANÍ USBfň?
        # Out-Printer -InputObject $tdata -Name $zebra
        Clear-Variable -Name tdata
    }
    else { Write-Host "`n@func tisk ERROR: Žádná data k tisku."}
}

FUNCTION pac-a-pusu {
    Write-Host "Pac a pusu :*"
    Start-Sleep -s 0.52
    exit
}

FUNCTION Get-Ctenar ($metoda) { #id=dle ID čtenáře; bcode=dle čárového kdódu na průkazce
    SWITCH ( $metoda )
    {
        bcode {
            TRY {
                $Script:ErrorMessage="Nebylo zadáno číslo průkazky." #Tohle vyteče jinde, když to bude třeba :)
                [long]$prukazka = Read-Host -Prompt "~ Číslo průkazky" }
            CATCH {
                [bool]$c_error=1
                $ErrorMessage = $_.Exception.Message
                Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n$ErrorMessage"
                $Script:ErrorMessage="Došlo k zadání nečíselné hodnoty."
            }

            if ( $c_error -ne 1 -AND $prukazka -ne "" ) {
                TRY {
                    $Script:ErrorMessage="Zadaná hodnota NEodpovídá právě jednomu čtenáři." #Tohle vyteče jinde, když to bude třeba :)
                    $Script:cdata= Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI "$k_uri/patrons`?cardnumber=$prukazka"
                    }
                CATCH {
                    [bool]$c_error=1
                    $ErrorMessage = $_.Exception.Message
                    Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n$ErrorMessage"
                    $Script:ErrorMessage = "Chyba komunikace se serverem."
                }
            }
        }
        id { 
            TRY {
                $Script:ErrorMessage="ID čtenáře neexistuje." #Tohle vyteče jinde, když to bude třeba :)
                $Script:cdata = Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI "$k_uri/patrons/$r_patronID"
                }
            CATCH {
                [bool]$c_error=1
                $ErrorMessage = $_.Exception.Message
                Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n$ErrorMessage"
                $Script:ErrorMessage = "Chyba komunikace se serverem."
            }
        }
    }
}

FUNCTION vytvor-barcode ( $b_typ, [long]$bdata ) { #k = knihy; p = průkazky
    if ( $bdata -ne 0 ) { [long]$kod = $bdata; Write-Host "~ Začátek generovaného rozsahu je $kod" }
    else { 
        SWITCH ( $b_typ )
        {
            k { Write-Host "`n> DÁVKOVÝ tisk čárových kódů na knihy" }
            p { Write-Host "`n> DÁVKOVÝ tisk čárových kódů na průkazky" }
        }

        TRY { [long]$kod = Read-Host -Prompt "~ Začátek generovaného rozsahu"; $e_mess = 1 }
        CATCH {
            [bool]$b_error = 1
            $ErrorMessage = $_.Exception.Message
            Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n$ErrorMessage"
        }
    }

    if ( $b_error -ne 1 -AND $kod -ge 1 ) {
        TRY { [int]$kolik = Read-Host -Prompt "~ Počet tisknutých štítků"; $e_mess = 1 }
        CATCH {
            Write-Host "> Neplatná hodnota! Opakujte zadání..."; $e_mess = 0
            vytvor-barcode -b_typ $b_typ -bdata $kod
            Clear-Variable -Name bdata, kolik, b_error 2>&1 | Out-Null
            [bool]$b_error = 1
        }
    }

    if ( $b_error -ne 1 -AND ( $kolik -ge 1 -AND $kod -ge 1 )) {
        $a=""
        SWITCH ( $b_typ )
        {
            k { $b_fill = "^FO60,10^BY3 ^BEN,80,Y,N" } #EAN-13
            p { $b_fill = "^FO15,10^BY3 ^BCN,80,Y,N,N" } #CODE_128; dřív bylo UPC_A (type PRODUCT) - co tedy skutečně platí?
        }

        do {
            $a= "$a ^XA ^CI28 $b_fill^FD$kod^FS ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS ^XZ `n"
            $i++ ; $kod++
        } while ( $i -lt $kolik -AND $i -lt $i_max ) 
        if ( $i -ge $i_max ) { Write-Host "`n@func vytvor-barcode INFO: Překročen maximální počet tisknutelných štítků (nyní $i_max štítků v dávce)." }
        tisk -tdata $a
    }
    elseif ( $e_mess -eq 1 ) { Write-Host "`n@func vytvor-barcode ERROR: Chybně zadané hodnoty pro čárový kód anebo množství." }

    Clear-Variable -Name bdata, b_error, i, kolik, kod 2>&1 | Out-Null
}

FUNCTION tisk-ctenare {
    Write-Host "`n> Tisk čtenářské průkazky"

    Get-Ctenar -metoda bcode
    if ( $cdata.count -eq 1 -AND $c_error -ne 1 ) {
        [string]$c_jmeno    = $cdata.firstname
        [string]$c_prijmeni = $cdata.surname
        $ctenar_rok         = $cdata.date_of_birth -split '-'; [string]$c_rok = $ctenar_rok[0]
        [string]$c_ulice    = $cdata | Select-Object -ExpandProperty address
        [string]$c_cp       = $cdata.street_number
        [string]$c_mesto    = $cdata.city
        [string]$c_psc      = $cdata.postal_code
    }

    if ( $c_error -eq 1 -OR ( $cdata.count -ne 1 -OR $prukazka -eq "" ) ) { Write-Host "`n@func tisk-ctenare ERROR: $ErrorMessage" }
    elseif ( $cdata.category_id -eq "D" -AND $c_error -ne 1 ) { 
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
    }
    elseif ( $cdata.category_id -ne $null -AND $c_error -ne 1 ) {
        $a= "
        ^XA
            ^CI28
            ^FT^A0N,30,20^FO10,10^FDČTENAŘSKY PRŮKAZ č.:^FS
            ^FT^A0N,30,23^FO215,10^FD$prukazka^FS
            ^FT^A0N,30,20^FO10,50^FDJméno:^FS
            ^FT^A0N,30,23^FO75,50^FD$c_jmeno $c_prijmeni^FS
            ^FT^A0N,30,20^FO10,90^FDBydlište:^FS
            ^FT^A0N,30,23^FO85,90^FD$c_ulice $c_cp^FS
            ^FT^A0N,30,23^FO85,120^FD$c_mesto $c_psc^FS
        ^XZ"
    }
    else { Write-Host "`n@func tisk-ctenare ERROR: Nedefinovaná chyba...dejte vědět jak se to stalo. :) " } #Tohle asi nikdy nenastane, ale kdyby náhodou...

    if ( $a -ne $null ) { tisk -tdata $a }

    Clear-Variable -Name prukazka, c_error, ErrorMessage, cdata, a 2>&1 | Out-Null
}

FUNCTION fronta-rezervaci {
    Write-Host "`n> Fronta rezervací"
    
    if ( $script:obj_rezervace -ne $null ) {
        Write-Host "@func fronta-rezervaci INFO: Fronta již byla jednou vygenerována. Co teď? `n  0: Zobrazit s možností tisku  `n  1: Jen vytisknout`n  2: Vygenerovat znovu"
        $volba = Read-Host -Prompt "`n~ Volba"

        SWITCH ( $volba )
        {
            0 { generuj-frontu-rezervaci -operace 0 ; [bool]$no_do=1 }
            1 { generuj-frontu-rezervaci -operace 1 ; [bool]$no_do=1 }
            2 { $script:obj_rezervace=@() ; stahni-frontu-rezervaci }
            Default { [bool]$no_do=1 ; Write-Host "@func fronta-rezervaci ERROR: Neplatná volba." }
        }
    }
    else { $script:obj_rezervace=@() ; stahni-frontu-rezervaci }

    if ( $f_fr_loaded -eq 1 -OR $r_error -eq 1 ) {} #tohle je ošklivé, ale vlastně správně...trust me #r/wcgw
    elseif ( ( $hdata.count -ne 0 -AND $r_error -ne 1 ) -AND ( (Test-Path $f_xknihy) -AND (Test-Path $f_xlokace) ) ) {
        Write-Host "@func fronta-rezervaci INFO: Načítají se soubory..."
        $script:tab_xbiblio = Import-Csv -Path $f_xknihy -Delimiter ";"
        $script:tab_xlokace = Import-Csv -Path $f_xlokace -Delimiter ";" -Header "Zkratka", "Popisek"
        [bool]$script:f_fr_loaded = 1
    }
    else { [bool]$r_error=1; $ErrorMessage="Nepodařilo se nalézt požadované soubory (x-lokace.csv anebo x-biblio_report-reportresults.csv)." }

    if ( $r_error -ne 1 -AND $no_do -ne 1 ) {
        [int]$r_pocet = $hdata.count
        [int]$i=1

        Write-Host "@func fronta-rezervaci INFO: Zpracovávají se data ($r_pocet rez.), čekejte prosím..."

        ForEach ($rezervace IN $hdata) {
            $r_biblioID = $rezervace.biblio_id
            $r_patronID = $rezervace.patron_id
                        
            Get-Ctenar -metoda ID
            if ( $cdata.count -eq 1 -AND $c_error -ne 1 ) {
                [string]$c_jmeno = $cdata.firstname
                [string]$c_prijmeni = $cdata.surname
            }

            $pom = $tab_xbiblio.Where({$_.biblionumber -eq ( $rezervace.biblio_id )}) | Select author, title, itemcallnumber, barcode, permanent_location

            $script:obj_rezervace+=[PSCustomObject]@{
                or_ID               = $i;
                or_Datum_Pozadavku  = $rezervace.hold_date;
                or_Autor            = $pom.author;
                or_Nazev_Knihy      = $pom.title;
                or_Signatura        = $pom.itemcallnumber;
                or_Lokace           = $tab_xlokace.Where({$_.Zkratka -eq ( $pom.permanent_location )}) | Select-Object Popisek -ExpandProperty Popisek;
                or_Ctenar           = "$c_jmeno $c_prijmeni";
                or_Barcode          = $pom.barcode
            }
            
            [int]$r_progress = $(100*$i/$r_pocet)
            Write-Progress -Activity "Parsují se data" -Status "$r_progress% Hotovo" -PercentComplete $r_progress
            $i++
        }
        $script:vygenerovano=Get-Date -Format "dd/MM/yyyy HH:mm"
    }
    elseif ( $no_do -eq 1 ) {}
    else { Write-Host "`n@func fronta-rezervaci ERROR: $ErrorMessage" }

    if ( $script:obj_rezervace.Count -ne 0 -AND $no_do -ne 1 ) { generuj-frontu-rezervaci -operace 0 }
    elseif ( $no_do -eq 1 ) {}
    else { Write-Host "`n@func fronta-rezervaci INFO: Žádné dostupné rezervace." }
}

FUNCTION generuj-frontu-rezervaci ($operace) {
    Write-Host "`n`t`t`t~~ VÝPIS FRONTY REZERVACÍ ~~"
    $vygenerovano=Get-Date -Format "dd/MM/yyyy HH:mm"
    [int]$line = 170 # vertikální pozice čáry v hlavičce
    $a="^CF0,60 ^FO60,80^FDFRONTA REZERVACÍ^FS ^CF0,30 ^FO65,140^FDVygenerováno:^FS ^FO58,$line^GB490,1,2^FS" #hlavička...teda, aspoň její část. Zbytek je dole.

    ForEach ($rezervace in $obj_rezervace) {
        $id     = $rezervace.or_ID
        $datum  = $rezervace.or_Datum_Pozadavku
        $autor  = $rezervace.or_Autor
        $kniha  = $rezervace.or_Nazev_Knihy
        $sig    = $rezervace.or_Signatura
        $lokace = $rezervace.or_Lokace
        $ctenar = $rezervace.or_Ctenar
        $bcode  = $rezervace.or_Barcode
        
        [int]$row1 = 15 + $line
        [int]$row2 = 35 + $row1
        [int]$row3 = 30 + $row2
        [int]$row4 = 35 + $row3
        [int]$row5 = 30 + $row4
        [int]$line = 25 + $row5

        $a="$a 
        ^CFA,20 ^FO20,$row1^FD$id.^FS
        ^FO65,$row5^FDReq: $datum^FS
        ^CFA,30,12
        ^FO65,$row1^FDLokace:^FS
        ^FO65,$row4^FDKomu:^FS
        ^CF0,30
        ^FO150,$row1^FD$lokace^FS
        ^FO65,$row2^FD$kniha^FS
        ^FO65,$row3^FD$autor ($sig)^FS
        ^FO125,$row4^FD$ctenar^FS
        ^FO15,$line^GB570,1,1^FS
        "
        $b="$b`n$id`:`tNázev:`t`t$kniha`n`tAutor:`t`t$autor`n`tSignatura:`t$sig`n`tLokace:`t`t$lokace`n`tKód:`t`t$bcode`n`tDatum:`t`t$datum`n`tČtenář:`t`t$ctenar`n"    
    }
    
    $a="^XA ^CI28 ^LL$line ^CFA,30 ^FO255,140^FD$vygenerovano^FS $a ^XZ"

    if ( $operace -eq 0) { 
        Write-Host $b
        $volba = Read-Host -Prompt "`n~ Vytisknout frontu rezervací? [ ANO = a,y,1 / NE = cokoliv jiného ]"
        if ($volba -eq "a" -OR $volba -eq "y" -OR $volba -eq "1") { tisk -tdata $a }
    }
    else { tisk -tdata $a }
}

FUNCTION stahni-frontu-rezervaci {
    TRY {
        $ErrorMessage="Chyba spojení se serverem!"
        $Script:hdata= Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI "$k_uri/holds"
    }
    CATCH {
        [bool]$Script:r_error=1
        $Script:ErrorMessage = $_.Exception.Message
        Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n$ErrorMessage"
    }
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
#       ÚČTENKY / stvrzenky

FUNCTION Get-StringHash {       # vytvoření hashe účtenky (čas+cena?...a kolik znaků?) # Get-StringHash "$datum_cas$cena_celkem"
    param
    (
        [String] $String,
        $HashName = "MD5"
    )
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
    $algorithm = [System.Security.Cryptography.HashAlgorithm]::Create('MD5')
    $StringBuilder = New-Object System.Text.StringBuilder 
  
    $algorithm.ComputeHash($bytes) | 
    ForEach-Object { 
        $null = $StringBuilder.Append($_.ToString("x2")) 
    } 
  
    $StringBuilder.ToString() 
}

FUNCTION vytvor-uctenku {
    # typy: dítě / dospělý / kopírování / jiné placené služby?
    Write-Host "`n> Tisk účtenek"
    $obj_uctenka=@()
    [bool]$u_complete=0
    [int]$u_suma=0

    WHILE ( $u_complete -ne 1 )
    {
        Write-Host "- Přidat položku:"
        ForEach ( $polozka IN $cenik ) { Write-Host "  $($polozka.id): $($polozka.nazev)" }
        Write-Host "`n  E: Opustit a zrušit aktuální účtenku"
        $volba = Read-Host -Prompt "~ Volba"
        $pom = $cenik.Where({$_.id -eq $volba})

        SWITCH -regex ( $volba )
        {
            '[01]' {
                        Get-Ctenar -metoda bcode
                        if ( $cdata.count -eq 1 -AND $c_error -ne 1 ) {
                            [string]$c_jmeno    = $cdata.firstname
                            [string]$c_prijmeni = $cdata.surname
                            [string]$c_typ      = $cdata.category_id
                        }
                        else { Write-Host "@func fronta-rezervaci ERROR: Problém s identifikací čtenáře.`n Doplňující informace: $ErrorMessage`n"}

                        SWITCH ( $volba ) {  0  { $u_cvybran = "DOSPĚLÝ" } ;  1   { $u_cvybran = "DÍTĚ" } }
                        SWITCH ( $c_typ ) { "D" { $u_csystem = "DÍTĚ" } ; Default { $u_csystem = $c_typ } }

                        if ( $c_error -ne 1 -AND (($volba -eq 1 -AND $c_typ -ne "D") -OR ($volba -eq 0 -AND $c_typ -eq "D")) ) {
                            Write-Host "@func fronta-rezervaci INFO: Vybraný typ čtenáře se neshoduje s údaji v systému! Co teď?`n  0: Pokračovat s typem vybraným typem čtenáře ($u_cvybran)`n  1: Pokračovat s typem čtenáře podle systému ($u_csystem)"
                            $volba = Read-Host -Prompt "~ Volba"
                        }
                        

                    }
            2   {
                    [int]$tisk_barevne_pocet = Read-Host -Prompt "`n~ Počet barevně tiskutých stran"        #trycatchovat
                    $obj_uctenka+=[PSCustomObject]@{ polozka="$($pom.nazev) ($($tisk_barevne_pocet)x)"; cena=$($pom.cena*$tisk_barevne_pocet)}
                }
            3   {
                    [int]$tisk_cernobile_pocet = Read-Host -Prompt "`n~ Počet černobíle tiskutých stran"        #trycatchovat
                    $obj_uctenka+=[PSCustomObject]@{ polozka="$($pom.nazev) ($($tisk_cernobile_pocet)x)"; cena=$($pom.cena*$tisk_cernobile_pocet)}
            '[4-9]+' { 
                        Write-Host "$($pom.id) má popisek $($pom.nazev)"
                     }
            e { [bool]$u_complete=1 ; [bool]$no_do=1 }
            Default { Write-Host "@func fronta-rezervaci ERROR: Neplatná volba, opakujte zadání.`n" }
        }
    }
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
<#                       MOŽNÁ SE POUŽIJE
FUNCTION MVS {
    #TŘEBA TAKTO:
    $a="
    ^XA^LRY
        ^CI28
        ^FO120,10^GB160,100,100^FS
        ^FO135,40^CFG^FDMVS^FS
        ^LRN
        ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS
    ^XZ"

    tisk -tdata $a    
}
#>

<#  TECH INFO
1 mm = 8 Zebra dots 
Lepítka: šířka 5 cm = ^PW400

Pokladní rolka (continuous media ^MNxxx ^LL): 7,5 cm = ^PW600
zkošuíme: ^MNV,0

#>

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
#              ** DIAGNOSTIKA A NASTAVENÍ A TROUBLESHOOTING **                 #

FUNCTION Fix-Menu {
Invoke-WebRequest -URI https://krizovatka-staff.koha.cloud/cgi-bin/koha/reports/guided_reports.pl?reports=1`&phase=Export`&format=csv`&report_id=44`&reportname=x-biblio_report
}


FUNCTION Set-Xprinter {
    #ZPL kód pro tovární factory reset a nastavení základních parametrů tisku
    Write-Host "`n!!>KOFIGURACE TISKÁRNY"
    Write-Host "Informace k ZPL: https://www.zebra.com/content/dam/zebra/manuals/printers/common/programming/zpl-zbi2-pm-en.pdf"

    Write-Host "Nastavení tiskárny pro profil`n`t0: Lepící štítky 2x5 cm (čárové kódy, průkazky)`n`t1: Pokladní rolka 7.5 cm (stvrzenky)"
        $volba = Read-Host -Prompt "`n~ Volba"
        SWITCH ( $volba )
        {
            0 { $a="~SD10 ~TA000 ~JSN ^XA ^SZ2 ^PW400 ^LL164 ^PON ^PR5,5 ^PMN ^MNA ^LS0 ^MTD ^MMT,N ^MPE ^XZ ^XA^JUS^XZ ~JC"; Write-Host "@funk Set-Xprinter INFO: Proběhne kalibrace tiskárny" }
            1 { $a="^XA ^PW600 ^LL800 ^PON ^PMN ^MNN ^MTD ^MMT,N ^MPE ^XZ ^XA^JUS^XZ" }
        }

        if ( $a -ne $null ) { tisk -tdata $a }
        Clear-Variable -Name volba, a 2>&1 | Out-Null

        # kde nic, tu nic
    #Write-Host "`t`t~~ UKONČENÍ KONFIGURACE TISKÁRNY ~~"

    <# 
    Factory defaults: ^XA ^JUF ^XZ
    2x5 cm štítky: ~SD10 ~TA000 ~JSN ^XA ^SZ2 ^PW400 ^LL164 ^PON ^PR5,5 ^PMN ^MNA ^LS0 ^MTD ^MMT,N ^MPE ^XZ ^XA^JUS^XZ ~JC

    Pokladní rolka: ^XA ^PW600 ^LL800 ^PON ^PMN ^MNN ^MTD ^MMT,N ^MPE ^XZ ^XA^JUS^XZ

    =======
    CONTINUOUS
    ^MN V,160 : V=continuous media, variable length; 160=(~2cm) mezera mezi tiskovými bloky ^XA..^XZ
    ^PW 600: 400=(~7,5cm) šířka štítku/rolky/tisknutelné oblasti


    NON-CONTINUOUS
    ^MN W,0: W= non-continuous media web sensing; 0=If set to 0, the media mark is expected to be found at the point of separation. (i.e., the perforation, cut point, etc.)
    ^ML 164: 164=(~2,05cm) maximální délka štítku (ignorováno v continuous režimu)
    ^PW 400: 400=(~5cm) šířka štítku
    ~JC: Kalibrace
    #>

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
