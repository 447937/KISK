<# 
Tiskař štítků pro Zebru na Křižovatce
Knihovna na Křižovatce
Ondřej Kadlec 2020
Kdo za to může: 447937@mail.muni.cz
Využívá ZPL (Zebra Programming Language), víc info třeba tu: https://www.zebra.com/content/dam/zebra/manuals/printers/common/programming/zpl-zbi2-pm-en.pdf
Je nutný mít správně nastavenou tiskárnu ve Windows, tak aby brala surová data.
Pro čárové kódy používáme CODE_128, nikoliv EAN-13 (problémy způsobené kontrolní číslicí)!
#>

#testovací fígl:
$kam='./out.txt' #kde se má tisknout, resp kam má jít textový výstup? - správně to má být tiskárna, nikoliv soubor

Clear-Host
Write-Host "                          >>> Zebrový tiskař štítků <<<"

FUNCTION Write-Menu {
Write-Host "`n> MENU:"
Write-Host "  0: Dávkový tisk čárových kódů na průkazky"
#Write-Host "  y: Tisk čárového kódu na průkazku"
Write-Host "  1: Tisk čtenářské průkazky"
Write-Host "  2: Dávkový tisk čárových kódů na knihy"
# Write-Host "  x: Tisk  MVS štítku" #chcete mě?
Write-Host "  q: Ukončit skript"

$volba = Read-Host -Prompt "`n~ Volba"
    switch ( $volba )
    {
        0 { tisk-carkod-na-prukazku }
        #y { tisk-stitek-na-prukazku }
        1 { tisk-ctenare }
        2 { tisk-carkod-na-knihu }
        #x { MVS }
        q { pac-a-pusu }
    }
Write-Menu <# Zachycení neplatné volby a taky doběhlé funkce...nechť rekurze vládne světu #>
}

FUNCTION tisk($tdata) {
    ## víc info na https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-printer?view=powershell-7
    # Write-Output $data | Out-Printer -Name '--název tiskárny--' 
    Write-Host "@func tisk"
    Write-Output $tdata >> $kam #> $pf  NEBO přímo ROZHRANÍ USBfň     #tiskárna baští
    # CMD cesta vede skrze soubor copy $pf \\localhost\tiskarna
    Clear-Variable -Name tdata
}

FUNCTION pac-a-pusu {
    Write-Host "Pac a pusu :*"
    Start-Sleep -s 0.5
    exit
    }
    
FUNCTION tisk-carkod-na-knihu {
    Write-Host "`n> DÁVKOVÝ tisk čárových kódů na knihy"
    [long]$kod = Read-Host -Prompt "~ Začátek generovaného rozsahu"
    [int]$kolik = Read-Host -Prompt "~ Počet tisknutých štítků"
    [int]$i=0

    do {
    $a = "
    ^XA
        ^CI28
        ^FO60,10^BY3
        ^BEN,80,Y,N
        ^FD$kod^FS
        ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS
    ^XZ"

    write-host "@func tisk-carkod-na-knihu Data: $i, $kod"
    tisk -tdata $a
    $i++
    $kod++
    } while ( $i -lt $kolik ) 

    Clear-Variable -Name i, kod, kolik
}

#### ### ## # IS THAT REALLY WHAT YOU WANT? # ## ### ####
# Jou jou, EAN-13 to není. CODE_128 možná, ale kdo ví?  #
# Musím to zjistit aby nebyly průkaky.                  #

FUNCTION tisk-carkod-na-prukazku ($dataCnP) {
    if($dataCnP -ne $null) { [int]$i=0; [int]$kolik=1; [long]$kod=$dataCnP }
    else {
        Write-Host "`n> DÁVKOVÝ tisk čárových kódů na průkazky"
        [long]$kod = Read-Host -Prompt "~ Začátek generovaného rozsahu"
        [int]$kolik = Read-Host -Prompt "~ Počet tisknutých štítků"
        [int]$i=0
    }

    do {
        $a="
        ^XA
            ^CI28
            ^FO15,10^BY3
            ^BCN,80,Y,N,N
            ^FD$dataCnP^FS
            ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS
        ^XZ"
        
        write-host "@func tisk-carkod-na-prukazku Data: $i, $kod"
        tisk -tdata $a
        $i++
        $kod++
    } while ( $i -lt $kolik )
    
    Clear-Variable -Name dataCnP, i, kod, kolik
}


<#
FUNCTION tisk-stitek-na-prukazku {
    if($prukazka -ne $null) {
        write-host "rovnou tisknu"
        $ktisku = "
        ^XA
            ^CI28
            ^FO15,10^BY3
            ^BCN,80,Y,N,N
            ^FD$prukazka^FS
            ^FT^A0N,30,20^FO105,125^FDKnihovna na Křižovatce^FS
        ^XZ"

        tisk -tdata $ktisku # Write-Output $ktisku
        Clear-Variable -Name prukazka # ten dolar tu opravdu být nemá
    }
    else { 
        write-host "ptám se; $prukazka"
        Write-Host "`n> Tisk čárových kódů na průkazku"
        TSnP-dotaz
        tisk-stitek-na-prukazku
    }
}
#>

FUNCTION TSnP-dotaz {
    [long]$script:prukazka = Read-Host -Prompt "~ Číslo průkazky"
}

FUNCTION tisk-ctenare {
    Write-Host "`n> Tisk průkazek"
    $ctenar_typ = Read-Host -Prompt "~ Čtenář mladší 12 let? [1,a,y / 0,n]"

    if( $ctenar_typ -eq 'y' -OR $ctenar_typ -eq '1' -OR $ctenar_typ -eq 'a' ) { ctenar_mladsi }
    elseif( $ctenar_typ -eq 'n' -OR $ctenar_typ -eq '0' ) { ctenar_starsi }
    else { Write-Host "!! NEPLATNÁ VOLBA !!" ; tisk-ctenare }
}

FUNCTION ctenar_mladsi {
    TSnP-dotaz
    $ctenar_jmeno = Read-Host -Prompt "~ Jméno a přijímení"
    $ctenar_rok = Read-Host -Prompt "~ Rok narození"
    $ctenar_bydlo = Read-Host -Prompt "~ Bydliště"
    $ctenar_bydlo2 = Read-Host -Prompt "          "
<#  $ctenar_skola = Read-Host -Prompt "~ Škola"
    $ctenar_trida = Read-Host -Prompt "~ Třída 
#>
    $a= "
    ^XA
        ^CI28
        ^FT^A0N,30,20^FO10,10^FDJméno:^FS
        ^FT^A0N,30,23^FO75,10^FD$ctenar_jmeno^FS
        ^FT^A0N,30,20^FO10,50^FDRok narození:^FS
        ^FT^A0N,30,23^FO125,50^FD$ctenar_rok^FS
        ^FT^A0N,30,20^FO10,90^FDBydlište:^FS
        ^FT^A0N,30,23^FO85,90^FD$ctenar_bydlo^FS
        ^FT^A0N,30,23^FO85,120^FD$ctenar_bydlo2^FS
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
    ##tisk-stitek-na-prukazku
    tisk-carkod-na-prukazku -dataCnP $prukazka
    tisk -tdata $a
}

FUNCTION ctenar_starsi {
    TSnP-dotaz
    $ctenar_jmeno = Read-Host -Prompt "~ Jméno a přijímení"
    $ctenar_bydlo = Read-Host -Prompt "~ Bydliště"
    $ctenar_bydlo2 = Read-Host -Prompt "          "

    $a= "
    ^XA
        ^CI28
        ^FT^A0N,30,20^FO10,10^FDČTENAŘSKY PRŮKAZ č.:^FS
        ^FT^A0N,30,23^FO215,10^FD$prukazka^FS
        ^FT^A0N,30,20^FO10,50^FDJméno:^FS
        ^FT^A0N,30,23^FO75,50^FD$ctenar_jmeno^FS
        ^FT^A0N,30,20^FO10,90^FDBydlište:^FS
        ^FT^A0N,30,23^FO85,90^FD$ctenar_bydlo^FS
        ^FT^A0N,30,23^FO85,120^FD$ctenar_bydlo2^FS
    ^XZ"

    ##tisk-stitek-na-prukazku
    tisk-carkod-na-prukazku -dataCnP $prukazka
    tisk -tdata $a
}

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

Write-Menu  #tady to vlastně začíná, ale musí to být na samotném konci