"""The `assist` fixture: a first slice whose WIP file carries leftovers from the code the slice trims away.

Reproduces traps seen splitting a real branch: a customer-token path to trim out of the adapter, a test
that only meant something beside that path, a comment explaining a constant by a cache in a later slice,
a hand-written type the base has since shipped, and test/env support that only later slices need.
"""

ASSIST_BASE = {
    "README.md": """
        # assist

        Help assistant backend. Layers: `assist/clients` (external APIs), `assist/service` (application
        logic), `assist/api` (HTTP handlers), `assist/app.py` (wiring), `assist/settings.py` (env flags).
        `assist_contracts/` is the vendored generated contract package; the contracts team bumps it, never
        edit it here.

        Test: `python3 -m unittest discover -s tests -t .`
    """,
    ".gitignore": """
        __pycache__/
    """,
    ".env.example": """
        GATEWAY_URL=https://gateway.example.com
    """,
    "assist/__init__.py": "",
    "assist/settings.py": """
        import os

        ENV = os.environ.get("ASSIST_ENV", "development")
    """,
    "assist/clients/__init__.py": "",
    "assist/clients/http.py": """
        class Session:
            \"\"\"Authenticated HTTP session to the gateway.\"\"\"

            def __init__(self, base_url, headers=None):
                self.base_url = base_url.rstrip("/")
                self.headers = dict(headers or {})

            def post(self, path, json, timeout):
                raise NotImplementedError("no network in this repo's tests")
    """,
    "assist/service/__init__.py": "",
    "assist/service/greeting_service.py": """
        class GreetingService:
            def greet(self, name):
                return f"Hello, {name}."
    """,
    "assist/api/__init__.py": "",
    "assist/api/handlers.py": """
        class Handlers:
            def __init__(self, greetings):
                self._greetings = greetings

            def get_greeting(self, request):
                return 200, {"text": self._greetings.greet(request["query"]["name"])}
    """,
    "assist/app.py": """
        from assist.api.handlers import Handlers
        from assist.service.greeting_service import GreetingService


        def build_app(env):
            handlers = Handlers(GreetingService())
            return {("GET", "/greeting"): handlers.get_greeting}
    """,
    "assist_contracts/__init__.py": """
        \"\"\"Generated from the gateway's contract. Do not edit; bumped by the contracts team.\"\"\"
        from dataclasses import dataclass

        VERSION = "1.4"


        @dataclass
        class Greeting:
            text: str
    """,
    "tests/__init__.py": "",
    "tests/helpers.py": """
        class FakeHTTP:
            \"\"\"Records posts and answers each with the same body.\"\"\"

            def __init__(self, body):
                self.body = body
                self.calls = []

            def post(self, path, json, timeout):
                self.calls.append({"path": path, "json": json, "timeout": timeout})
                return self.body
    """,
    "tests/test_app.py": """
        import unittest

        from assist.app import build_app


        class AppTest(unittest.TestCase):
            def test_routes(self):
                routes = build_app({"GATEWAY_URL": "https://gw.test"})
                self.assertIn(("GET", "/greeting"), routes)
    """,
}

# Lands on `integration` after `wip` forked, so the WIP branch never saw it.
ASSIST_BASE_LATER = [
    ("bump assist_contracts to 1.5 (ToolSpec, contracts#88)", {
        "assist_contracts/__init__.py": """
            \"\"\"Generated from the gateway's contract. Do not edit; bumped by the contracts team.\"\"\"
            from dataclasses import dataclass

            VERSION = "1.5"


            @dataclass
            class Greeting:
                text: str


            @dataclass
            class ToolSpec:
                name: str
                description: str
                parameters_schema: str  # a serialized JSON Schema object
        """,
    }),
]

_BODY = '{"tools": [{"name": "get_balance", "description": "Balance", "parameters_schema": "{}"}], "result": "{}"}'

ASSIST_WIP = [
    ("wip: catalog client", {
        "assist/clients/catalog_client.py": """
            import json
            from dataclasses import dataclass

            from assist.clients.http import Session  # noqa: F401


            @dataclass
            class ToolSpec:
                \"\"\"Written by hand until assist_contracts 1.5 ships ToolSpec (contracts#88).\"\"\"

                name: str
                description: str
                parameters_schema: str


            class CatalogClient:
                def __init__(self, session):
                    self._session = session

                def list_tools(self):
                    body = self._session.post("v1/list_tools", json={}, timeout=5)
                    return [ToolSpec(**t) for t in body.get("tools", [])]

                def call_tool(self, name, parameters):
                    body = self._session.post("v1/call_tool", json={"name": name, "parameters": json.dumps(parameters)}, timeout=10)
                    return body["result"]
        """,
        "tests/test_catalog_client.py": f"""
            import unittest

            from assist.clients.catalog_client import CatalogClient
            from tests.helpers import FakeHTTP

            BODY = {_BODY}


            class CatalogClientTest(unittest.TestCase):
                def test_parses_the_catalog(self):
                    tools = CatalogClient(FakeHTTP(BODY)).list_tools()
                    self.assertEqual([t.name for t in tools], ["get_balance"])
        """,
    }),
    ("wip: catalog cache, ask service, live flag", {
        "assist/settings.py": """
            import os

            ENV = os.environ.get("ASSIST_ENV", "development")

            # Off in tests and local runs so nothing reaches the model; the live assistant opts in with ASSIST_LIVE=1.
            LIVE_MODEL = os.environ.get("ASSIST_LIVE") == "1"
        """,
        "assist/service/catalog.py": """
            class ToolCatalog:
                \"\"\"The tool list, read once per process: it only changes on a deploy.\"\"\"

                def __init__(self, client):
                    self._client = client
                    self._tools = None

                def tools(self):
                    if self._tools is None:
                        self._tools = self._client.list_tools()
                    return self._tools
        """,
        "assist/service/ask_service.py": """
            from assist import settings


            class AskService:
                def __init__(self, catalog, client):
                    self._catalog = catalog
                    self._client = client

                def ask(self, question):
                    tools = self._catalog.tools()
                    if not settings.LIVE_MODEL:
                        return {"answer": f"(scripted) {len(tools)} tools available", "tools": [t.name for t in tools]}
                    for tool in tools:
                        if tool.name in question:
                            return {"answer": self._client.call_tool(tool.name, {"question": question}), "tools": [tool.name]}
                    return {"answer": "I can't help with that yet.", "tools": []}
        """,
        "tests/test_catalog.py": f"""
            import unittest

            from assist.clients.catalog_client import CatalogClient
            from assist.service.catalog import ToolCatalog
            from tests.helpers import FakeHTTP

            BODY = {_BODY}


            class ToolCatalogTest(unittest.TestCase):
                def test_reads_the_catalog_once(self):
                    http = FakeHTTP(BODY)
                    catalog = ToolCatalog(CatalogClient(http))
                    catalog.tools()
                    catalog.tools()
                    self.assertEqual(len(http.calls), 1)
        """,
        "tests/test_ask_service.py": """
            import unittest
            from unittest import mock

            from assist import settings
            from assist.clients.catalog_client import CatalogClient
            from assist.service.ask_service import AskService
            from assist.service.catalog import ToolCatalog
            from tests.helpers import FakeHTTP


            class AskServiceTest(unittest.TestCase):
                def setUp(self):
                    http = FakeHTTP({"tools": [{"name": "get_balance", "description": "Balance", "parameters_schema": "{}"}], "result": '{"gb": 3}'})
                    client = CatalogClient(http)
                    self.service = AskService(ToolCatalog(client), client)

                def test_scripted_unless_live(self):
                    with mock.patch.object(settings, "LIVE_MODEL", False):
                        self.assertTrue(self.service.ask("get_balance please")["answer"].startswith("(scripted)"))

                def test_live_calls_the_named_tool(self):
                    with mock.patch.object(settings, "LIVE_MODEL", True):
                        self.assertEqual(self.service.ask("get_balance please")["answer"], '{"gb": 3}')
        """,
    }),
    ("debug: let a developer drive the catalog with their own token", {
        "assist/clients/debug.py": """
            def debug_headers():
                \"\"\"Marks a request as coming from a developer's command line, so the gateway skips DPoP.\"\"\"
                return {"X-Debug-Client": "cli"}
        """,
        "assist/clients/catalog_client.py": """
            import json
            import os
            from dataclasses import dataclass

            from assist.clients.debug import debug_headers
            from assist.clients.http import Session

            # One tool call gates the whole answer, so it gets a longer budget than a plain read.
            CALL_TIMEOUT = 10
            # Read once per process by the ToolCatalog cache in assist/service/catalog.py, so no later request pays for it.
            LIST_TIMEOUT = 5


            @dataclass
            class ToolSpec:
                \"\"\"Written by hand until assist_contracts 1.5 ships ToolSpec (contracts#88).\"\"\"

                name: str
                description: str
                parameters_schema: str


            class CatalogClient:
                \"\"\"The gateway's tool catalog: which tools exist, and calling one.\"\"\"

                def __init__(self, session, token_session=None):
                    self._session = session
                    self._token_session = token_session or _token_session

                def _pick(self, customer_token):
                    # A developer driving the assistant from the command line brings their own token.
                    return self._token_session(customer_token) if customer_token else self._session

                def list_tools(self, customer_token=None):
                    body = self._pick(customer_token).post("v1/list_tools", json={}, timeout=LIST_TIMEOUT)
                    return [ToolSpec(**t) for t in body.get("tools", [])]

                def call_tool(self, name, parameters, customer_token=None):
                    body = self._pick(customer_token).post(
                        "v1/call_tool",
                        json={"name": name, "parameters": json.dumps(parameters)},
                        timeout=CALL_TIMEOUT,
                    )
                    return body["result"]


            def _token_session(customer_token):
                return Session(os.environ["ASSIST_DEBUG_URL"], headers={**debug_headers(), "Authorization": customer_token})
        """,
        "tests/helpers.py": """
            import contextlib
            import os


            class FakeHTTP:
                \"\"\"Records posts and answers each with the same body.\"\"\"

                def __init__(self, body):
                    self.body = body
                    self.calls = []

                def post(self, path, json, timeout):
                    self.calls.append({"path": path, "json": json, "timeout": timeout})
                    return self.body


            @contextlib.contextmanager
            def with_env(**values):
                \"\"\"Sets env vars for the block and restores what was there.\"\"\"
                saved = {k: os.environ.get(k) for k in values}
                os.environ.update(values)
                try:
                    yield
                finally:
                    for k, v in saved.items():
                        if v is None:
                            os.environ.pop(k, None)
                        else:
                            os.environ[k] = v
        """,
        "tests/test_catalog_client.py": f"""
            import unittest

            from assist.clients.catalog_client import CatalogClient, _token_session
            from tests.helpers import FakeHTTP, with_env

            BODY = {_BODY}


            class CatalogClientTest(unittest.TestCase):
                def test_uses_the_session_unless_a_token_is_given(self):
                    session, token = FakeHTTP(BODY), FakeHTTP(BODY)
                    client = CatalogClient(session, token_session=lambda t: token)
                    client.list_tools()
                    client.call_tool("get_balance", {{}})
                    self.assertEqual(len(session.calls), 2)
                    client.list_tools(customer_token="t")
                    self.assertEqual(len(token.calls), 1)

                def test_token_session_reads_the_debug_url(self):
                    with with_env(ASSIST_DEBUG_URL="https://debug.test"):
                        session = _token_session("t")
                    self.assertEqual(session.base_url, "https://debug.test")
                    self.assertEqual(session.headers["Authorization"], "t")

                def test_parses_the_catalog(self):
                    tools = CatalogClient(FakeHTTP(BODY)).list_tools()
                    self.assertEqual([t.name for t in tools], ["get_balance"])
        """,
    }),
    ("ask endpoint and wiring", {
        "assist/api/handlers.py": """
            class Handlers:
                def __init__(self, greetings, ask):
                    self._greetings = greetings
                    self._ask = ask

                def get_greeting(self, request):
                    return 200, {"text": self._greetings.greet(request["query"]["name"])}

                def post_ask(self, request):
                    return 200, self._ask.ask(request["body"]["question"])
        """,
        "assist/app.py": """
            from assist.api.handlers import Handlers
            from assist.clients.catalog_client import CatalogClient
            from assist.clients.http import Session
            from assist.service.ask_service import AskService
            from assist.service.catalog import ToolCatalog
            from assist.service.greeting_service import GreetingService


            def build_app(env):
                catalog_client = CatalogClient(Session(env["GATEWAY_URL"]))
                handlers = Handlers(GreetingService(), AskService(ToolCatalog(catalog_client), catalog_client))
                return {
                    ("GET", "/greeting"): handlers.get_greeting,
                    ("POST", "/ask"): handlers.post_ask,
                }
        """,
        ".env.example": """
            GATEWAY_URL=https://gateway.example.com
            ASSIST_LIVE=0
        """,
        "tests/test_app.py": """
            import unittest

            from assist.app import build_app


            class AppTest(unittest.TestCase):
                def test_routes(self):
                    routes = build_app({"GATEWAY_URL": "https://gw.test"})
                    self.assertIn(("GET", "/greeting"), routes)
                    self.assertIn(("POST", "/ask"), routes)
        """,
    }),
]
