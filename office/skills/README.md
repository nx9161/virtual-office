# Skill Registry

Skills the Knowledge Wizard hunted across the internet, vetted, and
installed. New skill = new directory `office/skills/<slug>/` with a
`SKILL.md` (frontmatter: name, description, version, source URL,
license, installed date) plus the original license file.

| Skill | Source | License | Installed | Tools wired |
|-------|--------|---------|-----------|-------------|
| _none yet_ | | | | |

## Format
Every skill directory follows the same shape the agent's own skill
system uses, so skills stay portable:

```
office/skills/<slug>/
├── SKILL.md        # frontmatter + how-to-use
├── LICENSE.*       # original license, kept verbatim
└── ...             # supporting files the skill needs
```
