export const meta = {
  name: "ship-feature",
  description: "Implement a task on a branch, test, verify, review with repair loop, and open a pull request.",
  phases: [
    { name: "implement", title: "Implement" },
    { name: "verify", title: "Verify" },
    { name: "review", title: "Review" },
    { name: "pr", title: "Open PR" }
  ]
};

const inputs = args ?? {};
const task = inputs.task;
const repoPath = inputs.repo_path || "workspace/virtual-office/repo";
const branch = inputs.branch || "feat/office-task";

if (!task) {
  throw new Error("ship-feature requires args.task (string)");
}

const implSchema = {
  type: "object",
  required: ["branch", "summary"],
  properties: {
    branch: { type: "string" },
    files_changed: { type: "array", items: { type: "string" } },
    summary: { type: "string" },
    test_command: { type: "string" }
  }
};

const reviewSchema = {
  type: "object",
  required: ["passed", "retryable", "feedback"],
  properties: {
    passed: { type: "boolean" },
    retryable: { type: "boolean" },
    feedback: { type: "string" },
    blockers: { type: "array", items: { type: "string" } }
  }
};

phase("implement");
const impl = agent(
  "You are an office employee (developer). Repo is at ~/" + repoPath + ". " +
  "Task: " + task + " " +
  "Create branch '" + branch + "' from main and implement the task, following the repo's office/HOUSE_RULES.md. " +
  "Commit with conventional commits. Do NOT push and do NOT open a PR. " +
  "Return the unwrapped result JSON with branch, files_changed, summary, test_command.",
  { key: "implement-1", label: "Implement task", schema: implSchema, timeoutMs: 1800000 }
);

let attempt = 1;
let review = null;
const maxAttempts = 3;

while (attempt <= maxAttempts) {
  phase("verify");
  agent(
    "You are the office qa-engineer. Repo at ~/" + repoPath + ", branch '" + impl.branch + "'. " +
    "Run the test suite (" + (impl.test_command || "the repo's standard test command") + ") and lint. " +
    "Report back briefly: what you ran and whether it passed. Return plain text.",
    { key: "verify-" + attempt, label: "Run tests", timeoutMs: 1200000 }
  );

  phase("review");
  const prior = review ? " Previous review feedback to address: " + review.feedback : "";
  review = agent(
    "You are the office qa-engineer doing code review. Repo at ~/" + repoPath + ", branch '" + impl.branch + "'. " +
    "Review the diff against main for correctness, edge cases, security issues, and test coverage." + prior + " " +
    "Return the unwrapped result JSON with passed (boolean), retryable (boolean), feedback (string), blockers (array of strings).",
    { key: "review-" + attempt, label: "Review code", schema: reviewSchema, timeoutMs: 1200000 }
  );

  if (review.passed) { break; }
  if (!review.retryable || attempt >= maxAttempts) { break; }

  phase("implement");
  agent(
    "You are an office employee (developer). Repo at ~/" + repoPath + ", branch '" + impl.branch + "'. " +
    "Address this review feedback: " + review.feedback + " Commit the fixes. Do NOT push or open a PR. Return a plain text summary.",
    { key: "repair-" + attempt, label: "Address review feedback", timeoutMs: 1800000 }
  );
  attempt = attempt + 1;
}

if (!review.passed) {
  return { __hatchWorkflowControl: "blocked", result: { blocked_reason: "Review did not pass after " + maxAttempts + " attempts.", message: review.feedback } };
}

phase("pr");
const pr = agent(
  "You are the office tech-writer/devops employee. Repo at ~/" + repoPath + ", branch '" + impl.branch + "'. " +
  "Push the branch and open a pull request against main with a clear title and description (summary: " + impl.summary + "). " +
  "Return the PR URL as plain text.",
  { key: "pr-1", label: "Open pull request", timeoutMs: 600000 }
);

return "Done. " + impl.summary + " PR: " + pr;
