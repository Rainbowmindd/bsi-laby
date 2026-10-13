# Raport z audytu bezpieczeństwa aplikacji webowej „Sklep Mydło i Powidło”

> To jest przykład dydaktyczny. Firma, aplikacja, adresy, osoby, fragmenty kodu i wyniki są wymyślone. Opisane
> klasy błędów są prawdziwe i w ten sposób występują w aplikacjach, które je popełniają. Raport pokazuje oczekiwaną
> formę projektu zaliczeniowego i jego zawartość.
>
> Akapity oznaczone „Uwaga dydaktyczna” to komentarz dla studenta. Wyjaśniają, dlaczego dana część ma taką postać.
> W raporcie oddawanym na zaliczenie takich akapitów się nie umieszcza. Napis `[ZRZUT EKRANU Z ...]` oznacza
> miejsce, w które w prawdziwym raporcie wkleja się zrzut ekranu.

| | |
|---|---|
| Zleceniodawca | Mydło i Powidło sp. z o.o. (fikcyjna) |
| Przedmiot audytu | Sklep internetowy: aplikacja webowa i API (Python, Flask) |
| Klasyfikacja | OWASP Top 10:2025 |
| Wersja raportu | 1.0 |
| Daty audytu | 16-20.11.2026 |
| Autor | Jan Student, gr. 3 |
| Poufność | Poufne. Raport zawiera opis sposobu wykorzystania podatności. |

---

## 1. Podsumowanie

Audyt sklepu Mydło i Powidło prowadzono przez pięć dni w środowisku testowym (staging). Stwierdzono 10 problemów,
w tym 1 krytyczny i 3 wysokie.

Najpoważniejsze możliwe skutki, gdyby te błędy pozostały na produkcji:

1. Odczyt danych wszystkich klientów. Przez pole wyszukiwarki można pobrać całą zawartość bazy, w tym adresy
   e-mail, adresy dostawy i historię zamówień (MP-01).
2. Dostęp do cudzych faktur. Każdy zalogowany klient może pobrać faktury innych klientów, zawierające imię,
   nazwisko i adres (MP-02).
3. Zakup towaru po zaniżonej cenie. Cenę ustala przeglądarka klienta, a serwer ją przyjmuje, co pozwala zamówić
   10 sztuk mydła za 0,10 zł zamiast 149 zł (MP-03).

Problemy 1 i 2 stanowią naruszenie ochrony danych osobowych w rozumieniu RODO. W razie ich wykorzystania firma
musiałaby zgłosić naruszenie do Prezesa UODO w ciągu 72 godzin.

Zalecana kolejność prac: najpierw poprawić MP-01, MP-02 i MP-03, przed następnym wdrożeniem na produkcję.
Pozostałe problemy można zaplanować w zwykłym cyklu prac.

| Waga | Liczba znalezisk |
|---|---|
| Krytyczna | 1 |
| Wysoka | 3 |
| Średnia | 2 |
| Niska | 3 |
| Informacyjna | 1 |

> Uwaga dydaktyczna. Ten rozdział czyta osoba nietechniczna, najczęściej kierownik projektu lub zarząd. Należy
> opisać możliwy skutek dla firmy, a nie użytą technikę. Zamiast nazwy „SQL injection” podaje się, co może stracić
> firma. Liczby w tabeli muszą się zgadzać z liczbą znalezisk w rozdziale 7.

---

## 2. Zakres, zasady i wyłączenia

### 2.1. Przedmiot audytu

| Element | Adres |
|---|---|
| Aplikacja webowa (Flask, szablony Jinja2) | `https://sklep-staging.mydloipowidlo.example` |
| API (trasy Flask `/api/*`, baza PostgreSQL) | `https://sklep-staging.mydloipowidlo.example/api` |
| Panel administratora | `.../admin` |

Audyt prowadzono w środowisku testowym (staging) z tą samą wersją aplikacji co produkcja (`v2.4.1`), na danych
wygenerowanych, nie prawdziwych. Repozytorium kodu: `https://git.mydloipowidlo.example/sklep` (gałąź `v2.4.1`).

### 2.2. Rodzaj audytu i dostępy

Zastosowano podejście szarej skrzynki (gray box). Zespół otrzymał konta testowe oraz kod źródłowy aplikacji, bez
dostępu do serwerów produkcyjnych.

| Konto | Rola | Przeznaczenie |
|---|---|---|
| `klient.a@test.example` | klient | główne konto testowe |
| `klient.b@test.example` | klient | sprawdzenie dostępu do cudzych danych |
| `admin.test@test.example` | administrator | analiza panelu |

Hasła do kont przekazano osobnym kanałem i nie są zamieszczone w raporcie.

### 2.3. Zgoda i zasady

- Pisemna zgoda właściciela z dnia 10.11.2026, zakres i terminy jak powyżej.
- Okno prac: 16-20.11.2026, godz. 9:00-17:00.
- Kontakt awaryjny po stronie zleceniodawcy podano w zgodzie.
- Techniki zakazane: ataki odmowy usługi (DoS), socjotechnika wobec pracowników, ładunki niszczące dane.
- Napotkane dane „osobowe” (wygenerowane): 1-2 rekordy jako dowód, w raporcie zamaskowane.

### 2.4. Wyłączenia z zakresu

Następujących elementów nie sprawdzano, ponieważ były poza zakresem lub nie działały w środowisku testowym:

- płatności: bramę płatniczą zastąpiono atrapą (sandbox), więc rzeczywistego procesu nie można było sprawdzić;
- funkcja „Nie pamiętam hasła”: wysyłka wiadomości e-mail była wyłączona na stagingu;
- integracja z firmą kurierską: zastąpiona atrapą.

> Uwaga dydaktyczna. To najważniejsza i najczęściej pomijana część raportu. Funkcję, której nie sprawdzono, trzeba
> wymienić wprost. Raport bez podatności z wąskiego zakresu niewiele znaczy. Gdy ktoś później znajdzie błąd w
> płatnościach, ten akapit dokumentuje, że płatności nie były przedmiotem audytu. Zakres i wyłączenia chronią obie strony.

---

## 3. Przebieg audytu

### 3.1. Klasyfikacja i ocena wagi

Znaleziska sklasyfikowano według OWASP Top 10:2025, czyli słownika dziesięciu kategorii ryzyka aplikacji webowych.
OWASP Top 10 służy do opisu znalezisk i jest wspólnym językiem z osobą czytającą raport, a nie metodyką testowania.

(W zawodowych audytach stosuje się pełne metodyki: OWASP Web Security Testing Guide, który opisuje konkretne testy,
oraz OWASP Application Security Verification Standard, czyli listę wymagań do weryfikacji. Oba dokumenty mają po
kilkaset stron i wykraczają poza zakres przedmiotu. Na potrzeby projektu wystarczy OWASP Top 10 i materiał wykładu.)

Wagę każdego znaleziska zespół ocenił samodzielnie, w kontekście tej aplikacji, na podstawie skutku i łatwości
wykorzystania. Jest to ocena zespołu, a nie wartość przepisana ze skanera. Użyto pięciu poziomów:

| Waga | Znaczenie |
|---|---|
| Krytyczna | Błąd pozwala przejąć aplikację lub odczytać dane wszystkich użytkowników i jest łatwy do wykorzystania. Naprawa natychmiast. |
| Wysoka | Poważny skutek, na przykład dostęp do cudzych danych osobowych lub strata finansowa. Wykorzystanie realne. Naprawa przed następnym wdrożeniem. |
| Średnia | Ograniczony skutek albo wykorzystanie wymagające dodatkowych warunków. Naprawa w zaplanowanym cyklu prac. |
| Niska | Niewielki skutek. Często wymaga współwystąpienia innego błędu lub mało prawdopodobnych warunków. |
| Informacyjna | Nie jest podatnością. Zalecenie lub dobra praktyka, która podnosi poziom bezpieczeństwa. |

### 3.2. Jak prowadzono audyt

Aplikacja była dostępna w środowisku testowym pod adresem z rozdziału 2.1. Uruchomiono ją także lokalnie z kodu
źródłowego, aby poznać jej działanie i potwierdzić przyczyny znalezisk w kodzie. Uruchomienie lokalne:

```bash
git clone https://git.mydloipowidlo.example/sklep && cd sklep
git checkout v2.4.1
docker compose up -d db          # PostgreSQL z danymi testowymi
pip install -r requirements.txt
flask db upgrade                 # migracje schematu
python seed.py                   # wypełnienie bazy danymi wygenerowanymi
flask run                        # serwer deweloperski na http://127.0.0.1:5000
```

Audyt oparto na dwóch czynnościach: zmapowaniu aplikacji (przejście przez wszystkie podstrony oraz spis ról,
funkcji i miejsc przyjmujących dane wejściowe) i przeglądzie kodu źródłowego. Ruch między przeglądarką a serwerem
obserwowano w serwerze pośredniczącym (proxy) Burp Suite. Dla każdego znaleziska w rozdziale 7 opisano przykładowy
scenariusz jego wykorzystania, który pokazuje skutek błędu.

### 3.3. Czego nie udało się sprawdzić

- Procesu płatności, resetu hasła i integracji kurierskiej (powód w rozdziale 2.4).
- Konfiguracji produkcyjnej. Nagłówki HTTP i tryb błędów oceniono na stagingu, który może różnić się od produkcji.
- Logów i mechanizmów wykrywania po stronie serwera. Zespół nie miał dostępu do serwerów, więc nie można było
  ocenić, czy ataki zostałyby zauważone (kategoria A09 OWASP Top 10 pozostaje poza oceną).

---

## 4. Narzędzia

| Narzędzie | Zastosowanie |
|---|---|
| Przegląd kodu źródłowego | ustalenie przyczyny znalezisk w kodzie aplikacji |
| Burp Suite Community | serwer pośredniczący (proxy), podgląd i podmiana żądań (Repeater) |
| Narzędzia deweloperskie przeglądarki (DevTools) | podgląd żądań, ciasteczek i nagłówków |
| `curl` | odtwarzalne wywołania API |
| `pip-audit` | sprawdzenie znanych podatności w zależnościach |

---

## 5. Tabela znalezisk

| ID | Znalezisko | Waga | Kategoria Top 10:2025 |
|---|---|---|---|
| MP-01 | SQL injection w wyszukiwarce produktów | Krytyczna | A05 Injection |
| MP-02 | IDOR, pobieranie cudzych faktur | Wysoka | A01 Broken Access Control |
| MP-03 | Cena zamówienia ustalana po stronie klienta | Wysoka | A06 Insecure Design |
| MP-04 | Panel administratora dostępny dla zwykłego klienta | Wysoka | A01 Broken Access Control |
| MP-05 | XSS w treści opinii o produkcie | Średnia | A05 Injection |
| MP-06 | Brak ograniczenia liczby prób logowania | Średnia | A07 Authentication Failures |
| MP-07 | Ciasteczko sesji bez flag `HttpOnly` i `Secure` | Niska | A02 Security Misconfiguration |
| MP-08 | Biblioteka z publicznie znaną podatnością | Niska | A03 Supply Chain Failures |
| MP-09 | Brak nagłówków bezpieczeństwa | Niska | A02 Security Misconfiguration |
| MP-10 | Komunikaty błędów ujawniają wersję serwera | Informacyjna | A02 Security Misconfiguration |

> Uwaga dydaktyczna. Tabelę sortuje się od znaleziska najgroźniejszego. Osoba czytająca od razu widzi liczbę
> problemów i ich wagę, a dopiero potem przechodzi do opisów. Identyfikator (MP-01 i dalsze) pozwala odwołać się do
> znaleziska w rozmowie i przy poprawkach.

---

## 6. Jak czytać raport

Rozdział 7 zawiera znaleziska, posortowane od najgroźniejszego. Każde znalezisko ma tę samą budowę:

- Tytuł, waga i kategoria: czego dotyczy błąd, jak jest groźny i do której kategorii OWASP Top 10 należy.
- Lokalizacja: który punkt końcowy API (endpoint) lub która funkcja zawiera błąd, ze wskazaniem miejsca w kodzie.
- Opis: na czym polega błąd, z fragmentem podatnego kodu.
- Scenariusz wykorzystania: jak błąd można wykorzystać, z przykładowym żądaniem i odpowiedzią.
  Pokazuje skutek błędu.
- Rekomendacja: jak go naprawić, z poprawioną wersją kodu.

Każde znalezisko jest opisane tak, aby osoba utrzymująca kod mogła odtworzyć problem u siebie i wiedziała, co zmienić.

> Uwaga dydaktyczna. Pole „scenariusz wykorzystania” pokazuje, jak błąd działa, na przykładowym żądaniu i
> odpowiedzi. W prawdziwym raporcie w oznaczone miejsce wkleja się zrzut ekranu z rzeczywistego wyniku. Raport
> opisuje znaleziska jako fakt, bez słowa „hipotetycznie”.

---

## 7. Znaleziska

### MP-01. SQL injection w wyszukiwarce produktów (waga krytyczna)

- Waga: krytyczna. Kategoria: A05 Injection.
- Lokalizacja: `GET /api/products?search=...`, moduł katalogu.
- Kod: `app/catalog/repository.py:42` (`https://git.mydloipowidlo.example/sklep/blob/v2.4.1/app/catalog/repository.py#L42`).

Opis. Tekst z pola wyszukiwarki jest wstawiany do zapytania SQL przez formatowanie napisu. Wpisana treść przestaje
być wyszukiwaną frazą i staje się częścią zapytania do bazy. Pozwala to odczytać dowolną tabelę, w tym tabelę klientów.

Podatny kod:

```python
# app/catalog/repository.py
def search_products(term):
    # podatność: zmienna term wstawiana wprost do zapytania (f-string)
    query = f"SELECT id, name, price FROM products WHERE name ILIKE '%{term}%'"
    return db.session.execute(query).fetchall()
```

Scenariusz wykorzystania. Zwykłe wyszukiwanie `GET /api/products?search=mydlo` zwraca listę mydeł.
Fraza wpisana w to samo pole, która zamyka pierwotny warunek i dokleja własny, pobierający dane z tabeli `users`
(dokładny ciąg znaków w załączniku A, nie w treści raportu), powoduje zwrócenie rekordów użytkowników zamiast
produktów:

```json
// GET /api/products?search=... -> 200 OK (przykładowa odpowiedź, dane zamaskowane)
[
  { "name": "j****@test.example", "city": "Kraków" },
  { "name": "a****@test.example", "city": "Gdańsk" }
]
```

`[ZRZUT EKRANU Z PRZYKŁADOWEJ ODPOWIEDZI SERWERA W NARZĘDZIU REPEATER]`

Skutek. Odczyt całej bazy klientów: adresów e-mail, adresów i zamówień. Przy innym ładunku także modyfikacja danych.

Rekomendacja. Stosować zapytania parametryzowane. Dane użytkownika przekazywać jako parametr, nigdy nie wstawiać ich
do treści zapytania:

```python
def search_products(term):
    query = "SELECT id, name, price FROM products WHERE name ILIKE :term"
    return db.session.execute(query, {"term": f"%{term}%"}).fetchall()
```

> Uwaga dydaktyczna. W treści raportu nie umieszcza się pełnego ładunku ataku. Opisuje się mechanizm i skutek, a
> dokładny ciąg znaków oraz surowe żądanie z odpowiedzią trafiają do załącznika. Raport jest w praktyce instrukcją,
> dlatego przekazuje się go bezpiecznie, w zaszyfrowanym archiwum, z hasłem podanym osobnym kanałem.

---

### MP-02. IDOR, pobieranie cudzych faktur (waga wysoka)

- Waga: wysoka. Kategoria: A01 Broken Access Control.
- Lokalizacja: `GET /api/invoices/{id}`, moduł faktur.
- Kod: `app/invoices/routes.py:31`.

Opis. Serwer wydaje fakturę na podstawie numeru z adresu (`id`) i nie sprawdza, do kogo ona należy. Każdy
zalogowany klient może pobrać fakturę dowolnego innego klienta. Numery faktur są nadawane kolejno, więc łatwo je
zgadnąć. Jest to podatność IDOR (Insecure Direct Object Reference), czyli bezpośrednie odwołanie do cudzego obiektu
po identyfikatorze.

Podatny kod:

```python
# app/invoices/routes.py
@bp.get("/api/invoices/<int:invoice_id>")
@login_required
def get_invoice(invoice_id):
    invoice = Invoice.query.get_or_404(invoice_id)
    # podatność: brak sprawdzenia, czy invoice.user_id == current_user.id
    return jsonify(invoice.to_dict())
```

Scenariusz wykorzystania. Konto A (`klient.a`), pobierając własną fakturę nr 2041, otrzymuje
`200 OK` z danymi konta A. Zmiana numeru w adresie na sąsiedni zwraca fakturę innego konta:

```
GET /api/invoices/2040  (z sesją konta A)
-> 200 OK, faktura konta B, z imieniem, nazwiskiem i adresem konta B
```

`[ZRZUT EKRANU Z DWÓCH ŻĄDAŃ W REPEATERZE: KONTO A WIDZI FAKTURĘ KONTA B]`

Przykładowe żądania dla obu kont znajdują się w załączniku B.

Skutek. Odczyt danych osobowych i zamówień dowolnego klienta przez zmianę jednej liczby w adresie.

Rekomendacja. Przy każdym pobraniu faktury sprawdzać po stronie serwera, czy należy ona do zalogowanego użytkownika,
i dla cudzej faktury zwracać `403`:

```python
    invoice = Invoice.query.get_or_404(invoice_id)
    if invoice.user_id != current_user.id:
        abort(403)
    return jsonify(invoice.to_dict())
```

> Uwaga dydaktyczna. Scenariusz korzysta z dwóch kont. Pokazuje, że kontem A można odczytać dane konta B. Bez
> drugiego konta nie da się wiarygodnie wykazać błędu kontroli dostępu.

---

### MP-03. Cena zamówienia ustalana po stronie klienta (waga wysoka)

- Waga: wysoka. Kategoria: A06 Insecure Design.
- Lokalizacja: `POST /api/orders`, moduł koszyka.
- Kod: `app/orders/routes.py:58`.

Opis. Przy składaniu zamówienia przeglądarka wysyła identyfikator produktu, ilość oraz cenę jednostkową. Serwer
przyjmuje tę cenę bez porównania z cennikiem. Jest to błąd projektu. Dane, które muszą pochodzić z serwera, są
pobierane od klienta, któremu nie wolno ufać.

Podatny kod:

```python
# app/orders/routes.py
@bp.post("/api/orders")
@login_required
def create_order():
    data = request.get_json()
    # podatność: cena jednostkowa brana z żądania klienta
    total = sum(item["unitPrice"] * item["qty"] for item in data["items"])
    order = Order(user_id=current_user.id, total=total)
    ...
```

Scenariusz wykorzystania. Zwykłe żądanie `POST /api/orders` zawiera pole `"unitPrice": 14.90`.
Zmiana tej wartości na `0.01` w serwerze pośredniczącym (proxy) przed wysłaniem powoduje przyjęcie zamówienia
po zaniżonej cenie:

```json
// POST /api/orders -> 201 Created (przykładowa odpowiedź)
{ "orderId": 5120, "total": 0.10, "status": "confirmed" }
```

`[ZRZUT EKRANU ZE ZMIENIONEGO ŻĄDANIA I ODPOWIEDZI 201 CREATED]`

Skutek. Zakup dowolnego towaru po dowolnie niskiej cenie, czyli bezpośrednia strata finansowa.

Rekomendacja. Serwer wylicza cenę samodzielnie, z własnego cennika, na podstawie identyfikatora produktu i ilości.
Cenę przesłaną przez klienta ignoruje:

```python
    total = 0
    for item in data["items"]:
        product = Product.query.get_or_404(item["id"])
        total += product.price * item["qty"]   # cena z bazy, nie z żądania
```

> Uwaga dydaktyczna. Takiego błędu nie wykryje automatyczny skaner. Aplikacja działa zgodnie z kodem, tylko kod
> zakłada uczciwego klienta. Błędy logiki biznesowej wymagają zrozumienia działania aplikacji, a znajduje się je
> właśnie przez przegląd kodu i ręczną analizę żądań.

---

### MP-04. Panel administratora dostępny dla zwykłego klienta (waga wysoka)

- Waga: wysoka. Kategoria: A01 Broken Access Control.
- Lokalizacja: `GET /api/admin/*`.
- Kod: `app/admin/routes.py:12`.

Opis. Przycisk panelu administratora jest w interfejsie ukryty przed klientem, ale punkty końcowe API (endpointy)
sprawdzają tylko, czy użytkownik jest zalogowany, a nie jego rolę. Klient, który zna adres, może wywołać funkcje
administracyjne.

Podatny kod:

```python
# app/admin/routes.py
@bp.get("/api/admin/users")
@login_required                 # podatność: sprawdza logowanie, nie rolę administratora
def admin_users():
    return jsonify([u.to_dict() for u in User.query.all()])
```

Scenariusz wykorzystania. Wywołanie `GET /api/admin/users` z sesją zwykłego konta `klient.a`
zwraca `200 OK` z listą wszystkich kont, ponieważ trasa nie sprawdza roli. Ukrycie przycisku w interfejsie nie
jest kontrolą dostępu. Przykładowe żądanie w załączniku C.

`[ZRZUT EKRANU Z ODPOWIEDZI 200 OK Z LISTĄ KONT PRZY SESJI ZWYKŁEGO KLIENTA]`

Rekomendacja. Sprawdzać rolę użytkownika po stronie serwera przy każdym punkcie końcowym administracyjnym, na
przykład własnym dekoratorem:

```python
@bp.get("/api/admin/users")
@admin_required                 # przepuszcza tylko konto z rolą administratora, inaczej 403
def admin_users():
    return jsonify([u.to_dict() for u in User.query.all()])
```

---

### MP-05. XSS w treści opinii o produkcie (waga średnia)

- Waga: średnia. Kategoria: A05 Injection.
- Lokalizacja: formularz opinii, wyświetlanie na stronie `/product/{id}`.
- Kod: `app/templates/product.html:54`.

Opis. Treść opinii jest wstawiana do szablonu z filtrem `| safe`, który wyłącza domyślne kodowanie znaków
(auto-escaping) w Jinja2. Pozwala to wstawić kod HTML lub JavaScript, który wykona się w przeglądarce każdej osoby
oglądającej produkt. Jest to podatność XSS (cross-site scripting), czyli wstrzyknięcie kodu wykonywanego w
przeglądarce ofiary.

Podatny kod:

```html
{# app/templates/product.html #}
{# podatność: | safe wyłącza kodowanie znaków dla treści od użytkownika #}
<div class="review-body">{{ review.body | safe }}</div>
```

Scenariusz wykorzystania. Opinia zawierająca znacznik skryptu wykonuje się w przeglądarce każdego,
kto otworzy stronę produktu. Nieszkodliwy znacznik testowy wyświetla okno dialogowe, co potwierdza wykonanie
wstawionego kodu. Dokładny znacznik znajduje się w załączniku D.

`[ZRZUT EKRANU Z OKNA DIALOGOWEGO WYWOŁANEGO PRZEZ TREŚĆ OPINII]`

Rekomendacja. Usunąć filtr `| safe`. Jinja2 domyślnie koduje znaki specjalne, więc wystarczy wyświetlać treść
bez niego: `{{ review.body }}`. Dodatkowo wprowadzić nagłówek `Content-Security-Policy` (patrz MP-09).

---

### MP-06. Brak ograniczenia liczby prób logowania (waga średnia)

- Waga: średnia. Kategoria: A07 Authentication Failures.
- Lokalizacja: `POST /api/auth/login`.
- Kod: `app/auth/routes.py:20`.

Opis. Trasa logowania nie ogranicza liczby prób, ani na konto, ani na adres IP. Umożliwia to zgadywanie haseł na
dużą skalę.

Podatny kod:

```python
# app/auth/routes.py
@bp.post("/api/auth/login")      # podatność: brak ograniczenia liczby prób (rate limiting)
def login():
    data = request.get_json()
    user = User.query.filter_by(email=data["email"]).first()
    if user and user.check_password(data["password"]):
        login_user(user)
        return jsonify(ok=True)
    return jsonify(ok=False), 401
```

Scenariusz wykorzystania. Trasa nie ma ogranicznika liczby prób, więc wielokrotne żądania logowania
na to samo konto nie są ani blokowane, ani opóźniane. Pozwala to zgadywać hasło automatycznie, aż do skutku.

`[ZRZUT EKRANU Z WIELU ODPOWIEDZI 401 BEZ BLOKADY]`

Rekomendacja. Wprowadzić ograniczenie liczby prób, na przykład biblioteką `Flask-Limiter`:

```python
@bp.post("/api/auth/login")
@limiter.limit("5 per minute")   # po 5 próbach na minutę kolejne są odrzucane
def login():
    ...
```

Dla kont administracyjnych rozważyć uwierzytelnianie dwuskładnikowe (2FA).

> Uwaga dydaktyczna. Jeżeli sprawdzasz to aktywnie, testuj mechanizm obrony, czyli to, czy po kilku nieudanych
> próbach pojawia się blokada, a nie prawdziwe hasła. Obowiązują zasady z zakresu: bez atakowania produkcji i bez
> niszczenia danych.

---

### MP-07. Ciasteczko sesji bez flag `HttpOnly` i `Secure` (waga niska)

- Waga: niska. Kategoria: A02 Security Misconfiguration.
- Lokalizacja: konfiguracja aplikacji, nagłówek `Set-Cookie` po zalogowaniu.
- Kod: `app/config.py:15`.

Opis. Ciasteczko sesji nie ma flagi `HttpOnly`, więc jest dostępne dla kodu JavaScript, co jest groźne w
połączeniu z podatnością XSS. Nie ma też flagi `Secure`, więc może zostać wysłane połączeniem nieszyfrowanym (HTTP).

Podatny kod:

```python
# app/config.py
SESSION_COOKIE_HTTPONLY = False   # powinno być True
SESSION_COOKIE_SECURE = False     # powinno być True
```

Scenariusz wykorzystania. W zakładce ciasteczek narzędzi deweloperskich kolumny `HttpOnly` i
`Secure` są puste dla ciasteczka `session`. Przy współwystępowaniu podatności XSS (MP-05) skrypt mógłby odczytać
ciasteczko i przejąć sesję użytkownika.

`[ZRZUT EKRANU Z ZAKŁADKI CIASTECZEK W DEVTOOLS: PUSTE KOLUMNY HTTPONLY I SECURE]`

Rekomendacja. Ustawić flagi w konfiguracji:

```python
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_SAMESITE = "Lax"
```

---

### MP-08. Biblioteka z publicznie znaną podatnością (waga niska)

- Waga: niska. Kategoria: A03 Software Supply Chain Failures.
- Lokalizacja: zależności aplikacji (`requirements.txt`).
- Kod: `requirements.txt:7`.

Opis. Jedna z bibliotek jest w wersji, dla której istnieje publicznie opisana podatność. W tej aplikacji podatny
fragment nie jest używany, dlatego waga jest niska. Wersję i tak należy zaktualizować.

Podatny wpis:

```
# requirements.txt
PyYAML==5.1      # znana podatność, poprawka w 5.4
```

Scenariusz wykorzystania. Polecenie `pip-audit` wskazuje bibliotekę i numer podatności. Przegląd
kodu potwierdza, że podatna funkcja (`yaml.load` bez bezpiecznego wczytywania) nie jest w aplikacji wywoływana,
więc obecnie nie da się jej wykorzystać. Ryzyko pojawi się, gdy ktoś użyje tej funkcji w przyszłości.

`[ZRZUT EKRANU Z WYNIKU POLECENIA pip-audit]`

Rekomendacja. Zaktualizować bibliotekę do wersji z poprawką (`PyYAML>=5.4`). Włączyć automatyczne sprawdzanie
zależności, na przykład `pip-audit` w procesie budowania.

> Uwaga dydaktyczna. Waga zależy od kontekstu. Ta sama biblioteka miałaby wagę wysoką, gdyby podatny kod był
> używany. Dlatego wagi nie przepisuje się ze skanera, tylko ocenia u siebie i uzasadnia.

---

### MP-09. Brak nagłówków bezpieczeństwa (waga niska)

- Waga: niska. Kategoria: A02 Security Misconfiguration.
- Lokalizacja: odpowiedzi HTTP aplikacji.
- Kod: `app/__init__.py` (brak konfiguracji nagłówków).

Opis. Brak nagłówków `Content-Security-Policy`, `Strict-Transport-Security` i `X-Content-Type-Options`. Same w
sobie nie dają włamania, ale usuwają warstwy ochrony. Nagłówek CSP ograniczyłby skutki podatności XSS z MP-05.

Scenariusz wykorzystania. Podgląd nagłówków odpowiedzi w narzędziach deweloperskich pokazuje, że
wymienione nagłówki są nieobecne. Bez nagłówka CSP przeglądarka nie blokuje skryptu wstrzykniętego przez XSS.

`[ZRZUT EKRANU Z ZAKŁADKI NETWORK W DEVTOOLS: NAGŁÓWKI ODPOWIEDZI BEZ CSP I HSTS]`

Rekomendacja. Dodać nagłówki, na przykład biblioteką `Flask-Talisman`:

```python
# app/__init__.py
from flask_talisman import Talisman
Talisman(app, content_security_policy={"default-src": "'self'"})
```

---

### MP-10. Komunikaty błędów ujawniają wersję serwera (waga informacyjna)

- Waga: informacyjna. Kategoria: A02 Security Misconfiguration.
- Lokalizacja: obsługa błędu 500, nagłówek `Server`.
- Kod: `app/errors.py:9`.

Opis. Przy błędzie serwer zwraca pełną treść wyjątku, a nagłówek `Server` podaje wersję frameworka. Ułatwia to
dobranie gotowych narzędzi ataku. Nie jest to podatność, tylko dobra praktyka do wdrożenia.

Podatny kod:

```python
# app/errors.py
@app.errorhandler(500)
def server_error(e):
    return str(e), 500        # zwraca pełną treść wyjątku użytkownikowi
```

Scenariusz wykorzystania. Wywołanie błędu zwraca treść wyjątku, a nagłówek odpowiedzi zawiera
`Server: Werkzeug/2.0.1 Python/3.11`. Znając wersję, atakujący szybciej dobiera gotowe narzędzia ataku.

`[ZRZUT EKRANU Z ODPOWIEDZI 500 ZE ŚLADEM WYJĄTKU I NAGŁÓWKIEM SERVER]`

Rekomendacja. Na produkcji zwracać ogólny komunikat błędu bez treści wyjątku. Usunąć lub nadpisać nagłówek `Server`.

> Uwaga dydaktyczna. Waga informacyjna oznacza zalecenie, nie podatność. Takie uwagi warto zapisywać, ale nie
> należy zawyżać ich wagi, bo wtedy raport traci wiarygodność.

---

## 8. Załączniki

Przekazane osobno, w zaszyfrowanym archiwum, z hasłem podanym osobnym kanałem:

- Załącznik A. MP-01: przykładowe żądanie i odpowiedź oraz użyty ciąg znaków.
- Załącznik B. MP-02: przykładowe żądania dla obu kont.
- Załącznik C. MP-04: przykładowe żądanie `GET /api/admin/users` z sesją klienta.
- Załącznik D. MP-05: dokładny znacznik użyty w opinii.

> Uwaga dydaktyczna. Szczegóły są w załączniku, a nie w treści, ponieważ raport bywa rozsyłany w firmie pocztą i
> drukowany, a załącznik z gotowymi żądaniami jest w praktyce instrukcją włamania. Treść raportu ma wystarczyć do
> zrozumienia problemu. Szczegóły potrzebne do jego odtworzenia przechowuje się osobno i przekazuje bezpiecznie.

---

## 9. Wymagania wobec projektu zaliczeniowego

Raport oddawany na zaliczenie zawiera:

- podsumowanie, bez żargonu, z najważniejszymi skutkami i zalecaną kolejnością prac;
- zakres i wyłączenia, czyli co sprawdzano, czego nie sprawdzano i dlaczego;
- przebieg audytu: jak uruchomiono aplikację, jakich narzędzi użyto, czego nie udało się sprawdzić;
- klasyfikację znalezisk według Top 10:2025 oraz sposób ustalenia wagi;
- tabelę znalezisk posortowaną od najgroźniejszego;
- każde znalezisko w sześciu polach: tytuł, waga i kategoria, lokalizacja z miejscem w kodzie, opis z fragmentem
  podatnego kodu, scenariusz wykorzystania z przykładowym żądaniem i odpowiedzią, rekomendacja z poprawioną wersją kodu;
- wagę w skali słownej (krytyczna, wysoka, średnia, niska, informacyjna), bez liczenia score, ale uzasadnioną
  kontekstem;
- przykładowe żądania w załączniku, nie w treści, przy czym cały raport traktuje się jako poufny.

Kryterium oceny każdego znaleziska: czy osoba utrzymująca kod odtworzy problem w pięć minut i będzie wiedziała, co
zmienić. Wskazanie miejsca w kodzie wraz z przykładowym żądaniem znaczy więcej niż długi opis.
