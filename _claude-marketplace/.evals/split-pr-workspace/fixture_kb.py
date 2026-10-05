"""The `kb` fixture: an approved plan whose bottom slice the user drops, taking its supporting changes with it.

The v1 plan puts the test helpers (`tmp_cwd`, `fixture_path`) and the refresh env var in the refresh-tooling
slice. Once that tooling is scoped out, `tmp_cwd` and the env var have no user at all, and `fixture_path`
belongs to the knowledge-loader slice, not to whatever became the bottom PR.
"""
from fixture_assist import ASSIST_BASE

KB_BASE = dict(ASSIST_BASE)

_INDEX = """
    {"id": "a1", "title": "Checking your data balance", "body": "Open the app and tap Data to see what is left this month."}
    {"id": "a2", "title": "Carrying over unused data", "body": "Unused data carries over to the next month once."}
    {"id": "a3", "title": "Changing your plan", "body": "Plan changes take effect on the first day of next month."}
"""

KB_WIP = [
    ("wip: knowledge refresh crawler", {
        "scripts/__init__.py": "",
        "scripts/refresh/__init__.py": "",
        "scripts/refresh/crawl.py": """
            import json
            import os
            import sys


            def refresh(fetch, out_dir="knowledge"):
                \"\"\"Rewrites the committed index from the help centre's pages.\"\"\"
                pages = fetch()
                os.makedirs(out_dir, exist_ok=True)
                with open(os.path.join(out_dir, "index.jsonl"), "w") as f:
                    for page in sorted(pages, key=lambda p: p["id"]):
                        f.write(json.dumps({"id": page["id"], "title": page["title"], "body": page["body"]}, ensure_ascii=False) + "\\n")
                return len(pages)


            def main():
                import urllib.request

                url = os.environ["REFRESH_SOURCE_URL"]
                count = refresh(lambda: json.load(urllib.request.urlopen(url)))
                print(f"wrote {count} articles", file=sys.stderr)


            if __name__ == "__main__":
                main()
        """,
        "tests/fixtures/pages.json": """
            [{"id": "b", "title": "B", "body": "second"}, {"id": "a", "title": "A", "body": "first"}]
        """,
        "tests/test_refresh.py": """
            import json
            import os
            import unittest

            from scripts.refresh.crawl import refresh
            from tests.helpers import fixture_path, tmp_cwd


            class RefreshTest(unittest.TestCase):
                def test_writes_the_index_sorted_by_id(self):
                    pages = json.load(open(fixture_path("pages.json")))
                    with tmp_cwd():
                        self.assertEqual(refresh(lambda: pages), 2)
                        ids = [json.loads(l)["id"] for l in open(os.path.join("knowledge", "index.jsonl"))]
                    self.assertEqual(ids, ["a", "b"])
        """,
        "tests/helpers.py": """
            import contextlib
            import os
            import tempfile


            class FakeHTTP:
                \"\"\"Records posts and answers each with the same body.\"\"\"

                def __init__(self, body):
                    self.body = body
                    self.calls = []

                def post(self, path, json, timeout):
                    self.calls.append({"path": path, "json": json, "timeout": timeout})
                    return self.body


            def fixture_path(name):
                return os.path.join(os.path.dirname(__file__), "fixtures", name)


            @contextlib.contextmanager
            def tmp_cwd():
                \"\"\"Runs the block in a fresh temporary directory, for code that writes relative paths.\"\"\"
                old = os.getcwd()
                with tempfile.TemporaryDirectory() as d:
                    os.chdir(d)
                    try:
                        yield d
                    finally:
                        os.chdir(old)
        """,
        ".env.example": """
            GATEWAY_URL=https://gateway.example.com
            REFRESH_SOURCE_URL=https://help.example.com/export.json
        """,
    }),
    ("wip: committed index and its check", {
        "knowledge/index.jsonl": _INDEX,
        "scripts/check_knowledge.py": """
            import json
            import sys

            REQUIRED = ("id", "title", "body")


            def problems(path):
                \"\"\"Every line of the index that CI should reject, as (line number, reason).\"\"\"
                found, seen = [], set()
                for n, line in enumerate(open(path), 1):
                    row = json.loads(line)
                    missing = [k for k in REQUIRED if not row.get(k)]
                    if missing:
                        found.append((n, "missing " + ", ".join(missing)))
                    if row.get("id") in seen:
                        found.append((n, "duplicate id " + row["id"]))
                    seen.add(row.get("id"))
                return found


            if __name__ == "__main__":
                bad = problems(sys.argv[1] if len(sys.argv) > 1 else "knowledge/index.jsonl")
                for n, why in bad:
                    print(f"line {n}: {why}", file=sys.stderr)
                sys.exit(1 if bad else 0)
        """,
        "tests/fixtures/index_bad.jsonl": """
            {"id": "x", "title": "", "body": "no title"}
            {"id": "x", "title": "Dup", "body": "same id"}
        """,
        "tests/test_check_knowledge.py": """
            import unittest

            from scripts.check_knowledge import problems
            from tests.helpers import fixture_path


            class CheckKnowledgeTest(unittest.TestCase):
                def test_committed_index_is_clean(self):
                    self.assertEqual(problems("knowledge/index.jsonl"), [])

                def test_reports_missing_fields_and_duplicates(self):
                    self.assertEqual(problems(fixture_path("index_bad.jsonl")), [(1, "missing title"), (2, "duplicate id x")])
        """,
    }),
    ("wip: catalog client", {
        "assist/clients/catalog_client.py": """
            import json


            class CatalogClient:
                \"\"\"The gateway's tool catalog: which tools exist, and calling one.\"\"\"

                def __init__(self, session):
                    self._session = session

                def list_tools(self):
                    return self._session.post("v1/list_tools", json={}, timeout=5).get("tools", [])

                def call_tool(self, name, parameters):
                    body = self._session.post("v1/call_tool", json={"name": name, "parameters": json.dumps(parameters)}, timeout=10)
                    return body["result"]
        """,
        "tests/test_catalog_client.py": """
            import unittest

            from assist.clients.catalog_client import CatalogClient
            from tests.helpers import FakeHTTP


            class CatalogClientTest(unittest.TestCase):
                def test_lists_the_tools(self):
                    http = FakeHTTP({"tools": [{"name": "get_balance"}]})
                    self.assertEqual(CatalogClient(http).list_tools(), [{"name": "get_balance"}])
                    self.assertEqual(http.calls, [{"path": "v1/list_tools", "json": {}, "timeout": 5}])

                def test_calls_a_tool_with_json_parameters(self):
                    http = FakeHTTP({"result": "{}"})
                    self.assertEqual(CatalogClient(http).call_tool("get_balance", {"a": 1}), "{}")
                    self.assertEqual(http.calls[0]["json"], {"name": "get_balance", "parameters": '{"a": 1}'})
        """,
    }),
    ("wip: answer from the knowledge", {
        "assist/knowledge/__init__.py": "",
        "assist/knowledge/load.py": """
            import json
            from dataclasses import dataclass


            @dataclass
            class Article:
                id: str
                title: str
                body: str


            def load_index(path="knowledge/index.jsonl"):
                with open(path) as f:
                    return [Article(**json.loads(line)) for line in f if line.strip()]


            def search(articles, question):
                \"\"\"Articles sharing a word with the question, best overlap first.\"\"\"
                words = set(question.lower().split())
                scored = [(len(words & set((a.title + " " + a.body).lower().split())), a) for a in articles]
                return [a for score, a in sorted(scored, key=lambda s: -s[0]) if score]
        """,
        "tests/fixtures/index_small.jsonl": """
            {"id": "s1", "title": "Data balance", "body": "tap Data"}
            {"id": "s2", "title": "Plans", "body": "change plan"}
        """,
        "tests/test_knowledge_load.py": """
            import unittest

            from assist.knowledge.load import load_index, search
            from tests.helpers import fixture_path


            class KnowledgeLoadTest(unittest.TestCase):
                def test_loads_and_searches(self):
                    articles = load_index(fixture_path("index_small.jsonl"))
                    self.assertEqual([a.id for a in search(articles, "my data balance")], ["s1"])

                def test_the_committed_index_loads(self):
                    self.assertEqual(len(load_index()), 3)
        """,
        "assist/service/ask_service.py": """
            from assist.knowledge.load import search


            class AskService:
                def __init__(self, articles, client):
                    self._articles = articles
                    self._client = client

                def ask(self, question):
                    if "balance" in question.lower():
                        return {"answer": self._client.call_tool("get_balance", {}), "sources": []}
                    hits = search(self._articles, question)
                    if not hits:
                        return {"answer": "I can't help with that yet.", "sources": []}
                    return {"answer": hits[0].body, "sources": [a.id for a in hits[:3]]}
        """,
        "tests/test_ask_service.py": """
            import unittest

            from assist.clients.catalog_client import CatalogClient
            from assist.knowledge.load import Article
            from assist.service.ask_service import AskService
            from tests.helpers import FakeHTTP


            class AskServiceTest(unittest.TestCase):
                def setUp(self):
                    self.http = FakeHTTP({"result": '{"gb": 3}'})
                    articles = [Article("a2", "Carrying over unused data", "Unused data carries over.")]
                    self.service = AskService(articles, CatalogClient(self.http))

                def test_balance_goes_to_the_tool(self):
                    self.assertEqual(self.service.ask("what is my balance")["answer"], '{"gb": 3}')

                def test_other_questions_answer_from_the_knowledge(self):
                    self.assertEqual(self.service.ask("does unused data carry over")["sources"], ["a2"])
                    self.assertEqual(self.http.calls, [])
        """,
    }),
    ("wip: ask endpoint and wiring", {
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
            from assist.knowledge.load import load_index
            from assist.service.ask_service import AskService
            from assist.service.greeting_service import GreetingService


            def build_app(env):
                client = CatalogClient(Session(env["GATEWAY_URL"]))
                handlers = Handlers(GreetingService(), AskService(load_index(), client))
                return {
                    ("GET", "/greeting"): handlers.get_greeting,
                    ("POST", "/ask"): handlers.post_ask,
                }
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

# The plan the user approved before changing scope; the run starts from it.
KB_PLAN_V1 = """
# Plan: carve `wip` onto `integration`

| # | PR title | Base | Contents | ~Lines (tests) |
|---|---|---|---|---|
| 1 | Refresh the knowledge index from the help centre | `integration` | `scripts/refresh/crawl.py`; `tests/helpers.py` gains `fixture_path` and `tmp_cwd`; `tests/fixtures/pages.json`; `REFRESH_SOURCE_URL` in `.env.example` | 30 (35) |
| 2 | Check the committed index in CI | 1 | `scripts/check_knowledge.py`, `knowledge/index.jsonl`, `tests/fixtures/index_bad.jsonl` | 25 (15) |
| 3 | Add the gateway tool-catalog client | 2 | `assist/clients/catalog_client.py` and its test, unwired | 15 (20) |
| 4 | Answer questions from the knowledge index | 3 | `assist/knowledge/load.py`, `assist/service/ask_service.py`, `tests/fixtures/index_small.jsonl` and their tests | 40 (45) |
| 5 | Expose `POST /ask` | 4 | handlers, `app.py` wiring, route test | 20 (5) |

The test helpers land in #1 because the refresh tests are their first user.
"""
