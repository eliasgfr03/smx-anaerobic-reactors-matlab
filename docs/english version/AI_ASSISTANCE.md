# Using AI with the package

[Português](../portuguese-br%20version/AI_ASSISTANCE_PT_BR.md) · [Documentation index](INDEX.md)

AI can help inspect code, explain settings, draft adapters and review errors. It does not establish scientific validity, confer data permissions or replace human review. Do not upload restricted measurements, manuscripts or personal information to an AI service without authorization. Review generated code and suggested commands before execution.

Use the following prompts with access to this package or provide the relevant files. Replace bracketed descriptions with your actual choices. These prompts do not authorize expensive runs by default.

## Understand the architecture

> Read README.md, docs/english version/ARCHITECTURE.md, docs/english version/INPUTS.md and docs/english version/ANALYSES.md, then inspect the actual function signatures. Explain the route for [analysis and reactor], distinguishing configuration, preparation, numerical execution and post-processing. List required inputs, dependencies, outputs and limitations. Do not modify files or execute models. Do not infer data or defaults that are not supplied.

## Prepare a job

> Help me prepare a [test or production] job for [analysis and reactor] using [authorized input folder]. Read docs/english version/JOB_EXAMPLES.md and the selected controller and helpers. Check units, time origin, phase split, LOD, initial state, parameter order, supports/priors, source certification and total budget. Show exact commands, file paths and expected preparation outputs. Separate preparation from execution. If nested scientific choices are missing, ask rather than inventing them. Do not execute the job until I explicitly approve its cost and destination.

## Adapt to another experiment

> Read docs/english version/USING_YOUR_OWN_DATA.md and inspect the relevant implementation. Compare [my experimental design] with the supplied model. Identify compatible inputs versus changes requiring an adapter: clock, phase counts, hydraulics, biomass, initial concentration, capacity law, censoring and priors. Propose the smallest coherent changes and tests in a separate copy. Preserve original measurements and existing results. Do not reuse the SMX Kd prior or error scales without justification. Do not run an optimization or sampler.

## Modify code safely

> For [specific change], identify all callers, coupled configuration checks, counters, saved metadata and code-manifest implications. Propose a minimal patch in a separate copy, preserving the numerical method unless explicitly requested otherwise. Explain a small technical and synthetic functional test with declared time, forward and storage limits. Do not bypass assertions or reuse old checkpoints under changed code. Wait for permission before executing scientific computations.

## Diagnose an error

> Inspect [exact message and saved files] and the relevant functions without repeating the failed scientific run. Distinguish missing input, schema, path/license, integrity, numerical and incomplete-result errors. Explain the evidence, the smallest correction and whether a supported resume is possible. Preserve charged attempts, original logs and checkpoints. Do not fabricate a successful result, weaken tolerances or change source identities to make a check pass.

## Review results

> Review [saved output folder] read-only using its effective configuration, counters, traces, rechecks and diagnostics. Distinguish software completion from convergence and scientific adequacy. Examine bounds, PL completeness/compensation, posterior convergence and source compatibility as applicable. Separate parameter-uncertainty and predictive bands. Cite actual saved values and flag missing evidence without inventing it. Do not refit, regenerate chains or reinterpret a synthetic test as article reproduction.

## Report AI assistance

Describe the actual tasks for which AI was used and retain human responsibility for code, analysis and interpretation. If naming a tool or model, use the recorded product and model identifiers rather than guessing from an interface or a later session. Follow the relevant journal or institution's disclosure requirements. This guide does not assert that every model, service or prompt listed by a future user was used in the associated article.
