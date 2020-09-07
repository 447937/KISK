<# 
Tiskař štítků pro Zebru na Křižovatce
Knihovna na Křižovatce
Ondřej Kadlec 2020
Kdo za to může: 447937@mail.muni.cz
Využívá ZPL (Zebra Programming Language), víc info třeba tu: https://www.zebra.com/content/dam/zebra/manuals/printers/common/programming/zpl-zbi2-pm-en.pdf
Je nutný mít správně nastavenou tiskárnu ve Windows, tak aby brala surová data.
Pro čárové kódy používáme CODE_128 i EAN-13 (záleží jak na co).
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
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

Clear-Host
Write-Host "`t`t`t>>> Zebrový tiskař štítků <<<"

FUNCTION Write-Menu {
    Write-Host "`n> MENU"
    Write-Host "  0: Tisk čtenářské průkazky"
    Write-Host "  1: Dávkový tisk čárových kódů na průkazky"
    Write-Host "  2: Dávkový tisk čárových kódů na knihy"
    Write-Host "  3: Fronta rezervací"
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
            #m { MVS }
            #adm { nastveni-zebry }
            d { probe-KOHA }
            q { pac-a-pusu }
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
    Start-Sleep -s 0.5
    exit
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
            [int]$b_error = 1
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
            [int]$b_error = 1
        }
    }

    if ( $b_error -ne 1 -AND ( $kolik -ge 1 -AND $kod -ge 1 )) {
        SWITCH ( $b_typ )
        {
            k { $b_fill = "^FO60,10^BY3 ^BEN,80,Y,N" } #EAN-13
            p { $b_fill = "^FO15,10^BY3 ^BCN,80,Y,N,N" } #CODE_128; dřív bylo UPC_A (type PRODUCT) - co tedy skutečně platí?
        }

        do {
            $a= "^XA ^CI28 $b_fill^FD$kod^FS ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS ^XZ"
            #write-host "@func tisk-carkod-na-knihu DATA: $i, $kod"
            tisk -tdata $a
            $i++ ; $kod++
        } while ( $i -lt $kolik -AND $i -lt $i_max ) 
        if ( $i -ge $i_max ) { Write-Host "`n@func vytvor-barcode INFO: Překročen maximální počet tisknutelných štítků (nyní $i_max štítků v dávce)." }
    }
    elseif ( $e_mess -eq 1 ) { Write-Host "`n@func vytvor-barcode ERROR: Chybně zadané hodnoty pro čárový kód anebo množství." }

    Clear-Variable -Name bdata, b_error, i, kolik, kod 2>&1 | Out-Null
}

FUNCTION tisk-ctenare {
    Write-Host "`n> Tisk čtenářské průkazky"

    TRY {
        $ErrorMessage="Nebylo zadáno číslo průkazky." #Tohle vyteče jinde, když to bude třeba :)
        [long]$prukazka = Read-Host -Prompt "~ Číslo průkazky" }
    CATCH { 
        [int]$p_error=1
        $ErrorMessage = $_.Exception.Message
        Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n$ErrorMessage"
    }

    if ( $p_error -ne 1 -AND $prukazka -ne "" ) {
        TRY {
            $ErrorMessage="Zadaná hodnota NEodpovídá právě jednomu čtenáři." #Tohle vyteče jinde, když to bude třeba :)
            $cdata= Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI "$k_uri/patrons`?cardnumber=$prukazka"

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
            Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n$ErrorMessage"
        }
    }

    if ( ( $p_error -eq 1 -OR $k_error -eq 1 ) -OR ( $cdata.count -ne 1 -OR $prukazka -eq "" ) ) { Write-Host "`n@func tisk-ctenare ERROR: $ErrorMessage" }
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

    }
    elseif ( $cdata.category_id -ne $null ) {
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
    else { Write-Host "`n@func tisk-ctenare ERROR: Nedefinovaná chyba...dejte vědět jak se to stalo. :) " }

    if ( $a -ne $null ) { tisk -tdata $a }

    Clear-Variable -Name prukazka, p_error, k_error, ErrorMessage, cdata, a 2>&1 | Out-Null
}

FUNCTION fronta-rezervaci {
    Write-Host "`n> Fronta rezervací"
    $obj_rezervace=@()

    if ( (Test-Path $f_xknihy) -AND (Test-Path $f_xlokace) ) {
        Write-Host "@func fronta-rezervaci INFO: Načítají se soubory, čekejte prosím..."
        $tab_xbiblio = Import-Csv -Path $f_xknihy -Delimiter ";"
        $tab_xlokace = Import-Csv -Path $f_xlokace -Delimiter ";" -Header "Zkratka", "Popisek"
    }
    else { [int]$r_error=1; $ErrorMessage="Nepodařilo se nalézt požadované soubory (x-lokace.csv anebo x-biblio_report-reportresults.csv)." }

    if ( $r_error -ne 1 ) {
        TRY {
                $ErrorMessage="Nedefinovaná chyba." #Tohle vyteče jinde, když to bude třeba :)
                $hdata= Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI "$k_uri/holds"
            }
        CATCH {
                [int]$r_error=1
                $ErrorMessage = $_.Exception.Message
                Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n$ErrorMessage"
            }
    }

    if ( $r_error -ne 1 ) {
        $tab_rezervace = @()
        [int]$r_pocet = $hdata.count
        Write-Host "~ Celkem $r_pocet rezervací k vyřízení."
        [int]$i=1

        Write-Host "`n@func fronta-rezervaci INFO: Zpracovávají se data, čekejte prosím..."
        ForEach ($rezervace in $hdata) {
            $r_biblioID = $rezervace.biblio_id
            $r_patronID = $rezervace.patron_id
            $pom = $tab_xbiblio.Where({$_.biblionumber -eq ( $rezervace.biblio_id )}) | Select-Object permanent_location -ExpandProperty permanent_location

            $rcdata = Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI "$k_uri/patrons/$r_patronID"
            [string]$rc_jmeno = $rcdata.firstname
            [string]$rc_prijmeni = $rcdata.surname

            $obj_rezervace+=[PSCustomObject]@{
                or_ID               = $i;
                or_Datum_Pozadavku  = $rezervace.hold_date;
                or_Autor            = $tab_xbiblio.Where({$_.biblionumber -eq ( $rezervace.biblio_id )}) | Select-Object author -ExpandProperty author;
                or_Nazev_Knihy      = $tab_xbiblio.Where({$_.biblionumber -eq ( $rezervace.biblio_id )}) | Select-Object title -ExpandProperty title;
                or_Signatura        = $tab_xbiblio.Where({$_.biblionumber -eq ( $rezervace.biblio_id )}) | Select-Object itemcallnumber -ExpandProperty itemcallnumber;
                or_Lokace           = $tab_xlokace.Where({$_.Zkratka -eq ( $pom )}) | Select-Object Popisek -ExpandProperty Popisek;
                or_Ctenar           = "$rc_jmeno $rc_prijmeni";
                or_Barcode          = $tab_xbiblio.Where({$_.biblionumber -eq ( $rezervace.biblio_id )}) | Select-Object barcode -ExpandProperty barcode;
            }
            $i++
        }
    }
    else { Write-Host "`n@func fronta-rezervaci ERROR: $ErrorMessage" }

    if ( $obj_rezervace.Count -ne 0 ) {
        Write-Host "`n`t`t`t~~ VÝPIS FRONTY REZERVACÍ ~~"
        
        ForEach ($rezervace in $obj_rezervace) {
            $id = $rezervace.or_ID
            $datum = $rezervace.or_Datum_Pozadavku
            $autor = $rezervace.or_Autor
            $kniha = $rezervace.or_Nazev_Knihy
            $sig = $rezervace.or_Signatura
            $lokace = $rezervace.or_Lokace
            $ctenar = $rezervace.or_Ctenar
            $bcode = $rezervace.or_Barcode
                        
            Write-Host "`n`n$id`:`tNázev:`t`t$kniha`n`tAutor:`t`t$autor`n`tSignatura:`t$sig`n`tLokace:`t`t$lokace`n`tKód:`t`t$bcode`n`tDatum:`t`t$datum`n`tČtenář:`t`t$ctenar"
        }

        $volba = Read-Host -Prompt "`n~ Vytisknout frontu rezervací? [a,y,1 / n,0]"
        if ($volba -eq "a" -OR $volba -eq "y" -OR $volba -eq "1") {
            ForEach ($rezervace in $obj_rezervace) {
                $id = $rezervace.or_ID
                $datum = $rezervace.or_Datum_Pozadavku
                $autor = $rezervace.or_Autor
                $kniha = $rezervace.or_Nazev_Knihy
                $sig = $rezervace.or_Signatura
                $lokace = $rezervace.or_Lokace
                $ctenar = $rezervace.or_Ctenar
                $bcode = $rezervace.or_Barcode

                $a = "^XA ... ^XZ"
                tisk -tdata $a
            }
        }
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
    # magický kód
    # typy: dítě / dospělý / kopírování / jiné placené služby?
}

<#  TECH INFO
1 mm = 8 Zebra dots 
Lepítka: šířka 5 cm = ^PW400

Pokladní rolka (continuous media ^MNxxx ^LL): 7,5 cm = ^PW600
zkošuíme: ^MNV,0

#>

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
#                        **  DIAGNOSTIKA A NASTAVENÍ **                        #

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
