export const meta = {
  name: "fix-ci",
  description: "Diagnose a CI failure on a branch, fix it with a bounded retry loop, and re-verify.",
  phases: [
    { name: "diagnose", title: "Diagnose" },
    { name: "fix", title: "Fix" },
    { name: "verify", title: "Verify" }
  ]
};

const inputs = args ?? {};
const repoPath = inputs.repo_path || "workspace/virtual-office/repo";
const branch = inputs.branch;
const failure = inputs.failure_summary || "CI is failing";

if (!branch) {
  throw new Error("fix-ci requires args.branch (string)");
}

const fixSchema = {
  type: "object",
  required: ["fixed", "retryable", "summary"],
  properties: {
    fixed: { type: "boolean" },
    retryable: { type: "boolean" },
    summary: { type: "string" }
  }
};

let attempt = 1;
let outcome = null;
const maxAttempts = 3;

while (attempt <= maxAttempts) {
  phase("diagnose");
  const diagnosis = agent(
    "You are the office devops employee. Repo at ~/" + repoPath + ", branch '" + branch + "'. " +
    "CI failure summary: " + failure + " Diagnose the root cause from logs and code. Return a plain text diagnosis.",
    { key: "diagnose-" + attempt, label: "Diagnose CI failure", timeoutMs: 1200000 }
  );

  phase("fix");
  outcome = agent(
    "You are an office employee (developer). Repo at ~/" + repoPath + ", branch '" + branch + "'. " +
    "Diagnosis: " + diagnosis + " Fix the issue, commit, and push the branch. " +
    "Return the unwrapped result JSON with fixed (boolean), retryable (boolean), summary (string).",
    { key: "fix-" + attempt, label: "Fix and push", schema: fixSchema, timeoutMs: 1800000 }
  );

  if (outcome.fixed) { break; }
  if (!outcome.retryable || attempt >= maxAttempts) { break; }
  attempt = attempt + 1;
}

if (!outcome.fixed) {
  return { __hatchWorkflowControl: "blocked", result: { blocked_reason: "CI fix failed after " + maxAttempts + " attempts.", message: outcome.summary } };
}

phase("verify");
agent(
  "You are the office qa-engineer. Repo at ~/" + repoPath + ", branch '" + branch + "'. " +
  "Run the test suite and confirm green. Return plain text.",
  { key: "verify-final", label: "Final verification", timeoutMs: 1200000 }
);

return "CI fixed on " + branch + ": " + outcome.summary;
