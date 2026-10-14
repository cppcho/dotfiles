# Gemini guidance, distilled from Google's docs

Taken on 2026-10-14. Each section names its source page and that page's last-updated date. When a claim here matters to a decision and may have moved — the model lineup changes every few months — re-check the page.

## Contents

1. Prompts and system instructions
2. Sampling and thinking, per model
3. Function declarations (tools)
4. Response schemas (structured output)
5. Agentic system instructions

## 1. Prompts and system instructions

Sources: [Prompt design strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies) (updated 2026-10-13), [Gemini 3 developer guide](https://ai.google.dev/gemini-api/docs/gemini-3) (updated 2026-10-09).

- **Be precise and direct.** "Gemini 3 responds best to direct, clear instructions." It "may over-analyze verbose or overly complex prompt engineering techniques used for older models." Google lists "unnecessary or overly persuasive language" as something to avoid.
- **One delimiter style per prompt.** XML-style tags (`<role>`, `<constraints>`, `<context>`, `<task>`) or Markdown headings both work. "Choose one format and use it consistently within a single prompt."
- **Placement.** Persona, behavioural constraints and output format go in the system instruction or at the very start. With long context (documents, code, transcripts), "supply all the context first" and put the instructions and question *at the end*, opened with an anchor such as "Based on the information above, …".
- **Verbosity.** Gemini 3 "is less verbose and prefers providing direct, efficient answers." If you want detail, a warm tone or a chatty persona, say so explicitly — e.g. "Answer comprehensively with details, unless the user asks for a concise response."
- **Constraints and format.** State what to do and what not to do (length limits, scope). Name the output shape (table, list, sentence count). A response prefix — starting the expected output, e.g. `I. Introduction` — pins the pattern.
- **Few-shot examples.** "We recommend to always include few-shot examples in your prompts. Prompts without few-shot examples are likely to be less effective." Use a few varied ones; too many makes the model overfit to them. Keep their formatting identical — same tags, whitespace, newlines, separators. When examples are clear enough, explicit instructions can be dropped.
- **No chain-of-thought scaffolding.** Gemini 3 thinks internally, so "think step by step" or forced visible reasoning is generally unnecessary. Raise `thinking_level` instead. For a genuinely hard problem a plain "think carefully" can help, at the cost of thinking tokens.
- **Date and cutoff clauses (Gemini 3 Flash).** Google suggests adding a current-date line ("Remember it is 2026 this year.") and the knowledge cutoff ("Your knowledge cutoff date is January 2025."). Inject the real date at runtime rather than hard-coding a year.
- **Grounded answers.** When the model must answer only from supplied context, add a strict clause that limits it to that context and tells it what to say when the answer is not there.
- **Decompose.** One prompt per instruction for complex jobs; chain steps when each feeds the next; aggregate when parallel parts combine.
- **Don't assume knowledge.** Supply the facts the model needs (a troubleshooting guide, a product catalogue) instead of expecting it to know them.

## 2. Sampling and thinking, per model

Sources: Gemini 3 developer guide (above); [What's new in the latest model](https://ai.google.dev/gemini-api/docs/latest-model) (updated 2026-10-13, now describes Gemini 4 Argon); Prompt design strategies.

| Model | temperature / top_p / top_k | Thinking control |
|---|---|---|
| Gemini 2.5 | Tunable. Lower for deterministic tasks. | `thinking_budget` (token count). |
| Gemini 3.x (before 3.6) | Leave at defaults. Google "strongly recommend[s] keeping the temperature parameter at its default value of `1.0`"; lower values "may cause looping or degraded performance, especially on math and reasoning tasks." | `thinking_level`. Gemini 3 Flash: `minimal`/`low`/`medium`/`high`; Gemini 3 Pro: `low`/`high`; Gemini 3.1 Pro: `low`/`medium`/`high`. Default `high` on 3 Pro/Flash. Never send `thinking_level` and `thinking_budget` together (400 error). |
| Gemini 3.6+ and Gemini 4 | Ignored. "Remove `temperature`, `top_p`, and `top_k` from your requests." | `thinking_level` `low`/`medium` (default)/`high`; it is "your main control over quality, latency, and token use." |

Migration from 2.5 prompts: remove step-by-step scaffolding and try a higher `thinking_level` with a simpler prompt; remove explicit `temperature`.

Determinism for a classifier or extractor on Gemini 3 comes from a tight instruction, few-shot examples, an `enum` in a response schema and a lower `thinking_level` — not from `temperature: 0`.

If the model returns a safety fallback response, Google's tip is to try a higher temperature (2.5-era models only).

## 3. Function declarations (tools)

Source: [Function calling](https://ai.google.dev/gemini-api/docs/function-calling) (updated 2026-09-23).

Google's best-practices list:

- **Descriptions** — "Be clear and specific" for both the function and every parameter. Say what the function does and when it is the right one to call; put formats, units, ranges and examples in the parameter descriptions (`"Date (e.g., '2024-07-29')"`, `"Light level from 0 to 100"`).
- **Naming** — "descriptive names without spaces or special characters"; underscores or camelCase. Prefer `snake_case` verbs: `get_order_status`, not `orderStatusHelper`. Remote MCP server names should be `snake_case` without `-`.
- **Strong typing** — "Use specific types (integer, string, enum)." A fixed set of values is an `enum`, not a string described as "one of …".
- **Required** — list mandatory parameters in `required`; leave optional ones out.
- **Tool count** — keep the active set to "10-20 tools maximum." Use `allowed_tools` within `tool_choice` to narrow it per request.
- **Prompting** — provide context and instructions about the tools in the system instruction (when to use which, what to do with results).
- **Validation** — validate arguments before executing, especially for calls with consequences (writes, payments, sends). The application runs the function, not the model.
- **Error handling** — return a useful error in the function response so the model can recover, rather than failing the whole request.

Schema notes: only a subset of the OpenAPI schema is supported, and very large or deeply nested schemas may be rejected (especially in `any` mode). Tool choice modes are `auto` (default), `any`, `none` and `validated`.

Gemini 3 notes: the SDKs handle thought signatures automatically; when you resend history by hand, return every model-generated part, including thought and function-call parts, exactly as received. If a model needs to write text before a tool call and that causes `MALFORMED_FUNCTION_CALL`, Google's workaround is a dedicated function (e.g. `update(note)`) for that text. If `gemini-3.1-pro-preview` prefers bash over your custom tools, use `gemini-3.1-pro-preview-customtools`.

## 4. Response schemas (structured output)

Source: [Structured output](https://ai.google.dev/gemini-api/docs/structured-output) (updated 2026-10-13).

- Put a `description` on every property; the model reads them. Use `title` for a short label and `description` for detail. Include units and formats ("Quantity of the ingredient, including units").
- Use specific types and `enum` for classifications. Nullable fields: a type array such as `["string", "null"]`.
- List mandatory fields in `required`; control extras with `additionalProperties`.
- `anyOf` for alternative shapes, `$ref: "#"` for recursion, `minItems`/`maxItems` for arrays.
- Supported types: `string`, `number`, `integer`, `boolean`, `object`, `array`, `null`. Only a subset of JSON Schema is supported; very large or deeply nested schemas may be rejected.
- The prompt states the task; Google's examples pass the schema only through the response format and don't repeat it in the prompt text.
- Valid JSON can still be wrong. Validate values in the application.
- Gemini 3 can combine structured output with built-in tools (Search, URL Context, Code Execution, function calling) — preview.

## 5. Agentic system instructions

Source: Prompt design strategies, "Agentic" section.

Google's agent template asks the model to:

- plan before every action, considering dependencies, risk, hypotheses and which information source to use;
- prefer acting with the information it has over asking the user, unless the missing information is needed later;
- treat low-risk reads differently from high-risk writes;
- retry transient errors, but change strategy after other errors;
- not give up until the reasoning is exhausted;
- take an action only after that reasoning is complete.

Use these as headings to fill with the specific agent's rules, not as boilerplate to paste whole.
