# Doporučení pro lepší online bezpečnost

Každý den se dostáváme do styku s online prostředím, které v posledních několika letech nabylo na důležitosti. Na internetu je snadné najít si práci, vztah, zajistit si půjčku nebo bydlení a spoustu dalších věcí včetně ovládání chytré domácnosti. Vše se zdá být v pořádku do okamžiku, kdy se zamyslíme nad naším soukromím, bezpečností online světa a především naším přístupem k této problematice. Právě tento článek se zaměří na možné problémy práce v online prostředí a doporučí možné nástroje k jejich řešení nebo alespoň poradí jak být na internetu co možná nejvíce v bezpečí.

Problematika soukromí a online bezpečnosti je zde rozebírána ze čtyř pohledů:

1.  Online služba (např. Spotify, Facebook nebo Google)
2.  Účet (např. Facebook nebo Google účty)
3.  (Domácí) Počítačová síť
4.  Koncová zařízení

## Internetové služby

Pojem *internetová služba (web service)* je v tomto článku chápán oproti [definici W3C](https://www.w3.org/TR/2004/NOTE-ws-arch-20040211/#whatis), jako soubor nástrojů a služeb poskytovaných v online prostředí s možným přesahem do offline světa přičemž je potřebné se vůči dané službě identifikovat, jinak není možné službu využívat nebo jsou její funkce limitovány.

Jinými slovy je nutné se do služby přihlásit s unikátním přihlašovacím jménem nebo jiným autentizačním tokenem a až poté je možné službu využívat bez omezení a získávat obsah relevantní pro konkrétního uživatele. Prakticky to znamená, že každý uživatel Facebooku vidí jiné příspěvky, každý posluchač na Spotify dostane každý týden jiný Discover Weekly playlist a tak dále.

Není možné jednoznačně doporučit, kterou internetovou službu využívat a kterou ne. Je plně na uvážení každého jednotlivce, které služby chce využívat a jak. Nejsilnějším faktorem určující výběr dané služby je pravděpodobně velikost uživatelské základny a její bezprostřední zastoupení v bezprostřední sociální blízkosti jednotlivce, o nic méně podstatný by však neměl být ani způsob zacházení s osobními údaji a jejich ochrana službou.

Důležité je si uvědomit, že informace, které službám poskytneme buď při registraci nebo jejich používáním mohou být využity jak pro lepší zážitek ze služby a její vylepšení zrovna tak, jako mohou být zpeněženy nebo mohou uniknout a být zneužity. Každý by si tak měl rozmyslet které informace má smysl na internetu sdílet a kterým službám důvěřovat. \[1\]

Určité typy služeb je možné hostovat s využitím vlastních prostředků, může se jednat například o cloudové služby, sociální sítě, komunikátory nebo i vyhledávače. Nepopiratelnou výhodou je absolutní kontrola nad daty i samotnou službu. Značnou nevýhodou pak může být zodpovědnost za bezpečný chod i uchování dat – oba uvedené aspekty mohou být náročné na znalosti, čas, ale i peníze.


| Typ služby        | Běžně používané služba          | Služby dbající na soukromí uživatelů    |
|-------------------|---------------------------------|-----------------------------------------|
| Sociální sítě     | Facebook, Instagram, Twitter    | [Diaspora](https://diasporafoundation.org/#get_started), [Mastodon](https://joinmastodon.org/), [Raftr](https://www.raftr.com/login?redirect_url=/)               |
| Rychlá komunikace | Skype, Messenger, WhatsApp      | [Telegram](https://telegram.org/), [Signal](https://signal.org/)                        |
| Email             | Google, Seznam.cz               | [ProtonMail.com](https://protonmail.com/), [Hushmail.com](https://www.hushmail.com/)            |
| Vyhledávače       | Google, Seznam.cz               | [DuckDuckGo.com](https://duckduckgo.com/), [searx.me](https://searx.me/), [Startpage.com](https://www.startpage.com/) |
| Cloud             | Google Drive, OneDrive, DropBox | [Mega](https://mega.nz/), [Sync.com](https://www.sync.com/), [tresorit](https://tresorit.com/), [pCloud](https://www.pcloud.com/)        |

Tabulka 1.: Alternativní služby s ohledem na soukromí uživatelů. \[2\] \[3\] \[4\] \[5\] \[6\]

## Účty

Jak již bylo zmíněno výše, s používáním internetových služeb jsou neodmyslitelně spojeny i účty, které slouží k autentizaci jednotlivých uživatelů. Dnes není neobvyklé přihlašovat se do jedné služby účtem, který si uživatel zřídil u služby jiné. Poskytovateli těchto univerzálních účtů jsou zpravidla velcí internetoví hráči jako jsou například Google, Twitter nebo Facebook, ale není nemožné se setkat i s méně známými poskytovateli identit jako je například GitHub.

Kromě těchto povětšinou známých poskytovatelů účtů si můžou organizace spravovat vlastní identity nevázané na jinou společnost. V českém akademickém prostředí k tomu například slouží technologie Shibboleth (mezinárodně pak české VŠ vystupují pod federací [eduID.cz](https://www.eduid.cz/)). Veřejnost pak může využívat české řešení [mojeID](https://www.mojeid.cz/cs/).

Byť výše uvedení poskytovatelé účtů a tedy i online identit elegantně řeší potíže spojené s velkým množstvím hesel je nutné si uvědomit i možná rizika takového řešení. Pro případné útočníky je výhodnější napadnout účet zajišťující přístup k většímu množství služeb. Na druhou stranu bývají poskytovatelé identit velmi dobře zabezpečení, takže nejslabším článkem jsou zpravidla koncoví uživatelé.

Běžné zabezpečení účtu heslem je možné rozšířit o tzv. dvoufaktorové ([2FA](https://en.wikipedia.org/wiki/Multi-factor_authentication)) ověření formou SMS nebo push notifikace na telefon.

Úplným základem je však dobře zvolené heslo tak aby nešlo uhodnout na základě znalostí o konkrétní osobě a aby bylo pro každý účet unikátní. Rovněž by se mělo v čase měnit nebo alespoň z větší části obměňovat. Existuje několik doporučení jak by správné heslo mělo a nemělo vypadat. Tato doporučení by se dala shrnout do následujících bodů:

-   Heslo musí být delší než 8 znaků a čím delší je, tím lépe.
-   Používejte číslice i speciální znaky (např.: ( ) , . ; - \* / + % \# @)
-   Nepoužívejte smysluplná slova a jednoduché číselné řady.
-   Součástí hesla nesmí být název služby nebo účtu který používáte.
-   V hesle by se neměl vyskytnout současný rok.

Po určitém čase se však každý dostane dostane do situace kdy bude problém vymyslet nové heslo podle výše uvedených pravidel a následně si ho zapamatovat. Jedním řešením jsou tzv. bezpečnostní fráze nebo také *passphrases*, které i při použití běžných slov (slovníkových výrazů) poskytují lepší bezpečnost díky své délce. Je však důležité se vyhnout již existujícím textům, jinak je možné bezpečnostní frázi téměř okamžitě prolomit. Více informací se můžete dozvědět v [článku od bezpečnostní společnosti CyberHound](https://cyberhound.com/wp-content/uploads/CH-Research-Paper-Password-Security-LR-.pdf). \[7\] \[8\]

Z druhé strany řeší problém velkého množství hesel tzv. správci hesel, což jsou aplikace skladující hesla k libovolnému množství účtů, kromě toho pomáhají s automatickým vyplňováním přihlašovacích údajů. Mezi neznámější patří [LastPass](https://www.lastpass.com/), [DashLane](https://www.dashlane.com/) nebo open source řešení [KeePass](https://keepass.info/). Jejich srovnání je dostupné například [zde](https://www.howtogeek.com/240255/password-managers-compared-lastpass-vs-keepass-vs-dashlane-vs-1password/). \[9\]

Nakonec je dobré si čas od času ověřit zda nedošlo k úniku přihlašovacích údajů, případně citlivých informací. K tomu lze využít různé služby a mezi nejznámější patří [Have I been pwned?](https://haveibeenpwned.com/) Použít lze i novou službu [Firefox Monitor](https://monitor.firefox.com/) nebo [DeHashed](https://www.dehashed.com/). \[10\]

Velice zajímavou stránkou je i [Ghost Project](https://ghostproject.fr/), na které je možné se dovědět i první tři znaky uniklého hesla v kombinaci s emailovou adresou. Můžete tak lépe odhadnout kdy přibližně k úniku došlo.

## Přenosová síť

I když jde téměř o samozřejmost, je stále možné narazit stránky, které při komunikaci s uživatelem svoji komunikaci nešifrují (nepoužívají protokol [HTTPS](https://cs.wikipedia.org/wiki/HTTPS), jen HTTP). Právě takovou komunikaci je snadné odposlechnout, zjistit veškerý přenášený obsah včetně přihlašovacích údajů a dalších citlivých informací. Je tedy vhodné kontrolovat, zda web na který přistupujete používá protokol HTTPS a pokud ne, můžete správce požádat jeho implementaci. Nejedná se o nic složitého. \[11\] \[12\]

Ani použití HTTPS však nemusí nutně znamenat bezpečnou komunikaci. Existuje hned několik způsobů jak šifrovanou komunikaci kompromitovat, ale jediné co běžný uživatel může udělat je kontrola platnosti certifikátu zvláště pokud nějaký web navštěvuje poprvé. \[13\]

Z technického hlediska nemají běžní uživatelé žádnou kontrolu nad zabezpečením aktivních síťových prvků svých poskytovatelů a musejí spoléhat na jejich svědomitost a odbornost.

Kde už běžní uživatelé nějakou moc i zodpovědnost za bezpečnou komunikaci mají jsou domácí sítě. Zkuste se zeptat sami sebe, kdy naposledy jste kontrolovali dostupnost aktualizací pro váš Wi-Fi router, měnili jste výchozí heslo do administrace nebo k síti a je vaše heslo bezpečné? Jaké zabezpečení bezdrátové sítě používáte? Docela určitě jste si většinou odpověděli “Ne“ nebo “Nevím“ a to je v pořádku pokud máte doma někoho, kdo se techniku stará za vás. Pokud ne, zkuste zmíněné aspekty zabezpečení zkontrolovat.

Aktualizace softwaru pro vaše zařízení můžete najít na stránkách výrobce buď v sekci podpory nebo po vyhledání vámi používaného zařízení. Aktuální systém vás bude chránit před útoky z vnější sítě, nezapomeňte však zapnout alespoň výchozí firewall. Pokud výrobce ukončil podporu vašeho routeru a máte stále zájem o aktualizovaný systém, můžete zkusit [OpenWrt](https://openwrt.org/).

Změna hesla k nastavení routeru a nastavení silného hesla k Wi-Fi naopak chrání před útoky z vnitřní sítě a bezprostředního okolí routeru zrovna tak jako použití [WPA2](https://en.wikipedia.org/wiki/Wi-Fi_Protected_Access#WPA2) šifrované komunikace. Během několika následujících let se na trhu objeví i zařízení s podporou [WPA3](https://en.wikipedia.org/wiki/Wi-Fi_Protected_Access#WPA3) a jakmile budete moci, použijte tuto novější variantu šifrování bezdrátové komunikace. \[14\]

## Koncová zařízení

Poslední část článku bych věnoval problematice koncových zařízení. Myslím si však, že je většina lidí v této oblasti již dostatečně poučená, že je důležité mít aktuální verzi nejen operačního systému, který používá, ale i aplikací – především pak internetových prohlížečů. Neuškodí ani pravidelné skenování antivirovým softwarem.

Co už si ale všichni neuvědomují nebo to okázale ignorují je fakt, že u mobilních aplikací lze omezit přístup k vybraným funkcím jako je například poloha nebo mikrofon. Seznam požadovaných oprávnění je možné si zkontrolovat před instalací a už tehdy lze odhalit záškodnickou aplikaci. Např. pokud aplikace vydávající se za kompas vyžaduje přístup k mikrofonu a fotoaparátu, asi nebude vše v pořádku a takovou aplikaci je lepší vůbec nestahovat nebo nesmyslná oprávnění alespoň neudělovat. Užitečné mohou být i komentáře jiných uživatelů.

Na zcela samostatný článek je pak problematika internetových bublin, posuzování pravdivosti zpráv a informací na internetu a rozpoznání podvodů apod. Jediné co můžu poradit je aby jste hned všemu nevěřili, ověřovali si zdroje a zamyslete se na tím kdo a proč danou zprávu či informaci na internet vystavil.

## Použité zdroje
| [1]  | Who’s selling private data about us? More importantly, who’s buying it?. In: The Sociable [online]. Ireland: ESPACIO, 2018 [cit. 2019-01-26]. Dostupné z: https://sociable.co/technology/selling-private-data/                                                                                                                   |
|------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [2]  | 8 Best Facebook Alternatives With Focus On Privacy For 2018. In: Fossbytes [online]. Delhi-NCR, India: Fossbytes Media Pvt, 2018 [cit. 2019-01-26]. Dostupné z: https://fossbytes.com/best-facebook-alternatives/                                                                                                                |
| [3]  | REISINGER, Don. How Switzerland's ProtonMail Delivers End-to-End Email Encryption. EWeek [online]. 2016, , 1-1 [cit. 2019-01-26]. ISSN 15306283. Dostupné z: http://search.ebscohost.com/login.aspx?direct=true&db=asn&AN=113988443&lang=cs&site=ehost-live                                                                      |
| [4]  | The 5 Best Secure Email Services for 2019. Lifewire [online]. New York, USA: Lifewire, 2019 [cit. 2019-01-26]. Dostupné z: https://www.lifewire.com/best-secure-email-services-4136763                                                                                                                                           |
| [5]  | The Best Private Search Engines That Respect Your Privacy. In: Best VPN Services [online]. Bromborough, UK: 4Choice, 2019 [cit. 2019-01-27]. Dostupné z: https://www.bestvpn.com/guides/private-search-engines/                                                                                                                  |
| [6]  | Compare Online Backup Services - All Providers At Your Fingertips. In: Compare Best Cloud Storage | Best VPN | Web Hosting & More [online]. Dubai, UAE: Cloudwards, 2019 [cit. 2019-01-26]. Dostupné z: https://www.cloudwards.net/comparisons/?compare=9101,10850,9097,18832,9072,28949,8763,9078,                              |
| [7]  | Passphrase vs. password entropy. In: Information Security Stack Exchange [online]. New York, USA: Stack Overflow, 2018 [cit. 2019-01-27]. Dostupné z: https://security.stackexchange.com/questions/178015/passphrase-vs-password-entropy                                                                                         |
| [8]  | Unmasked: An Analysis of 10 Million Passwords. In: WordPress Hosting, Perfected. WP Engine® [online]. London, UK: WPEngine, 2018 [cit. 2019-01-27]. Dostupné z: https://wpengine.com/unmasked/                                                                                                                                   |
| [9]  | Password Managers Compared: LastPass vs KeePass vs Dashlane vs 1Password. In: How To Geek - We Explain Technology [online]. Herndon, USA: How-To Geek, 2018 [cit. 2019-01-27]. Dostupné z: https://www.howtogeek.com/240255/password-managers-compared-lastpass-vs-keepass-vs-dashlane-vs-1password/                             |
| [10] | Know About the Best Alternatives of HIBP. In: Anti Malware [online]. Jaipur, India: Tweaking Technologies, 2018 [cit. 2019-01-27]. Dostupné z: https://www.antimalware.news/know-about-the-best-alternatives-of-hibp/                                                                                                            |
| [11] | Man-in-the-middle attack. In: Wikipedia: the free encyclopedia [online]. San Francisco (CA): Wikimedia Foundation, 2019 [cit. 2019-01-26]. Dostupné z: https://en.wikipedia.org/wiki/Man-in-the-middle_attack                                                                                                                    |
| [12] | How to Use — and Why You Need — Let’s Encrypt More Than Ever. In: Medium – a place to read and write big ideas and important stories [online]. San Francisco, USA: A Medium Corporation, 2017 [cit. 2019-01-27]. Dostupné z: https://medium.com/linode-cube/how-to-use-and-why-you-need-lets-encrypt-more-than-ever-5e04131b3a12 |
| [13] | It's there a way to bypass https nowadays?. In: Stack Exchange [online]. New York, USA: Stack Overflow, 2018 [cit. 2019-01-26]. Dostupné z: https://security.stackexchange.com/questions/178101/its-there-a-way-to-bypass-https-nowadays                                                                                         |
| [14] | What is WPA3? And some gotchas to watch out for in this Wi-Fi security upgrade. In: Welcome to Network World [online]. Framingham, USA: IDG Communications, 2018 [cit. 2019-01-28]. Dostupné z: https://www.networkworld.com/article/3316567/mobile-wireless/what-is-wpa3-wi-fi-security-protocol-strengthens-connections.html   |
