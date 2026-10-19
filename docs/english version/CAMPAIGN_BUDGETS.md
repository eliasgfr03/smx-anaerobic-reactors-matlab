# Increasing campaign budgets

[Português](../portuguese-br%20version/CAMPAIGN_BUDGETS_PT_BR.md) · [Documentation index](INDEX.md)

This guide identifies the settings and checks that must agree when increasing
the computational effort of a new campaign. It does not change the distributed
defaults. Work in a separate package copy and prepare new jobs and output
folders after changing a method. Never enlarge a budget by editing a saved
checkpoint, run state, counter or completed result.

See [Analysis interfaces](ANALYSES.md) for the required inputs and
[Using your own data](USING_YOUR_OWN_DATA.md) for scientific compatibility.
A larger budget does not establish convergence or make another dataset
compatible with the source model.

## Distinguish the limits before changing them

- An objective-call limit bounds requests made by an optimizer. A cache hit
  may consume a request without a new model simulation.
- A raw-forward limit bounds model evaluations, including independent
  rechecks and any explicitly permitted retries. Increasing only the optimizer
  limit can leave the raw-forward allowance exhausted before finalization.
- Inner optimization limits control estimation of observation-error scales.
  They are not extra reactor simulations and should not be increased merely
  because the outer search is longer.
- A wall-time option can terminate a search before its evaluation allowance.
  It is not a hard deadline for a single forward or the final recheck.
- MCMC length, work per invocation, retained draws and observation-error
  replicates are different settings with different computational costs.

Keep the model, supports, priors, data split, likelihood, solver tolerances
and numerical acceptance thresholds unchanged when investigating budget alone.
Preserve failed attempts and report actual counts, not only requested maxima.

## Fixed Kd M1 calibration

The simple constructor fixes production at 250 objective calls plus one raw
recheck; synthetic demo mode uses 24 plus one. There is no arbitrary-budget
argument in `jwpe_prepare_m1`. A larger production budget requires coordinated
source edits in your separate copy:

| File | Fields or checks | Required action |
|---|---|---|
| `src/kernels/jwpe_m1_calibration_config.m` | `cfg.budget.optimizerCalls`, `rawForwards`, `recheck`, `retries`; `cfg.surrogate.MaxTime` | Set the production objective cap and raw allowance together; retain one recheck and zero retries |
| `src/api/jwpe_prepare_m1.m` | Production `cfg.surrogate.MaxTime=Inf`; demo overrides `24`, `25`, `900`; start-bank size check | Retain the demo branch unless deliberately adapting it; set any production time cap here because it overrides the constructor value |
| `src/kernels/jwpe_m1_calibration_state.m` | Explicit production equality checks for `250` and `251` | Replace only the production budget values with those declared in your modified configuration; retain the other validity checks |
| `analyses/run_m1_own_v1.m` | `MaxFunctionEvaluations`, `MaxTime`, saved cfg equality and consumed-count checks | Verify that options receive the new cfg and that a new job is used; do not remove resume compatibility checks |
| `src/kernels/jwpe_calibration_record.m` | Counter checks against `state.cfg.budget` | Verify the derived allowance covers optimization and the final recheck; do not reset these counters |
| `src/kernels/jwpe_m1_calibration_result.m` | Final count and recheck checks | Retain the checks; they already use the configured limits |

For example, a proposed 1000-call production search with the existing one
recheck and no retries would use these assignments inside the modified
configuration function, not as edits to a job already running:

```matlab
cfg.budget.optimizerCalls = 1000;
cfg.budget.recheck = 1;
cfg.budget.rawForwards = 1001;
cfg.budget.retries = 0;
```

The production branch in `jwpe_m1_calibration_state.m` must then require
`cfg.budget.optimizerCalls==1000` and `cfg.budget.rawForwards==1001`, while
retaining its existing checks on Kd, free indices, demo mode and rechecks.
Update function help and the configuration version label to describe your
copy accurately. This example is a proposed budget, not a recommended amount
or a demonstrated convergence result. Use the identity procedure below before
preparing a fresh job. Changing the returned `inputs.cfg` alone does not update
the saved job or all its identities.

## Profile likelihood searches

Budgets apply to individual fixed-coordinate searches. A larger per-point
allowance does not add missing coordinates, run the other reactor or launch
a full profile automatically. [Profile likelihood recipes](PROFILE_LIKELIHOOD.md)
describes the coordinate catalogues and finalization requirements.

| Formulation | Configuration and raw allowance | Consumers to inspect |
|---|---|---|
| M0 CS | `caseConfig.config.maxFunctionEvaluations`, `minSurrogatePoints`, `allowNonstandardBudget`; raw cap derived as objective cap plus one | `analyses/m0_cs_context_own_v1.m`, `analyses/run_m0_cs_own_v1.m`, `src/kernels/jwpe_pl_m0_run_surrogate.m` |
| M0 PF | `caseConfig.config.maxFunctionEvaluations` and `totalNewObjectiveCap`; include any new seed evaluations before search and reserve one recheck | `analyses/m0_pf_context_own_v1.m`, `analyses/run_m0_pf_own_v1.m`, `src/kernels/pf_pl_prepare_seeds.m` |
| M1 free or fixed Kd | `caseConfig.options.MaxFunctionEvaluations`, `objectiveCap`, `hardBudget`; `options.MinSurrogatePoints` and `MaxTime` | `src/kernels/jwpe_m1_pl_search.m`, `src/kernels/jwpe_m1_pl_session.m`, `src/kernels/jwpe_fixed_search_v1.m`, `src/kernels/jwpe_fixed_session_v1.m` |
| M1 local closures | `caseConfig.closure.MaxFunctionEvaluations`, `maxPollForwards`, `maxCompletePollsPerMesh`, and total `hardBudget` | `src/kernels/jwpe_m1_pl_closure.m`, `src/kernels/jwpe_fixed_closure_v1.m`, and the corresponding session counters |

For a plain M1 search with no closure, choose a consistent objective cap and
set `hardBudget` to at least that cap plus one recheck. For a closure, include
all separately budgeted pattern-search calls and deterministic polls plus the
recheck; inspect the selected closure role rather than adding every field
blindly. Keep `MinSurrogatePoints` within the available objective budget.

If increasing complete polls per existing mesh, increase `maxPollForwards`
consistently. A conservative allowance is the number of meshes times
`maxCompletePollsPerMesh` times twice the nuisance-coordinate dimension;
boundary exclusions can reduce actual calls. Keep mesh values, move tolerance
and the allowed number of closures unchanged when changing budget alone.

For M0 PF, the explicit-normalized-start path uses
`config.maxFunctionEvaluations` directly; it does not subtract historical
seed costs from that setting. Other supported seed paths subtract new seed
evaluations from `totalNewObjectiveCap`. Declare consistent maxima for the
path you actually use.

Method recipes are in `analyses/recipes/M0_CS.json`,
`analyses/recipes/M0_PF.json`, `analyses/recipes/M1_FREE.json` and
`analyses/recipes/M1_FIXED.json`. If editing a recipe in your copy, update its
paired limits and then its asset binding in the code manifest. If instead
changing a completed case structure before saving a new job, record that
effective configuration in the method identity; the catalogue hash alone
does not describe such an override. Do not change anchors, physical supports,
closure eligibility, confidence thresholds or anchor-challenge handling to
make a longer run pass. Supply the new run hashes to the finalizer; never
replace the provenance of old endpoints.

## Observation error and temporal capacity comparisons

These analyses have additional limits beyond the outer optimizer options.

| Analysis | Files and fields to adjust together |
|---|---|
| Observation-error comparison | `src/kernels/JWPE_OEM_optimize_v1_3.m` reads `cfg.optimizer.MaxFunctionEvaluations.CS/PF`, `polishMaxFunctionEvaluations.CS/PF`, `MaxIterations` and `polishMaxIterations`. `analyses/run_oem_own_v1.m` and `src/kernels/jwpe_oem_problem.m` enforce `cfg.public.rawForwardHardMax`; `src/kernels/jwpe_oem_assemble.m` checks the final allowance |
| G1 versus constant capacity and LOG2 | `src/kernels/jwpe_opt_master_config.m` supplies `maxFunctionEvaluations`; `src/kernels/jwpe_opt_run_surrogate.m` checks nonstandard budgets. `src/kernels/jwpe_03b_make_problem_v1.m` and `src/kernels/jwpe_03b_log2_make_problem_v1.m` also explicitly require 50 calls |
| Capacity raw accounting and outputs | `analyses/capacity_inputs_own_v1.m` creates 51-forward allowances. `analyses/run_capacity_own_v1.m` records `rawMaxEach=51` and `rawMaxStage=102`; `analyses/run_log2_own_v1.m` records `rawMaxStage=51`. `src/kernels/jwpe_capacity_assemble.m` explicitly checks `rawAttempts<=51` |

For a capacity budget of B outer calls, replace the relevant 50-call checks
with the declared B, allocate B+1 raw evaluations per fitted model and update
the recorded stage totals. With G1 and A1 both fitted, that is 2*(B+1); with
LOG2 fitted against an existing G1 result, it is B+1 new raw evaluations.
Keep the supplied G1 result fixed in the latter comparison.

The shared surrogate wrapper's nonstandard-budget path also requires
`allowNonstandardBudget=true` in the newly declared optimizer configuration
when using a cap other than 50. This flag does not update any other limit:
retain the builder checks against your declared B and the matching raw
allowances rather than removing assertions. Changing the shared optimization
constructor can affect multiple analyses, so review each caller in the
modified copy.

Observation-error comparison runs three families with four starts each in
`run_oem_own_v1.m`. Estimate a raw cap covering the initial reference,
searches, refinements and their evaluations; there is no general one-to-one
conversion from an fmincon function limit to reactor forwards. Keep the
finite-difference scheme and parameterization fixed when comparing budgets.

If changing inner error-profile budgets separately, inspect
`src/kernels/jwpe_inf_config.m` (`errorProfile.MaxIterations` and
`MaxFunctionEvaluations`), `src/kernels/m1pl_sb_cfg_v3.m`
(`blockMaxIterations`, `blockMaxFunctionEvaluations`) and
`src/kernels/jwpe_sigma_config.m`. OFL uses
`analyses/ofl_sigcfg_own_v1.m` and `analyses/ofl_sigma_own_v1.m`.
The sigma routines compare their method fields for consistency. Keep all
copies aligned; do not loosen likelihood/recheck tolerances to compensate
for inadequate inner optimization.

## Global sensitivity analysis

`analyses/prepare_gsa_own_v1.m` generates `cfg.rng.rows` six-column samples.
`analyses/run_gsa_own_v1.m` processes those rows, checks convergence every
250 samples and reserves independent rechecks. `src/kernels/g2_conv.m` uses
`cfg.(reactor).budget.mcMax` to identify the maximum-size terminal state.

For a larger design, set `cfg.rng.rows` and the selected reactor's
`budget.mcMax` consistently, using a multiple of 250 large enough for the
existing convergence history. Adjust `budget.hardTotal` to cover the main
design, `cfg.qa.count` independent rechecks and `budget.retryReserve` raw
retries. Only the existing single identical retry for classified failures is
supported; a larger reserve does not authorize repeated retries of a point.
Rebuild the sampled/native arrays from the new configuration instead of
combining an old matrix with a new row count. Keep distributions, six-column
mapping, 18 outputs and convergence thresholds unchanged. More samples can
still end in a convergence-review state.

## MCMC length and checkpoint frequency

The current consumer is `analyses/run_mcmc_own_v1.m`. Before a new run, supply
consistent values in the explicit `b.config` structure:

- `config.sampler.ramSweeps`: adaptive warmup sweeps per chain.
- `config.sampler.productionRows`: retained frozen-MH rows per chain.
- `config.sampler.checkpointEvery`: complete-block checkpoint interval.
- `config.maximumRawPerChain`: allowance for all warmup and production
  forwards, including initialization. With the present one mechanistic
  proposal per sweep, no retries and no cache savings, allow at least
  1 + ramSweeps + productionRows raw forwards per chain.
- `b.sweepLimit`: work per invocation, not additional chain length. Use `Inf`
  or a finite positive integer multiple of `config.sampler.checkpointEvery`; it is
  checked at complete boundaries and may span more than one chain.

The retained CS method constructor `src/kernels/tb_cfg_v1.m` also contains
`sampler.mhSweeps` and descriptive `budget.*` totals. These do not replace the
`productionRows` and `maximumRawPerChain` fields required by the current
controller. Populate the effective configuration explicitly and update any
reported target/forward/error-proposal totals and diagnostic prefixes used
by your configuration. Keep prefixes within the retained length.

For example, 2000 warmup sweeps and 20000 retained rows imply a worst-case
allowance of 22001 raw forwards per chain under those assumptions, or 88004
across four chains. These are arithmetic planning bounds, not measured costs
or a convergence recommendation. Review memory and storage for physical and
sampled seven-column arrays in each chain and their checkpoints.

Do not change the total length, warmup, numerical method or cfg during a
resume: the controller requires equality with the saved configuration.
Choose a longer campaign before starting a new run. A finite `sweepLimit`
can split that declared campaign across sessions; it does not extend it.
Keep four independent chains, no routine thinning, and the original rank-based
convergence requirements. Increasing length cannot certify a failed diagnostic.

## Posterior selection and propagation

With longer certified chains, keeping 500 selected draws requires updating
`config.(reactor).rowsPerChain` and `stratumWidth`, so that
`strataPerChain*stratumWidth == rowsPerChain`. Production selection currently
uses four chains, 125 equal strata per chain and 500 joint rows. Thus the
retained row count must be compatible with 125 equal strata; do not silently
discard rows to satisfy that layout. Inspect `analyses/run_selection_own_v1.m`
and `src/kernels/ppu_select_v1.m`, and use a new compatible closed chain source.

Increasing the selected count itself is a separate implementation change,
not just a longer MCMC campaign. Inspect all of these consumers together:

- `analyses/run_selection_own_v1.m`: 500/125 production checks and array sizes.
- `analyses/jwpe_own_production_guard_v1.m`: certified 500-row source checks.
- `analyses/run_propagation_own_v1.m`, `analyses/run_holdout_own_v1.m` and
  `analyses/run_external_own_v1.m`: 500-row arrays, loops and raw allowances.
- `src/kernels/jwpe_eval_noise.m`: 500 selected rows and 20 error replicates
  per draw. Replicate count affects noise arrays and RNG ordering, not the
  number of mechanistic forwards for a fixed selection.

External SMX evaluation additionally performs two initialization-sensitivity
forwards before the draw loop, uses selected row 426 for that check and enforces
a raw cap of 502. If adapting the selection size, update that row choice and
the cap consistently, preserving the two checks; the no-cache forward bound
is the number of selected draws plus two, not just the draw count.

Update dimensions, loop bounds, caps, source receipts and downstream metadata
consistently in the modified implementation. Preserve complete joint parameter
rows, source certification and the distinction between parameter uncertainty
and observation error. More error replicates cannot replace more independent
posterior information.

## OFL fits and scenarios

`analyses/run_ofl_own_v1.m` declares A1 block caps `[200 200 125]` and raw
maximum 528, or G1-screen caps `[100 60]` and raw maximum 162. Matching solver
limits are in `src/kernels/ofl_options_v1.m`,
`src/kernels/pa_options_v1.m` and `src/kernels/g1s_options_v1.m`.
Adjust the appropriate block caps, options and total raw allowance together;
reserve one independent recheck per block. Inspect
`analyses/jwpe_ofl_own_evaluate_v1.m` for raw accounting. Changing only an
options function leaves the controller cap unchanged. Preserve the number
and purpose of blocks, shared within-run cache and frozen error model.

For PF dispersion, `analyses/run_pf_dispersion_own_v1.m` allocates 6000 rows,
loops over 500 draws and requires exactly 5500 new forwards, reusing the
500-row baseline. Changing `config.f` or the draw count requires reviewing
all of those constants. In general, with one reused baseline, D draws and C
coordinates imply D*C summary rows and D*(C-1) new forwards. Also inspect
`src/kernels/pf_dax_math_v1.m` and `src/kernels/pf_dax_coordinates_v1.m`;
keep `config.selectedRows` equal to D and `config.logicalPairs` equal to D*C.
Retain a matched baseline, its index and the required zero-dispersion entry.
Do not interpret a larger coordinate set as more posterior information.

CS time equivalence in `analyses/run_cs_time_own_v1.m` uses the supplied full
retained chains algebraically, with no mechanistic optimizer budget. A larger
chain source changes input size and summary cost, not a forward allowance.
Holdout evaluations similarly do not need an optimization budget: preserve
the frozen fit and never refit against responses reserved for evaluation.

## Update the identity of a modified code copy

The manifest lists source files in `files` and method recipes in `assets`.
Both their byte counts and SHA-256 values must match. Changing either source
or recipes changes the manifest hash used as the code identity. Old jobs and
checkpoints must remain attached to their original code.

The following preparation-only MATLAB example refreshes an existing inventory
after reviewed edits in a separate copy, without running a scientific analysis.
Use a fresh MATLAB session and select the modified copy, not the original
distribution. It preserves the previous manifest and refuses to replace an
existing backup. It covers edits to existing listed files only; adding or
removing modules requires explicitly updating the inventory and reviewing
their dependencies and unique function names first.

```matlab
modifiedRoot = uigetdir(pwd,'Select your modified package copy');
assert(ischar(modifiedRoot),'No folder selected.');
manifestFile = fullfile(modifiedRoot,'code_manifest.json');
backupFile = fullfile(modifiedRoot,'code_manifest.before_budget_changes.json');
nextFile = fullfile(modifiedRoot,'code_manifest.updated.json');
assert(isfile(manifestFile) && ~isfile(backupFile) && ~isfile(nextFile));
[ok,msg] = copyfile(manifestFile,backupFile);
assert(ok,'%s',msg);
binding = jsondecode(fileread(manifestFile));
assert(strcmp(binding.schemaVersion,'JWPE_EXECUTION_CODE_v1'));
groups = {'files','assets'};
for g = 1:numel(groups)
    group = groups{g};
    for k = 1:numel(binding.(group))
        relative = binding.(group)(k).path;
        assert(~java.io.File(relative).isAbsolute() && ~contains(relative,'..'));
        file = fullfile(modifiedRoot,relative);
        details = dir(file);
        assert(isscalar(details) && ~details.isdir);
        fid = fopen(file,'rb');
        assert(fid>=0);
        bytes = fread(fid,Inf,'*uint8');
        fclose(fid);
        md = java.security.MessageDigest.getInstance('SHA-256');
        if ~isempty(bytes), md.update(typecast(bytes,'int8')); end
        digest = typecast(md.digest(),'uint8');
        binding.(group)(k).bytes = details.bytes;
        binding.(group)(k).sha256 = ...
            lower(reshape(dec2hex(digest,2).',1,[]));
    end
end
fid = fopen(nextFile,'w');
assert(fid>=0);
fprintf(fid,'%s\n',jsonencode(binding));
fclose(fid);
```

Review `code_manifest.updated.json` against your intended file list before
replacing `code_manifest.json` in the modified copy. Keep the backup. Then
open that copy in a fresh MATLAB session, run `setup_jwpe`, inspect the reported
code identity and effective function paths, and prepare new jobs. The example
does not discover omitted dependencies or validate equations; refreshing hashes
alone never establishes numerical equivalence.

## Checks before a larger campaign

1. Review the diff: only the intended budgets and matching metadata/checks
   should change. Reconcile outer, raw, seed, poll, retry and recheck allowances.
2. Confirm that every new job names the new data/method/code identity and a
   new output folder. Do not substitute these identities into old results.
3. Inspect the prepared configuration and solver options without execution.
   Confirm the active limits, not just comments or a variable edited after save.
4. Check syntax and dependencies, then perform a small separately budgeted
   synthetic functional run of any modified branch before an expensive campaign.
   Do not present that test as convergence or as reproduction of the article.
5. Estimate storage, checkpoint size and runtime, retain all consumed attempts,
   and inspect final counts, recheck agreement and convergence diagnostics.
   A limit reached without the required checks is a result for review, not
   permission for automatic extension or relaxed acceptance criteria.
