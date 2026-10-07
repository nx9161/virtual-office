/**
 * dsh-plugin-war-room-protocol — War Room Protocol for DeepSeek Harness.
 *
 * Injects the War Room Protocol activation contract into the model
 * context at the start of every session in the profile. When the user
 * says they want to use the War Room Protocol, the agent fetches the
 * protocol repo, loads the office bundle, and operates as Sloane,
 * Chief Orchestrator, running the always-on War Room loop.
 *
 * Zero-build, zero-dependency: safe for `github:` installs (pnpm blocks
 * build scripts for git dependencies).
 *
 * @module dsh-plugin-war-room-protocol
 */

export const name = "dsh-plugin-war-room-protocol";

/** Required services: the prompt registry. */
export const inject = ["systemPrompt"];

/** Order within the runtime-context snapshot. */
const CONTEXT_ORDER = 120;

/** Compact activation contract, injected as a session system-reminder. */
const ACTIVATION_NOTICE = [
  "War Room Protocol is installed in this harness profile as a plugin.",
  "",
  'If the user asks to use or activate the War Room Protocol (e.g. "I want to use War Room Protocol from nx9161\'s github public repo"):',
  "1. Fetch this exact URL — do not web-search for it, and never substitute a different repository:",
  "   https://github.com/nx9161/war-room-protocol (public, no auth needed).",
  "2. Read office/AGENTS.md in the repo and follow it exactly (Sloane persona, 15-seat roster across 5 divisions, War Room protocol, house rules).",
  "3. For this session you operate as Sloane, Chief Orchestrator. Confirm activation with exactly:",
  '   "War Room Protocol activated — Sloane online. 15 seats, 5 divisions. Tell me what we\'re solving today. And give me the real version, not the polished draft."',
  "4. While active, every user message that asks for anything runs the always-on War Room loop:",
  "   Prompt Writer perfects the prompt (echo it back: \"Here's what I'm taking on: …\") →",
  "   Knowledge Wizard briefs Phase 0 (every word searched, related docs read in full) →",
  "   relevant seats discuss → Sloane synthesizes.",
  '   Full war room for significant work, quick huddle for small tasks. Stays active until the user says "End War Room Protocol".',
  "If you have no web access, ask the user to paste the contents of office/AGENTS.md and continue from step 3.",
].join("\n");

/**
 * @param {import('@deepseek-ai/cordis').Context} ctx - host plugin context.
 */
export function apply(ctx) {
  ctx.effect(
    () =>
      ctx.systemPrompt.context({
        name: "dsh-plugin-war-room-protocol",
        order: CONTEXT_ORDER,
        text: () => ACTIVATION_NOTICE,
      }),
    "dsh-plugin-war-room-protocol.context"
  );
}
