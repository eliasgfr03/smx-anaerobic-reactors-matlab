# Global sensitivity analysis

[Português](../portuguese-br%20version/GSA_PT_BR.md) · [Documentation index](INDEX.md)

The GSA interface evaluates the native six-parameter M0 model at 18 times
from day 5 to day 90. Its sampling coordinates are Kd, kSigma, Fdir, kG,
tinf and Ai; the model coordinates are Kd, kb, krev, kG, tinf and Ai.
The analysis reports signed standardized rank regression coefficients and
rank-regression R2. Sensitivity does not establish parameter identifiability.

## Required inputs

This is an advanced structured-input interface. Supply a compatible `context`
and a complete method configuration `cfg`, as described in
[Analysis interfaces](ANALYSES.md) and [Input contracts](INPUTS.md). The settings
below select execution effort; they are not a complete constructor for a new
scientific model or sampling distribution.

The context must contain the selected reactor, a response-free `forcingData`
table, compatible hydraulic and numerical `settings`, the corresponding model
`engine` handle, and `outputTimes_d = (5:5:90).'`. Forcing includes
`Time_d`, `Cin_ug_L` and an all-NaN `Cout_ug_L` column. Do not insert experimental
effluent responses into GSA forcing.

The method configuration includes the sampling ranges and names, the shared
output-time grid, metric and convergence rules, RNG settings, per-reactor
budgets and independent-recheck settings. `prepare_gsa_own_v1(cfg,reactor)`
constructs a Monte Carlo design from explicit settings without running a reactor
simulation. Alternatively, supply `uniform`, `sampled` and `native` arrays
together with `cfg` and `reactor` in `inputs` to reuse an existing design.

## Short functional example

The short branch requires `payload.mode = 'test'`. It evaluates exactly
32 samples and two independently repeated samples selected by the original
Kennard-Stone routine. It preserves the production convergence criteria and
does not certify Monte Carlo convergence.

For a compatible configuration and context, set:

```matlab
cfg.rng.rows = 32;
cfg.qa.count = 2;
cfg.retry.maxIdenticalRetries = 0;
cfg.(reactor).budget.mcMax = 32;
cfg.(reactor).budget.retryReserve = 0;
cfg.(reactor).budget.hardTotal = 34;
cfg.shortTest = struct('sampleCount',32,'recheckCount',2,'maxSeconds',900);
```

Keep `cfg.qa.maxAbsDiff_ug_L = 1e-12`, the source numerical tolerances and the
original convergence settings. In the source method, the production checkpoint
size is 250 and the first possible convergence stop is at N = 1000. Diagnostic
prefixes at N = 16, 24 and 32 are not production convergence checkpoints.

After assembling the complete payload and its dataset, method and code
identities, save and inspect the job without executing a reactor:

```matlab
job = jwpe_save_job(payload,jobFile);
plan = jwpe_job(job,'prepare');
disp(plan.status)
```

Choose a new job file and a new output directory that does not yet exist,
inside an existing writable working folder outside the package. The
controller creates the run directory. A
successful preparation verifies the job contract but does not certify every
scientific setting. Review the complete configuration before execution.

After reviewing that plan and accepting at most 34 forwards for this reactor,
execute the short example separately:

```matlab
result = jwpe_job(job,'execute');
```

Expected short-run status: `TEST_ONLY_GSA_COMPLETE_NOT_CONVERGENCE`.
The result contains 32 by 18 model outputs, sampling/native SRRC histories,
convergence flags, two recheck indices and differences, and a raw-forward
ledger. There are 34 forwards per reactor, no retries and no automatic run of
the other reactor. `scientificConvergenceCertified` and
`productionCheckpointsReached` remain false.

Files include `configuration.mat`, `result.mat`, `ledger.mat`, `outputs.csv`,
`native_srrc.csv`, `summary.json`, `manifest.csv` and `execution_mode.json`.
Inspect the ledger and preserve any stopped run rather than repeating it into
the same folder. The per-run time check occurs before each forward; it is not
a hard interruption of a running solver call.

## Production runs

Use `payload.mode = 'production'` with the complete production design and
budgets. Production retains its original convergence checks and independent
recheck selection. A short example is not a certified production GSA result.
Do not lower convergence thresholds to make an example pass. See
[Increasing campaign budgets](CAMPAIGN_BUDGETS.md) before planning a larger run.
