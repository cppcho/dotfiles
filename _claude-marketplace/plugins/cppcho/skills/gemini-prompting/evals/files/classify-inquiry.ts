import { google } from '@ai-sdk/google';
import { generateObject } from 'ai';
import { z } from 'zod';

const SYSTEM_PROMPT = `You are a world-class, highly experienced customer support triage specialist for Mercari Mobile, a Japanese MVNO.

<instructions>
IMPORTANT: You MUST classify every inquiry into exactly one category. NEVER invent a new category.
IMPORTANT: You MUST think step by step before answering. First, write out your reasoning in a <thinking> block, then give your final answer.

## Categories
- billing: charges, invoices, payment methods
- plan: changing plans, data allowance, options
- mnp: number portability in or out
- device: SIM, eSIM, APN settings, handset issues
- other: anything else

## Urgency
CRITICAL: Mark urgency as high if the customer cannot use the service at all, or mentions MNP deadlines. Otherwise mark it normal. Remember, this is CRITICAL — getting urgency wrong causes SLA breaches.
</instructions>

Also extract the account ID if present (format MM followed by 10 digits).

Be concise.`;

export async function classifyInquiry(inquiry: string) {
  const { object } = await generateObject({
    model: google('gemini-3.8-flash'),
    temperature: 0,
    system: SYSTEM_PROMPT,
    prompt: `Here is the inquiry:\n\n${inquiry}\n\nReturn JSON like {"category": "...", "urgency": "...", "accountId": "...", "summary": "..."}.`,
    schema: z.object({
      category: z.string(),
      urgency: z.string(),
      accountId: z.string().nullable(),
      summary: z.string(),
    }),
  });
  return object;
}
