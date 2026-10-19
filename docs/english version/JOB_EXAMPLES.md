# Building jobs by analysis family

[Português](../portuguese-br%20version/JOB_EXAMPLES_PT_BR.md) · [Documentation index](INDEX.md)

Use the complete runnable M1 example first. The advanced examples below are construction patterns: named inputs must already contain your compatible data, settings or results. Empty template fields are not scientific defaults. Preparation does not certify every nested field.

## Complete synthetic M1 example

Run from the package root, choosing a new writable working folder outside it:

```matlab
previousPath = path;
info = setup_jwpe();
workRoot = uigetdir(pwd,'Choose an external working folder');
assert(ischar(workRoot));
folders = jwpe_make_demo_inputs(fullfile(workRoot,'inputs01'));
[job,inputs] = jwpe_prepare_m1(folders.CS, ...
    fullfile(workRoot,'outputs01'),'CS','demo01','demo');
plan = jwpe_job(job,'prepare');
disp(inputs.cfg.budget)
disp(plan.status)
descriptorFile = fullfile(workRoot,'descriptor_CS_demo01.mat');
assert(~isfile(descriptorFile) && ~isfolder(descriptorFile));
save(descriptorFile,'job');
```

Expected: `OWN_EXECUTOR_BOUND_NOT_RUN`; no simulation, optimization or result folder. The saved specification is under `outputs01/jobs`. The declared allowance is 24 objective calls plus one independent recheck, at most 25 raw forwards. Only the following separate command executes that allowance:

```matlab
result = jwpe_job(job,'execute');
disp(result)
```

Use `folders.PF` and `'PF'` for a separate PF job. For compatible measured inputs use your five-file folder and `'production'`, which declares 250 calls plus one recheck. Do not label fictitious inputs as production. Restore the previous session path with `path(previousPath)` when finished.

## Common advanced pattern

Inspect the contract before filling a payload. This example prepares no runnable scientific configuration by itself:

```matlab
[b,contract] = jwpe_job_template('mcmc','CS');
disp(contract.target)
disp(contract.requiredFields)
disp(b)
```

Complete `runID`, absolute `folder`, nonempty `identity.datasetID` and `identity.methodID`, then every analysis-specific field. Dataset identity should describe the actual input files; method identity should describe the effective settings, not just the name of a recipe. The writer assigns the current code hash. Set `mode='test'` for synthetic work or `'production'` for compatible measured inputs and closed production sources.

For compatibility across controllers, use a runID beginning with a letter,
followed only by letters, digits or underscores, with at most 32 characters.
GSA and MCMC reject hyphens even though the generic validator permits them.

Only after completing the payload, save and inspect it:

```matlab
b.executeScientific = true;
job = jwpe_save_job(b,jobFile);  % jobFile: new absolute MAT path
plan = jwpe_job(job,'prepare');
disp(plan)
save(descriptorFile,'job');     % descriptorFile: your chosen new MAT path
% Execute separately after reviewing inputs, destination and cost:
% result = jwpe_job(job,'execute');
```

`executeScientific=false` is the template default. Setting it true permits execution but does not start it when saving or preparing. Do not loop over the full registry unless you intentionally designed and budgeted every dependency.

## Error and capacity comparisons

Use `jwpe_job_template('observation_error_selection','CS')` for the separate historical M0 error-model comparison. Populate `b.inputs` with the fields in [Analysis interfaces](ANALYSES.md), including six-coordinate reference parameters and explicit error-model settings. Run PF separately. `observation_error_joint` uses reactor `'joint'`, with `csRun` and `pfRun` set to completed own historical result folders. Its finalizer requires 50 observations per reactor and a 145 d source horizon, including the historical Phase III records; this is not the 33-observation final M1 calibration. Do not substitute those historical sources for final calibration or posterior sources.

`capacity_g1_a1` needs `context`, `core`, `capacityBase`, `capacityConfig` and `thetaRef`. `capacity_log2` additionally needs the saved own `g1` fit and `g1Reference`; preserve that G1 source rather than recalculating it. `capacity_joint`, reactor `'joint'`, uses `csBase`, `csLog2`, `pfBase` and `pfLog2`. Inspect the corresponding controllers for complete nested configurations. Production finalizers reject synthetic or unclassified sources.

The capacity adapter requires 33 quantified responses strictly above its LOD.
It does not directly accept the censored M1 demonstration. A manually built
`context` must include `dataFile` and `harmonization` recording the actual
provenance and preprocessing. Do not discard or impute observations to satisfy
the adapter; another censoring pattern requires an explicit adaptation.

## Profile likelihood

```matlab
cases = jwpe_pl_cases('M1_FIXED','CS');
disp({cases.id}.')
```

Choose a case ID from this returned list. Given your rechecked `anchor` and compatible nuisance starts `normalizedStarts`, construct:

```matlab
caseConfig = jwpe_pl_case( ...
    'M1_FIXED','CS',caseID,normalizedStarts,anchor);
caseConfig.sigma = jwpe_sigma_config();
caseConfig.freeIndices = caseConfig.freeIndices(:).';
caseConfig.lower = caseConfig.lower(:).';
caseConfig.upper = caseConfig.upper(:).';
[b,contract] = jwpe_job_template('pl_m1_fixed','CS');
b.context = context;
b.caseConfig = caseConfig;
b.catalogSHA256 = caseConfig.catalogSHA256;
```

Finish the common fields and use the save/prepare sequence above. The M1 case structure carries its catalogue hash. PF also needs its explicit negative-state classification policy. [PL recipes](PROFILE_LIKELIHOOD.md) explains M0, free Kd, closures and finalization. One coordinate job is not a complete profile. Short bounded closure searches can legitimately stop incomplete; do not report their endpoints as complete confidence limits.

## GSA and MCMC

For GSA, start with `jwpe_job_template('gsa','CS')`, supply the response-free `context` and `inputs=prepare_gsa_own_v1(cfg,'CS')`. Review the sampling map, 18 output times, recheck policy and [short GSA configuration](GSA.md). Random design preparation is not a reactor simulation.

For MCMC use `jwpe_job_template('mcmc','CS')`, then supply `context`, complete `config`, `initial`, `action='start'` and `sweepLimit`. Inspect `run_mcmc_own_v1` and [Analysis interfaces](ANALYSES.md) for four-chain starts, transformed covariances, priors, RNG and complete checkpoint boundaries. A short test is not posterior certification. PF uses its own configuration and seeds; do not pool reactor populations.

## Selection and uncertainty evaluation

Use `selection` with `config`, separate physical `chains` and `chainCertification`; production also needs `chainSourceFolder`. For `propagation`, provide `context`, `config`, `selected` and the production `selectionSourceFolder`. Keep joint parameter rows together. Production currently uses 500 selected rows, 125 per chain.

`temporal_holdout` adds a compatible saved `reference` and separate `responseFile`; `external_smx` adds `study` and `responseFile`. Responses reserved for evaluation must not enter inference or prediction forcing. These are advanced study-specific adapters, not automatic conversions of the five M1 files. Mean-response bands contain parameter uncertainty; predictive bands also include observation error.

## OFL and scenarios

`ofl_calibration` or `ofl_g1_screen` uses `context` and `config`; [OFL calibration](OFL_CALIBRATION.md) gives separate short/full budgets. `ofl_holdout` uses `config`, `acceptedCalibration`, `responseFile` and, in production, `acceptedFitFolder`. Freeze the accepted state, parameters and error scales.

`cs_time_equivalence`, reactor `'CS'`, uses `chainsCS`, `chainsPF`, `config` and production `chainSourceCS`/`chainSourcePF`. Supply separate cells of chains, with equal declared retained length within each reactor: `config.chains`, `csRowsPerChain` and `pfRowsPerChain` must match the supplied arrays. Counts need not equal those of the article. This computation performs activity integrals and algebraic summaries, not mechanistic forwards or refitting.

`pf_dispersion`, reactor `'PF'`, uses `context`, `config`, `selected`, matching `baseline` and the production selection source. [PF dispersion](PF_DISPERSION.md) defines the pairing and budgets, including zero dispersion.

`numeric_products` uses `product`, `numericInput` and `numericPolicy`; inspect `run_numeric_own_v1` for supported products and required dimensions. It produces numbers, not figures. Numerical post-processing is still an intentional analysis: prepare and review its input first.
