#!/usr/bin/env python3
"""Builds a split-pr eval fixture: a bare remote plus a clone holding `main`, `integration` and a messy
`wip` branch that interleaves two features.

    build_fixture.py <dest> shop      # Python app, runnable tests (python3 -m unittest)
    build_fixture.py <dest> billing   # TypeScript app, plan-only (no install needed)
"""
import os
import subprocess
import sys
import textwrap


def sh(cwd, *args):
    subprocess.run(args, cwd=cwd, check=True, capture_output=True)


def write(root, files):
    for path, body in files.items():
        full = os.path.join(root, path)
        if body is None:
            os.remove(full)
            continue
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with open(full, "w") as f:
            f.write(textwrap.dedent(body).lstrip("\n"))


def commit(repo, msg):
    sh(repo, "git", "add", "-A")
    sh(repo, "git", "-c", "core.hooksPath=/dev/null", "commit", "-q", "-m", msg)


# ---------------------------------------------------------------------------------------------- shop
SHOP_BASE = {
    "README.md": """
        # shop

        Order service. Layers: `shop/domain` (entities, rules), `shop/repository` (storage),
        `shop/clients` (external APIs), `shop/service` (application logic), `shop/api` (HTTP
        handlers), `shop/app.py` (wiring). Config comes from env; see `.env.example`.

        Test: `python3 -m unittest discover -s tests -t .`
    """,
    ".env.example": """
        EMAIL_API_URL=https://email.example.com
    """,
    "shop/__init__.py": "",
    "shop/domain/__init__.py": "",
    "shop/domain/errors.py": """
        class OrderNotFound(Exception):
            pass
    """,
    "shop/domain/order.py": """
        from dataclasses import dataclass


        @dataclass
        class Order:
            id: str
            customer_id: str
            total: int  # yen
            charge_id: str
            status: str = "paid"
    """,
    "shop/repository/__init__.py": "",
    "shop/repository/order_repository.py": """
        from shop.domain.errors import OrderNotFound


        class OrderRepository:
            def __init__(self):
                self._orders = {}

            def add(self, order):
                self._orders[order.id] = order

            def find(self, order_id):
                if order_id not in self._orders:
                    raise OrderNotFound(order_id)
                return self._orders[order_id]
    """,
    "shop/clients/__init__.py": "",
    "shop/clients/http.py": """
        import json
        import urllib.request


        def post_json(url, payload):
            req = urllib.request.Request(
                url,
                data=json.dumps(payload).encode(),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=5) as resp:
                return resp.status, json.loads(resp.read() or b"{}")
    """,
    "shop/clients/email_client.py": """
        from shop.clients.http import post_json


        class EmailClient:
            def __init__(self, base_url, transport=post_json):
                if not base_url:
                    raise ValueError("email API URL is required")
                self._base_url = base_url.rstrip("/")
                self._transport = transport

            def send(self, to, subject, body):
                status, _ = self._transport(f"{self._base_url}/messages", {"to": to, "subject": subject, "body": body})
                return status == 202
    """,
    "shop/service/__init__.py": "",
    "shop/service/order_service.py": """
        class OrderService:
            def __init__(self, orders):
                self._orders = orders

            def get_order(self, order_id):
                return self._orders.find(order_id)
    """,
    "shop/api/__init__.py": "",
    "shop/api/handlers.py": """
        from shop.domain.errors import OrderNotFound


        class Handlers:
            def __init__(self, order_service):
                self._orders = order_service

            def get_order(self, request):
                try:
                    order = self._orders.get_order(request["params"]["id"])
                except OrderNotFound:
                    return 404, {"error": "order not found"}
                return 200, {"id": order.id, "total": order.total, "status": order.status}
    """,
    "shop/app.py": """
        from shop.api.handlers import Handlers
        from shop.clients.email_client import EmailClient
        from shop.repository.order_repository import OrderRepository
        from shop.service.order_service import OrderService


        def build_app(env):
            orders = OrderRepository()
            EmailClient(env["EMAIL_API_URL"])
            handlers = Handlers(OrderService(orders))
            routes = {
                ("GET", "/orders/{id}"): handlers.get_order,
            }
            return routes, orders
    """,
    "tests/__init__.py": "",
    "tests/test_order_repository.py": """
        import unittest

        from shop.domain.errors import OrderNotFound
        from shop.domain.order import Order
        from shop.repository.order_repository import OrderRepository


        class OrderRepositoryTest(unittest.TestCase):
            def test_find(self):
                repo = OrderRepository()
                repo.add(Order("o1", "c1", 1000, "ch1"))
                self.assertEqual(repo.find("o1").total, 1000)
                with self.assertRaises(OrderNotFound):
                    repo.find("nope")
    """,
    "tests/test_handlers.py": """
        import unittest

        from shop.api.handlers import Handlers
        from shop.domain.order import Order
        from shop.repository.order_repository import OrderRepository
        from shop.service.order_service import OrderService


        class HandlersTest(unittest.TestCase):
            def setUp(self):
                self.repo = OrderRepository()
                self.repo.add(Order("o1", "c1", 1000, "ch1"))
                self.handlers = Handlers(OrderService(self.repo))

            def test_get_order(self):
                self.assertEqual(self.handlers.get_order({"params": {"id": "o1"}})[0], 200)
                self.assertEqual(self.handlers.get_order({"params": {"id": "x"}})[0], 404)
    """,
    "tests/test_app.py": """
        import unittest

        from shop.app import build_app


        class AppTest(unittest.TestCase):
            def test_routes(self):
                routes, _ = build_app({"EMAIL_API_URL": "https://email.test"})
                self.assertIn(("GET", "/orders/{id}"), routes)
    """,
}

# WIP history: five commits that interleave the refund feature with a newsletter feature.
SHOP_WIP = [
    ("wip: refunds domain + service", {
        "shop/domain/errors.py": """
            class OrderNotFound(Exception):
                pass


            class RefundNotAllowed(Exception):
                pass
        """,
        "shop/domain/order.py": """
            from dataclasses import dataclass

            from shop.domain.errors import RefundNotAllowed


            @dataclass
            class Refund:
                id: str
                order_id: str
                amount: int


            @dataclass
            class Order:
                id: str
                customer_id: str
                total: int  # yen
                charge_id: str
                status: str = "paid"
                refunded: int = 0

                def refundable_amount(self):
                    return self.total - self.refunded

                def apply_refund(self, amount):
                    if amount > self.refundable_amount():
                        raise RefundNotAllowed(self.id)
                    self.refunded += amount
        """,
        "shop/service/refund_service.py": """
            from shop.domain.order import Refund


            class RefundService:
                def __init__(self, orders):
                    self._orders = orders

                def refund(self, order_id, amount):
                    order = self._orders.find(order_id)
                    order.apply_refund(amount)
                    return Refund(id="TODO", order_id=order.id, amount=amount)
        """,
    }),
    ("newsletter start", {
        "shop/clients/email_client.py": """
            from shop.clients.http import post_json


            class EmailClient:
                def __init__(self, base_url, transport=post_json):
                    if not base_url:
                        raise ValueError("email API URL is required")
                    self._base_url = base_url.rstrip("/")
                    self._transport = transport

                def send(self, to, subject, body):
                    status, _ = self._transport(f"{self._base_url}/messages", {"to": to, "subject": subject, "body": body})
                    return status == 202

                def send_newsletter(self, to, issue):
                    return self.send(to, f"Newsletter #{issue}", "Thanks for subscribing.")
        """,
        "shop/service/newsletter_service.py": """
            class NewsletterService:
                def __init__(self, email):
                    self._email = email
                    self._subscribers = set()

                def subscribe(self, address):
                    if address in self._subscribers:
                        return False
                    self._subscribers.add(address)
                    self._email.send_newsletter(address, 1)
                    return True
        """,
        "tests/test_newsletter_service.py": """
            import unittest

            from shop.clients.email_client import EmailClient
            from shop.service.newsletter_service import NewsletterService


            class NewsletterServiceTest(unittest.TestCase):
                def test_subscribe_sends_first_issue_once(self):
                    sent = []
                    email = EmailClient("https://email.test", transport=lambda url, p: (sent.append(p), (202, {}))[1])
                    service = NewsletterService(email)
                    self.assertTrue(service.subscribe("a@example.com"))
                    self.assertFalse(service.subscribe("a@example.com"))
                    self.assertEqual(len(sent), 1)
        """,
    }),
    ("payment client + wire refunds", {
        "shop/domain/errors.py": """
            class OrderNotFound(Exception):
                pass


            class RefundNotAllowed(Exception):
                pass


            class PaymentFailed(Exception):
                pass
        """,
        "shop/clients/payment_client.py": """
            from shop.clients.http import post_json
            from shop.domain.errors import PaymentFailed


            class PaymentClient:
                \"\"\"Client for the payment provider's refund API.\"\"\"

                def __init__(self, base_url, transport=post_json):
                    if not base_url:
                        raise ValueError("payment API URL is required")
                    self._base_url = base_url.rstrip("/")
                    self._transport = transport

                def refund(self, charge_id, amount):
                    status, body = self._transport(f"{self._base_url}/charges/{charge_id}/refunds", {"amount": amount})
                    if status != 201:
                        raise PaymentFailed(f"refund of {charge_id} failed with status {status}")
                    return body["refund_id"]
        """,
        "shop/service/refund_service.py": """
            from shop.domain.order import Refund


            class RefundService:
                def __init__(self, orders, payments):
                    self._orders = orders
                    self._payments = payments

                def refund(self, order_id, amount):
                    order = self._orders.find(order_id)
                    order.apply_refund(amount)
                    refund_id = self._payments.refund(order.charge_id, amount)
                    return Refund(id=refund_id, order_id=order.id, amount=amount)
        """,
        ".env.example": """
            EMAIL_API_URL=https://email.example.com
            PAYMENT_API_URL=https://payments.example.com
        """,
    }),
    ("handlers, list refunds, newsletter endpoint", {
        "shop/repository/order_repository.py": """
            from shop.domain.errors import OrderNotFound


            class OrderRepository:
                def __init__(self):
                    self._orders = {}
                    self._refunds = {}

                def add(self, order):
                    self._orders[order.id] = order

                def find(self, order_id):
                    if order_id not in self._orders:
                        raise OrderNotFound(order_id)
                    return self._orders[order_id]

                def save(self, order):
                    self._orders[order.id] = order

                def save_refund(self, refund):
                    self._refunds.setdefault(refund.order_id, []).append(refund)

                def list_refunds(self, order_id):
                    return list(self._refunds.get(order_id, []))

                def count_refunds(self, order_id):
                    return len(self._refunds.get(order_id, []))
        """,
        "shop/service/refund_service.py": """
            from shop.domain.order import Refund


            class RefundService:
                def __init__(self, orders, payments):
                    self._orders = orders
                    self._payments = payments

                def refund(self, order_id, amount):
                    \"\"\"Refunds part or all of an order through the payment provider.\"\"\"
                    order = self._orders.find(order_id)
                    order.apply_refund(amount)
                    refund_id = self._payments.refund(order.charge_id, amount)
                    refund = Refund(id=refund_id, order_id=order.id, amount=amount)
                    self._orders.save(order)
                    self._orders.save_refund(refund)
                    return refund

                def list_refunds(self, order_id):
                    self._orders.find(order_id)
                    return self._orders.list_refunds(order_id)
        """,
        "shop/api/handlers.py": """
            from shop.domain.errors import OrderNotFound, PaymentFailed, RefundNotAllowed


            class Handlers:
                def __init__(self, order_service, refund_service, newsletter_service):
                    self._orders = order_service
                    self._refunds = refund_service
                    self._newsletter = newsletter_service

                def get_order(self, request):
                    try:
                        order = self._orders.get_order(request["params"]["id"])
                    except OrderNotFound:
                        return 404, {"error": "order not found"}
                    return 200, {"id": order.id, "total": order.total, "status": order.status}

                def post_refund(self, request):
                    try:
                        refund = self._refunds.refund(request["params"]["id"], int(request["body"]["amount"]))
                    except OrderNotFound:
                        return 404, {"error": "order not found"}
                    except RefundNotAllowed as e:
                        return 409, {"error": str(e)}
                    except PaymentFailed:
                        return 502, {"error": "payment provider failed"}
                    return 201, {"refund_id": refund.id, "amount": refund.amount}

                def get_refunds(self, request):
                    try:
                        refunds = self._refunds.list_refunds(request["params"]["id"])
                    except OrderNotFound:
                        return 404, {"error": "order not found"}
                    return 200, {"refunds": [{"id": r.id, "amount": r.amount} for r in refunds]}

                def subscribe(self, request):
                    created = self._newsletter.subscribe(request["body"]["email"])
                    return (201 if created else 200), {}
        """,
        "shop/app.py": """
            from shop.api.handlers import Handlers
            from shop.clients.email_client import EmailClient
            from shop.clients.payment_client import PaymentClient
            from shop.repository.order_repository import OrderRepository
            from shop.service.newsletter_service import NewsletterService
            from shop.service.order_service import OrderService
            from shop.service.refund_service import RefundService


            def build_app(env):
                orders = OrderRepository()
                email = EmailClient(env["EMAIL_API_URL"])
                payments = PaymentClient(env["PAYMENT_API_URL"])
                handlers = Handlers(
                    OrderService(orders),
                    RefundService(orders, payments),
                    NewsletterService(email),
                )
                routes = {
                    ("GET", "/orders/{id}"): handlers.get_order,
                    ("POST", "/orders/{id}/refunds"): handlers.post_refund,
                    ("GET", "/orders/{id}/refunds"): handlers.get_refunds,
                    ("POST", "/newsletter/subscriptions"): handlers.subscribe,
                }
                return routes, orders
        """,
    }),
    ("fix refund rules, tests", {
        "shop/domain/order.py": """
            from dataclasses import dataclass

            from shop.domain.errors import RefundNotAllowed


            @dataclass
            class Refund:
                id: str
                order_id: str
                amount: int


            @dataclass
            class Order:
                id: str
                customer_id: str
                total: int  # yen
                charge_id: str
                status: str = "paid"
                refunded: int = 0

                def refundable_amount(self):
                    \"\"\"What can still be refunded: the total less what earlier refunds returned.\"\"\"
                    if self.status not in ("paid", "partially_refunded"):
                        return 0
                    return self.total - self.refunded

                def apply_refund(self, amount):
                    if amount <= 0 or amount > self.refundable_amount():
                        raise RefundNotAllowed(f"order {self.id} cannot refund {amount}")
                    self.refunded += amount
                    self.status = "refunded" if self.refunded == self.total else "partially_refunded"
        """,
        "tests/test_order.py": """
            import unittest

            from shop.domain.errors import RefundNotAllowed
            from shop.domain.order import Order


            class OrderRefundTest(unittest.TestCase):
                def test_partial_then_full_refund(self):
                    order = Order("o1", "c1", 1000, "ch1")
                    order.apply_refund(400)
                    self.assertEqual(order.status, "partially_refunded")
                    self.assertEqual(order.refundable_amount(), 600)
                    order.apply_refund(600)
                    self.assertEqual(order.status, "refunded")
                    self.assertEqual(order.refundable_amount(), 0)

                def test_refund_beyond_total_or_non_positive(self):
                    order = Order("o1", "c1", 1000, "ch1")
                    for amount in (0, -1, 1001):
                        with self.assertRaises(RefundNotAllowed):
                            order.apply_refund(amount)
        """,
        "tests/test_order_repository.py": """
            import unittest

            from shop.domain.errors import OrderNotFound
            from shop.domain.order import Order, Refund
            from shop.repository.order_repository import OrderRepository


            class OrderRepositoryTest(unittest.TestCase):
                def test_find(self):
                    repo = OrderRepository()
                    repo.add(Order("o1", "c1", 1000, "ch1"))
                    self.assertEqual(repo.find("o1").total, 1000)
                    with self.assertRaises(OrderNotFound):
                        repo.find("nope")

                def test_refunds_are_kept_per_order(self):
                    repo = OrderRepository()
                    repo.save_refund(Refund("r1", "o1", 100))
                    repo.save_refund(Refund("r2", "o1", 200))
                    self.assertEqual([r.id for r in repo.list_refunds("o1")], ["r1", "r2"])
                    self.assertEqual(repo.list_refunds("o2"), [])
        """,
        "tests/test_payment_client.py": """
            import unittest

            from shop.clients.payment_client import PaymentClient
            from shop.domain.errors import PaymentFailed


            class PaymentClientTest(unittest.TestCase):
                def test_refund_posts_to_the_charge(self):
                    calls = []
                    client = PaymentClient("https://pay.test/", transport=lambda url, p: (calls.append((url, p)), (201, {"refund_id": "r1"}))[1])
                    self.assertEqual(client.refund("ch1", 500), "r1")
                    self.assertEqual(calls, [("https://pay.test/charges/ch1/refunds", {"amount": 500})])

                def test_refund_failure(self):
                    client = PaymentClient("https://pay.test", transport=lambda url, p: (500, {}))
                    with self.assertRaises(PaymentFailed):
                        client.refund("ch1", 500)

                def test_requires_url(self):
                    with self.assertRaises(ValueError):
                        PaymentClient("")
        """,
        "tests/test_refund_service.py": """
            import unittest

            from shop.domain.errors import OrderNotFound, RefundNotAllowed
            from shop.domain.order import Order
            from shop.repository.order_repository import OrderRepository
            from shop.service.refund_service import RefundService


            class FakePayments:
                def __init__(self):
                    self.calls = []

                def refund(self, charge_id, amount):
                    self.calls.append((charge_id, amount))
                    return f"r{len(self.calls)}"


            class RefundServiceTest(unittest.TestCase):
                def setUp(self):
                    self.repo = OrderRepository()
                    self.repo.add(Order("o1", "c1", 1000, "ch1"))
                    self.payments = FakePayments()
                    self.service = RefundService(self.repo, self.payments)

                def test_refund_charges_back_and_records(self):
                    refund = self.service.refund("o1", 300)
                    self.assertEqual(refund.id, "r1")
                    self.assertEqual(self.payments.calls, [("ch1", 300)])
                    self.assertEqual(self.repo.find("o1").refunded, 300)

                def test_refund_not_allowed_never_reaches_the_provider(self):
                    with self.assertRaises(RefundNotAllowed):
                        self.service.refund("o1", 5000)
                    self.assertEqual(self.payments.calls, [])

                def test_list_refunds(self):
                    self.service.refund("o1", 100)
                    self.service.refund("o1", 200)
                    self.assertEqual([r.amount for r in self.service.list_refunds("o1")], [100, 200])
                    with self.assertRaises(OrderNotFound):
                        self.service.list_refunds("nope")
        """,
        "tests/test_handlers.py": """
            import unittest

            from shop.api.handlers import Handlers
            from shop.clients.email_client import EmailClient
            from shop.domain.errors import PaymentFailed
            from shop.domain.order import Order
            from shop.repository.order_repository import OrderRepository
            from shop.service.newsletter_service import NewsletterService
            from shop.service.order_service import OrderService
            from shop.service.refund_service import RefundService


            class Payments:
                fail = False

                def refund(self, charge_id, amount):
                    if self.fail:
                        raise PaymentFailed(charge_id)
                    return "r1"


            class HandlersTest(unittest.TestCase):
                def setUp(self):
                    self.repo = OrderRepository()
                    self.repo.add(Order("o1", "c1", 1000, "ch1"))
                    self.payments = Payments()
                    email = EmailClient("https://email.test", transport=lambda url, p: (202, {}))
                    self.handlers = Handlers(
                        OrderService(self.repo),
                        RefundService(self.repo, self.payments),
                        NewsletterService(email),
                    )

                def test_get_order(self):
                    self.assertEqual(self.handlers.get_order({"params": {"id": "o1"}})[0], 200)
                    self.assertEqual(self.handlers.get_order({"params": {"id": "x"}})[0], 404)

                def test_post_refund(self):
                    req = lambda oid, amt: {"params": {"id": oid}, "body": {"amount": amt}}
                    self.assertEqual(self.handlers.post_refund(req("o1", "300")), (201, {"refund_id": "r1", "amount": 300}))
                    self.assertEqual(self.handlers.post_refund(req("o1", "5000"))[0], 409)
                    self.assertEqual(self.handlers.post_refund(req("x", "1"))[0], 404)
                    self.payments.fail = True
                    self.assertEqual(self.handlers.post_refund(req("o1", "1"))[0], 502)

                def test_get_refunds(self):
                    self.handlers.post_refund({"params": {"id": "o1"}, "body": {"amount": "100"}})
                    self.assertEqual(self.handlers.get_refunds({"params": {"id": "o1"}}), (200, {"refunds": [{"id": "r1", "amount": 100}]}))
                    self.assertEqual(self.handlers.get_refunds({"params": {"id": "x"}})[0], 404)

                def test_subscribe(self):
                    self.assertEqual(self.handlers.subscribe({"body": {"email": "a@example.com"}})[0], 201)
                    self.assertEqual(self.handlers.subscribe({"body": {"email": "a@example.com"}})[0], 200)
        """,
        "tests/test_app.py": """
            import unittest

            from shop.app import build_app


            class AppTest(unittest.TestCase):
                def test_routes(self):
                    routes, _ = build_app({"EMAIL_API_URL": "https://email.test", "PAYMENT_API_URL": "https://pay.test"})
                    for route in [
                        ("GET", "/orders/{id}"),
                        ("POST", "/orders/{id}/refunds"),
                        ("GET", "/orders/{id}/refunds"),
                        ("POST", "/newsletter/subscriptions"),
                    ]:
                        self.assertIn(route, routes)
        """,
    }),
]

# ------------------------------------------------------------------------------------------- billing
BILLING_BASE = {
    "package.json": """
        {
          "name": "billing",
          "private": true,
          "scripts": { "build": "tsc -p .", "test": "vitest run" },
          "dependencies": { "express": "^4.19.2", "pg": "^8.12.0" },
          "devDependencies": { "typescript": "^5.5.4", "vitest": "^2.0.5" }
        }
    """,
    "tsconfig.json": """
        { "compilerOptions": { "strict": true, "outDir": "dist", "module": "commonjs", "target": "es2022" }, "include": ["src"] }
    """,
    "src/entities/invoice.ts": """
        export type InvoiceStatus = "open" | "paid" | "void";

        export interface Invoice {
          id: string;
          customerId: string;
          amountDue: number;
          dueDate: Date;
          status: InvoiceStatus;
        }
    """,
    "src/entities/customer.ts": """
        export interface Customer {
          id: string;
          email: string;
          phone?: string;
        }
    """,
    "src/db/invoiceStore.ts": """
        import { Pool } from "pg";
        import { Invoice } from "../entities/invoice";

        export class InvoiceStore {
          constructor(private readonly pool: Pool) {}

          async get(id: string): Promise<Invoice | undefined> {
            const { rows } = await this.pool.query("SELECT * FROM invoices WHERE id = $1", [id]);
            return rows[0];
          }
        }
    """,
    "src/db/customerStore.ts": """
        import { Pool } from "pg";
        import { Customer } from "../entities/customer";

        export class CustomerStore {
          constructor(private readonly pool: Pool) {}

          async get(id: string): Promise<Customer | undefined> {
            const { rows } = await this.pool.query("SELECT * FROM customers WHERE id = $1", [id]);
            return rows[0];
          }
        }
    """,
    "src/integrations/mailer.ts": """
        export class Mailer {
          constructor(private readonly apiKey: string) {}

          async send(to: string, subject: string, text: string): Promise<void> {
            await fetch("https://mail.example.com/send", {
              method: "POST",
              headers: { authorization: `Bearer ${this.apiKey}` },
              body: JSON.stringify({ to, subject, text }),
            });
          }
        }
    """,
    "src/routes/invoices.ts": """
        import { Router } from "express";
        import { InvoiceStore } from "../db/invoiceStore";

        export function invoiceRoutes(invoices: InvoiceStore): Router {
          const router = Router();
          router.get("/invoices/:id", async (req, res) => {
            const invoice = await invoices.get(req.params.id);
            if (!invoice) return res.status(404).end();
            res.json(invoice);
          });
          return router;
        }
    """,
    "src/ui/theme.ts": """
        export const theme = { background: "#ffffff", text: "#111111" };
    """,
    "src/container.ts": """
        import { Pool } from "pg";
        import { CustomerStore } from "./db/customerStore";
        import { InvoiceStore } from "./db/invoiceStore";
        import { Mailer } from "./integrations/mailer";

        export function buildContainer(env: NodeJS.ProcessEnv) {
          const pool = new Pool({ connectionString: env.DATABASE_URL });
          return {
            invoices: new InvoiceStore(pool),
            customers: new CustomerStore(pool),
            mailer: new Mailer(env.MAIL_API_KEY ?? ""),
          };
        }
    """,
    "src/server.ts": """
        import express from "express";
        import { buildContainer } from "./container";
        import { invoiceRoutes } from "./routes/invoices";

        const c = buildContainer(process.env);
        const app = express();
        app.use(invoiceRoutes(c.invoices));
        app.listen(Number(process.env.PORT ?? 3000));
    """,
}

BILLING_WIP = [
    ("reminders wip", {
        "src/entities/invoice.ts": """
            export type InvoiceStatus = "open" | "paid" | "void";

            export interface Invoice {
              id: string;
              customerId: string;
              amountDue: number;
              dueDate: Date;
              status: InvoiceStatus;
              lastRemindedAt?: Date;
            }

            const REMIND_EVERY_MS = 3 * 24 * 60 * 60 * 1000;

            /** An open, overdue invoice gets a reminder at most once every three days. */
            export function isDueForReminder(invoice: Invoice, now: Date): boolean {
              if (invoice.status !== "open" || invoice.dueDate > now) return false;
              if (!invoice.lastRemindedAt) return true;
              return now.getTime() - invoice.lastRemindedAt.getTime() >= REMIND_EVERY_MS;
            }
        """,
        "src/db/invoiceStore.ts": """
            import { Pool } from "pg";
            import { Invoice } from "../entities/invoice";

            export class InvoiceStore {
              constructor(private readonly pool: Pool) {}

              async get(id: string): Promise<Invoice | undefined> {
                const { rows } = await this.pool.query("SELECT * FROM invoices WHERE id = $1", [id]);
                return rows[0];
              }

              async listOverdue(now: Date): Promise<Invoice[]> {
                const { rows } = await this.pool.query("SELECT * FROM invoices WHERE status = 'open' AND due_date <= $1", [now]);
                return rows;
              }

              async markReminded(id: string, at: Date): Promise<void> {
                await this.pool.query("UPDATE invoices SET last_reminded_at = $2 WHERE id = $1", [id, at]);
              }
            }
        """,
        "src/services/reminderService.ts": """
            import { CustomerStore } from "../db/customerStore";
            import { InvoiceStore } from "../db/invoiceStore";
            import { Invoice, isDueForReminder } from "../entities/invoice";
            import { Mailer } from "../integrations/mailer";
            import { SmsClient } from "../integrations/sms/smsClient";

            export class ReminderService {
              constructor(
                private readonly invoices: InvoiceStore,
                private readonly customers: CustomerStore,
                private readonly mailer: Mailer,
                private readonly sms: SmsClient,
              ) {}

              /** Reminds every customer with an overdue invoice; returns how many were reminded. */
              async remindOverdue(now: Date): Promise<number> {
                const due = (await this.invoices.listOverdue(now)).filter((i) => isDueForReminder(i, now));
                for (const invoice of due) await this.remind(invoice, now);
                return due.length;
              }

              /** Reminds one invoice's customer now, whatever the schedule says. */
              async remindNow(invoiceId: string, now: Date): Promise<boolean> {
                const invoice = await this.invoices.get(invoiceId);
                if (!invoice || invoice.status !== "open") return false;
                await this.remind(invoice, now);
                return true;
              }

              private async remind(invoice: Invoice, now: Date): Promise<void> {
                const customer = await this.customers.get(invoice.customerId);
                if (!customer) return;
                const text = `Invoice ${invoice.id} for ${invoice.amountDue} is overdue.`;
                await this.mailer.send(customer.email, "Payment reminder", text);
                if (customer.phone) await this.sms.send(customer.phone, text);
                await this.invoices.markReminded(invoice.id, now);
              }
            }
        """,
    }),
    ("dark mode", {
        "src/ui/theme.ts": """
            import Color from "color";

            const base = { background: "#ffffff", text: "#111111" };

            export const theme = base;
            export const darkTheme = {
              background: Color(base.background).negate().hex(),
              text: Color(base.text).negate().hex(),
            };
        """,
        "package.json": """
            {
              "name": "billing",
              "private": true,
              "scripts": { "build": "tsc -p .", "test": "vitest run" },
              "dependencies": { "color": "^4.2.3", "express": "^4.19.2", "pg": "^8.12.0" },
              "devDependencies": { "typescript": "^5.5.4", "vitest": "^2.0.5" }
            }
        """,
    }),
    ("sms client, job, route, wiring", {
        "src/integrations/sms/smsClient.ts": """
            import twilio from "twilio";

            /** Sends text messages through Twilio. */
            export class SmsClient {
              private readonly client: ReturnType<typeof twilio>;

              constructor(accountSid: string, authToken: string, private readonly from: string) {
                if (!accountSid || !authToken || !from) throw new Error("Twilio credentials are required");
                this.client = twilio(accountSid, authToken);
              }

              async send(to: string, body: string): Promise<void> {
                await this.client.messages.create({ to, from: this.from, body });
              }
            }
        """,
        "src/jobs/sendReminders.ts": """
            import { buildContainer } from "../container";

            /** Cron entrypoint: `node dist/jobs/sendReminders.js`, scheduled daily. */
            async function main() {
              const c = buildContainer(process.env);
              const reminded = await c.reminders.remindOverdue(new Date());
              console.log(JSON.stringify({ msg: "reminders sent", reminded }));
            }

            main().catch((err) => {
              console.error(err);
              process.exit(1);
            });
        """,
        "src/routes/reminders.ts": """
            import { Router } from "express";
            import { ReminderService } from "../services/reminderService";

            export function reminderRoutes(reminders: ReminderService): Router {
              const router = Router();
              router.post("/invoices/:id/reminders", async (req, res) => {
                const sent = await reminders.remindNow(req.params.id, new Date());
                res.status(sent ? 202 : 404).end();
              });
              return router;
            }
        """,
        "src/container.ts": """
            import { Pool } from "pg";
            import { CustomerStore } from "./db/customerStore";
            import { InvoiceStore } from "./db/invoiceStore";
            import { Mailer } from "./integrations/mailer";
            import { SmsClient } from "./integrations/sms/smsClient";
            import { ReminderService } from "./services/reminderService";

            export function buildContainer(env: NodeJS.ProcessEnv) {
              const pool = new Pool({ connectionString: env.DATABASE_URL });
              const invoices = new InvoiceStore(pool);
              const customers = new CustomerStore(pool);
              const mailer = new Mailer(env.MAIL_API_KEY ?? "");
              const sms = new SmsClient(env.TWILIO_ACCOUNT_SID ?? "", env.TWILIO_AUTH_TOKEN ?? "", env.TWILIO_FROM ?? "");
              return {
                invoices,
                customers,
                mailer,
                reminders: new ReminderService(invoices, customers, mailer, sms),
              };
            }
        """,
        "src/server.ts": """
            import express from "express";
            import { buildContainer } from "./container";
            import { invoiceRoutes } from "./routes/invoices";
            import { reminderRoutes } from "./routes/reminders";

            const c = buildContainer(process.env);
            const app = express();
            app.use(invoiceRoutes(c.invoices));
            app.use(reminderRoutes(c.reminders));
            app.listen(Number(process.env.PORT ?? 3000));
        """,
        "package.json": """
            {
              "name": "billing",
              "private": true,
              "scripts": { "build": "tsc -p .", "test": "vitest run" },
              "dependencies": { "color": "^4.2.3", "express": "^4.19.2", "pg": "^8.12.0", "twilio": "^5.2.2" },
              "devDependencies": { "typescript": "^5.5.4", "vitest": "^2.0.5" }
            }
        """,
    }),
    ("dark mode toggle + reminder tests", {
        "src/ui/themeToggle.ts": """
            import { darkTheme, theme } from "./theme";

            export function pickTheme(prefersDark: boolean) {
              return prefersDark ? darkTheme : theme;
            }
        """,
        "src/entities/invoice.test.ts": """
            import { describe, expect, it } from "vitest";
            import { Invoice, isDueForReminder } from "./invoice";

            const day = 24 * 60 * 60 * 1000;
            const now = new Date("2026-09-10T00:00:00Z");
            const overdue: Invoice = { id: "i1", customerId: "c1", amountDue: 100, dueDate: new Date(now.getTime() - day), status: "open" };

            describe("isDueForReminder", () => {
              it("reminds an overdue open invoice never reminded", () => expect(isDueForReminder(overdue, now)).toBe(true));
              it("waits three days between reminders", () => {
                expect(isDueForReminder({ ...overdue, lastRemindedAt: new Date(now.getTime() - 2 * day) }, now)).toBe(false);
                expect(isDueForReminder({ ...overdue, lastRemindedAt: new Date(now.getTime() - 3 * day) }, now)).toBe(true);
              });
              it("skips paid and not-yet-due invoices", () => {
                expect(isDueForReminder({ ...overdue, status: "paid" }, now)).toBe(false);
                expect(isDueForReminder({ ...overdue, dueDate: new Date(now.getTime() + day) }, now)).toBe(false);
              });
            });
        """,
        "src/services/reminderService.test.ts": """
            import { describe, expect, it, vi } from "vitest";
            import { ReminderService } from "./reminderService";

            describe("ReminderService", () => {
              it("mails, texts and marks each due invoice", async () => {
                const now = new Date("2026-09-10T00:00:00Z");
                const invoice = { id: "i1", customerId: "c1", amountDue: 100, dueDate: new Date("2026-09-01"), status: "open" as const };
                const invoices = { get: vi.fn(), listOverdue: vi.fn().mockResolvedValue([invoice]), markReminded: vi.fn() };
                const customers = { get: vi.fn().mockResolvedValue({ id: "c1", email: "a@example.com", phone: "+8190" }) };
                const mailer = { send: vi.fn() };
                const sms = { send: vi.fn() };
                const s = new ReminderService(invoices as never, customers as never, mailer as never, sms as never);
                expect(await s.remindOverdue(now)).toBe(1);
                expect(mailer.send).toHaveBeenCalledOnce();
                expect(sms.send).toHaveBeenCalledWith("+8190", expect.any(String));
                expect(invoices.markReminded).toHaveBeenCalledWith("i1", now);
              });
            });
        """,
    }),
]

FIXTURES = {"shop": (SHOP_BASE, SHOP_WIP), "billing": (BILLING_BASE, BILLING_WIP)}


def main():
    dest, name = sys.argv[1], sys.argv[2]
    base, wip = FIXTURES[name]
    remote = os.path.join(dest, "remote.git")
    repo = os.path.join(dest, "repo")
    os.makedirs(dest, exist_ok=True)
    sh(dest, "git", "init", "-q", "--bare", "-b", "main", remote)
    sh(dest, "git", "init", "-q", "-b", "main", repo)
    sh(repo, "git", "config", "user.name", "Fixture")
    sh(repo, "git", "config", "user.email", "fixture@example.com")
    sh(repo, "git", "remote", "add", "origin", remote)
    write(repo, base)
    commit(repo, "initial app")
    sh(repo, "git", "branch", "integration")
    sh(repo, "git", "switch", "-q", "-c", "wip")
    for msg, files in wip:
        write(repo, files)
        commit(repo, msg)
    sh(repo, "git", "push", "-q", "origin", "main", "integration", "wip")
    sh(repo, "git", "switch", "-q", "main")
    print(repo)


if __name__ == "__main__":
    main()
