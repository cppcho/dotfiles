"""The `merge` fixture: a WIP branch that merged the base back in and kept its own stale text.

The greeting reply started on `wip`, was carved onto `integration` as a reviewed PR that fixed a bug (a
greeting ending in "!" reached the model), reworded a comment and added a test for it. `wip` then merged
`integration` and resolved the conflicts in its own favour, so the fix and the test are gone from `wip`;
after the merge it gained the follow-up suggestions. `git diff integration...wip` therefore shows the
suggestions *and* a silent revert of the reviewed greeting fix, and since the merge-base is now the base's
tip, `git diff wip...integration` is empty: nothing says the base changed these files.
"""
import subprocess

MERGE_BASE = {
    "README.md": """
        # chat

        Help-chat backend. `chat/turn.py` (the turn: one question in, one answer out), `chat/app.py`
        (routes and wiring).

        Test: `python3 -m unittest discover -s tests -t .`
    """,
    ".gitignore": """
        __pycache__/
    """,
    "chat/__init__.py": "",
    "chat/turn.py": """
        def run_turn(question, model):
            return {"answer": model(question)}
    """,
    "chat/app.py": """
        from chat.turn import run_turn


        def build_app(model):
            return {("POST", "/turn"): lambda body: (200, run_turn(body["question"], model))}
    """,
    "tests/__init__.py": "",
    "tests/test_turn.py": """
        import unittest

        from chat.turn import run_turn


        class TurnTest(unittest.TestCase):
            def test_answers_from_the_model(self):
                self.assertEqual(run_turn("price?", lambda q: "¥990")["answer"], "¥990")
    """,
}

_TURN_GREETING_WIP = """
    GREETINGS = ("hi", "hello", "thanks")
    GREETING_REPLY = "Hello! Ask me anything about your plan."


    def is_greeting(question):
        # Greetings skip the model.
        return question.strip().lower() in GREETINGS


    def run_turn(question, model):
        if is_greeting(question):
            return {"answer": GREETING_REPLY}
        return {"answer": model(question)}
"""

_TURN_GREETING_REVIEWED = """
    GREETINGS = ("hi", "hello", "thanks")
    GREETING_REPLY = "Hello! Ask me anything about your plan."


    def is_greeting(question):
        # The whole question must be a greeting, so "hi, what's my bill?" still reaches the model.
        return question.strip().lower().rstrip("!.") in GREETINGS


    def run_turn(question, model):
        if is_greeting(question):
            return {"answer": GREETING_REPLY}
        return {"answer": model(question)}
"""

_TEST_TURN_GREETING_WIP = """
    import unittest

    from chat.turn import GREETING_REPLY, run_turn


    class TurnTest(unittest.TestCase):
        def test_answers_from_the_model(self):
            self.assertEqual(run_turn("price?", lambda q: "¥990")["answer"], "¥990")

        def test_greeting_skips_the_model(self):
            self.assertEqual(run_turn("hello", lambda q: self.fail("called"))["answer"], GREETING_REPLY)
"""

_TEST_TURN_GREETING_REVIEWED = """
    import unittest

    from chat.turn import GREETING_REPLY, run_turn


    class TurnTest(unittest.TestCase):
        def test_answers_from_the_model(self):
            self.assertEqual(run_turn("price?", lambda q: "¥990")["answer"], "¥990")

        def test_greeting_skips_the_model(self):
            self.assertEqual(run_turn("hello", lambda q: self.fail("called"))["answer"], GREETING_REPLY)

        def test_greeting_with_punctuation_skips_the_model(self):
            self.assertEqual(run_turn("Thanks!", lambda q: self.fail("called"))["answer"], GREETING_REPLY)

        def test_question_starting_with_a_greeting_reaches_the_model(self):
            self.assertEqual(run_turn("hi, what's my bill?", lambda q: "¥990")["answer"], "¥990")
"""

# On `wip`: the greeting reply as first written.
MERGE_WIP_BEFORE = [
    ("wip: answer greetings without the model", {
        "chat/turn.py": _TURN_GREETING_WIP,
        "tests/test_turn.py": _TEST_TURN_GREETING_WIP,
    }),
]

# On `integration`: the greeting reply after review, squash-merged.
MERGE_BASE_SLICE = [
    ("Answer a greeting without calling the model (#101)", {
        "chat/turn.py": _TURN_GREETING_REVIEWED,
        "tests/test_turn.py": _TEST_TURN_GREETING_REVIEWED,
    }),
]

# The resolution `wip` committed when it merged `integration`: its own side of every conflict.
MERGE_RESOLUTION = {
    "chat/turn.py": _TURN_GREETING_WIP,
    "tests/test_turn.py": _TEST_TURN_GREETING_WIP,
}

# On `wip`, after the merge: the follow-up suggestions, the feature the user wants carved.
MERGE_WIP_AFTER = [
    ("wip: suggest follow-up questions", {
        "chat/suggest.py": """
            # Follow-ups keyed by a word the answer mentions; the first match wins.
            FOLLOW_UPS = {
                "¥": ["How do I change my plan?", "When is my bill charged?"],
                "data": ["How much data do I have left?"],
            }
            MAX_SUGGESTIONS = 2


            def suggest(answer):
                for word, questions in FOLLOW_UPS.items():
                    if word in answer:
                        return questions[:MAX_SUGGESTIONS]
                return []
        """,
        "chat/turn.py": """
            from chat.suggest import suggest

            GREETINGS = ("hi", "hello", "thanks")
            GREETING_REPLY = "Hello! Ask me anything about your plan."


            def is_greeting(question):
                # Greetings skip the model.
                return question.strip().lower() in GREETINGS


            def run_turn(question, model):
                if is_greeting(question):
                    return {"answer": GREETING_REPLY, "suggestions": []}
                answer = model(question)
                return {"answer": answer, "suggestions": suggest(answer)}
        """,
        "tests/test_suggest.py": """
            import unittest

            from chat.suggest import suggest


            class SuggestTest(unittest.TestCase):
                def test_offers_follow_ups_for_a_price(self):
                    self.assertEqual(suggest("It is ¥990."), ["How do I change my plan?", "When is my bill charged?"])

                def test_offers_nothing_when_no_word_matches(self):
                    self.assertEqual(suggest("Sure."), [])
        """,
        "tests/test_turn.py": """
            import unittest

            from chat.turn import GREETING_REPLY, run_turn


            class TurnTest(unittest.TestCase):
                def test_answers_from_the_model(self):
                    self.assertEqual(run_turn("price?", lambda q: "¥990")["answer"], "¥990")

                def test_greeting_skips_the_model(self):
                    self.assertEqual(run_turn("hello", lambda q: self.fail("called"))["answer"], GREETING_REPLY)

                def test_answer_carries_suggestions(self):
                    self.assertEqual(len(run_turn("price?", lambda q: "¥990")["suggestions"]), 2)

                def test_greeting_offers_no_suggestions(self):
                    self.assertEqual(run_turn("hi", lambda q: "x")["suggestions"], [])
        """,
    }),
]


def build_history(repo, sh, write, commit):
    """Writes the base, the WIP's first commit, the reviewed slice on integration, the stale merge and the
    WIP's later commit. Leaves `integration` and `wip` ready to push."""
    write(repo, MERGE_BASE)
    commit(repo, "initial app")
    sh(repo, "git", "branch", "integration")
    sh(repo, "git", "switch", "-q", "-c", "wip")
    for msg, files in MERGE_WIP_BEFORE:
        write(repo, files)
        commit(repo, msg)
    sh(repo, "git", "switch", "-q", "integration")
    for msg, files in MERGE_BASE_SLICE:
        write(repo, files)
        commit(repo, msg)
    sh(repo, "git", "switch", "-q", "wip")
    # The merge conflicts on both files; record the WIP's own side as the resolution.
    subprocess.run(["git", "-C", repo, "merge", "-q", "--no-commit", "integration"], capture_output=True)
    write(repo, MERGE_RESOLUTION)
    commit(repo, "Merge branch 'integration' into wip")
    for msg, files in MERGE_WIP_AFTER:
        write(repo, files)
        commit(repo, msg)
