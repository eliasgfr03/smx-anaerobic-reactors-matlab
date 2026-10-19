# Resuming unfinished runs

[Português](../portuguese-br%20version/RESUMING_RUNS_PT_BR.md) · [Documentation index](INDEX.md)

The public resume interface supports fixed-Kd M1 calibration and MCMC only. It continues a compatible unfinished run under its original total budget. It does not grant that budget again. Other controllers may save intermediate files, but that alone does not provide a supported native resume through `jwpe_resume_job`.

## Keep the required files

Keep the original saved job, its returned descriptor, the entire output folder, code copy and input files. For M1 this includes `run_spec.mat`, `run_state.mat` and `surrogate_checkpoint.mat` when generated. MCMC needs its matching configuration, complete chain checkpoints and RNG states. Do not move the result folder or change its contents to force a resume.

Resume requires a coherent saved boundary without a pending evaluation or recorded failure. A completed run should be inspected, not executed again as a resume test. An arbitrary Ctrl+C, process termination or machine failure can leave a non-resumable state. Preserve that state and diagnose it rather than resetting counters or writing into the same directory.

## Commands

Save the descriptor when preparing your original job:

```matlab
save(descriptorFile,'job');  % choose a new absolute MAT path
```

The getting-started example uses `job = jobCS` before saving, so the MAT
contains `job` rather than `jobCS`. If an earlier descriptor was saved with
another variable name, load that exact name and assign it to `job` explicitly.
For example, for a file containing `jobCS`, use
`saved = load(descriptorFile,'jobCS'); job = saved.jobCS;` instead of the
generic load below. Do not overwrite an existing descriptor to rename it.

In a later session, open the unchanged package, run setup and load your trusted descriptor:

```matlab
info = setup_jwpe();
saved = load(descriptorFile,'job');
job = saved.job;
resumeJob = jwpe_resume_job(job,newResumeJobFile);
resumePlan = jwpe_job(resumeJob,'prepare');
disp(resumePlan.status)
disp(resumePlan.scientificExecutionPerformed)
```

`newResumeJobFile` is a new absolute MAT path. Preparation returns `OWN_EXECUTOR_BOUND_NOT_RUN` and false; it does not establish that every numerical checkpoint is usable. The separate execution command performs the controller's saved-state checks and then continues, if eligible:

```matlab
result = jwpe_job(resumeJob,'execute');
```

The original destination remains the destination. Do not change data, method, code hash, mode, runID, supports, likelihood, budgets or total chain length. For MCMC, `sweepLimit` controls work per invocation at complete checkpoint boundaries; it accepts `Inf` or a finite positive integer multiple of `config.sampler.checkpointEvery`. It is not a new production length. Plan the total length before starting.

## Unsupported cases

PL coordinate searches and local closures do not expose this generic resume interface. A coordinate that stops before completing its required search remains incomplete. LOG2 may save a diagnostic optimizer checkpoint, but native checkpoint continuation is not qualified for this interface. The OFL controller's separate optimizer blocks do not imply generic native continuation support. For these analyses, diagnose saved outputs, then design a distinct new run if needed; do not present a fresh search as an exact resume.

Longer campaigns require new configurations and matching code checks, as explained in [Campaign budgets](CAMPAIGN_BUDGETS.md). Retain all consumed evaluations in your records, including interrupted attempts.
