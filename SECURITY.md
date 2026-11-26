# Security policy

## Supported versions

Only the `main` branch is supported. Fixes land on `main` and ship in the next release; nothing is backported to older releases.

## Reporting a vulnerability

Do not open a public issue or pull request for a security problem.

Use GitHub's private vulnerability reporting instead: open <https://github.com/fugo101/wellface/security/advisories/new> (Security tab, "Report a vulnerability"). Only the maintainer can read the report. The project publishes no email address for security reports.

The same private form is also used for Code of Conduct reports, which are not vulnerabilities: start the title with "Conduct:" (see [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)). The rest of this policy is about vulnerabilities.

Please include:

- what is affected (the face, a script, the sideload helper or a workflow) and the commit, branch or release you tested;
- the steps to reproduce, with the smallest example that shows the problem;
- the impact as you understand it, for example what an attacker could read, change, run or leak;
- how you would like to be credited, if at all.

Do not include your developer key, Garmin account details or health data in a report.

## Scope

In scope:

- the face code in `source/` and `tests/`. The face runs on the watch, reads heart rate, stress, Body Battery, steps and the heart-rate zones (permissions `ComplicationSubscriber` and `UserProfile`) and makes no network requests, so a way to make it leak or send data off the watch would be a vulnerability;
- the scripts in `scripts/` and the tools in `tools/`, including the libmtp sideload helper written in C (`tools/sideload/`): for example command injection, unsafe handling of file names or a developer key path leaking into logs or output;
- the CI workflows in `.github/workflows/`: for example a way to run untrusted code with secrets, or to leak a secret;
- the release process: a way for a published `.prg` to differ from what the documented build produces.

Out of scope:

- bugs in Garmin's firmware, the Connect IQ SDK, the simulator or the Garmin apps. Report those to Garmin;
- `design/claude-design/support.js`, the Claude Design runtime, which is not part of the project's work (see [`NOTICE`](NOTICE)). Report problems in it to Anthropic;
- attacks that need physical access to a watch or a computer, a compromised machine on the reporter's side, or social engineering of the maintainer;
- vulnerabilities in a third-party dependency that have no effect on Wellface. Report those upstream. If Wellface is affected, report it here.

## What to expect

Wellface is maintained on a best-effort basis by one person. There is no response-time commitment. The maintainer will read the report, may ask follow-up questions in the private advisory, and will say whether it is accepted as a vulnerability (or, for a "Conduct:" report, handle it under the Code of Conduct).

When a fix is on `main`, the maintainer may publish a GitHub security advisory and credit the reporter if they want that. Please keep the details private until then.
