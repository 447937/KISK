#!/bin/bash
# očekávaný vstup:
# [tabulátor]pd [slovo]
# generuje výstup:
# [slovo][nový řádek][tabulátor]nd  [nadřazený pojem]

echo -e "\n   >>> TEZAUŘÍ UDĚLÁTOR na generování záznamů z pd položek <<<"

wf="/tmp/a.$$"
touch $wf
echo -n "~ Zadej nd termín: "; read nd
read -p "~ Otevře se nano pro vložení seznamu pd položek. Stiskni [Enter] až budeš připravený..."
nano $wf

sed -ie 's/\tpd  /*/g' $wf
sed -ie 's/\tpd /*/g' $wf

sed -ie "s/$/\n\tnd  $nd\n/g" $wf
nano $wf

echo -e "~ Pracovní soubor: $wf\n >>> KONEC"
