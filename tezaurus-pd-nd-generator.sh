#!/bin/bash
clear
echo "			<<< Vítej v pekle >>>"

function do-menu
{

	echo -ne "> MENU \n 1: Abecední porovnávač \t 2: Generátor nd<>pd \n 0: Ukončit skript \n > Volba: "
	read volba
	case $volba in
		1 ) porovnej; do-menu
			;;
		2 ) generuj; do-menu
			;;
		0 ) exit
			;;
		* ) echo -e "~ Chybná volba, zkus to znovu...\n"; do-menu ;;
	esac
}

function porovnej
{
	alive=1
	wf="/tmp/a.$$"
	compar="/tmp/a.compar"

	while [ $alive -eq 1 ]
	do

	read -p "~ nano pro imput. Tlač [Enter]..."
	nano $wf
	cat $wf | sort > $compar
	md5sum $wf $compar
	echo "> Výblitek ze \"správného\" souboru".
	cat $compar 

	rm $wf
	echo -e "=== === === === === === === === === === === ===\n"

	echo -ne ">> 1: Opakovat proceduru porovnání \t 0: Návrat do menu \n>> Volba: "; read alive

	done
}

function generuj
{
# očekávaný vstup:
# [tabulátor]pd [slovo]
# generuje výstup:
# [slovo][nový řádek][tabulátor]nd  [nadřazený pojem]

	alive=1	
	while [ $alive -eq 1 ]
	do

	wf="/tmp/a.$$"
	touch $wf
	echo -n "~ Zadej nd termín: "; read nd
	read -p "~ Otevře se nano pro vložení seznamu pd položek. Stiskni [Enter] až budeš připravený..."
	nano $wf

	sed -ie 's/\tpd  /*/g' $wf
	sed -ie 's/\tpd /*/g' $wf

	sed -ie "s/$/\n\tnd  $nd\n/g" $wf
	nano $wf

	echo -e "~ Pracovní soubor: $wf"

	echo -ne ">> 1: Opakovat proceduru generování \t 0: Návrat do menu \n>> Volba: "; read alive

	done
}

do-menu
