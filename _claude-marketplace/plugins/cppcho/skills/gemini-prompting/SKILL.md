---
name: gemini-prompting
description: Writes and reviews prompts, system instructions, tool/function descriptions and response schemas that a Google Gemini model will read, following Google's current Gemini guidance rather than Claude-style prompting habits. Use whenever the text being written or edited is consumed by Gemini — a `system`/`prompt` passed to `google('gemini-…')` through the Vercel AI SDK (`ai`, `@ai-sdk/google`), a `tool({ description, inputSchema })` or zod `.describe()` on a Gemini call, a `genai.FunctionDeclaration` or `genai.Schema` in Go, a `google-genai` call in Python, a prompt file loaded for a Gemini model, or an MCP/agent tool served to a Gemini agent — and when the user asks to improve, audit, tune or "make Gemini follow" a prompt, even if they never say "best practice". Skip it when the target model is Claude, GPT or another non-Gemini model.
argument-hint: "[file|description of the prompt or tools]"
---

# Gemini prompting

You are writing for a different reader. Claude's prompting instincts — and Anthropic's guidance — come from tuning Claude. Gemini 3 was tuned differently, and a few habits that help Claude actively hurt it. This skill is the translation layer.

## 1. Pin the target

Before writing, find out from the code (or ask, if the code doesn't say):

- **Model ID** — `gemini-2.5-*`, `gemini-3*` / `gemini-3.x-*`, or `gemini-4-*`. Sampling and thinking advice differs by generation; see the table in `references/gemini-guidance.md` §2.
- **SDK and where the text lives** — AI SDK `system`/`prompt`/`tool()`, Go `genai` structs, a prompt file, an MCP tool. `references/sdk-notes.md` shows how each rule maps onto each one.
- **What the call is for** — chat assistant, extractor/classifier (needs a schema), grounded Q&A over supplied context, or a tool-using agent.

## 2. Drop the Claude habits

These are the defaults you will reach for. Each one costs something on Gemini.

| Claude habit | On Gemini | Instead |
|---|---|---|
| `IMPORTANT`, `MUST`, `CRITICAL`, `NEVER` in caps; restating a rule twice for weight | Google lists "unnecessary or overly persuasive language" as something to avoid; Gemini 3 "may over-analyze" it. | State each rule once, plainly. If one rule truly dominates, put it first. |
| "Think step by step", a `<thinking>` block, forced visible reasoning | Gemini 3 thinks internally; the scaffolding is noise and burns tokens. | Remove it. Set `thinkingLevel` to match the difficulty. |
| `temperature: 0` (or 0.2) "for determinism" | On Gemini 3 below-default temperature "may cause looping or degraded performance"; on 3.6+/4 it is ignored. | Delete `temperature`/`topP`/`topK`. Get consistency from tight instructions, examples, enums and a lower thinking level. |
| Instructions only, no examples, to keep the prompt "general" | Google: "always include few-shot examples … prompts without few-shot examples are likely to be less effective." | Add 2–4 short, varied examples with identical formatting. |
| Mixing XML tags and Markdown headings in one prompt | Google: pick one format and use it consistently. | Choose one style for the whole prompt. |
| Long role preamble ("You are a world-class…") and motivational framing | Gemini 3 "responds best to direct, clear instructions." | One line of role, then the rules. |
| Leaving length to the model | Gemini 3 defaults to terse, direct answers. | Say how much detail, what tone, and what format you want. |
| Instructions above a long document | With long context Google wants context first, question last. | System instruction holds persona, constraints and format; the user turn holds the data, then the question opened by "Based on the information above, …". |
| Tool behaviour explained in prose ("pass one of daily, weekly…") | Gemini follows types better than prose. | `enum`, specific types, `required`, formats in parameter descriptions. |

Not every Claude habit is wrong for Gemini: clear section delimiters, supplying the context the model needs, naming the output format and long-context-first ordering are shared advice. Keep those.

## 3. Write it

**Prompts and system instructions.** Persona, constraints and output format go in the system instruction. Then context, then the task. For grounded answers, say the model may use only the supplied context and say exactly what to reply when the answer isn't there. For Gemini 3 Flash, add the current date (inject it at runtime) and the knowledge cutoff when time-sensitive questions are possible. Agents: see `references/gemini-guidance.md` §5 for the planning, risk and retry rules Google's agent template covers.

**Tool / function declarations.** Name: `snake_case` verb phrase, no spaces, hyphens or other special characters. Description: what it does and when it is the right tool, in a sentence or two — plus a disambiguating line when two tools are close. Every parameter has a type and a description carrying format, unit or range ("Billing month as YYYY-MM"). Fixed choices are an `enum`. Mandatory parameters are in `required`. Keep the tools active on one request to 10–20 at most. Guidance on *when* to use which tool belongs in the system instruction too. Calls with side effects get validated by the application before they run.

**Response schemas.** A `description` on every property, with units and formats. `enum` for categories. `required` listing the mandatory fields; nullable fields as a type array. Keep nesting shallow — large or deep schemas are rejected. When the SDK sends the schema to Gemini (AI SDK `structuredOutputs`, the default), describe the task in the prompt and don't paste the schema into it as well.

When rewriting an existing prompt, keep its domain rules and intent. The change is in how it says things, not what it asks for.

## 4. Check, then report

Read the result once as Gemini would and check each row of the table in §2, plus: one delimiter style; examples formatted identically; no sampling parameters on Gemini 3+; every tool parameter typed and described; schema fields described.

Report to the user briefly: what you wrote or changed, and the Gemini-specific choices that a Claude-trained reviewer might otherwise "fix" back (removed temperature, no step-by-step, added examples). Cite the guideline, not your preference.

If a decision depends on something the references mark as fast-moving — a new model generation, a parameter's support — and the stakes are real, re-check the linked Google page before relying on it.
