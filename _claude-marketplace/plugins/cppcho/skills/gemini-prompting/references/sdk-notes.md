# Where the guidance lands in code

Field names drift between SDK versions. Check the version the repo pins (`package.json`, `go.mod`) and match the calls already in the codebase before introducing a new style.

## Vercel AI SDK (`ai` + `@ai-sdk/google`)

Source: [AI SDK Google provider](https://ai-sdk.dev/providers/ai-sdk-providers/google-generative-ai), read 2026-10-14.

- **System instruction** — the `system` option is sent as Gemini's system instruction. Persona, constraints and output format go there; the long context and the question go in `prompt` / `messages`, question last.
- **Sampling** — the SDK sends no `temperature` unless you pass one, so for Gemini 3 the fix is to delete `temperature`, `topP` and `topK` from the call.
- **Thinking** — `providerOptions.google.thinkingConfig.thinkingLevel` (`'minimal' | 'low' | 'medium' | 'high'`, per model support); `includeThoughts: true` returns thought summaries as `reasoning`. `thinkingBudget` is the Gemini 2.5 control; don't send both.

  ```ts
  providerOptions: {
    google: { thinkingConfig: { thinkingLevel: 'low' } } satisfies GoogleLanguageModelOptions,
  },
  ```

- **Tools** — `tool({ description, inputSchema: z.object({...}), execute })`. The object key is the function name Gemini sees, so make it a `snake_case` verb. Zod `.describe('…')` becomes the parameter description; `z.enum([...])` becomes an `enum`; `.optional()` drops it from `required`.
- **Structured output** — `Output.object({ schema })` with `generateText`/`streamText` (or `generateObject` in older code). `structuredOutputs` defaults to `true`, which sends the schema to Gemini; then don't restate the schema in the prompt. Put `.describe()` on every field. Unions, records and deep nesting may be rejected with a generic `Request contains an invalid argument.` — flatten, or use an `enum` discriminator.
- **Forward compatibility** — unknown `gemini-*` IDs and `-latest` aliases get Gemini 3 request behaviour.

## Go — `google.golang.org/genai`

```go
var getUsage = &genai.FunctionDeclaration{
	Name:        "get_data_usage",
	Description: "Returns the data used in one billing month for one account. Use it when the user asks how much data they have used or have left.",
	Parameters: &genai.Schema{
		Type: genai.TypeObject,
		Properties: map[string]*genai.Schema{
			"account_id": {Type: genai.TypeString, Description: "Account ID, e.g. \"MM0123456789\"."},
			"month":      {Type: genai.TypeString, Description: "Billing month as YYYY-MM. Omit for the current month."},
			"unit":       {Type: genai.TypeString, Enum: []string{"MB", "GB"}, Description: "Unit for the returned amounts."},
		},
		Required: []string{"account_id"},
	},
}
```

- Wrap declarations in `&genai.Tool{FunctionDeclarations: []*genai.FunctionDeclaration{...}}` on `GenerateContentConfig.Tools`.
- Newer SDK versions also accept `ParametersJsonSchema` (a raw JSON Schema). Use one or the other, matching the repo.
- The system instruction is `GenerateContentConfig.SystemInstruction` (a `*genai.Content`).
- Leave `Temperature`, `TopP` and `TopK` unset (nil) for Gemini 3. Thinking is under `GenerateContentConfig.ThinkingConfig`; check the pinned SDK for the exact thinking-level field and constants.
- Return errors to the model as a `FunctionResponse` whose `Response` map carries an `error` key with a message the model can act on.

## Go — tools served to a Gemini agent another way (MCP, custom JSON)

The same rules apply to whatever string ends up as the function's description and to the parameter schema, whichever library builds them: `snake_case` names with no `-`, a description that says what it does and when to call it, a description, type and format on every parameter, `enum` for fixed sets, `required` for the mandatory ones.
