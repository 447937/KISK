$release = "2023-04-17"
<# 
Tiskař štítků pro Zebru na Křižovatce
Knihovna na Křižovatce
Ondřej Kadlec 2020-2023
Kdo za to může: 447937@mail.muni.cz
Využívá ZPL (Zebra Programming Language), víc info třeba tu: https://www.zebra.com/content/dam/zebra/manuals/printers/common/programming/zpl-zbi2-pm-en.pdf
Pro čárové kódy používáme CODE_128 i EAN-13 (záleží jak na co).
#>

<# Batch pro obejití powershell security politiky
@echo off
powershell -ExecutionPolicy Bypass -Command "& '%~d0%~p0%~n0.ps1'"
#>

<#
# KOHA login a URI (Nutné povolit BasicAuth pro REST API v KOHA)
# Konfigurační soubor: config.json
# Logo knihobny pro Zebru - kovertováno pomocí http://labelary.com/viewer.html ... base64
# Je nutné mít správně nastavenou tiskárnu ve Windows, tak aby brala surová data.
#>

TRY { $conf = Get-Content -Raw "./config.json" -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop }
CATCH { $ierr = "@init ERROR: Chyba při zpracování konfiguračního souboru config.json! Vetšina funkcí bude omezena!`n"; $Script:Message2Menu+=$ierr; Write-Host "$ierr > $($_.Exception.Message)" -BackgroundColor Red -ForegroundColor White; pause }

$f_log  = ".\x-error_log.txt"       # Log pro zaznamenání errorů; ~ to co se vypíše před menu
$f_tmp  = ".\temp_print_file.txt"   # Protože RAW data, UTF8 a Out-Printer se dohromady nebaví :/

# Import ceníku - při úpravách je nutné náležitě upravit funkci vytvor-uctenku (ten velkej ošklivej if skoro dole)
if ( Test-Path $($conf.files.cenik) ) {
    $cen_load = Import-Csv -Path $($conf.files.cenik) -Delimiter ";"
    [int]$ce_i=0; $cenik=@()
    ForEach ( $ce_polozka IN $cen_load ) {
        [int]$ce_audit = $ce_polozka.audit          # Audit: 0=Netiskne se audit štítek pro KJM, 1=audit štítek se tiskne+záznam do auditlogu.
        $DMC_text = $ce_polozka.DMC_text
        $ce_nazev = $ce_polozka.nazev
        [int]$ce_cena = $ce_polozka.cena
    
        $cenik+=[PSCustomObject]@{ id=$ce_i; audit=$ce_audit; DMC_text=$DMC_text; nazev=$ce_nazev; cena=$ce_cena }
        $ce_i++
    }
} else { $Script:Message2Menu += "@init ERROR: Ceníkový soubor ($($conf.files.cenik)) nebyl nalezen, nebude možné tisknout účtenky. Soubor vytvořte včetně odpovídajícího obsahu nebo kontaktujte knihovního technomága.`n" }
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

FUNCTION Write-Menu {
    Clear-Host
    Write-Host "`t`t`t`t`t`t>>> X TERMIX <<<`n"
    if ( $null -ne $Message2Menu ) { Write-Host $Message2Menu; Write-Log -inString $Message2Menu; $Script:Message2Menu = $null }
    if ( $($conf.rezim_lepitek) -eq 1 ) { Write-Host "@Write-Menu INFO: Předpokládá se tisk lepítek.`n" }

    Write-Host "> MENU"
    Write-Host "  0: Fronta rezervací"
    Write-Host "  1: Účtenky"
    Write-Host "  2: Dávkový tisk čárových kódů na průkazky"
    Write-Host "  3: Dávkový tisk čárových kódů na knihy"
    Write-Host "  4: Tisk MVS štítků"
    Write-Host "  5: Tisk čtenářské průkazky"
    Write-Host "`n  d: Diagnostika spojení`t`tx: Nastavení tiskárny`t`ti: Vytvořit/Importovat čtenáře`n  q: Ukončit skript`t`t`tm: Manual override`t`tf: Upravit/zobrazit důležité soubory"

    $volba = Read-Host -Prompt "`n~ Volba"
        SWITCH ( $volba )
        {
            0 { Fronta-Rezervaci }
            1 { vytvor-uctenku }
            2 { vytvor-barcode -b_typ p }
            3 { vytvor-barcode -b_typ k }
            4 { tisk-MVS }
            5 { tisk-ctenare }
            d { probe-KOHA }
            q { pac-a-pusu }
            x { Set-Xprinter }
            m { manual-override }
            i { novy-ctenar }
            f { files-menu }
            t { test-feature }
            Default { if ( "" -ne $volba ) {$Script:Message2Menu+="@Write-Menu WARNING: Neplatná volba <$volba>, opakujte zadání.`n"} }
        }
    
    Clear-Variable -Scope Script -Name r_error 2>&1 | Out-Null
    Write-Menu # Zachycení neplatné volby a taky doběhlé funkce...nechť rekurze vládne světu
}

FUNCTION test-feature {
    Write-Host ">> Entered test feature, now processing..."

    $postParams = '{ "firstname": "Ondroro", "surname": "Kororo", "cardnumber": "121212", "city": "Brno", "category_id": "KJMPL", "library_id": "11", "address": "Nezadáno 0", "incorrect_address": true }'

    $pesto = Invoke-RestMethod -Method POST -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($conf.auth.user):$($conf.auth.password)"))} -URI "$($conf.uri.api)/patrons" -Body $($postParams)

    #$pesto
    if ($null -ne $pesto.patron_id) {Start-Process "https://krizovatka-staff.koha.cloud/cgi-bin/koha/members/memberentry.pl?op=modify&borrowernumber=$($pesto.patron_id)"}
    else { Write-Host "@Test-Feature ERROR: Vytvoření čtenáře se nezdařilo!" }
    Write-Host "> $pesto`n-- -- END -- -- $($postParams)"; pause
}

FUNCTION tisk ($tdata) {
    if ( $null -ne $tdata ) {
        Write-Host "`n@tisk INFO: Tisková data se zpracovávají a odesílají do tiskárny..."
        $tdata | Out-File $f_tmp -Encoding UTF8
        TRY { if ($Env:windir) { Invoke-Expression "cmd /C 'COPY /B $f_tmp $($conf.printer)'" } else { cp $f_tmp $conf.printer }
                if ($LASTEXITCODE -eq 1 ) { $Script:Message2Menu+="@tisk ERROR: Nebylo možné vytisknout požadovaná data - LastExitCode = $LASTEXITCODE`n"; pause }
        } CATCH { $Script:Message2Menu+="@tisk ERROR: Nebylo možné vytisknout požadovaná data - $($_.Exception.Message)`n" }
        
        Clear-Variable -Name tdata
    }
    else { $Script:Message2Menu+="@tisk WARNING: Žádná data k tisku.`n"}
}

FUNCTION pac-a-pusu {
    Write-Host "Pac a pusu :*"
    Start-Sleep -s 0.52
    $host.UI.RawUI.WindowTitle = "X TERMIX byl ukončen normálně"
    exit
}

FUNCTION varovani-tiskarny {
    if ( $($conf.rezim_lepitek) -ne 1 ) {
        Write-Host "`n`t`t`t!! Funkce s tiskem lepících štítků !!`nPokud jste tiskárnu nanastavili pro tisk lepítek (výměna média nestačí), proveďte prosím nastavení tiskárny nyní. `n`n~ Přejít do nastavení tiskárny?`n  0: Ano`n  1: Ne`n  2: Ne a tuhle hlášku už nechci vidět"
        DO { $sub_volba = Read-Host -Prompt "~ Volba" } WHILE ( $sub_volba -lt 0 -OR $sub_volba -gt 2 )
        if ( $sub_volba -eq 0 ) { Set-Xprinter }
        elseif ( $sub_volba -eq 2 ) { [bool]$Script:conf.rezim_lepitek = 1 }
    }
}

FUNCTION Write-Log ($inString) {
    TRY { "[$(Get-Date -Format "yyyy/MM/dd HH:mm:ss")]`n$inString" | Out-File $f_log -Append -Encoding UTF8 }
    CATCH { Write-Host "@Write-Log ERROR: Nebylo možné zapsat do logu ($f_log)`n > $($_.Exception.Message)" -BackgroundColor Red -ForegroundColor White }

}

FUNCTION tisk-MVS ([bool]$rerun) {
    varovani-tiskarny; if ( $chyba_konfigurace -ne 1 ) {

    if ( $rerun -ne 1 ) { Clear-Host; Write-Host "> Tisk MVS štítků" }

    TRY { [int]$kolik = Read-Host -Prompt "~ Počet tisknutých štítků"; [bool]$m_error = 0 }
        CATCH {
            Write-Host "`n> Neplatná hodnota! Opakujte zadání..."
            [bool]$m_error = 1
            tisk-MVS -rerun $m_error
            Clear-Variable -Name kolik 2>&1 | Out-Null
        }

    if ( $m_error -ne 1 ) {
        [int]$pocitadlo = 1
        WHILE ( $pocitadlo -le $kolik )
            { $a+= " ^XA^LRY ^CI28
                    ^FO20,10^GB160,100,100^FS ^FO35,40^CFG^FDMVS^FS
                    ^LRN ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS
                    ^A0N,30,30^FO220,15^FDVraťte do:^FS
                    ^FO150,108^GB230,1,2^FS ^XZ"
                $pocitadlo++
        }
        tisk -tdata $a
    }
}}

FUNCTION Get-Ctenar ($metoda, $param) { #id=dle ID čtenáře; bcode=dle čárového kdódu na průkazce
    SWITCH ( $metoda )
    {
        bcode {
            TRY {
                $Script:ErrorMessage="Nebylo zadáno číslo průkazky." #Tohle vyteče jinde, když to bude třeba :)
                [long]$prukazka = Read-Host -Prompt "~ Číslo průkazky" }
            CATCH {
                [bool]$c_error=1
                $Script:Message2Menu+="@Get-Ctenar ERROR: $($_.Exception.Message)`n"
                $Script:ErrorMessage="Došlo k zadání nečíselné hodnoty."
                RETURN $null
            }

            if ( $c_error -ne 1 -AND $prukazka -ne "" ) {
                TRY {
                    $Script:ErrorMessage="Zadaná hodnota NEodpovídá právě jednomu čtenáři. ($prukazka)" #Tohle vyteče jinde, když to bude třeba :)
                    [Array]$ctenar= Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($conf.auth.user):$($conf.auth.password)")) } -URI "$($conf.uri.api)/patrons`?cardnumber=$prukazka"
                    RETURN $ctenar
                    }
                CATCH {
                    [bool]$c_error=1
                    $Script:Message2Menu+="@Get-Ctenar ERROR: $($_.Exception.Message)`n"
                    $Script:ErrorMessage = "Chyba komunikace se serverem."
                    RETURN $null
                }
            }
        }
        id { 
            TRY {
                $Script:ErrorMessage="ID čtenáře neexistuje." #Tohle vyteče jinde, když to bude třeba :)
                [Array]$ctenar = Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($conf.auth.user):$($conf.auth.password)")) } -URI "$($conf.uri.api)/patrons/$param"
                RETURN $ctenar
                }
            CATCH {
                [bool]$c_error=1
                $Script:Message2Menu+="@Get-Ctenar ERROR: $($_.Exception.Message)`n"
                $Script:ErrorMessage = "Chyba komunikace se serverem."
                RETURN $null
            }
        }
    }
}

FUNCTION vytvor-barcode ( $b_typ, [long]$bdata ) { #k = knihy; p = průkazky
    varovani-tiskarny; if ( $chyba_konfigurace -ne 1 ) {

    if ( $bdata -ne 0 ) { [long]$kod = $bdata; Write-Host "~ Začátek generovaného rozsahu je $kod" }
    else {
        Clear-Host
        SWITCH ( $b_typ )
        {
            k { Write-Host "> DÁVKOVÝ tisk čárových kódů na knihy" }
            p { Write-Host "> DÁVKOVÝ tisk čárových kódů na průkazky" }
        }

        TRY { 
            if ( $b_typ -eq "p" -AND ( Test-Path $($conf.files.dalsi_ckod) ) ) {
                TRY { [int]$dalsi_p_kod = Get-Content $($conf.files.dalsi_ckod)
                        Write-Host "- Stikněte ENTER pro pokračování v číselné řadě průkazek. (nezadávejte žádné hodnoty)`n- Další tisknuté číslo průkazky bude: $dalsi_p_kod"
                } CATCH { $err = "@vytvor-barcode WARNING: Chyba při čtení pomocného souboru."; Write-Host $err; Write-Log -inString "$err - $($_.Exception.Message)" }
            }

            [long]$kod = Read-Host -Prompt "~ Začátek generovaného rozsahu"; $e_mess = 1
            if ( $b_typ -eq "p" -AND $kod -eq "" ) { $kod = $dalsi_p_kod }
        }
        CATCH {
            [bool]$b_error = 1
            $Script:Message2Menu+="@vytvor-barcode ERROR: $($_.Exception.Message)`n"
        }
    }

    if ( $b_error -ne 1 -AND $kod -ge 1 ) {
        TRY { [int]$kolik = Read-Host -Prompt "~ Počet tisknutých štítků"; $e_mess = 1 }
        CATCH {
            Write-Host "`n> Neplatná hodnota! Opakujte zadání..."; $e_mess = 0
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
            SWITCH ( $b_typ )
            {
                k   { $a= "$a ^XA ^CI28 $b_fill^FD$kod^FS ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS ^XZ `n" }  # tiskne se jednou
                p   { $a= "$a ^XA ^CI28 $b_fill^FD$kod^FS ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS ^XZ `n ^XA ^CI28 $b_fill^FD$kod^FS ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS ^XZ `n" }  # tiskne se dvakrát za sebou
            }
            
            #$a= "$a ^XA ^CI28 $b_fill^FD$kod^FS ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS ^XZ `n"
            ##$a+="^XA ^CI28 $b_fill^FD$kod^FS ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS ^XZ `n"
            $i++ ; $kod++
        } while ( $i -lt $kolik -AND $i -lt $($conf.max_lepitek) ) 
        if ( $i -ge $($conf.max_lepitek) ) { $Script:Message2Menu+="@vytvor-barcode INFO: Překročen maximální počet tisknutelných štítků (nyní $($conf.max_lepitek) štítků v dávce).`n" }
        tisk -tdata $a
        if ( $b_typ -eq "p" ) { $kod | Out-File $($conf.files.dalsi_ckod) -NoNewline -Encoding UTF8 }
    }
    elseif ( $e_mess -eq 1 ) { $Script:Message2Menu+="@vytvor-barcode ERROR: Chybně zadané hodnoty pro čárový kód anebo množství.`n" }

    Clear-Variable -Name bdata, b_error, i, kolik, kod 2>&1 | Out-Null
}}

FUNCTION tisk-ctenare {
    varovani-tiskarny; if ( $chyba_konfigurace -ne 1 ) {

    Clear-Host
    Write-Host "> Tisk čtenářské průkazky"

    [Array]$ctenar = Get-Ctenar -metoda bcode

    if ( $ctenar.count -eq 1 -AND $c_error -ne 1 ) {
        [int]$c_prukazka    = $($ctenar.cardnumber)
        [string]$c_jmeno    = $ctenar.firstname
        [string]$c_prijmeni = $ctenar.surname
        $ctenar_rok         = $ctenar.date_of_birth -split '-'; [string]$c_rok = $ctenar_rok[0]
        [string]$c_ulice    = $ctenar | Select-Object -ExpandProperty address
        [string]$c_cp       = $ctenar.street_number
        [string]$c_mesto    = $ctenar.city
        [string]$c_psc      = $ctenar.postal_code
    }

    if ( $c_error -eq 1 -OR ( $ctenar.count -ne 1 -OR $prukazka -eq "" ) ) { $Script:Message2Menu+="@tisk-ctenare ERROR: $ErrorMessage`n" }
    elseif ( $ctenar.category_id -eq "D" -AND $c_error -ne 1 ) { 
        $a="^XA ^CI28
            ^FT^A0N,30,20^FO10,10^FDJméno:^FS
            ^FT^A0N,30,23^FO75,10^FD$c_jmeno $c_prijmeni^FS
            ^FT^A0N,30,20^FO10,50^FDRok narození:^FS
            ^FT^A0N,30,23^FO125,50^FD$c_rok^FS
            ^FT^A0N,30,20^FO10,90^FDBydlište:^FS
            ^FT^A0N,30,23^FO85,90^FD$c_ulice $c_cp^FS
            ^FT^A0N,30,23^FO85,120^FD$c_mesto $c_psc^FS
        ^XZ"
    }
    elseif ( $null -ne $ctenar.category_id -AND $c_error -ne 1 ) {
        $a= "^XA ^CI28
            ^FT^A0N,30,20^FO10,10^FDČTENAŘSKY PRŮKAZ č.:^FS
            ^FT^A0N,30,23^FO215,10^FD$c_prukazka^FS
            ^FT^A0N,30,20^FO10,50^FDJméno:^FS
            ^FT^A0N,30,23^FO75,50^FD$c_jmeno $c_prijmeni^FS
            ^FT^A0N,30,20^FO10,90^FDBydlište:^FS
            ^FT^A0N,30,23^FO85,90^FD$c_ulice $c_cp^FS
            ^FT^A0N,30,23^FO85,120^FD$c_mesto $c_psc^FS
        ^XZ"
    }
    else { $Script:Message2Menu+="`n@tisk-ctenare ERROR: Nedefinovaná chyba...dejte vědět jak se to stalo. :)`n" } #Tohle asi nikdy nenastane, ale kdyby náhodou...

    if ( $null -ne $a ) { tisk -tdata $a }

    Clear-Variable -Name prukazka, c_error, ErrorMessage, a 2>&1 | Out-Null
}}

FUNCTION Fronta-Rezervaci {
    Clear-Host
    Write-Host "> Fronta rezervací"
    $rezervace = Get-FrontaRezervaci
    $i = 0; $r_pocet = $rezervace.Count
    if ($r_pocet -eq 0) { $Script:Message2Menu+="@fronta-rezervaci INFO: Nebyly nalezeny žádné existující rezervace.`n"; RETURN $null }
    Write-Host "@fronta-rezervaci INFO: Zpracovávají se data ($r_pocet rez.), čekejte prosím..."

    Write-Host "`n`t~~ VÝPIS FRONTY REZERVACÍ ~~"
    $vygenerovano=Get-Date -Format "dd/MM/yyyy HH:mm"
    [int]$line = 170 # vertikální pozice čáry v hlavičce
    $a="^CF0,60 ^FO60,80^FDFRONTA REZERVACÍ^FS ^CF0,30 ^FO65,140^FDVygenerováno:^FS ^FO58,$line^GB490,2,2^FS" #hlavička...teda, aspoň její část. Zbytek je dole.

    ForEach ($polozka IN $rezervace) { $i++
        [int]$r_progress = $(100*$i/$r_pocet)
        Write-Progress -Activity "Parsují se data" -Status "$r_progress% Hotovo" -PercentComplete $r_progress

        $bookInfo = Get-Report -report "biblio" -param $polozka.biblio_id
        $ctenar = Get-Ctenar -metoda ID -param $polozka.patron_id

        $id     = $i
        $datum  = $polozka.hold_date
        $autor  = $bookInfo.author
        $kniha  = $bookInfo.title
        $sig    = $bookInfo.itemcallnumber
        $lokace = $bookInfo.Lokace
        $ctenar = "$($ctenar.firstname) $($ctenar.surname)"
        $bcode  = $bookInfo.barcode
        
        [int]$row1 = 15 + $line
        [int]$row2 = 35 + $row1
        [int]$row3 = 30 + $row2
        [int]$row4 = 35 + $row3
        [int]$row5 = 30 + $row4
        [int]$line = 55 + $row5

        $a="$a 
        ^CFA,20 ^FO20,$row1^FD$id.^FS
        ^FO65,$row5^FDReq: $datum^FS
        ^CFA,30,12
        ^FO65,$row1^FDLokace:^FS
        ^FO65,$row4^FDKomu:^FS
        ^CF0,30
        ^FO150,$row1^FD$lokace^FS
        ^FO65,$row2^FD$autor ($sig)^FS
        ^FO65,$row3^FD$kniha^FS
        ^FO125,$row4^FD$ctenar^FS
        ^FO270,$row5 ^BY3 ^BEN,40,N,N^FD$bcode^FS
        ^FO15,$line^GB570,1,1^FS
        "
        
        $b="$b`n$id`:`tLokace:`t`t$lokace`n`tAutor:`t`t$autor`n`tNázev:`t`t$kniha`n`tČtenář:`t`t$ctenar`n`tKód:`t`t$bcode`n`tDatum:`t`t$datum`n"
        
    }
    
    Write-Progress -Activity "Parsují se data" -Completed
    Write-Host $b

    $a="^XA ^CI28 ^LL$line ^CFA,30 ^FO255,140^FD$vygenerovano^FS $a ^XZ"
    $volba = Read-Host -Prompt "`n~ Vytisknout frontu rezervací? [ ANO = a,y,1 / Ne = cokoliv jiného ]"
    if ($volba -IN @('a', 'y', 1, '')) { tisk -tdata $a }

}

FUNCTION Get-Report ($report, $param) { #určeno pro nezabezpečené reporty (knihy, čtenářské kategorie)
    SWITCH ($report) {
        "biblio"{   TRY { $Book = Invoke-RestMethod -Method GET -URI "$($conf.uri.report)$($conf.reports.kniha)$param"
                                RETURN $Book
                            }
                        CATCH { $Script:Message2Menu+="@Get-Report ERROR: Nebylo možné získat data knize (biblionumber=$param) ze systému KOHA.`n"
                                $script:ErrorMessage="Nebylo možné získat data knize (biblionumber=$param)."
                                [bool]$script:r_error=1
                                RETURN $null
                              }
        }
        "ctenKat"   {   TRY { $kategorie = Invoke-RestMethod -Method GET -URI "$($conf.uri.report)$($conf.reports.ctenari)"
                                RETURN $kategorie
                            }
                        CATCH { Write-Host "@Get-Report ERROR: Spojení se serverem se nezdařilo."
                                $Script:Message2Menu+="@Get-Report ERROR: Nezdařilo se stažení informací o čtenářských kategoriích ze systému KOHA.`n"
                                [bool]$script:r_error=1
                                RETURN $null
                              }
                    }
    }
}

FUNCTION Get-FrontaRezervaci {
    TRY {
        $holds= Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($conf.auth.user):$($conf.auth.password)")) } -URI "$($conf.uri.api)/holds"
        RETURN $holds
    }
    CATCH {
        [bool]$Script:r_error=1
        $Script:Message2Menu+="@Get-FrontaRezervaci ERROR: $($_.Exception.Message)`n"
        RETURN $null
    }
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
#       ÚČTENKY / stvrzenky

FUNCTION Get-StringHash {       # vytvoření hashe účtenky
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
    Clear-Host
    Write-Host "> Tisk účtenek"
    
    if ( $cenik.Count -eq 0 ) { $Script:Message2Menu+="@vytvor-uctenku ERROR: Datový objekt s ceníkem je prázdný! Kontaktujte technomága nebo vytvořte soubor definovaný v conf.files.cenik.`n" }
    else {
        $obj_uctenka=@()
        [bool]$u_complete=0
        [int]$u_suma=0
        $u_ShowError=""

        WHILE ( $u_complete -ne 1 )
        {
            if ( $u_ShowError -ne "" ) { Write-Host "$u_ShowError"; $u_ShowError="" }
            if ( $obj_uctenka.Count -ge 1 ) { generuj-uctenku -operace 1 }
            Write-Host "`n+ Přidat položku:"
            ForEach ( $polozka IN $cenik ) { Write-Host "  $($polozka.id): $($polozka.nazev)" }
            Write-Host "`n  P: Tisknout účtenku`t`t`tE: Opustit a zrušit aktuální účtenku"
            $volba = Read-Host -Prompt "`n~ Volba"

            if ( $volba -IN 0..8 -OR $volba -eq "e" -OR $volba -eq "p") {

                $pom = $cenik.Where({$_.id -eq $volba})

                if ( $volba -eq "e" ) { [bool]$u_complete=1 ; [bool]$no_do=1 } elseif ( $volba -eq "p" ) { [bool]$u_complete=1 }
                elseif ( $volba -eq 0 ) { # Registrační poplatky
                    [Array]$ctenar = Get-Ctenar -metoda bcode
                    if ( $ctenar.count -eq 1 -AND $c_error -ne 1 ) {
                        [string]$c_typ      = $ctenar.category_id
                        [string]$c_bcode    = $ctenar.cardnumber
                    } else { $u_ShowError = "@vytvor-uctenku ERROR: Problém s identifikací čtenáře.`n Doplňující informace: $ErrorMessage"; $c_error = 1 }
                    
                    $kategorie = Get-Report -report ctenKat
                    $pom2 = $kategorie.Where({$_.kategorie -eq $c_typ})

                    if ( $c_error -ne 1 ) { 
                        Write-Host "`ni: Zjištěná kategorie a poplatek pro čtenáře: $($pom2.popis) -> $($pom2.poplatek) Kč"
                        $cvolba = Read-Host -Prompt "~ Ponechat nebo změnit čtenářskou kategorii? [ ZMĚNIT = n,z,0 / PONECHAT = cokoliv, Enter ]"
                        
                        DO {
                            if ( $rerun_ctyp -eq 1 ) { Write-Host "@vytvor-uctenku INFO: Chybné zadání! Opakujte volbu, např. `"DU`" pro kategorii `"Senior`""; $cvolba = "n"; pause }
                            $rerun_ctyp = 1
                            if ( $cvolba -IN ("n", "z", "0")) {
                                Write-Host "`n  Cena`tKat`tPopis`n  ====`t===`t====="
                                ForEach ( $ctyp IN $kategorie ) { Write-Host "  $($ctyp.poplatek)`t$($ctyp.kategorie)`t$($ctyp.popis)" }
                                $v_c_typ = Read-Host -Prompt "~ Volba (Kat)"
                                $pom2 = $kategorie.Where({$_.kategorie -eq $v_c_typ})
                            }
                        } WHILE ( $pom2.Count -ne 1 )

                        $obj_uctenka+=[PSCustomObject]@{ audit="$($pom.audit)"; DMC_text="$($pom.DMC_text) $c_typ ($c_bcode)"; text="Čtenářský poplatek: $($pom2.popis) ($c_bcode)"; cena=$($pom2.poplatek)}
                    }

                    Clear-Variable -Name c_error, rerun_ctyp 2>&1 | Out-Null
                 }
                elseif ( $volba -le 2 ) { # tisk/kopírování
                    TRY {   [int]$pocet_stran = Read-Host -Prompt "`n++ $($pom.nazev)`n~ Zadejte počet stran"
                            $obj_uctenka+=[PSCustomObject]@{ audit="$($pom.audit)"; text="$($pom.nazev) ($($pocet_stran)x)"; cena=$($pom.cena*$pocet_stran)} 
                        }
                    CATCH { $u_ShowError="@vytvor-uctenku ERROR: Byla zadána neplatná hodnota! Zadávejte pouze číslice." }
                }
                elseif ( $volba -le 4 ) { # Poškození majetku
                    Write-Host "`n++ $($pom.nazev)`n!! V případě poškození majetku KJM je minimální cena 50 Kč."
                    WHILE (( $volba -eq 3 -AND $uc_cena -lt 50) -OR ( $volba -eq 4 -AND $uc_cena -lt 1 ))
                        {   [int]$uc_cena = Read-Host -Prompt "`n~ Škoda na majetku (Kč)"   }
                    $obj_uctenka+=[PSCustomObject]@{ audit="$($pom.audit)"; DMC_text="$($pom.DMC_text)"; text="$($pom.nazev)"; cena=$uc_cena }
                    Clear-Variable -Name uc_cena 2>&1 | Out-Null
                }
                elseif ( $volba -le 6 ) { $obj_uctenka+=[PSCustomObject]@{ audit="$($pom.audit)"; DMC_text="$($pom.DMC_text)"; text="$($pom.nazev)"; cena=$($pom.cena)} } #MVS a rešerše
                elseif ( $volba -eq 7 ) { # Naprostá volnost pro knihovníka, neauditováno
                    $uc_nazev = Read-Host -Prompt "`n~ Zadejte vlastní název položky"
                    [int]$uc_cena = Read-Host -Prompt "~ Cena (Kč)"
                    $obj_uctenka+=[PSCustomObject]@{ audit="0"; text="$uc_nazev"; cena=$uc_cena }
                }
            }
            else { Clear-Host; $u_ShowError="@vytvor-uctenku ERROR: Neplatná volba ($volba), opakujte zadání." }
            Clear-Host
        }
        if ( $no_do -ne 1 -AND $obj_uctenka.Count -ge 1 ) { generuj-uctenku -operace 0 }
        elseif ( $no_do -eq 1 ) { $Script:Message2Menu+="@vytvor-uctenku INFO: Účtenka zneplatněna.`n" } #Klamstvo! Ke zneplatnění ve skutečnosti dojde až při opětovném vstupu do této funkce.
    }
}

FUNCTION generuj-uctenku ($operace) {
    $vygenerovano=Get-Date -Format "dd/MM/yyyy HH:mm"
    [bool]$aud=$false   # Přítomnost auditovaných položek
    [int]$suma=0
    [int]$vyska=250     # Výchozí vertikální poloha textu
    $a="^CFA,20 ^FO20,$vyska ^FDKontakt:$($conf.contacts.phone); $($conf.contacts.email)^FS ^CF0,28" ; $vyska += 10 #ošklivý fígl
    
    $hash= Get-StringHash "$obj_uctenka $vygenerovano"

    ForEach ($polozka IN $obj_uctenka.Where({$_.audit -eq 1})) { $aud=$true }

    ForEach ($polozka IN $obj_uctenka) {
        $suma += $polozka.cena
        $vyska += 40

        $a="$a ^FO30,$vyska^FD$($polozka.text)^FS ^FO500,$vyska^FD$($polozka.cena)^FS"
        $a1CSV="$a1CSV$hash;$vygenerovano;$($polozka.text);$($polozka.cena)`n"
        $b="$b  $($polozka.cena)`t$($polozka.text)`n"
    }
    $super_suma = $suma
    
    $vyska += 60
    [int]$row1 = 60 + $vyska
    [int]$row2 = 30 + $row1
    [int]$delka= 30 + $row2

    $a="^XA ^CI28 ^LL$delka ^FO20,80$($conf.ZPL_logo) $a ^CF0,30 ^FO,$vyska ^FB600,,,C, ^FDCelkem: $suma CZK^FS ^CFA,20 ^FO20,$row1 ^FDVystaveno: $vygenerovano^FS ^FO20,$row2 ^FDID: $hash^FS ^XZ"

# # # # # # # # # # # AUDITOVANÁ SEKCE # # # # # # # # # # # 
    if ( $aud -eq $true ) {
        [int]$suma=0
        [int]$vyska=160
        $a2DMC="$vygenerovano;$hash;"
        $a_aud="^CFA,40 ^FO,80 ^FB600,,,C, ^FDSTRVZENKA PRO KNIHOVNU^FS ^CF0,25 ^FO110,130 ^FDPobočka KJM: Staré Brno, Křížova 24^FS ^FO15,$vyska ^GB570,1,1^FS ^CF0,28"; $vyska -= 20

        ForEach ($polozka IN $obj_uctenka.Where({$_.audit -eq 1})) { #auditované položky -> utržek pro knihovnu
            $suma += $polozka.cena
            $vyska += 40

            $a_aud="$a_aud ^FO30,$vyska ^FD$($polozka.text)^FS ^FO500,$vyska ^FD$($polozka.cena)^FS"
            $a2DMC="$a2DMC$($polozka.DMC_text),$($polozka.cena);"
            $a2CSV="$a2CSV$hash;$vygenerovano;$($polozka.text);$($polozka.cena)`n"
        }

        [int]$row1      = 40 + $vyska
        [int]$row2      = 30 + $row1
        [int]$DMC_poz   = 30 + $row2
        [int]$delka     = 400 + $row2
        [int]$b_line    = $delka - 1

        $a_aud="^XA ^CI28 ^LL$delka $a_aud ^CFA,20 ^FO20,$row1 ^FDVystaveno: $vygenerovano, Suma: $suma CZK^FS ^FO20,$row2 ^FDID: $hash^FS ^BXN,7,200 ^FO70,$DMC_poz ^FD$a2DMC^FS ^FO15,645 ^GB$b_line,1,1^FS ^XZ"
    }

    SWITCH ( $operace ) {
        0   { tisk -tdata "$a $a_aud"
              $a1CSV | Out-File $($conf.files.uctenky) -Append -NoNewline -Encoding UTF8                            # Všechny vytisknuté účtenky se zaznamenají i do souboru
              if ( $aud -eq $true ) { $a2CSV | Out-File $($conf.files.audit) -Append -NoNewline -Encoding UTF8 }    # Extra soubor s auditovanými položkami
            }
        1   { Write-Host "`n  Cena`tPoložka`n  ----`t-------`n$b`n  Celkem k úhradě: $super_suma Kč" }
    }
}

# = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
<#  TECH INFO
1 mm = 8 Zebra dots 
Lepítka: šířka 5 cm = ^PW400

Pokladní rolka (continuous media ^MNxxx ^LL): 7,5 cm = ^PW600
zkošuíme: ^MNV,0

#>

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
#              ** DIAGNOSTIKA A NASTAVENÍ A TROUBLESHOOTING **                 #

FUNCTION Set-Xprinter {
    #ZPL kód pro tovární factory reset a nastavení základních parametrů tisku
    Clear-Host 
    Write-Host ">> KOFIGURACE TISKÁRNY"
    Write-Host "Informace k ZPL: https://www.zebra.com/content/dam/zebra/manuals/printers/common/programming/zpl-zbi2-pm-en.pdf"

    Write-Host "`nPřed potvzením nastavení vypněte tiskárnu, vložte požadované médium a tiskárnu opět zapněte.`nNastavit profil tiskárny:`n  0: Lepící štítky 2x5 cm (čárové kódy, průkazky, MVS)`n  1: Pokladní rolka 7.5 cm (stvrzenky, fronta rezervací)"
        $volba = Read-Host -Prompt "`n~ Volba"
        SWITCH ( $volba )
        {
            0 { $a="~SD10 ~TA000 ~JSN ^XA ^SZ2 ^PW400 ^LL164 ^PON ^PR5,5 ^PMN ^MNA ^LS0 ^MTD ^MMT,N ^MPE ^XZ ^XA^JUS^XZ ~JC"
                $Script:Message2Menu+="@Set-Xprinter INFO: Proběhne kalibrace.`n"
                [bool]$Script:conf.rezim_lepitek = 1
              }
            1 { $a="^XA ^PW600 ^LL800 ^PON ^PMN ^MNN ^MTD ^MMT,N ^MPE ^XZ ^XA^JUS^XZ"; [bool]$Script:conf.rezim_lepitek = 0 }
        }

        if ( $null -ne $a ) {   tisk -tdata $a
                                $Script:Message2Menu+="@Set-Xprinter INFO: Konfigurační řetězec odeslán do tiskárny.`n"
                                [bool]$Script:chyba_konfigurace = 0
                            }
        else {  $Script:Message2Menu+="@Set-Xprinter INFO: Neplatná volba, nebyly provedeny žádné změny.`n"
                [bool]$Script:chyba_konfigurace = 1 }
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

FUNCTION manual-override {
    Clear-Host
    Write-Host ">> MANUAL OVERRIDE`n"
    Write-Host "Tato funkce umožňuje odesílat prostý ZPL kód přímo do tiskárny, buďte opatrní.`n`nInformace k ZPL: https://www.zebra.com/content/dam/zebra/manuals/printers/common/programming/zpl-zbi2-pm-en.pdf`n`nPokud jste se sem dostali omylem, jednoduše stiskněte ENTER, nic se nepokazí ;)"
    $m_data = Read-Host -Prompt "`n~ Data"
    if ( $m_data -ne "" ) { tisk -tdata $m_data }
    else { $Script:Message2Menu+="@manual-override INFO: Nedošlo k zadání dat, nic se nestalo.`n" }
}

FUNCTION probe-KOHA {
    Write-Host "`n!!> DIAGNOSTIKA SPOJENÍ SE SYSTÉMEM KOHA`n ~ Výpis základních údajů..."
    Write-Host "`tVýchozí URI: $($conf.uri.api)`n`tUživatel: $($conf.auth.user)`n`tHeslo: ** Dostupné v konfiguračním souboru ./config.json **"
    Write-Host " ~ Dojde k pokusu o stažení dat pro patron_id = 2 (Michal Denár)"; pause
    Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($conf.auth.user):$($conf.auth.password)")) } -URI "$($conf.uri.api)/patrons/2"
    Write-Host "`n ~ Dojde k pokusu o stažení dat pro cardnumber = 26000138 (Martin Krčál)"; pause
    Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($conf.auth.user):$($conf.auth.password)")) } -URI "$($conf.uri.api)/patrons`?cardnumber=26000138"
    Write-Host "~ Vypíše se ceník"; pause; $cenik
    Write-Host "~ Vypíše se zdrojový objekt ceníku: cen_load"; pause; $cen_load
    Write-Host "`t`t~~ KONEC DIAGNOSTIKY ~~"; pause
}

FUNCTION novy-ctenar {
    Clear-Host
    Write-Host "> Vytvořit/Importovat nového čtenáře"
    TRY { [int]$CardNum = Read-Host -Prompt " ~ Zadejte číslo kartičky" }   <# Od této chvíle mohou být teoreticky dotazovány systémy KJM #>
    CATCH { $Script:Message2Menu+="@Novy-Ctenar ERROR: Chybně zadaná kartička.`n"; break }
    if (0 -eq $CardNum ) { $Script:Message2Menu+="@Novy-Ctenar ERROR: Chybně zadaná kartička.`n"; break }
    
    $NewSurn = Read-Host -Prompt " ~ Zadejte příjmení čtenáře (bez diakritiky)"

    [string]$postParams = '{ "surname": "' + $NewSurn + '", "cardnumber": "' + $CardNum + '", "city": "Brno", "category_id": "KJMPL", "library_id": "11", "address": "Nezadano 0", "incorrect_address": true }'
    $Response = Invoke-RestMethod -Method POST -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($conf.auth.user):$($conf.auth.password)"))} -URI "$($conf.uri.api)/patrons" -Body $postParams
    
    $Response
    if ( $null -ne $Response.patron_id) { Write-Host "@Novy-Ctenar INFO: Čtenářské konto bylo úspěšně založeno. Nyní budete přesměrováni..."; Start-Process "https://krizovatka-staff.koha.cloud/cgi-bin/koha/members/memberentry.pl?op=modify&borrowernumber=$($Response.patron_id)"}
    else { Write-Host "@Novy-Ctenar ERROR: Vytvoření čtenáře se nezdařilo!" -BackgroundColor Red -ForegroundColor White }

    pause
}

FUNCTION files-menu {
    Clear-Host
    Write-Host "> Upravit nebo zobrazit důležité soubory"
    Write-Host "`n== == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == =="
    Write-Host " c: Ceník`te: Error log`tk: Konfigurační soubor`tu: Účtenky`tau: Auditované účtenky"
    Write-Host " q: Návrat do hlavního menu"
    Write-Host "== == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ==`n"
    $volba = Read-Host -Prompt "~ Volba"

    SWITCH ($volba) {
        'c' { $soubor = $conf.files.cenik }
        'e' { $soubor = $f_log }
        'k' { $soubor = "./config.json" }
        'u' { $soubor = $conf.files.uctenky }
        'au'{ $soubor = $conf.files.audit }
        'q' { RETURN $NULL }
    }

    if ($Env:windir) { $editor = "notepad.exe" } else { $editor = "gedit" }
    if ($volba -IN @("c", "e", "k", "u", "au")) { Start-Process -FilePath $editor -ArgumentList $soubor }

    files-menu
}

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
#                            LET'S BEGIN, SHALL WE?                            #
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
$host.UI.RawUI.WindowTitle = "X TERMIX | Release $release"
Write-Menu
