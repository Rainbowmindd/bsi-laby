# Sklep "Przecena" - BSI, cwiczenia z Burpa
# uruchomienie: python -m uvicorn app:app --port 8000
# dane sa tylko w pamieci, po restarcie wracaja do stanu poczatkowego
from fastapi import FastAPI, Request, Form, Cookie
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse

app = FastAPI()

USERS = {
    "alice": {"password": "alice123", "name": "Alice Kowalska", "role": "user"},
    "bob": {"password": "bob123", "name": "Bob Nowak", "role": "user"},
    "admin": {"password": "admin123", "name": "Administrator", "role": "admin"},
}

CATALOG = {
    1: {"name": "Klawiatura", "price": 199},
    2: {"name": "Mysz", "price": 89},
    3: {"name": "Monitor", "price": 1299},
}

COUPONS = {"BSI10": 10}  # rabat w %

ORDERS = {
    1001: {"owner": "alice", "items": "Klawiatura x1", "total": 199},
    1002: {"owner": "bob", "items": "Monitor x1", "total": 1299},
}
next_order_id = 1003

CARTS = {}  # koszyki wg loginu
USED_COUPONS = {}


# pomocnicze

def page(title, body):
    return HTMLResponse(f"""<!doctype html><html lang="pl"><meta charset="utf-8">
<title>{title}</title><body style="font-family:sans-serif;max-width:640px;margin:2rem auto">
<h1>Sklep „Przecena”</h1>{body}</body></html>""")


def current_user(session):
    return USERS.get(session or "")


# logowanie

@app.get("/", response_class=HTMLResponse)
def home(session: str = Cookie(default=None)):
    user = current_user(session)
    if not user:
        return page("Logowanie", """
<form method="post" action="/login">
  <p>Login: <input name="username"></p>
  <p>Hasło: <input name="password" type="password"></p>
  <button>Zaloguj</button>
</form>
<p style="color:#888">Konta: alice/alice123, bob/bob123, admin/admin123</p>""")
    return page("Panel", f"""
<p>Zalogowany: <b>{user['name']}</b> (rola: {user['role']})</p>
<ul>
  <li><a href="/shop">Sklep</a></li>
  <li><a href="/cart">Koszyk</a></li>
  <li><a href="/profile">Profil</a></li>
  <li><a href="/orders">Moje zamówienia</a></li>
  <li><a href="/logout">Wyloguj</a></li>
</ul>""")


@app.post("/login")
def login(username: str = Form(...), password: str = Form(...)):
    user = USERS.get(username)
    if not user or user["password"] != password:
        return page("Błąd", "<p>Złe dane. <a href='/'>Wróć</a></p>")
    resp = RedirectResponse("/", status_code=303)
    resp.set_cookie("session", username)
    return resp


@app.get("/logout")
def logout():
    resp = RedirectResponse("/", status_code=303)
    resp.delete_cookie("session")
    return resp


# sklep i koszyk

@app.get("/shop", response_class=HTMLResponse)
def shop(session: str = Cookie(default=None)):
    if not current_user(session):
        return RedirectResponse("/")
    rows = ""
    for pid, p in CATALOG.items():
        rows += f"""
<form method="post" action="/api/cart" style="margin:.5rem 0">
  <b>{p['name']}</b> — {p['price']} zł
  <input type="hidden" name="product_id" value="{pid}">
  <input type="hidden" name="price" value="{p['price']}">
  ilość: <input name="qty" value="1" size="3">
  <button>Do koszyka</button>
</form>
<a href="/api/buy?product_id={pid}&amp;price={p['price']}">Kup teraz za {p['price']} zł</a>"""
    return page("Sklep", rows + "<p><a href='/cart'>Przejdź do koszyka</a></p>")


@app.post("/api/cart")
def add_to_cart(session: str = Cookie(default=None),
                product_id: int = Form(...), qty: int = Form(...), price: int = Form(...)):
    user = current_user(session)
    if not user:
        return JSONResponse({"error": "not logged in"}, status_code=401)
    product = CATALOG.get(product_id)
    if not product:
        return JSONResponse({"error": "no such product"}, status_code=404)
    CARTS.setdefault(session, []).append(
        {"name": product["name"], "qty": qty, "price": price})
    return RedirectResponse("/cart", status_code=303)


@app.get("/api/buy")
def buy_now(session: str = Cookie(default=None), product_id: int = 0, price: int = 0):
    global next_order_id
    user = current_user(session)
    if not user:
        return JSONResponse({"error": "not logged in"}, status_code=401)
    product = CATALOG.get(product_id)
    if not product:
        return JSONResponse({"error": "no such product"}, status_code=404)
    order_id = next_order_id
    next_order_id += 1
    ORDERS[order_id] = {"owner": session, "items": f"{product['name']} x1", "total": price}
    return page("Zamówienie", f"""
<p>Kupiono <b>{product['name']}</b> — zapłacono <b>{price} zł</b> (zamówienie #{order_id}).</p>
<p><a href="/shop">Wróć</a></p>""")


def cart_total(session):
    return sum(item["qty"] * item["price"] for item in CARTS.get(session, []))


@app.get("/cart", response_class=HTMLResponse)
def cart(session: str = Cookie(default=None)):
    if not current_user(session):
        return RedirectResponse("/")
    items = CARTS.get(session, [])
    rows = "".join(f"<li>{i['name']}: {i['qty']} × {i['price']} zł</li>" for i in items)
    return page("Koszyk", f"""
<ul>{rows or '<li>pusty</li>'}</ul>
<p>Suma: <b>{cart_total(session)} zł</b></p>
<form method="post" action="/api/coupon">
  Kod rabatowy: <input name="code"> <button>Zastosuj</button>
</form>
<form method="post" action="/api/checkout"><button>Zamów</button></form>
<p><a href="/shop">Wróć do sklepu</a></p>""")


@app.post("/api/coupon")
def coupon(session: str = Cookie(default=None), code: str = Form(...)):
    if not current_user(session):
        return JSONResponse({"error": "not logged in"}, status_code=401)
    discount = COUPONS.get(code.strip().upper())
    if discount is None:
        return JSONResponse({"error": "zły kod"}, status_code=400)
    USED_COUPONS.setdefault(session, []).append(code)
    for item in CARTS.get(session, []):
        item["price"] = int(item["price"] * (100 - discount) / 100)
    return RedirectResponse("/cart", status_code=303)


@app.post("/api/checkout")
def checkout(session: str = Cookie(default=None)):
    global next_order_id
    user = current_user(session)
    if not user:
        return JSONResponse({"error": "not logged in"}, status_code=401)
    items = CARTS.get(session, [])
    summary = ", ".join(f"{i['name']} x{i['qty']}" for i in items) or "—"
    order_id = next_order_id
    next_order_id += 1
    ORDERS[order_id] = {"owner": session, "items": summary, "total": cart_total(session)}
    CARTS[session] = []
    return page("Zamówienie", f"""
<p>Złożono zamówienie <b>#{order_id}</b> na kwotę <b>{ORDERS[order_id]['total']} zł</b>.</p>
<p><a href="/orders">Moje zamówienia</a></p>""")


# profil

@app.get("/profile", response_class=HTMLResponse)
def profile(session: str = Cookie(default=None)):
    user = current_user(session)
    if not user:
        return RedirectResponse("/")
    return page("Profil", f"""
<form method="post" action="/api/profile">
  Imię i nazwisko: <input name="name" value="{user['name']}"><br><br>
  <button>Zapisz</button>
</form>
<p>Twoja rola: {user['role']}</p>
<p><a href="/">Panel</a></p>""")


@app.post("/api/profile")
async def update_profile(request: Request, session: str = Cookie(default=None)):
    user = current_user(session)
    if not user:
        return JSONResponse({"error": "not logged in"}, status_code=401)
    form = await request.form()
    for key, value in form.items():
        user[key] = value
    return RedirectResponse("/profile", status_code=303)


# zamówienia

@app.get("/orders", response_class=HTMLResponse)
def my_orders(session: str = Cookie(default=None)):
    if not current_user(session):
        return RedirectResponse("/")
    mine = {oid: o for oid, o in ORDERS.items() if o["owner"] == session}
    rows = "".join(
        f'<li><a href="/api/orders/{oid}">#{oid}</a> — {o["items"]} ({o["total"]} zł)</li>'
        for oid, o in mine.items())
    return page("Zamówienia", f"<ul>{rows or '<li>brak</li>'}</ul><p><a href='/'>Panel</a></p>")


@app.get("/api/orders/{order_id}")
def get_order(order_id: int, session: str = Cookie(default=None)):
    if not current_user(session):
        return JSONResponse({"error": "not logged in"}, status_code=401)
    order = ORDERS.get(order_id)
    if not order:
        return JSONResponse({"error": "not found"}, status_code=404)
    return order


# panel administratora

@app.get("/admin", response_class=HTMLResponse)
def admin_panel(session: str = Cookie(default=None)):
    if not current_user(session):
        return RedirectResponse("/")
    rows = "".join(
        f"""<li>{u} ({USERS[u]['role']})
        <form method="post" action="/api/admin/set-role" style="display:inline">
          <input type="hidden" name="username" value="{u}">
          <input name="role" value="user" size="6"><button>Ustaw rolę</button>
        </form></li>""" for u in USERS)
    return page("Panel administratora", f"<ul>{rows}</ul><p><a href='/'>Panel</a></p>")


@app.post("/api/admin/set-role")
def admin_set_role(session: str = Cookie(default=None),
                   username: str = Form(...), role: str = Form(...)):
    if not current_user(session):
        return JSONResponse({"error": "not logged in"}, status_code=401)
    if username in USERS:
        USERS[username]["role"] = role
    return RedirectResponse("/admin", status_code=303)
