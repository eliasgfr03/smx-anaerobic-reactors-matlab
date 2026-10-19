# Step-by-step: fictitious inputs and a prepared calibration

[Português](../portuguese-br%20version/GETTING_STARTED_PT_BR.md) · [Documentation index](INDEX.md)

## 1. Locate the package and inspect the session

Open MATLAB in the directory containing README.md and setup_jwpe.m. Optionally
save the current session path before setup:

```matlab
previousPath = path;
info = setup_jwpe();
disp(info)
ver
which jwpe_prepare_m1 -all
which jwpe_job -all
```

Expected: `scientificExecutionPerformed` is false, the reported package root
is the directory you opened, and the first effective function paths belong
to this copy. Later `which -all` entries marked `Shadowed` are not used.
If another copy is effective, use a clean session or remove only that copy's
session paths, without deleting files or resetting unrelated settings. A false
toolbox-availability field means that analyses requiring that solver cannot
be executed in this session. The MATLAB command `ver` displays the installed
MATLAB version and toolbox versions. An installed toolbox does not guarantee
that its license can be checked out later. No result file is created.

## 2. Generate fictitious inputs

Choose a new writable folder, outside the package, with a reasonably short
path. For example, choose a working directory interactively and then use a new
subfolder within it:

```matlab
workRoot = uigetdir(pwd,'Choose a working directory outside the package');
assert(ischar(workRoot),'No directory selected.');
inputRoot = fullfile(workRoot,'synthetic_inputs_01');
folders = jwpe_make_demo_inputs(inputRoot);
disp(folders)
F = readtable(fullfile(folders.CS,'forcing.csv'));
O = readtable(fullfile(folders.CS,'observations.csv'));
disp(size(F))
disp(size(O))
disp(F(1:3,:))
disp(O(1:3,:))
```

`F` is 33x3 and `O` is 33x6. Each CS/PF folder contains forcing.csv,
observations.csv, phases.csv, physical.json and initialization.json. The generator
uses arithmetic expressions only: it does not call a reactor model, draw random
numbers, calibrate parameters or create chains. It refuses an existing destination.

## 3. Prepare a job; do not execute yet

```matlab
outputRoot = fullfile(workRoot,'outputs_01');
[jobCS, inputsCS] = jwpe_prepare_m1(folders.CS,outputRoot,'CS','demo01','demo');
planCS = jwpe_job(jobCS,'prepare');
disp(planCS)
disp(inputsCS.cfg.parameterNames)
disp(inputsCS.cfg.freeIndices)
disp(inputsCS.cfg.budget)
disp(inputsCS.context.phaseAudit)
disp(isfolder(jobCS.outputFolder))
descriptorFile = fullfile(workRoot,'descriptor_CS_demo01.mat');
assert(~isfile(descriptorFile) && ~isfolder(descriptorFile));
job = jobCS;
save(descriptorFile,'job');
```

Expected: status `OWN_EXECUTOR_BOUND_NOT_RUN`, scientificExecutionPerformed=false;
parameter order [Kd, kb, kG, tinf, Ai], freeIndices=2:5, Kd fixed at 0.020.
The demo budget is 24 optimizer calls, one independent recheck and at most
25 raw forwards, with no retries. There are 17 Phase I and 16 Phase II
observations, giving 33 calibration observations. Forcing ends at 94 d and
contains no response values. The result-folder existence check returns 0.

Preparation creates `outputs_01/jobs/CS_demo01.mat`, not a fitted result. It
validates and hashes the five input files and code, preserving input numbers.
`inputsCS` is returned for inspection; no numerical model is evaluated.
The descriptor file stores a variable named `job`, pointing to this CS job.
The [resumption guide](RESUMING_RUNS.md) loads that same variable name in a
later session; keep the absolute `descriptorFile` path with your records.

## 4. Explicit execution, separate from preparation

The following call performs scientific computations and should be used only
after inspecting the preceding specification and accepting its cost:

```matlab
resultCS = jwpe_job(jobCS,'execute');
```

The demo uses the real M1 forward/likelihood/optimizer kernels. It has a 900 s
optimizer time option (not a strict wall-clock kill for a single objective or
the final recheck). An error stops the call. Expect finite results and a recheck,
not a particular optimum or a claim of convergence. A short result is tagged
`DEMO_CALIBRATION_COMPLETE`, testOnly=true, productionCertified=false.

Inspect result.mat, summary.json, parameters.csv, prediction.csv, trace.csv and
manifest.csv in `jobCS.outputFolder`. run_spec.mat/run_state.mat and the native
optimizer checkpoint support inspection and compatible resumptions. Exact
optimizer exit flags/evaluation totals can vary or stop early within the cap.

For PF, repeat preparation with folders.PF and reactor='PF', using its separate
job/destination. Never overwrite or silently reuse another run. A new runID
creates a distinct execution. For genuine inputs, use mode='production' and
the input schema in INPUTS.md; production keeps the 250 + 1 budget and is not a
short demonstration.

## 5. Resumption

Only a coherent saved run at a supported boundary is resumable. To prepare
a new resume specification without executing it:

```matlab
resumeFile = fullfile(outputRoot,'jobs','CS_demo01_resume.mat');
resumeJob = jwpe_resume_job(jobCS,resumeFile);
resumePlan = jwpe_job(resumeJob,'prepare');
disp(resumePlan.status)
disp(resumePlan.scientificExecutionPerformed)
```

Expected: `OWN_EXECUTOR_BOUND_NOT_RUN` and false. This call checks the job
interface; it does not continue the optimizer or prove that every saved
checkpoint is resumable. Keep the original job descriptor, including its
file path and SHA-256, with your run records. If using a new MATLAB session,
run setup again and restore that descriptor from your own saved records.

For a compatible, unfinished run with a coherent saved state and checkpoint,
the separate continuation command is:

```matlab
resultCS = jwpe_job(resumeJob,'execute');
```

This command performs scientific computation. M1 loads the native optimizer
checkpoint when its search is unfinished and preserves the original total
budget; the budget is not granted again at each continuation. It also checks
the saved run state. No pending evaluation or recorded failure is allowed.
The result folder and native checkpoint must stay at their original paths.
A completed run is not a test of optimizer continuation and should not be
executed again merely to test resume.

Do not change data, method, mode, code, runID, output path or budget. A
missing or uncertain state is not permission to restart into the same folder.
An interruption during an objective evaluation can leave a pending attempt;
the controller then rejects resumption rather than silently repeating it.
Pressing Ctrl+C or killing MATLAB does not guarantee a recoverable boundary.
MCMC supports only its recorded complete checkpoint boundaries; its
analysis-specific settings are described in [Analysis interfaces](ANALYSES.md).

## Campaigns beyond the short example

The simple M1 constructor uses `demo` for synthetic functional examples and
`production` for compatible measured inputs. Production has 250 objective
calls plus one recheck, not an unlimited or automatically converged search.
See [Production campaign configuration](ANALYSES.md#production-campaign-configuration)
for what is configurable and what requires an adapted implementation.

For concrete changes to evaluation limits, chain lengths and downstream draw
counts, follow [Increasing campaign budgets](CAMPAIGN_BUDGETS.md). It identifies
the matching files and checks; do not change a saved run's budget on resume.

## 6. End the session

```matlab
path(previousPath)
```

This restores the path saved in Step 1. Your generated input and result files
remain in the working directory you selected.
