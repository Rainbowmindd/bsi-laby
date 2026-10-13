// kolory, fonty
#let accent = rgb("#1d4e89")
#let accent-light = rgb("#eef3fa")
#let ink = rgb("#1b2430")
#let muted = luma(105)
#let warn = rgb("#a15c00")
#let warn-light = rgb("#fff6e5")
#let sans-head = ("Inter", "Segoe UI", "Arial")
#let mono = ("Cascadia Mono", "Consolas")

#set document(title: "Pierwsze kroki z Burp Suite", author: "BSI")
#set page(
  paper: "a4",
  margin: (x: 2.2cm, top: 2.2cm, bottom: 2cm),
  header: context {
    if counter(page).get().first() > 1 {
      set text(font: sans-head, size: 8pt, fill: muted)
      [Bezpieczeństwo Systemów Informatycznych #h(1fr) Pierwsze kroki z Burp Suite]
      v(-6pt)
      line(length: 100%, stroke: 0.4pt + luma(210))
    }
  },
  footer: context {
    set text(font: sans-head, size: 8pt, fill: muted)
    h(1fr)
    counter(page).display("1 / 1", both: true)
  },
)
#set text(font: ("Noto Sans", "Segoe UI", "Arial"), size: 10pt, fill: ink, lang: "pl")
#set par(justify: true, leading: 0.68em, spacing: 1em)
#set list(indent: 0.4em, marker: text(fill: accent)[•])
#set enum(indent: 0.4em, numbering: n => text(fill: accent, weight: "semibold")[#n.])
#show strong: set text(weight: "semibold")

// rozdzialy od 0
#set heading(numbering: (..n) => numbering("1.", n.pos().first() - 1, ..n.pos().slice(1)))
#show heading.where(level: 1): it => {
  set text(font: sans-head, size: 14pt, weight: "semibold", fill: ink)
  block(above: 1.6em, below: 0.75em, sticky: true, width: 100%)[
    #if it.numbering != none [
      #text(fill: accent)[#counter(heading).display(it.numbering)]#h(0.45em)
    ]#it.body
    #v(-0.55em)
    #line(length: 100%, stroke: 0.6pt + luma(205))
  ]
}
#show heading: set text(hyphenate: false)
#show heading.where(level: 2): it => {
  set text(font: sans-head, size: 11pt, weight: "semibold", fill: accent)
  block(above: 1.3em, below: 0.7em, sticky: true, it)
}
#show outline.entry.where(level: 1): set block(above: 0.55em)
#show outline.entry: set text(font: sans-head, size: 9.5pt)

#show link: set text(fill: accent)
#show raw: set text(font: mono, size: 0.92em)
#show raw.where(block: false): box.with(fill: rgb("#f0f2f5"), outset: (x: 1.5pt, y: 2.5pt), radius: 2pt)
#show raw.where(block: true): block.with(
  fill: rgb("#f6f8fa"), stroke: 0.5pt + luma(215), inset: (x: 11pt, y: 9pt), radius: 3pt, width: 100%,
)
// sierotki (a, i, w, z...)
#show regex("\b[aiouwzAIOUWZ] "): it => [#it.text.trim()~]

// tabele
#set table(
  inset: (x: 7pt, y: 5pt),
  stroke: (_, y) => if y == 0 { (bottom: 0.8pt + accent) } else { (bottom: 0.4pt + luma(220)) },
  fill: (_, y) => if y == 0 { accent-light },
)
#show table.cell.where(y: 0): set text(font: sans-head, size: 9pt, weight: "semibold", fill: accent)
#show table: set par(justify: false)
#show table: block.with(breakable: false)

// ramki i zrzuty
#let ramka(label, color, light, body) = block(
  fill: light, stroke: (left: 2.5pt + color), radius: (right: 3pt),
  inset: (left: 11pt, right: 10pt, y: 9pt), width: 100%, above: 1.1em, below: 1.1em, breakable: false,
  [#text(font: sans-head, size: 7.5pt, weight: "bold", tracking: 0.09em, fill: color)[#label]
   #v(1pt)
   #set par(justify: false)
   #body],
)
#let krok(body) = ramka("KROK", accent, accent-light, body)
#let uwaga(body) = ramka("UWAGA", warn, warn-light, body)
#let zrzut(path, cap, width: 100%) = {
  let fig(placement) = figure(
    box(stroke: 0.5pt + luma(200), radius: 2pt, clip: true, image(path, width: 100%)),
    caption: cap,
    supplement: [Zrzut],
    placement: placement,
  )
  align(center, block(width: width, fig(none)))
}
#show figure: set block(above: 1.2em, below: 1.2em)
#show figure.caption: it => {
  set text(size: 8.5pt, fill: muted)
  set align(left)
  set par(justify: false)
  [#text(weight: "semibold", fill: ink)[#it.supplement #context it.counter.display(it.numbering).] #it.body]
}

// tytul
#block(width: 100%, below: 1.4em)[
  #text(font: sans-head, size: 8pt, weight: "semibold", tracking: 0.12em, fill: accent)[
    BEZPIECZEŃSTWO SYSTEMÓW INFORMATYCZNYCH · ĆWICZENIA
  ]
  #v(2pt)
  #text(font: sans-head, size: 24pt, weight: "bold", fill: ink)[Pierwsze kroki z Burp Suite]
  #v(4pt)
  #line(length: 100%, stroke: 1.5pt + accent)
]

Instrukcja jest przeznaczona dla osób, które nie korzystały wcześniej z Burp Suite. Prowadzi od
uruchomienia narzędzia do wykrycia ośmiu podatności w przygotowanej aplikacji. Każda z nich
powinna zostać opisana w raporcie z testu penetracyjnego.

Po zakończeniu ćwiczenia student potrafi:

- skonfigurować Burp Suite jako proxy dla przeglądarki i odczytać przechwycone żądanie HTTP,
- sporządzić mapę aplikacji na podstawie zakładki _HTTP history_,
- zmodyfikować i ponowić żądanie w _Repeaterze_ oraz porównać odpowiedzi,
- rozpoznać błędy uwierzytelniania, kontroli dostępu i logiki biznesowej (rozdziały 8–13),
- opisać znalezisko w formie przyjętej w raporcie z testu penetracyjnego.

Test penetracyjny to kontrolowana próba ataku na system, prowadzona w celu wykrycia podatności.
Wymaga on pisemnej zgody właściciela systemu, określającej zakres i termin testów. Te same
czynności wykonane bez zgody mogą stanowić przestępstwo (art. 267 Kodeksu karnego). Ćwiczenie
dotyczy wyłącznie lokalnej aplikacji pod adresem `http://127.0.0.1:8000`, uruchomionej na
własnym komputerze. Narzędzia nie należy kierować na inne cele, w szczególności na sieci
i systemy AGH.

#outline(title: [Spis treści], depth: 1, indent: auto)

= Wymagania

#block(sticky: true)[Przed zajęciami należy zainstalować następujące oprogramowanie:]

- *Python 3.12 lub nowszy*, pobierany ze strony
  #link("https://www.python.org/downloads/")[python.org/downloads]. W systemie Windows podczas
  instalacji należy zaznaczyć opcję _Add python.exe to PATH_. Poprawność instalacji sprawdza
  polecenie `python --version`.
- *Burp Suite Community Edition*, pobierany ze strony
  #link("https://portswigger.net/burp/communitydownload")[portswigger.net/burp/communitydownload].
  Wersja bezpłatna nie wymaga licencji ani rejestracji.
- *Przeglądarka*: Burp Suite zawiera wbudowaną przeglądarkę Chromium, która wystarcza do
  ćwiczenia. Jako rozwiązanie zapasowe (rozdział~4) można użyć przeglądarki Firefox, pobieranej
  ze strony #link("https://www.mozilla.org/firefox/")[mozilla.org/firefox].
- *Plik aplikacji* `app.py`, udostępniony przez prowadzącego.

Pakiety Pythona potrzebne do uruchomienia aplikacji instaluje się poleceniem opisanym
w rozdziale~2. Polecenie to również należy wykonać przed zajęciami.

= Czym jest Burp i do czego służy proxy

Burp Suite to *proxy HTTP* z zestawem narzędzi do testowania aplikacji webowych. Proxy to
pośrednik między przeglądarką a serwerem, przez który przechodzi każde żądanie i każda
odpowiedź. Burp zapisuje ten ruch, a po włączeniu przechwytywania pozwala zatrzymać żądanie
i zmienić je przed wysłaniem do serwera.

Przeglądarka wysyła żądania na podstawie tego, co udostępnia interfejs aplikacji. Osoba
testująca może w Burpie zmienić w żądaniu dowolne dane, także takie, których interfejs nie
pozwala edytować. Serwer otrzymuje wyłącznie samo żądanie i nie może ustalić, czy dane pochodzą
z interfejsu. Jeśli przyjmuje je bez weryfikacji, w aplikacji występuje podatność.

== Budowa żądania i odpowiedzi HTTP

Żądanie HTTP składa się z wiersza żądania (metoda, ścieżka, wersja protokołu, np.
`GET /shop HTTP/1.1`), nagłówków w postaci `Nazwa: wartość`, pustego wiersza i opcjonalnej
treści (body). Metoda GET służy do pobierania danych. Formularz HTML wysyłany metodą POST
przekazuje dane w treści żądania, domyślnie w postaci `pole1=wartość1&pole2=wartość2`.

Dane kontrolowane przez klienta znajdują się w ścieżce (`/api/orders/1001`), w adresie po
znaku `?` (parametry zapytania, np. `?price=1299`), w treści żądania POST oraz w nagłówkach,
w tym w nagłówku `Cookie`. Każde z tych miejsc można zmienić w Burpie.

Ciasteczko (cookie) to wartość, którą serwer przekazuje przeglądarce w nagłówku `Set-Cookie`.
Przeglądarka dołącza ją do kolejnych żądań w nagłówku `Cookie`. Ciasteczko sesji pozwala
serwerowi rozpoznać, który użytkownik wysłał żądanie.

Odpowiedź zaczyna się od wiersza statusu, który zawiera wersję protokołu, kod statusu i jego
opis, np. `HTTP/1.1 200 OK`. Kod 200 oznacza powodzenie, 303 przekierowanie na adres podany
w nagłówku `Location`, 401 brak uwierzytelnienia (użytkownik nie jest zalogowany), 403 odmowę
dostępu zalogowanemu użytkownikowi, a 404 brak zasobu.

Uwierzytelnianie (_authentication_) to ustalenie, kim jest użytkownik, np. na podstawie hasła
albo ciasteczka sesji. Kontrola dostępu, nazywana też autoryzacją (_authorization_), to
sprawdzenie, czy ustalony użytkownik ma prawo wykonać daną operację na danym obiekcie.

== Narzędzia Burpa używane w ćwiczeniu

- _Proxy_ służy do przechwytywania i podglądu ruchu.
- _HTTP history_ to chronologiczna lista żądań, które przeszły przez proxy. W ćwiczeniu służy
  jako uproszczona mapa aplikacji (szerszą mapę, uwzględniającą także
  odnośniki znalezione w odpowiedziach, buduje podzakładka _Site map_ w zakładce _Target_).
- _Repeater_ pozwala ponawiać to samo żądanie ze zmianą wybranego parametru. Jest to narzędzie
  wykorzystywane w ćwiczeniu najczęściej.

Ćwiczenie wykorzystuje Burp Suite Community Edition, czyli wersję bezpłatną. Nie zawiera ona
skanera podatności i nie zapisuje projektu na dysk, a _Intruder_ (narzędzie do wysyłania
zautomatyzowanych serii żądań) działa w niej z ograniczoną szybkością. Żadna z tych funkcji nie
jest potrzebna w ćwiczeniu.

= Uruchomienie aplikacji

W katalogu aplikacji wykonaj polecenia:

```
python -m pip install fastapi uvicorn python-multipart
python -m uvicorn app:app --port 8000
```

Aplikacja nasłuchuje pod adresem `http://127.0.0.1:8000`. Okno terminala z uruchomioną aplikacją
należy pozostawić otwarte do końca ćwiczenia. Wszystkie dane są przechowywane w pamięci, dlatego
zatrzymanie aplikacji (Ctrl+C) i ponowne uruchomienie przywracają stan początkowy.

#block(breakable: false)[
Konta testowe:

#table(
  columns: (auto, auto, 1fr),
  inset: (x: 8pt, y: 5pt),
  table.header[Login][Hasło][Rola],
  [`alice`], [`alice123`], [zwykły użytkownik, konto osoby testującej],
  [`bob`], [`bob123`], [zwykły użytkownik, konto innej osoby],
  [`admin`], [`admin123`], [administrator],
)
]

W ćwiczeniu loguje się wyłącznie konto `alice`. Konta `bob` i `admin` są celem testów. Z konta
`alice` próbuje się uzyskać ich dane i uprawnienia.

= Pierwsze uruchomienie Burpa

Uruchom Burp Suite Community Edition. Przy starcie program wyświetla okna wyboru projektu i konfiguracji.
W wersji Community wystarczą ustawienia domyślne.

#krok[
  Na pierwszym ekranie pozostaw _Temporary project in memory_ i kliknij _Next_. Na drugim
  pozostaw _Use Burp defaults_ i kliknij _Start Burp_.
]

Po chwili pojawi się główne okno z zakładkami _Dashboard_, _Target_, _Proxy_, _Intruder_,
_Repeater_ i kolejnymi. W ćwiczeniu wykorzystywane są zakładki _Proxy_ i _Repeater_.

= Konfiguracja przeglądarki

Ruch przeglądarki musi przechodzić przez Burpa. Najprostszym rozwiązaniem jest wbudowana
przeglądarka Chromium, skonfigurowana do korzystania z proxy Burpa. Nie wymaga ona
dodatkowych ustawień ani instalacji certyfikatu CA Burpa (certyfikatu potrzebnego do
przechwytywania ruchu HTTPS).

#krok[
  Otwórz zakładkę _Proxy_, a w niej podzakładkę _Intercept_, i kliknij przycisk _Open browser_. Zostanie otwarte okno
  przeglądarki. Wprowadź adres `http://127.0.0.1:8000` i zaloguj się jako `alice`.
]

#uwaga[
  Jeśli wbudowana przeglądarka się nie uruchomi, otwórz w Burpie okno _Settings_, w sekcji
  _Tools_ wybierz _Burp's browser_, zaznacz opcję _Allow Burp's browser to run without
  a sandbox_ i ponownie kliknij _Open
  browser_. Jeśli to nie pomoże, użyj Firefoksa. W ustawieniach Firefoksa, na karcie _Ogólne_,
  w sekcji _Ustawienia sieci_ kliknij _Ustawienia…_, wybierz ręczną konfigurację serwerów proxy i wpisz serwer HTTP
  `127.0.0.1`, port `8080`. Następnie na stronie `about:config` ustaw opcję
  `network.proxy.allow_hijacking_localhost` na `true`. Bez tej opcji Firefox wysyła żądania do
  adresu `127.0.0.1` z pominięciem proxy i nie pojawiają się one w Burpie. Aplikacja korzysta
  z nieszyfrowanego HTTP, więc certyfikat Burpa nie jest potrzebny.
]

Od tej chwili każde żądanie wysłane przez przeglądarkę przechodzi przez Burpa (zrzuty 1 i 2).

#zrzut("zrzuty/00_logowanie.png", [Strona logowania aplikacji.], width: 75%)

#zrzut("zrzuty/01_sklep.png", [Strona sklepu. Przy każdym produkcie znajduje się formularz
_Do koszyka_ i odnośnik _Kup teraz za X zł_.], width: 75%)

= Przechwytywanie żądania

W zakładce _Proxy_, w podzakładce _Intercept_, znajduje się przełącznik _Intercept off / Intercept on_. Gdy jest
włączony, Burp zatrzymuje każde żądanie zgodne z regułami przechwytywania (domyślnie pomijane są
m.in. obrazki, pliki CSS i JavaScript) i czeka na decyzję. Przycisk _Forward_ przekazuje żądanie
do serwera, a _Drop_ je odrzuca. Przed podjęciem decyzji żądanie można obejrzeć i zmienić.

#krok[
  Włącz przechwytywanie (_Intercept on_). W przeglądarce kliknij _Moje zamówienia_. Strona nie
  zostanie wczytana,
  ponieważ żądanie zostało zatrzymane w Burpie. Przełącz się na okno Burpa i kliknij _Forward_.
  Następnie kliknij w przeglądarce zamówienie `#1001`. W zakładce _Intercept_ pojawi się żądanie
  `GET /api/orders/1001`.
]

#zrzut("zrzuty/02_intercept.png", [Przechwycone żądanie `GET /api/orders/1001`. Nagłówek
`Cookie: session=alice` pozwala serwerowi rozpoznać użytkownika. Żądanie nie zostało jeszcze
wysłane do serwera i oczekuje na decyzję _Forward_ albo _Drop_.])

Widoczne są metoda (`GET`), ścieżka (`/api/orders/1001`) i nagłówki, w tym ciasteczko sesji.
Kliknij _Forward_, aby przekazać żądanie do serwera.

#uwaga[
  Każde zatrzymane żądanie wstrzymuje przeglądarkę do czasu decyzji, dlatego _Intercept_ zwykle
  pozostaje wyłączony, a analiza odbywa się w zakładkach _HTTP history_ i _Repeater_. _Intercept_
  włącza się tylko wtedy, gdy trzeba zmienić konkretne żądanie przed wysłaniem.
]

= Mapa aplikacji: _HTTP history_

Wyłącz przechwytywanie (_Intercept off_) i przejdź przez wszystkie podstrony aplikacji, wykonując
każdą dostępną akcję z wyjątkiem _Wyloguj_. Dodaj produkt do koszyka (_Do koszyka_), kliknij jeden z odnośników _Kup
teraz_ przy klawiaturze lub myszy, wpisz w koszyku kod `BSI10` i kliknij _Zastosuj_, zapisz profil
(_Zapisz_) i złóż zamówienie (_Zamów_).

Następnie otwórz w zakładce _Proxy_ podzakładkę _HTTP history_. Jest to lista wszystkich żądań, które przeszły przez
proxy, w kolejności wysłania (najstarsze u góry; kliknięcie nagłówka kolumny `#` odwraca
kolejność). Lista pełni rolę mapy aplikacji. Widoczne są na niej endpointy wywołane podczas
przeglądania aplikacji (endpoint, czyli punkt końcowy, to metoda i ścieżka obsługiwane przez
serwer), kody odpowiedzi i ciasteczka.

#zrzut("zrzuty/03_http_history.png", [_HTTP history_ po przejściu przez aplikację. Zaznaczone
żądanie `POST /login`; w panelu odpowiedzi widoczny nagłówek `Set-Cookie`, który ustawia
ciasteczko `session`.])

Mapa aplikacji stanowi punkt wyjścia testu. Przejrzyj listę i wypisz endpointy, które przyjmują
identyfikator obiektu lub dane z formularza. Przetestuj je w pierwszej kolejności.

Interfejs nie udostępnia wszystkich ścieżek obsługiwanych przez serwer. Ścieżki administracyjne
o typowych nazwach (`/admin`, `/administrator`, `/panel`) sprawdza się, wpisując je ręcznie
(ang. _forced browsing_).

= Repeater

_Repeater_ to narzędzie, które pozwala wysłać żądanie, obejrzeć odpowiedź i wysłać to samo żądanie
ponownie po dowolnej zmianie. Zwykle zmienia się jeden parametr, wysyła żądanie przyciskiem
_Send_ i porównuje odpowiedź z poprzednią. W ten sposób wykrywa się większość podatności
opisanych w instrukcji.

#krok[
  W _HTTP history_ kliknij żądanie prawym przyciskiem myszy i wybierz _Send to Repeater_ (skrót
  Ctrl+R). Przejdź do zakładki _Repeater_. Po lewej stronie znajduje się żądanie, które można
  edytować, a po prawej odpowiedź. Przycisk _Send_ wysyła żądanie.
]

Znalezisko jest potwierdzone, gdy odpowiedź serwera albo stan aplikacji odczytany kolejnym
żądaniem potwierdza skutek, np. ujawnienie cudzych danych, wykonanie akcji administratora albo
zmianę kwoty zamówienia. Sam kod 200 lub 303 nie jest dowodem.

Zestaw nagłówków na zrzutach może różnić się od widocznego w Burpie. Istotne są ścieżka,
parametry i nagłówek `Cookie`. Numery zamówień również mogą być inne niż na zrzutach.

= Znalezisko 1: ciasteczko sesji możliwe do podrobienia

W _HTTP history_ zaznacz żądanie `POST /login` i obejrzyj odpowiedź. Nagłówek ma postać
`Set-Cookie: session=alice; Path=/; SameSite=lax`. Wartością ciasteczka sesji jest sam login,
zapisany jawnym tekstem i bez podpisu. Serwer nie może więc odróżnić ciasteczka, które sam
wydał, od ciasteczka wpisanego ręcznie.

#krok[
  Wyślij do _Repeatera_ żądanie `GET /`. W nagłówku `Cookie` zmień wartość `session=alice` na
  `session=admin` i kliknij _Send_.
]

#zrzut("zrzuty/09_repeater_session_admin.png", [Żądanie z nagłówkiem `Cookie: session=admin`.
Serwer odpowiada stroną „Zalogowany: Administrator (rola: admin)”, choć nie podano hasła
administratora.])

Zmiana jednej wartości daje dostęp do dowolnego konta bez znajomości hasła. Jest to obejście
uwierzytelniania (rozdział~1.1) o wadze krytycznej.

W tym samym nagłówku `Set-Cookie` brakuje dwóch flag. Flaga `HttpOnly` blokuje odczyt
ciasteczka przez skrypty JavaScript uruchomione na stronie, co ogranicza skutki ataku XSS
(cross-site scripting, czyli wstrzyknięcia skryptu do strony; temat kolejnych wykładów). Flaga `Secure` ogranicza wysyłanie ciasteczka do połączeń
HTTPS. Brak tych flag ma niską wagę. Sam w sobie nie umożliwia ataku, ale zwiększa możliwe skutki
innych błędów. Atrybut `SameSite=lax` ustawia domyślnie framework aplikacji (Starlette).

#uwaga[
  W pozostałych testach ciasteczko pozostaje niezmienione (`session=alice`). Test z podmianą
  ciasteczka dotyczy uwierzytelniania, a pozostałe testy dotyczą kontroli dostępu i logiki
  aplikacji przy poprawnej sesji.
]

= Znalezisko 2: IDOR (dostęp do cudzych danych)

Eskalacja pozioma to dostęp do danych lub funkcji innego użytkownika o tych samych
uprawnieniach. Jej najczęstszą przyczyną jest IDOR (_insecure direct object reference_,
niebezpieczne bezpośrednie odwołanie do obiektu). Serwer zwraca obiekt wskazany identyfikatorem
w żądaniu i nie sprawdza, czy należy on do zalogowanego użytkownika.

#krok[
  Wyślij do _Repeatera_ żądanie `GET /api/orders/1001` (zamówienie konta `alice`). Zmień
  w ścieżce identyfikator na `1002` i kliknij _Send_.
]

#zrzut("zrzuty/04_repeater_idor.png", [Żądanie zamówienia `1002` wysłane w sesji konta `alice`
(`Cookie: session=alice`). Serwer zwraca kod 200 i dane `{"owner":"bob", ...}`. Zamówienie należy do konta `bob`,
co potwierdza podatność IDOR.])

Jeśli serwer zwróci kod 403 (odmowa dostępu), zasób jest chroniony. Kod 404 może oznaczać brak
obiektu albo ochronę, która ukrywa istnienie cudzego obiektu. Aby odróżnić te przypadki, należy
użyć identyfikatora obiektu, który na pewno istnieje (zamówienie `1002` należy do konta `bob`). Test należy powtórzyć dla każdego
endpointu z mapy aplikacji, który przyjmuje identyfikator obiektu.

#uwaga[
  Losowy identyfikator, np. UUID w wersji 4 (128-bitowy identyfikator, w którym 122 bity są
  losowe), utrudnia zgadywanie, ale nie zastępuje autoryzacji. Jeśli taki identyfikator zostanie ujawniony, dostęp do obiektu nadal będzie możliwy.
]

= Znalezisko 3: eskalacja pionowa (panel administratora)

Eskalacja pionowa to uzyskanie uprawnień wyższego poziomu, na przykład wywołanie przez zwykłego
użytkownika funkcji przeznaczonej dla administratora.

#krok[
  Jako `alice` otwórz w przeglądarce adres `http://127.0.0.1:8000/admin`.
]

#zrzut("zrzuty/10_browser_admin_panel.png", [Panel administratora otwarty przez konto `alice`
o roli `user`.], width: 75%)

Panel zostaje wyświetlony, mimo że konto `alice` nie ma roli administratora. Serwer sprawdza
jedynie, czy użytkownik jest zalogowany, i nie weryfikuje jego roli. Ten sam błąd dotyczy endpointu
`POST /api/admin/set-role`.

#krok[
  W panelu przy koncie `bob` wpisz w polu roli `admin` i kliknij _Ustaw rolę_. Lista kont
  pokaże konto `bob` z rolą `admin`.
]

Dowodem do raportu są żądania `GET /admin` i `POST /api/admin/set-role` odczytane w _HTTP
history_.

#uwaga[
  Pole roli ma domyślną wartość `user`. Nie klikaj _Ustaw rolę_ przy koncie `admin`,
  ponieważ spowoduje to odebranie temu kontu uprawnień administratora.
]

= Znalezisko 4: mass assignment (zmiana własnej roli)

Mass assignment (masowe przypisanie) to błąd, w którym serwer zapisuje do obiektu wszystkie pola
przesłane w żądaniu, a nie wyłącznie pola, które użytkownik może zmieniać. Formularz profilu
udostępnia tylko pole `name`, a serwer przyjmie także pole `role`.

#krok[
  Na stronie _Profil_ kliknij _Zapisz_. Żądanie `POST /api/profile` pojawi się w _HTTP
  history_. Wyślij je do _Repeatera_. Treść żądania ma postać `name=Alice+Kowalska` (znak `+`
  zastępuje spację). Na końcu treści dopisz `&role=admin` i kliknij _Send_. Burp
  automatycznie aktualizuje nagłówek `Content-Length` (długość treści żądania w bajtach).
]

#zrzut("zrzuty/06_repeater_mass_assignment.png", [W treści żądania dopisane pole
`role=admin`, którego formularz nie zawiera. Serwer odpowiada kodem 303 i przekierowuje na
`/profile`.])

Odpowiedzią jest przekierowanie (kod 303), które nie potwierdza skutku zmiany. Kliknij
w _Repeaterze_ _Follow redirection_, aby zobaczyć stronę profilu po zmianie.

#zrzut("zrzuty/07_repeater_mass_assignment_result.png", [Profil po dopisaniu `role=admin`.
Strona wyświetla „Twoja rola: admin”, czyli zwykły użytkownik nadał sobie uprawnienia
administratora.])

#uwaga[
  Po tym teście konto `alice` ma rolę administratora. Przed przejściem dalej przywróć rolę,
  wysyłając w _Repeaterze_ treść `name=Alice+Kowalska&role=user`, albo uruchom aplikację
  ponownie.
]

= Znalezisko 5: cena w adresie URL

Kliknięcie odnośnika _Kup teraz_ wysyła żądanie `GET /api/buy?product_id=3&price=1299`. Cena produktu jest
przekazywana w adresie URL, a serwer przyjmuje ją bez porównania z cennikiem.

#krok[
  W przeglądarce kliknij odnośnik _Kup teraz za 1299 zł_ przy monitorze. Żądanie pojawi się
  w _HTTP history_. Wyślij je do _Repeatera_, zmień `price` na `1` i kliknij _Send_. Każde
  wysłanie tego żądania tworzy nowe zamówienie.
]

#zrzut("zrzuty/05_repeater_buy_url.png", [Parametr `price=1` w adresie. Odpowiedź: „Kupiono
Monitor — zapłacono 1 zł”. Monitor w cenniku kosztuje 1299 zł.])

Ten sam efekt można uzyskać bezpośrednio w pasku adresu przeglądarki. Dodatkowo operacja
zmieniająca stan aplikacji (zakup) jest wykonywana metodą GET, więc może ją wywołać odnośnik
umieszczony na innej stronie.

#zrzut("zrzuty/08_browser_cena_url.png", [Ten sam atak w pasku adresu przeglądarki. Adres zawiera
`price=1`, a aplikacja potwierdza zakup za 1 zł.], width: 75%)

= Znaleziska 6–8: logika biznesowa

Błąd logiki biznesowej to wada reguł działania aplikacji (np. zasad naliczania ceny i rabatu albo
kontroli zamawianej ilości), która pozwala użyć poprawnie działających funkcji w sposób niezamierzony przez twórców.
Automatyczne skanery zwykle takich błędów nie wykrywają, ponieważ żądania i odpowiedzi są
poprawne technicznie. Wykrycie wymaga zrozumienia reguł obowiązujących w aplikacji.

Znaleziska 6 i 7 dotyczą żądania `POST /api/cart`, które przeglądarka wysyła po kliknięciu
_Do koszyka_. Już samo kliknięcie dodaje produkt do koszyka, dlatego wartość zmienia się przed
wysłaniem żądania, w zakładce _Intercept_. Ponowne wysłanie tego żądania z _Repeatera_ dodałoby
do koszyka drugą pozycję. Znalezisko 8 polega na powtarzaniu żądania, więc wykonuje się je
w _Repeaterze_. Wynik każdego testu widać na stronie _Koszyk_ w przeglądarce.

Przed każdym z trzech testów koszyk powinien być pusty. Jeśli pozostały w nim pozycje
z wcześniejszego testu, złóż zamówienie przyciskiem _Zamów_ (złożenie zamówienia opróżnia
koszyk).

== Znalezisko 6: cena z żądania

Formularz _Do koszyka_ zawiera ukryte pole `price`, czyli pole formularza niewidoczne na stronie
(`<input type="hidden">`), wysyłane razem z pozostałymi polami. Serwer odczytuje cenę z tego
pola, a nie z cennika.

#krok[
  Włącz przechwytywanie (_Intercept on_) i kliknij _Do koszyka_ przy monitorze. W zatrzymanym
  żądaniu `POST /api/cart` zmień w treści wartość `price=1299` na `price=1` i kliknij
  _Forward_. Wyłącz przechwytywanie (_Intercept off_). Monitor zostanie dodany do koszyka
  w cenie 1 zł.
]

Jest to odmiana znaleziska 5, w której cena jest przekazywana w treści żądania POST zamiast
w adresie URL.

== Znalezisko 7: ujemna ilość

#krok[
  W przeglądarce dodaj do koszyka klawiaturę (199 zł). Włącz przechwytywanie (_Intercept on_)
  i kliknij _Do koszyka_ przy monitorze. W zatrzymanym żądaniu `POST /api/cart` zmień
  `qty=1` na `qty=-1` i kliknij _Forward_. Wyłącz przechwytywanie (_Intercept off_). Suma
  koszyka wyniesie −1100 zł (199 − 1299). Kliknij _Zamów_, aby złożyć zamówienie na ujemną
  kwotę.
]

Serwer nie sprawdza, czy ilość jest dodatnia, i przyjmuje zamówienie o ujemnej wartości
(`POST /api/checkout`). Zamówienie jest widoczne na stronie _Moje zamówienia_.

== Znalezisko 8: kupon bez limitu

#krok[
  Dodaj do koszyka klawiaturę (199 zł). W koszyku wpisz kod `BSI10` (rabat 10%) i kliknij
  _Zastosuj_. Żądanie `POST /api/coupon` wyślij z _HTTP history_ do _Repeatera_ i kliknij
  _Send_ jeszcze dwa razy. Po odświeżeniu strony _Koszyk_ cena klawiatury wyniesie 144 zł
  (kolejne naliczenia rabatu dają 179, 161 i 144 zł).
]

#zrzut("zrzuty/11_browser_koszyk_kupon.png", [Koszyk po trzykrotnym wysłaniu kodu `BSI10`
(raz w przeglądarce, dwa razy w _Repeaterze_). Rabat został naliczony przy każdym żądaniu.], width: 75%)

Rabat jest naliczany przy każdym żądaniu, ponieważ serwer nie sprawdza, czy kod został już
użyty. Rabat obniża cenę wyłącznie produktów, które znajdują się w koszyku w chwili
wysłania kodu.

W każdej aplikacji warto sprawdzić wartości, które powinny być dodatnie (ilość, kwota), dane,
których klient nie powinien ustalać (cena, rabat, status płatności), oraz operacje, które
powinny zostać wykonane jednokrotnie (kupon, przelew).

= Zapis znaleziska w raporcie

#block(sticky: true)[Każde znalezisko opisuje się według jednego schematu:]

+ Tytuł i identyfikator, np. „F-02. Dostęp do cudzych zamówień (IDOR)”.
+ Lokalizacja: metoda, endpoint i parametr, np. `GET /api/orders/{id}`, parametr ścieżki `id`.
+ Opis: na czym polega błąd i jaki skutek może wywołać.
+ Kategoria według OWASP Top 10 lub OWASP API Security Top 10 (tabela poniżej). Są to listy
  najczęstszych kategorii zagrożeń aplikacji webowych i interfejsów API, publikowane przez
  fundację OWASP. Oznaczenie `A01:2025` to kategoria 1 w wydaniu z 2025 roku.
+ Waga (krytyczna, wysoka, średnia, niska) z jednozdaniowym uzasadnieniem, które opisuje skutek
  dla właściciela systemu. Zakup dowolnego produktu za 1 zł ma wyższą wagę niż ciasteczko
  bez flagi `HttpOnly`. Waga krytyczna oznacza przejęcie dowolnego konta lub pełną kontrolę nad
  danymi bez dodatkowych warunków, wysoka dostęp do cudzych danych lub straty finansowe, średnia
  skutki ograniczone lub wymagające dodatkowych warunków, a niska osłabienie innych zabezpieczeń
  bez bezpośredniego skutku.
+ Kroki odtworzenia: numerowana lista czynności, która pozwala innej osobie powtórzyć test.
+ Dowód: żądanie i odpowiedź skopiowane jako tekst z _Repeatera_, skrócone do istotnych wierszy.
  Zrzut ekranu stanowi uzupełnienie.
+ Rekomendacja: zmiana po stronie serwera, która usuwa przyczynę błędu.

Przykład dowodu dla znaleziska 2:

```
GET /api/orders/1002 HTTP/1.1
Host: 127.0.0.1:8000
Cookie: session=alice

HTTP/1.1 200 OK
content-type: application/json

{"owner":"bob","items":"Monitor x1","total":1299}
```

Rekomendacja dla tego przykładu: przed zwróceniem zamówienia serwer porównuje pole `owner`
z użytkownikiem przypisanym do sesji i w razie niezgodności zwraca kod 404, aby nie ujawniać
istnienia obiektu.

Tabela zestawia kategorie i rekomendacje dla wszystkich znalezisk. CWE (Common Weakness
Enumeration) to katalog typów słabości oprogramowania; numer CWE wskazuje konkretny typ błędu.

#table(
  columns: (auto, 1fr, 1fr),
  inset: (x: 6pt, y: 4pt),
  table.header[Nr][Kategoria][Rekomendacja],
  [1], [A07:2025 Authentication Failures (brak flag: A02:2025 Security Misconfiguration)],
    [losowy identyfikator sesji przechowywany po stronie serwera; flagi `HttpOnly`, `Secure`,
    `SameSite`],
  [2], [A01:2025 Broken Access Control; API1:2023 Broken Object Level Authorization], [sprawdzanie właściciela obiektu],
  [3], [A01:2025 Broken Access Control; API5:2023 Broken Function Level Authorization], [sprawdzanie roli przy każdej akcji
    administratora],
  [4], [A08:2025 Software or Data Integrity Failures; API3:2023 Broken Object Property Level Authorization (CWE-915)], [zapisywanie wyłącznie dozwolonych pól],
  [5, 6], [A06:2025 Insecure Design], [cena odczytywana z cennika po stronie serwera; zakup
    metodą POST],
  [7], [A06:2025 Insecure Design], [walidacja ilości (wartość co najmniej 1)],
  [8], [A06:2025 Insecure Design (CWE-841)], [zapis użycia kodu i sprawdzenie go przed
    naliczeniem rabatu],
)

Dane innych użytkowników użyte jako dowód należy ograniczyć do minimum, zamaskować w raporcie
i usunąć po zakończeniu testu.

= Pytania kontrolne

+ Dlaczego test IDOR wykonuje się przy niezmienionym ciasteczku sesji?
+ Czym różni się eskalacja pozioma od pionowej? Które znaleziska z ćwiczenia należą do każdej
  z tych kategorii?
+ Dlaczego ukrycie pola formularza (`type="hidden"`) nie chroni przesyłanej wartości?
+ Które znalezisko ma najwyższą wagę? Uzasadnij odpowiedź, opisując skutek dla właściciela
  sklepu.
+ Jaka wspólna zasada została naruszona w znaleziskach 5–8? Wskaż dla każdego z nich zmianę po
  stronie serwera, która usuwa przyczynę błędu.
+ Dlaczego kod odpowiedzi 200 lub 303 nie wystarcza jako dowód znaleziska? Co powinno zostać
  pokazane zamiast niego?
+ Dlaczego automatyczny skaner podatności nie wykryje kuponu, który można wykorzystać
  wielokrotnie?

#v(1.5em)
#ramka("DALSZA PRAKTYKA", accent, accent-light)[
  #set text(9.5pt)
  Do dalszych ćwiczeń można wykorzystać
  #link("https://portswigger.net/web-security")[PortSwigger Web Security Academy] (bezpłatne
  laboratoria przygotowane przez twórców Burpa, z ćwiczeniem i rozwiązaniem dla większości
  omówionych podatności) oraz aplikacje OWASP Juice Shop i DVWA.
  Testy należy prowadzić wyłącznie we własnym środowisku lub za pisemną zgodą właściciela
  systemu.
]
