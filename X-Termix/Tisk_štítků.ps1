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
powershell -ExecutionPolicy Bypass -Command "& '%~d0%~p0%~n0.ps1'"
#>

## ## ## ## ## ## ## ## ## ## NASTAVENÍ ## ## ## ## ## ## ## ## ## ##
# KOHA login a URI (Nutný povolit BasicAuth pro REST API v KOHA)
$k_user="--uzivatel--"
$k_pass="--heslo--"
$k_uri="--KOHA STAFF URL--/api/v1"
$pub_report_uri="--KOHA OPAC URL--/cgi-bin/koha/svc/report"
# Další nastavení
$zebra="--tiskárna--"                               # Nastavení výstupu
$t_file=".\temp_print_file.txt"                     # Protože RAW data, UTF8 a Out-Printer se dohromady nebaví :/
[int]$i_max=100                                     # Maximální počet generovaných štítků
$f_audit="./x-KJM_uctenky.csv"                      # Umístění auditu
$f_uctenky="./x-uctenky.csv"                        # Soubor s účtenkami
$f_log="./x-error_log.txt"                          # Log pro zaznamenání errorů; ~ to co se vypíše před menu
$rep_xlokace="?name=x-lokace&annotated=1"           # JSON report systému KOHA vracející potřebné údaje o lokacích #zatím čekám na Štěpána
$rep_xknihy="?name=x-biblio_report&annotated=1"     # JSON report systému KOHA vracející potřebné údaje o knihách
$f_xknihy="./x-biblio_report-reportresults.csv"     # NÁHRADNÍ ŘEŠENÍ: CSV soubor s potřebnými daty o knihách -- jednou snad bude dostupné API
$f_xcenik="./x-cenik.csv"                           # CSV soubor ceníku (Formát: audit;DMC_text;nazev;cena;komentar | int;ASCII;UTF-8;int;UTF-8)
$f_dalsi_ckod_p="./x-dalsi_ckod_p.txt"              # Pamatuje si číslo další průkazky v číselné řadě (již vytisknutých). --> vytvor-barcode -b_typ p
[bool]$Script:rezim_lepitek = 0                     # Vztahuje se k varování na tisk lepítek (ve výchozím vztahu se očekává tisk na pokladní rolku)
# Logo knihobny pro Zebru - kovertováno pomocí http://labelary.com/viewer.html
$logo="^GFA,10500,10500,70,T03gV030600C3gN03hN0181,T03gV030601C3gN038hN0C3,38007M0E03gQ0701C018C0383T07K038L038gQ01FF8S0C6,3800EM0E03gQ0701C00D80303T078J03CL038gQ01IFS06C,3801CM0E03gQ0701C00F80703T078J07CL038gQ01IF8R07C,38038O03gQ07K0700E03T07CJ07CL038gQ01803CR038,38078O03gQ07N0C03T07CJ07CL038gQ01801C,380FP03gQ07P03T07EJ0FCL038gQ01801C,381EP03gQ07P03T07EJ0DCL038gQ01801C,381CP03gQ07L06I03T077I01DCL038gQ01800CR07C,38380020FC0040307CI03F8018003060F8I0FEL07008031E040307CI03F8K077I019C007F00387EI03F00183EI03F8J0CI0CI01801C030F0C1F8001FF,387I073FE00E031FFI0FFE038003063FE003FFL0701C033E0E031FFI0FFEK073I039C03FF8039FFI0FFC018FF800FFCJ0E001CI01801C033F0E7FC003C38,38EI0770F00E0338F801F0F81C0070671F007878K0701C03700E0338F801F0FK07380031C03C3C03B87801E1E019C7C01E1EJ06001CI018018033B0EE1E00701C,39CI07C0780E03E03C03C0381C00707C0700601CK0701C03600E036038038038J07180071C0300E03E03C0380701F01E01807J070018I01803803600F80F00E00E,3B8I0780380E03C01C07001C0C006078038I01CK0701C03C00E03C01C07001CJ071C0071CJ0E03C01C0700301E00EJ07J070038I0180F003C00F00700C006,3FJ0780180E03801C07I0E0E00E070038J0CK0701C03800E03801C06I0CJ071C00E1CJ0603C00C0700381C00EJ03J030038I01FFC003800F00301C007,3FJ07001C0E03800C0EI0E0E00C070018J0EK0701C03800E03801C0EI0EJ070E00E1CJ0603800E0600381C006J038I03803J01IF003800E00381C007,3B8I07001C0E03800C0EI060701C070018J0EK0701C03I0E03I0C0EI0EJ070E00C1CJ0703800E0E00181C007J038I03807J01C1F803800E003818003,3BCI07001C0E03800E0CI060701C060018I03EK0701C03I0E03I0C0CI06J070701C1CI01F03800E0E00181C007J0F8I01C06J01801C03I0E00381JF,39EI07001C0E03I0E0CI070301806001800FFEK0701C03I0E03I0C1CI06J07070181C007FF03800E0JFC18007003FF8I01C0EJ01800E03I0E00381JF,38FI07001C0E03I0E0CI070383806001803FFEK0701C03I0E03I0C1CI06J07038381C01IF03800E0JFC1800700IF8J0C0EJ01800E03I0E003818,3878007001C0E03I0E0CI07038300600180F80EK0701C03I0E03I0C1CI06J07038301C07C0703800E0EJ01800703E038J0E0CJ01800703I0E003818,3838007001C0E03I0E0CI07018300600181E00EK0701C03I0E03I0C1CI06J07018701C0F00703800E0EJ018007038038J0E1CJ01800703I0E003818,381C007001C0E03I0E0CI0601C700600181C00EK0701C03I0E03I0C0CI06J0701C601C0E00703800E0EJ018007070038J0618J01800703I0E00381C,380E007001C0E03I0E0EI0E01C600600181800EK0701C03I0E03I0C0EI0EJ0700CE01C0C00703800E0EJ018007070038J0718J01800703I0E00381C,380F007001C0E03I0E0EI0E00CE00600181801EK0701C03I0E03I0C0EI0EJ0700EE01C0C00F03800E0EJ018007060038J0338J01800603I0E00380C007,3807807001C0E03I0E07I0C00EC00600181801EK0E01C03I0E03I0C07001CJ07007C01C0C00F03800E07J018007060078J033K01800E03I0E00380E007,3803C07001C0E03I0E07801C006C00600181C03EK0E01C03I0E03I0C07001CJ07007C01C0E01F03800E078I0180070700F8J03BK01801E03I0E00380700E,3801E07001C0E03I0E03C038007C00600181C06EJ01C01C03I0E03I0C03C078J07007801C0E03703800E03C030180070781B8J01EK01807C03I0E003803C3C,3800F07001C0E03I0E01F9FI07800600180F9EEI03FC01C03I0E03I0C01F9FK07003801C07DE703800E01F9F01800703E7B8J01EK01IF803I0E003801FF8,3800787001C0E03I0E00FFEI038006001807F8EI03F801CK0E03I0C00FFEK07003001C03FC703800E00FFE01800701FE38J01EK01FFE003I0E0038007E,gG01FT01EK03CX01FV0FP01FO078,,::::::::::::::::::::::::gR018408O042K018S06,gS08818O066K018S0C,gS0D83P02CK018S08gK018,gS0702P038K018R018gK018,gU06W018R03,gU0CW018R02,hS018,:gO078011C001FI0F800FEK018I01FM03EK07CI0700F8001FI03CN03EI0F801F,gM013FE0130607F833FC018106003180C07FE0C0041FFJ01FF80CF03FCC07F80CFF0187FFC0FF003FE07F8,gM01603014060C00360603008300218180C070400C1818I0301C0D00602C0C0C0D838180018181806I0C0C,gM01C01818060C0038030200C3006183018010600CI08I0600C0E00C01CI060F018180018I0C0C001806,gM0180181806080038018600410061860300186008I0CI0C0060E00801CI060E00818003J0C18001002,gM01800810060C00300186006180418C03I082018I0CI0C0020C01800CI060C00C18006J0418003003,gM01I0C10060C00300184006180C19802I0C301J0CI080030C01I0CI020C00C1800CJ041I03003,gM01I0C100606003I087FFE08081B002I0C303I03CI080030C01I0C001E0C00C1800CI03C3I02003,gM01I0C100603803I086J0C181E002I0C183007FCI080030C01I0C03FE0C00C18018007FC3I03IF,gM01I0C100601E03I084J04181E006I0C18201E0C00180030C03I0C0F020C00C1803001E043I03,gM01I0C100600703I084J06101B002I0C0860300CI080030C01I0C18020C00C18060030043I02,gM01I0810060018300186J063019802I0C0C40600CI080030C01I0C10060C00C18060020043I02,gM01I081006I0C300186J022018C03I080C40600CI0C0020C01I0C30060C00C180C00600C1I03,gM0180181006I0C300102004036018603001804C0600CI0C0060C01801C30060C00C181800600C18003,gM0180101006I0C38030300C03601830180180680601CI060060C01801C300E0C00C183I0601C180018,gM0140301006I083C060181801C018181C0300380603CI0700C0C00C02C181A0C00C183I030140C001C02,gM0130E010060C38360C00FF001C0180C0E0E00380386CI038380C0070EC1C320C00C187I0386407060E0E,gM011F8J020FE033F8003CI080180603FC003001F8CJ0FF00C003F8C0FE20C00C18IFC1FC403FC03F8,gM01R03hI0C,gM01R03hI08,:gM01R03hH018,gM01R03hH03,gM01R03hH07,gM01R03h0E1E,gM01R03h03F8,,:::::::::::::::::gK0818gT0EgW060401C303,R0CR0C3007gR0CgW030C038183,R0CR063007S03FEU01CK07FEgI07I0E03180300C6gG01FEK06,R0CR076007S0IFU038K0IF8gH07001C01B80600CEgG07FFK0E,R0CR03C007R01E07U03L0IFEgH07003C00F00E006Cg01F078I01E,R0CR01C007R038J0CR06L0E01EgH07007800E00C0038g01C01CI01E,R0CV07R07K0CR0CL0E007gH0700FK0180038g01001CI03E,R0CV07R07K0CY0E007gH0701EgU0EI036,R0CV07R07K0CY0E007gH0701CgU0EI076,R0CR07E007R07K0CY0E007gH07038J0CgP0EI0E6,01F8I03FI0C1F8I03FI01FF807K07EK07J01EI0FCI01E00FCK0E007I03800FCI03FN0707I063CO0FO01F8N0EI0C6,E7FE001FFC00C7FE001FFC003C3C0700F01FF8J07J0IF03FF0073E03FFK0E00701CFC73FFI0FFEM070EI067C1C1IFE03F8007I0E07FEN0E001C6,EF1F003E3F00CF1F003E3E00701E0701E03C3CJ078I0IF07C78077E07C78J0E00601DFC778F003E1FM071CI06601C1IFC07FC007I0E0F8FN0C00386,FC0780780700FC0780700700700E0703C0301EJ03CJ0C00601C07C00E01CJ0E00E01D8076038078078L0738I06C01CI01C0FFE003001C0C038L01C00306,F80380E00380F00380E00380E00707078J0EJ01FJ0CJ01C07801C01CJ0E03C01F007C03807003CL0778I07801CI0380FFE003801CI038L01C00706,F001C0E001C0F001C0C00180C004070FK06K0FCI0CK0C07801C00EJ0IF001E007801C0E001CL07FJ07801CI0701FFE0838018I018L03800E06,E001C1C001C0E001C1C001C0CJ070EK06K03EI0CK0E07003800EJ0IF801E007801C0EI0CL07EJ07001CI0E01CFC081C038I01CL07001C06,EI0C1CI0C0EI0C1C001C1CJ071CK07K01F800CK0E070038006J0F1FE01C007001C1CI0EL077J07001CI0E01C30081C038I01CL0E001806,EI0E18I0C0EI0C18I0C1CJ0738K0FL07C00CJ01E070038006J0E00F01C007001C1CI0EL0778I06001C001C038I0C0C03J03CK03C003806,EI0E18I0E0EI0E38I0C1CJ077J07FFL01E00CI0FFE07003IFEJ0E00381C007001C1CI0EL073CI06001C0038038I040E07001FFCK078007006,EI0E18I0E0CI0E38I0C1CJ07EI01IFM0F00C003FFE07003IFEJ0E00381C007001C1CI0EL071EI06001C0070038I040E06007FFCK0EI0E006,EI0E18I0E0CI0C38I0C1CJ07FI07E07M0780C00FC0E070038M0E001C1C007001C1CI0EL070FI06001C0070038I04060E01F81CJ03C001C007,EI0E18I0E0CI0C38I0C1CJ077800F007M0380C00E00E07003N0E001C1C007001C1CI0EL0707I06001C00E0038I0C070E01C01CJ078001!EI0C18I0C0EI0C18I0C1CJ073C00E007M0380C01C00E070038M0E001C1C007001C1CI0EL07038006001C01C0038I0C070C03801CJ0FI01!E001C1C001C0E001C1C001C0CJ071E00C007M0380C01800E070038M0E001C1C007001C1CI0EL0701C006001C0180018I0C031C03001CJ0EM07,E001C1C001C0E001C1C001C0E007070F00C00FM0380C01800E070038M0E00381C007001C0EI0CL0700E006001C038001C001C039803003CI01CM06,F00180E00180F00381E003806006070700C00FM0380C01801E07001CM0E00381C007001C0E001CL0700F006001C07I01C0018019803003CI018M06,F00380E00380F00380E00380700E070380E01FM0700E01C03E07001CM0E00701C007001C0700380EJ07007806001C0EJ0E003801B803807CI038M06,F80700780700F807007007003C3C0701C0E037J0600F00E01C06E07I0E00CJ0E01F01C007001C0780780EJ07003C06001C0EJ07007001F00380DCI038M06,EF3E003E3E00CF3E003E3E001FF80700E078F7J07FFE00FB0F1EE07I07C7CJ0IFE01C007001C03F1F00CJ07001E06001C1IFE07E3EI0F001E3DCI03IFEJ06,E7FC001FFC00C7FC001FFCI07E00700703FC7J07FF8007F07FCE07I03FF8J0IF801C007001C00FFC00CJ07I0FJ01C3IFE01FFCI0EI0FF9CI03IFEJ06,E1FJ03EJ01FJ03ET0FM0FEI01E01FN0FCgG03F001CgH07EN03E,EjM018,:EjM038,EjM03,:E,:::^FS"
# Import ceníku - při úpravách je nutné náležitě upravit funkci vytvor-uctenku (ten velkej ošklivej if skoro dole)
if ( Test-Path $f_xcenik ) {
    $cen_load = Import-Csv -Path $f_xcenik -Delimiter ";"
    [int]$ce_i=0; $cenik=@()
    ForEach ( $ce_polozka IN $cen_load ) {
        [int]$ce_audit = $ce_polozka.audit          # Audit: 0=Netiskne se audit štítek pro KJM, 1=audit štítek se tiskne+záznam do auditlogu.
        $DMC_text = $ce_polozka.DMC_text
        $ce_nazev = $ce_polozka.nazev
        [int]$ce_cena = $ce_polozka.cena
    
        $cenik+=[PSCustomObject]@{ id=$ce_i; audit=$ce_audit; DMC_text=$DMC_text; nazev=$ce_nazev; cena=$ce_cena }
        $ce_i++ 
    }
} else { $Message2Menu = "@init ERROR: Ceníkový soubor ($f_xcenik) nebyl nalezen, nebude možné tisknout účtenky. Soubor vytvořte včetně odpovídajícího obsahu nebo kontaktujte knihovního technomága.`n" }
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

FUNCTION Write-Menu {
    Write-Host "`t`t`t`t`t`t>>> X TERMIX <<<`n"
    if ( $Message2Menu -ne $null ) {
        Write-Host "$Message2Menu"
        "[$(Get-Date -Format "yyyy/MM/dd HH:mm:ss")]`n$Script:Message2Menu" | Out-File $f_log -Append -Encoding UTF8 
        $Script:Message2Menu = $null 
    }

    if ( $rezim_lepitek -eq 1 ) { Write-Host "@init INFO: Předpokládá se tisk lepítek.`n" }

    Write-Host "> MENU"
    Write-Host "  0: Fronta rezervací"
    Write-Host "  1: Účtenky"
    Write-Host "  2: Dávkový tisk čárových kódů na průkazky"
    Write-Host "  3: Dávkový tisk čárových kódů na knihy"
    Write-Host "  4: Tisk MVS štítků"
    Write-Host "  5: Tisk čtenářské průkazky"
    Write-Host "`n  d: Diagnostika spojení`t`tx: Nastavení tiskárny`n  q: Ukončit skript`t`t`tm: Manual override"

    $volba = Read-Host -Prompt "`n~ Volba"
        SWITCH ( $volba )
        {
            0 { fronta-rezervaci }
            1 { vytvor-uctenku }
            2 { vytvor-barcode -b_typ p }
            3 { vytvor-barcode -b_typ k }
            4 { tisk-MVS }
            5 { tisk-ctenare }
            d { probe-KOHA }
            q { pac-a-pusu }
            x { Set-Xprinter }
            m { manual-override }
            Default { $Script:Message2Menu+="@func Write-Menu INFO: Neplatná volba, opakujte zadání.`n" }
        }
    Clear-Host; Write-Menu # Zachycení neplatné volby a taky doběhlé funkce...nechť rekurze vládne světu
}

FUNCTION tisk ($tdata) {        #add testpath nebo trycatch na tiskarnu
    if ( $tdata -ne $null ) {
        Write-Host "`n@func tisk INFO: Tisková data se zpracovávají a odesílají do tiskárny..."
        #$Script:Message2Menu+= $tdata       # Pro kontrolu, vypíše tisková na místo informačních hlášek v menu.
        #Out-Printer -InputObject $tdata -Name "Zebra"    # tohle bohužel s UTF8 nefunguje :/ 
        $tdata | Out-File $t_file -Encoding UTF8
        #Start-Sleep -s 0.52
        cmd /C 'COPY /B .\temp_print_file.txt \\localhost\Zebra'  # Hello darkness, my old friend...I've come to talk with you again.
        Clear-Variable -Name tdata
    }
    else { $Script:Message2Menu+="@func tisk ERROR: Žádná data k tisku.`n"}
}

FUNCTION pac-a-pusu {
    Write-Host "Pac a pusu :*"
    Start-Sleep -s 0.52
    exit
}

FUNCTION varovani-tiskarny {
    if ( $rezim_lepitek -ne 1 ) {
        Write-Host "`n`t`t`t!! Funkce s tiskem lepících štítků !!`nPokud jste tiskárnu nanastavili pro tisk lepítek (výměna média nestačí), proveďte prosím nastavení tiskárny nyní. `n`n~ Přejít do nastavení tiskárny?`n  0: Ano`n  1: Ne`n  2: Ne a tuhle hlášku už nechci vidět"
        DO { $sub_volba = Read-Host -Prompt "~ Volba" } WHILE ( $sub_volba -lt 0 -OR $sub_volba -gt 2 )
        if ( $sub_volba -eq 0 ) { Set-Xprinter }
        elseif ( $sub_volba -eq 2 ) { [bool]$Script:rezim_lepitek = 1 }
    }
}

FUNCTION tisk-MVS ([bool]$rerun) {
    varovani-tiskarny; if ( $chyba_konfigurace -ne 1 ) {

    if ( $rerun -ne 1 ) { Write-Host "`n> Tisk MVS štítků" }

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
                $Script:Message2Menu+="`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n@func Get-Ctenar $ErrorMessage`n"
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
                    $Script:Message2Menu+="`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n@func Get-Ctenar $ErrorMessage`n"
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
                $Script:Message2Menu+="`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n@func Get-Ctenar $ErrorMessage`n"
                $Script:ErrorMessage = "Chyba komunikace se serverem."
            }
        }
    }
}

FUNCTION vytvor-barcode ( $b_typ, [long]$bdata ) { #k = knihy; p = průkazky
    varovani-tiskarny; if ( $chyba_konfigurace -ne 1 ) {

    if ( $bdata -ne 0 ) { [long]$kod = $bdata; Write-Host "~ Začátek generovaného rozsahu je $kod" }
    else { 
        SWITCH ( $b_typ )
        {
            k { Write-Host "`n> DÁVKOVÝ tisk čárových kódů na knihy" }
            p { Write-Host "`n> DÁVKOVÝ tisk čárových kódů na průkazky" }
        }

        TRY { 
            if ( $b_typ -eq "p" -AND ( Test-Path $f_dalsi_ckod_p ) ) {
                [int]$dalsi_p_kod = Get-Content $f_dalsi_ckod_p 
                Write-Host "~ Stikněte ENTER pro pokračování v číselné řadě průkazek. (nezadávejte žádné hodnoty)`n~ Další tisknuté číslo průkazky bude $dalsi_p_kod."
            }

            [long]$kod = Read-Host -Prompt "~ Začátek generovaného rozsahu"; $e_mess = 1
            if ( $b_typ -eq "p" -AND $kod -eq "" ) { $kod = $dalsi_p_kod }
        }
        CATCH {
            [bool]$b_error = 1
            $ErrorMessage = $_.Exception.Message
            $Script:Message2Menu+="`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n@func vytvor-barcode $ErrorMessage"
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
        } while ( $i -lt $kolik -AND $i -lt $i_max ) 
        if ( $i -ge $i_max ) { $Script:Message2Menu+="@func vytvor-barcode INFO: Překročen maximální počet tisknutelných štítků (nyní $i_max štítků v dávce).`n" }
        tisk -tdata $a
        if ( $b_typ -eq "p" ) { $kod | Out-File $f_dalsi_ckod_p -NoNewline -Encoding UTF8 }
    }
    elseif ( $e_mess -eq 1 ) { $Script:Message2Menu+="@func vytvor-barcode ERROR: Chybně zadané hodnoty pro čárový kód anebo množství.`n" }

    Clear-Variable -Name bdata, b_error, i, kolik, kod 2>&1 | Out-Null
}}

FUNCTION tisk-ctenare {
    varovani-tiskarny; if ( $chyba_konfigurace -ne 1 ) {

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

    if ( $c_error -eq 1 -OR ( $cdata.count -ne 1 -OR $prukazka -eq "" ) ) { $Script:Message2Menu+="@func tisk-ctenare ERROR: $ErrorMessage`n" }
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
    else { $Script:Message2Menu+="`n@func tisk-ctenare ERROR: Nedefinovaná chyba...dejte vědět jak se to stalo. :) " } #Tohle asi nikdy nenastane, ale kdyby náhodou...

    if ( $a -ne $null ) { tisk -tdata $a }

    Clear-Variable -Name prukazka, c_error, ErrorMessage, cdata, a 2>&1 | Out-Null
}}

FUNCTION fronta-rezervaci {         # UPDATE-ME
# porovnání dat: https://stackoverflow.com/questions/5097125/powershell-comparing-dates --pro vyřazení již vytisknutých rezervací
    Write-Host "`n> Fronta rezervací"

    if ( $script:obj_rezervace -ne $null ) {
        Write-Host "@func fronta-rezervaci INFO: Fronta již byla jednou vygenerována. Co teď? `n  0: Zobrazit s možností tisku  `n  1: Jen vytisknout`n  2: Vygenerovat znovu"
        $volba = Read-Host -Prompt "`n~ Volba"

        SWITCH ( $volba )
        {
            0 { generuj-frontu-rezervaci -operace 0 ; [bool]$no_do=1 }
            1 { generuj-frontu-rezervaci -operace 1 ; [bool]$no_do=1 }
            2 { $script:obj_rezervace=@() ; [bool]$script:f_fr_loaded = 0; Get-FrontaRezervaci }
            Default { [bool]$no_do=1 ; $Script:Message2Menu+="@func fronta-rezervaci ERROR: Neplatná volba operace (zobrazení/tisk/regenerace).`n" }
        }
    }
    else { $script:obj_rezervace=@() ; Get-FrontaRezervaci }

    if ( $f_fr_loaded -eq 1 -OR $r_error -eq 1 ) {} #tohle je ošklivé, ale vlastně správně...trust me #r/wcgw
    elseif ( $hdata.count -ne 0 -AND $r_error -ne 1 ) {
        Write-Host "@func fronta-rezervaci INFO: Získávají se data..."
        Get-Report -report "biblio"
        if ( $r_error -ne 1) { [bool]$script:f_fr_loaded = 1 }
    }

    if ( $r_error -ne 1 -AND $no_do -ne 1 ) {
        [int]$r_pocet = $hdata.count
        [int]$i=1

        Write-Host "@func fronta-rezervaci INFO: Zpracovávají se data ($r_pocet rez.), čekejte prosím..."

        ForEach ($rezervace IN $hdata) {
            $r_biblioID = $rezervace.biblio_id
            $r_patronID = $rezervace.patron_id

            Get-Ctenar -metoda ID
            $pom = $tab_xbiblio.Where({$_.biblionumber -eq ( $rezervace.biblio_id )}) | Select author, title, itemcallnumber, barcode, permanent_location, lokace
            if ( $pom.lokace -eq "" -OR $pom.lokace -eq $null ) { $pom.lokace = "Asi výměnný fond | 80" }

            $script:obj_rezervace+=[PSCustomObject]@{
                or_ID               = $i;
                or_Datum_Pozadavku  = $rezervace.hold_date;
                or_Autor            = $pom.author;
                or_Nazev_Knihy      = $pom.title;
                or_Signatura        = $pom.itemcallnumber;
                or_Lokace           = $pom.lokace;
                or_Ctenar           = "$($cdata.firstname) $($cdata.surname)";
                or_Barcode          = $pom.barcode
            }
            
            if ( $warn_me -eq 1 ) { $Script:Message2Menu+="s ID rezervace $i.`n"; $warn_me=0 }

            [int]$r_progress = $(100*$i/$r_pocet)
            Write-Progress -Activity "Parsují se data" -Status "$r_progress% Hotovo" -PercentComplete $r_progress
            $i++
        }
        Write-Progress -Activity "Parsují se data" -Completed
        $script:vygenerovano=Get-Date -Format "dd/MM/yyyy HH:mm"
    }
    elseif ( $no_do -eq 1 ) {}
    else { $Script:Message2Menu+="@func fronta-rezervaci ERROR: $ErrorMessage`n" }

    if ( $script:obj_rezervace.Count -ne 0 -AND $no_do -ne 1 ) { generuj-frontu-rezervaci -operace 0 }
    elseif ( $no_do -eq 1 ) {}
    else { $Script:Message2Menu+="@func fronta-rezervaci INFO: Žádné dostupné rezervace.`n" }
}

FUNCTION generuj-frontu-rezervaci ($operace) {  # 0 = Zobrazí a nabídne tisk; 1/* Pošle rovnou na tiskárnu
    Write-Host "`n`t~~ VÝPIS FRONTY REZERVACÍ ~~"
    $vygenerovano=Get-Date -Format "dd/MM/yyyy HH:mm"
    [int]$line = 170 # vertikální pozice čáry v hlavičce
    $a="^CF0,60 ^FO60,80^FDFRONTA REZERVACÍ^FS ^CF0,30 ^FO65,140^FDVygenerováno:^FS ^FO58,$line^GB490,2,2^FS" #hlavička...teda, aspoň její část. Zbytek je dole.

    ForEach ($rezervace IN $obj_rezervace) {
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

    $a="^XA ^CI28 ^LL$line ^CFA,30 ^FO255,140^FD$vygenerovano^FS $a ^XZ"

    if ( $operace -eq 0 ) { 
        Write-Host $b
        $volba = Read-Host -Prompt "`n~ Vytisknout frontu rezervací? [ ANO = a,y,1 / NE = cokoliv jiného ]"
        if ($volba -eq "a" -OR $volba -eq "y" -OR $volba -eq "1") { tisk -tdata $a }
    }
    else { tisk -tdata $a }
}

FUNCTION Get-Report ($report) { #určeno pro nezabezpečené reporty (knihy, čtenářské kategorie)
    SWITCH ($report) {
        "biblio"    {   TRY { $script:tab_xbiblio = Invoke-RestMethod -Method GET -URI "$k_pubreport_uri`?name=x-biblio_report&annotated=1" } 
                        CATCH { Write-Host "@func Get-Report INFO: Spojení se serverem se nezdařilo. Dojde k pokusu o zpracování lokálního souboru..."
                                $Script:Message2Menu+="@func Get-Report INFO: Nezdařilo se stažení informací o knihách ze systému KOHA.`n"
                                if ( Test-Path $f_xknihy ) { $script:tab_xbiblio = Import-Csv -Path $f_xknihy -Delimiter ";" 
                                                             $Script:Message2Menu+="@func Get-Report INFO: Byl použit záložní soubor $f_xknihy! Kontaktujte technomága.`n" 
                                                           }
                                else {  $Script:Message2Menu+="@func Get-Report ERROR: Záložní soubor $f_xknihy nebyl nalezen! Kontaktujte technomága.`n"
                                        $script:ErrorMessage="Nebylo možné získat data o knihách."
                                        [bool]$script:r_error=1
                                     }
                              }
                    }
        "ctenKat"   {   TRY { $script:tab_ctypy = Invoke-RestMethod -Method GET -URI "$k_pubreport_uri`?name=x-kategorie_ctenaru&annotated=1" }     #kategorie čtenářů
                        CATCH { Write-Host "@func Get-Report INFO: Spojení se serverem se nezdařilo. Dojde k pokusu o zpracování lokálního souboru..."
                                $Script:Message2Menu+="@func Get-Report INFO: Nezdařilo se stažení informací o čtenářských kategoriích ze systému KOHA.`n"
                              }
                    }
    }
}

FUNCTION Get-FrontaRezervaci {
    TRY {
        $ErrorMessage="Chyba spojení se serverem!"
        $Script:hdata= Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI "$k_uri/holds"
    }
    CATCH {
        [bool]$Script:r_error=1
        $Script:ErrorMessage = $_.Exception.Message
        Write-Host "`t`t`t!! DOŠLO K VÝZNAMNÉ CHYBĚ !!`n@func Get-FrontaRezervaci $ErrorMessage`n"
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
    Clear-Host
    Write-Host "> Tisk účtenek"
    
    if ( $cenik.Count -eq 0 ) { $Script:Message2Menu+="@func vytvor-uctenku ERROR: Datový objekt s ceníkem je prázdný! Kontaktujte technomága nebo vytvořte soubor $f_xcenik.`n" }
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
                    Get-Ctenar -metoda bcode
                    if ( $cdata.count -eq 1 -AND $c_error -ne 1 ) {
                        [string]$c_jmeno    = $cdata.firstname
                        [string]$c_prijmeni = $cdata.surname
                        [string]$c_typ      = $cdata.category_id
                        [int]$c_bcode       = $cdata.cardnumber
                    } else { $u_ShowError = "@func vytvor-uctenku ERROR: Problém s identifikací čtenáře.`n Doplňující informace: $ErrorMessage"; $c_error = 1 }
                    
                    Get-Report -report ctenKat
                    $pom2 = $tab_ctypy.Where({$_.kategorie -eq $c_typ})

                    if ( $c_error -ne 1 ) { 
                        Write-Host "`ni: Zjištěná kategorie a poplatek pro čtenáře: $($pom2.popis) -> $($pom2.poplatek) Kč"
                        $cvolba = Read-Host -Prompt "~ Ponechat nebo změnit čtenářskou kategorii? [ ZMĚNIT = n,z,0 / PONECHAT = cokoliv, Enter ]"
                        
                        DO {
                            if ( $rerun_ctyp -eq 1 ) { Write-Host "@func vytvor-uctenku INFO: Chybné zadání! Opakujte volbu, např. `"DU`" pro kategorii `"Senior`"" }
                            $rerun_ctyp = 1
                            if ( $cvolba -eq "n" -OR $cvolba -eq "z" -OR $cvolba -eq "0") {
                                Write-Host "`n  Cena`tKat`tPopis`n  ====`t===`t====="
                                ForEach ( $ctyp IN $tab_ctypy ) { Write-Host "  $($ctyp.poplatek)`t$($ctyp.kategorie)`t$($ctyp.popis)" }
                                $v_c_typ = Read-Host -Prompt "~ Volba (Kat)"
                                $pom2 = $tab_ctypy.Where({$_.kategorie -eq $v_c_typ})
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
                    CATCH { $u_ShowError="@func vytvor-uctenku ERROR: Byla zadána neplatná hodnota! Zadávejte pouze číslice." }
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
            else { Clear-Host; $u_ShowError="@func vytvor-uctenku ERROR: Neplatná volba ($volba), opakujte zadání." }
            Clear-Host
        }
        if ( $no_do -ne 1 -AND $obj_uctenka.Count -ge 1 ) { generuj-uctenku -operace 0 }
        elseif ( $no_do -eq 1 ) { $Script:Message2Menu+="@func vytvor-uctenku INFO: Účtenka zneplatněna.`n" } #Klamstvo! Ke zneplatnění ve skutečnosti dojde až při opětovném vstupu do této funkce.
    }
}

FUNCTION generuj-uctenku ($operace) {
    $vygenerovano=Get-Date -Format "dd/MM/yyyy HH:mm"
    [bool]$aud=$false   # Přítomnost auditovaných položek
    [int]$suma=0
    [int]$vyska=250     # Výchozí vertikální poloha textu
    $a="^CFA,20 ^FO20,$vyska ^FDKontakt:+420 123456789; mail@email.com^FS ^CF0,28" ; $vyska += 10 #ošklivý fígl
    
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

    $a="^XA ^CI28 ^LL$delka ^FO20,80$logo $a ^CF0,30 ^FO,$vyska ^FB600,,,C, ^FDCelkem: $suma CZK^FS ^CFA,20 ^FO20,$row1 ^FDVystaveno: $vygenerovano^FS ^FO20,$row2 ^FDID: $hash^FS ^XZ"

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
              $a1CSV | Out-File $f_uctenky -Append -NoNewline -Encoding UTF8                            # Všechny vytisknuté účtenky se zaznamenají i do souboru
              if ( $aud -eq $true ) { $a2CSV | Out-File $f_audit -Append -NoNewline -Encoding UTF8 }    # Extra soubor s auditovanými položkami
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
                $Script:Message2Menu+="@func Set-Xprinter INFO: Proběhne kalibrace.`n"
                [bool]$Script:rezim_lepitek = 1
              }
            1 { $a="^XA ^PW600 ^LL800 ^PON ^PMN ^MNN ^MTD ^MMT,N ^MPE ^XZ ^XA^JUS^XZ"; [bool]$Script:rezim_lepitek = 0 }
        }

        if ( $a -ne $null ) {   tisk -tdata $a
                                $Script:Message2Menu+="@func Set-Xprinter INFO: Konfigurační řetězec odeslán do tiskárny.`n"
                                [bool]$Script:chyba_konfigurace = 0
                            }
        else {  $Script:Message2Menu+="@func Set-Xprinter INFO: Neplatná volba, nebyly provedeny žádné změny.`n"
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
    else { $Script:Message2Menu+="@func manual-override INFO: Nedošlo k zadání dat, nic se nestalo.`n" }
}

FUNCTION probe-KOHA {
    Write-Host "`n!!> DIAGNOSTIKA SPOJENÍ SE SYSTÉMEM KOHA`n ~ Výpis základních údajů..."
    Write-Host "`tVýchozí URI: $k_uri`n`tUživatel: $k_user`n`tHeslo: $k_pass"
    Write-Host " ~ Dojde k pokusu o stažení dat pro patron_id = 2 (--jmeno--)"; pause
    Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI $k_uri/patrons/2
    Write-Host "`n ~ Dojde k pokusu o stažení dat pro cardnumber = 26000138 (--jmeno2--)"; pause
    Invoke-RestMethod -Method GET -Headers @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${k_user}:${k_pass}")) } -URI "$k_uri/patrons`?cardnumber=26000138"
    Write-Host "~ Vypíše se ceník"; pause; $cenik
    Write-Host "~ Vypíše se zdrojový objekt ceníku: cen_load"; pause; $cen_load
    Write-Host "`t`t~~ KONEC DIAGNOSTIKY ~~"; pause
}

## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
Clear-Host; Write-Menu  #tady to vlastně začíná, ale musí to být na samotném konci
