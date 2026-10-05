"""The `turn` fixture: a feature that lives almost entirely in one layer, on a base that already has the rest.

The model client is already on `integration`; `wip` adds a turn engine (`chat/turn/`) whose runner applies
several independent behaviours — an off-topic refusal, answer clipping, a citation retry, follow-up
suggestions — plus two diagnostics (a debug system-prompt override and a log-only figures metric). A
layer split has nothing to split; the reviewable order is a bare working turn, then one behaviour per PR.
The off-topic refusal and the suggestions both read `knowledge/topics.json`, so dropping one moves it.
"""

TURN_BASE = {
    "README.md": """
        # chat

        Help-chat backend. `chat/clients` (model gateway client), `chat/turn` (the turn engine: one
        question in, one answer out), `chat/api` (HTTP handlers), `chat/app.py` (wiring),
        `knowledge/` (committed data the engine reads). Config comes from env; see `.env.example`.

        Test: `python3 -m unittest discover -s tests -t .`
    """,
    ".gitignore": """
        __pycache__/
    """,
    ".env.example": """
        # no settings yet
    """,
    "chat/__init__.py": "",
    "chat/clients/__init__.py": "",
    "chat/clients/http.py": """
        def post_json(url, payload):
            raise NotImplementedError("no network in this repo's tests")
    """,
    "chat/clients/model.py": """
        class ModelClient:
            \"\"\"Completions from the model gateway.\"\"\"

            def __init__(self, base_url, transport):
                self._base_url = base_url.rstrip("/")
                self._transport = transport

            def complete(self, system, messages):
                body = self._transport(f"{self._base_url}/v1/complete", {"system": system, "messages": messages})
                return body["text"]
    """,
    "chat/api/__init__.py": "",
    "chat/api/handlers.py": """
        class Handlers:
            def get_health(self, request):
                return 200, {"ok": True}
    """,
    "chat/app.py": """
        from chat.api.handlers import Handlers


        def build_app(env):
            handlers = Handlers()
            return {("GET", "/health"): handlers.get_health}
    """,
    "tests/__init__.py": "",
    "tests/test_model_client.py": """
        import unittest

        from chat.clients.model import ModelClient


        class ModelClientTest(unittest.TestCase):
            def test_posts_the_system_prompt_and_messages(self):
                calls = []
                client = ModelClient("https://m.test/", lambda url, payload: calls.append((url, payload)) or {"text": "hi"})
                self.assertEqual(client.complete("sys", [{"role": "user", "content": "q"}]), "hi")
                self.assertEqual(calls, [("https://m.test/v1/complete", {"system": "sys", "messages": [{"role": "user", "content": "q"}]})])
    """,
    "tests/test_app.py": """
        import unittest

        from chat.app import build_app


        class AppTest(unittest.TestCase):
            def test_routes(self):
                self.assertIn(("GET", "/health"), build_app({}))
    """,
}

_REQUEST = """
    from dataclasses import dataclass, field
    from typing import Optional


    @dataclass
    class TurnRequest:
        question: str
        history: list = field(default_factory=list)
        system_prompt: Optional[str] = None  # only /debug/turn sets this
"""

_HELPERS = """
    class FakeModel:
        \"\"\"Answers with each reply in turn (repeating the last), recording what it was asked.\"\"\"

        def __init__(self, *replies):
            self.replies = list(replies)
            self.calls = []

        def complete(self, system, messages):
            self.calls.append({"system": system, "messages": messages})
            return self.replies[min(len(self.calls), len(self.replies)) - 1]
"""

TURN_WIP = [
    ("wip: turn engine", {
        "chat/turn/__init__.py": "",
        "chat/turn/request.py": _REQUEST,
        "chat/turn/run.py": """
            SYSTEM = "You are the help assistant for a mobile plan."


            def run_turn(request, model, topics):
                messages = request.history + [{"role": "user", "content": request.question}]
                answer = model.complete(request.system_prompt or SYSTEM, messages)
                return {"answer": answer}
        """,
        "tests/helpers.py": _HELPERS,
    }),
    ("wip: rules, suggestions, figures", {
        "chat/turn/policy.py": """
            import re

            MAX_ANSWER_CHARS = 400


            def off_topic(question, topics):
                \"\"\"True when the question names none of the topics the assistant covers.\"\"\"
                return not set(re.findall(r"[a-z]+", question.lower())) & set(topics)


            def clip(answer):
                return answer if len(answer) <= MAX_ANSWER_CHARS else answer[: MAX_ANSWER_CHARS - 1] + "…"


            def has_citation(answer):
                return re.search(r"\\[\\d+\\]", answer) is not None
        """,
        "chat/turn/figures.py": """
            import re


            def count_figures(answer):
                \"\"\"How many numbers the answer states; logged to see how often it quotes figures.\"\"\"
                return len(re.findall(r"\\d+(?:\\.\\d+)?", answer))
        """,
        "chat/turn/topics.py": """
            import json


            def load_topics(path="knowledge/topics.json"):
                with open(path) as f:
                    return json.load(f)
        """,
        "chat/turn/suggest.py": """
            def suggest(topics):
                \"\"\"Follow-up questions to offer under an answer, one per covered topic.\"\"\"
                return [f"How do I check my {t}?" for t in topics[:3]]
        """,
        "knowledge/topics.json": """
            ["data", "plan", "bill", "balance"]
        """,
        "chat/turn/run.py": """
            import logging

            from chat.turn.figures import count_figures
            from chat.turn.policy import clip, has_citation, off_topic
            from chat.turn.suggest import suggest

            log = logging.getLogger(__name__)

            SYSTEM = "You are the help assistant for a mobile plan. Cite each source as [n]."
            REFUSAL = "Sorry, I can only help with your plan, data and bill."


            def run_turn(request, model, topics):
                if off_topic(request.question, topics):
                    return {"answer": REFUSAL, "refused": True, "suggestions": suggest(topics)}
                messages = request.history + [{"role": "user", "content": request.question}]
                system = request.system_prompt or SYSTEM
                answer = model.complete(system, messages)
                if not has_citation(answer):
                    # One retry; a second miss is answered as is rather than refused.
                    answer = model.complete(system + " Your last answer cited nothing; cite a source.", messages)
                log.info("figures=%d", count_figures(answer))
                return {"answer": clip(answer), "refused": False, "suggestions": suggest(topics)}
        """,
        "tests/test_policy.py": """
            import unittest

            from chat.turn.policy import MAX_ANSWER_CHARS, clip, has_citation, off_topic


            class PolicyTest(unittest.TestCase):
                def test_off_topic(self):
                    self.assertTrue(off_topic("write me a poem", ["data", "plan"]))
                    self.assertFalse(off_topic("How much DATA is left?", ["data", "plan"]))

                def test_clip(self):
                    self.assertEqual(clip("short"), "short")
                    self.assertEqual(len(clip("a" * 500)), MAX_ANSWER_CHARS)

                def test_has_citation(self):
                    self.assertTrue(has_citation("3 GB left [1]."))
                    self.assertFalse(has_citation("3 GB left."))
        """,
        "tests/test_figures.py": """
            import unittest

            from chat.turn.figures import count_figures


            class FiguresTest(unittest.TestCase):
                def test_counts_numbers(self):
                    self.assertEqual(count_figures("3 GB of 20.5 GB"), 2)
        """,
        "tests/test_topics.py": """
            import unittest

            from chat.turn.suggest import suggest
            from chat.turn.topics import load_topics


            class TopicsTest(unittest.TestCase):
                def test_the_committed_topics_load(self):
                    self.assertIn("data", load_topics())

                def test_suggests_one_question_per_topic(self):
                    self.assertEqual(suggest(["data", "plan", "bill", "balance"])[:2], ["How do I check my data?", "How do I check my plan?"])
        """,
        "tests/test_run.py": """
            import unittest

            from chat.turn.request import TurnRequest
            from chat.turn.run import run_turn
            from tests.helpers import FakeModel

            TOPICS = ["data", "plan", "bill"]


            class RunTurnTest(unittest.TestCase):
                def test_answers_with_the_model(self):
                    model = FakeModel("You have 3 GB left [1].")
                    out = run_turn(TurnRequest("how much data is left", history=[{"role": "assistant", "content": "Hi"}]), model, TOPICS)
                    self.assertEqual(out["answer"], "You have 3 GB left [1].")
                    self.assertEqual(model.calls[0]["messages"], [{"role": "assistant", "content": "Hi"}, {"role": "user", "content": "how much data is left"}])

                def test_refuses_off_topic_without_asking_the_model(self):
                    model = FakeModel("x [1]")
                    self.assertTrue(run_turn(TurnRequest("write me a poem"), model, TOPICS)["refused"])
                    self.assertEqual(model.calls, [])

                def test_retries_an_uncited_answer_once(self):
                    model = FakeModel("no source", "with source [1]")
                    self.assertEqual(run_turn(TurnRequest("my plan"), model, TOPICS)["answer"], "with source [1]")
                    self.assertEqual(len(model.calls), 2)

                def test_clips_long_answers(self):
                    out = run_turn(TurnRequest("my bill"), FakeModel("a" * 500 + " [1]"), TOPICS)
                    self.assertEqual(len(out["answer"]), 400)

                def test_offers_suggestions(self):
                    out = run_turn(TurnRequest("my data"), FakeModel("ok [1]"), TOPICS)
                    self.assertEqual(out["suggestions"][0], "How do I check my data?")

                def test_debug_system_prompt_overrides(self):
                    model = FakeModel("ok [1]")
                    run_turn(TurnRequest("my data", system_prompt="be brief"), model, TOPICS)
                    self.assertEqual(model.calls[0]["system"], "be brief")
        """,
    }),
    ("wip: endpoints, debug route", {
        "chat/api/handlers.py": """
            from chat.turn.request import TurnRequest
            from chat.turn.run import run_turn


            class Handlers:
                def __init__(self, model=None, topics=()):
                    self._model = model
                    self._topics = list(topics)

                def get_health(self, request):
                    return 200, {"ok": True}

                def post_turn(self, request):
                    body = request["body"]
                    turn = TurnRequest(question=body["question"], history=body.get("history", []))
                    return 200, run_turn(turn, self._model, self._topics)

                def post_debug_turn(self, request):
                    body = request["body"]
                    turn = TurnRequest(question=body["question"], history=body.get("history", []), system_prompt=body.get("system_prompt"))
                    return 200, run_turn(turn, self._model, self._topics)
        """,
        "chat/app.py": """
            from chat.api.handlers import Handlers
            from chat.clients.http import post_json
            from chat.clients.model import ModelClient
            from chat.turn.topics import load_topics


            def build_app(env):
                handlers = Handlers(ModelClient(env["MODEL_URL"], post_json), load_topics())
                routes = {
                    ("GET", "/health"): handlers.get_health,
                    ("POST", "/turn"): handlers.post_turn,
                }
                if env.get("CHAT_DEBUG") == "1":
                    routes[("POST", "/debug/turn")] = handlers.post_debug_turn
                return routes
        """,
        ".env.example": """
            MODEL_URL=https://model.example.com
            CHAT_DEBUG=0
        """,
        "tests/test_handlers.py": """
            import unittest

            from chat.api.handlers import Handlers
            from tests.helpers import FakeModel


            class HandlersTest(unittest.TestCase):
                def test_post_turn_answers(self):
                    handlers = Handlers(FakeModel("3 GB [1]"), ["data"])
                    status, body = handlers.post_turn({"body": {"question": "my data"}})
                    self.assertEqual((status, body["answer"]), (200, "3 GB [1]"))

                def test_debug_turn_passes_the_system_prompt(self):
                    model = FakeModel("ok [1]")
                    Handlers(model, ["data"]).post_debug_turn({"body": {"question": "my data", "system_prompt": "terse"}})
                    self.assertEqual(model.calls[0]["system"], "terse")
        """,
        "tests/test_app.py": """
            import unittest

            from chat.app import build_app


            class AppTest(unittest.TestCase):
                def test_routes(self):
                    routes = build_app({"MODEL_URL": "https://m.test"})
                    self.assertIn(("GET", "/health"), routes)
                    self.assertIn(("POST", "/turn"), routes)
                    self.assertNotIn(("POST", "/debug/turn"), routes)

                def test_debug_route_only_when_enabled(self):
                    self.assertIn(("POST", "/debug/turn"), build_app({"MODEL_URL": "https://m.test", "CHAT_DEBUG": "1"}))
        """,
    }),
]

# The approved plan the subset-approval eval starts from.
TURN_PLAN_V1 = """
# Plan: carve the turn engine out of `wip` onto `integration`

| # | PR title | Base | Contents | ~Lines (tests) |
|---|---|---|---|---|
| 1 | Answer a turn over `POST /turn` | `integration` | `TurnRequest` (question, history), bare `run_turn`, `post_turn`, `app.py` wiring with `MODEL_URL`, `FakeModel` helper | 45 (40) |
| 2 | Refuse off-topic questions | 1 | `policy.off_topic`, `topics.py`, `knowledge/topics.json`, topics loaded in `app.py`, the refusal in `run_turn` | 30 (25) |
| 3 | Clip long answers | 2 | `MAX_ANSWER_CHARS`, `policy.clip` | 10 (10) |
| 4 | Suggest follow-up questions | 3 | `suggest.py`, suggestions in both `run_turn` returns | 15 (15) |
| 5 | Retry an uncited answer once | 4 | `policy.has_citation`, citation instruction in `SYSTEM`, the retry | 15 (15) |
| 6 | Debug turn and figures metric | 5 | `system_prompt` field, `post_debug_turn`, `CHAT_DEBUG` route, `figures.py` and its log line | 35 (25) |

The thin path answers any question with the model; each slice above it adds one behaviour to `run_turn`.
"""
