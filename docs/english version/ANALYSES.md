# Analysis interfaces and order of use

[Português](../portuguese-br%20version/ANALYSES_PT_BR.md) · [Documentation index](INDEX.md)

All analyses use explicit input specifications, a new output directory and
`jwpe_job(job,'prepare')` before an intentional `jwpe_job(job,'execute')`.
The latter may perform substantial scientific computation. There is no automatic
execution of the next reactor or next analysis. Configuration construction is
not model execution. `jwpe_job_contract` reports the required fields; controllers
are in analyses/. Each `b.field` in a controller refers to a payload field.

For GSA, [the GSA guide](GSA.md) explains the explicit 32-sample test mode,
required settings, outputs and unchanged production-convergence requirements.

For OFL calibration, [the OFL budget guide](OFL_CALIBRATION.md) explains the
explicit short test and the unchanged full-campaign defaults.

| analysis | Explicit analysis fields | Dependency / principal output |
|---|---|---|
| calibration_m1_fixed | inputs,action | Prepared data/cfg/starts; result.mat and parameter/prediction tables |
| observation_error_selection | inputs | Separate historical M0 comparison; cfg,data,settings,reactor,nObs,isCensored,isQuantified,nCensored,role,identity; three families/four starts |
| observation_error_joint | csRun,pfRun | Historical sources with 50 observations/reactor and a 145 d horizon; joint comparison |
| capacity_g1_a1 | context,core,capacityBase,capacityConfig,thetaRef | 33 quantified I–II observations above LOD; independent G1/A1 fits |
| capacity_log2 | preceding fields,g1,g1Reference | Own frozen G1 recheck; one LOG2 fit |
| capacity_joint | csBase,csLog2,pfBase,pfLog2 | Four own completed sources; joint comparison |
| pl_m0 | forcing,observations,settings,core,catalogue,caseConfig | Own rechecked anchor and starts; one CS/PF endpoint |
| pl_m1_free | context,caseConfig,catalogSHA256 | Own anchor/configuration; one conditional endpoint |
| pl_m1_fixed | context,caseConfig,catalogSHA256 | Kd=0.020; anchor/conditional endpoint |
| pl_m1_free_closure | context,caseConfig,catalogSHA256 | Explicit local closure, not automatic discovery |
| pl_m1_fixed_closure | preceding fields,anchor,candidate,campaignID | Eligible own endpoints; at most one closure per campaign/reactor |
| pl_finalize | model,nativeRuns,catalogSHA256,requiredOrigins,anchorCaseId,points,D95 | Explicit own origins; lower envelope, preserving incomplete/HOLD state |
| gsa | context,inputs | inputs.cfg and reactor; MC design and SRRC histories |
| mcmc | context,config,initial,action,sweepLimit | Four own starts/proposals/RNG; chains and diagnostics |
| selection | config,chains,chainCertification | Four separate joint physical chains; selected.mat/CSV |
| propagation | context,config,selected | Closed certified own selection in production; mean/predictive bands |
| temporal_holdout | context,config,selected,reference,responseFile | Compatible own baseline; prediction saved before response scoring |
| external_smx | context,config,selected,study,responseFile | Own PF uncertainty, study-specific physics/clock; no refit |
| ofl_calibration | context,config | A=1, own data; kb fit and combined observation error |
| ofl_g1_screen | context,config | Separate G1 comparison configuration, not the A=1 fit |
| ofl_holdout | config,acceptedCalibration,responseFile | Own frozen A=1 state/parameters/error scales; no reprofile |
| cs_time_equivalence | chainsCS,chainsPF,config | All own retained rows, separate reactors; algebraic summaries |
| pf_dispersion | context,config,selected,baseline | Matched PF baseline and selection; Dax multipliers including 0 |
| numeric_products | product,numericInput,numericPolicy | Own saved sources; activity,correlations,marginals,diagnostics or bands |

The simple five-file constructor `jwpe_prepare_m1` covers fixed-Kd calibration.
Other analyses expose the structured-input interface; they are not automatic
conversions of the five M1 files. Their nested configurations must be supplied
explicitly, including study-specific arrays and any previously computed own
results. This interface does not replace scientific design of a new experiment.

## Model/error/capacity comparison

The observation-error comparison is a separate, optional historical M0
analysis. Its joint finalizer expects 50 observations per reactor and a
145 d source horizon, including the historical Phase III records. It is not
the 33-observation Phase I–II M1 calibration. Do not substitute its historical
sources for the final calibration or posterior sources, or feed the five-file
M1 demonstration directly into this route.

The error-comparison inputs require the numerical optimization configuration
and the user's own six-coordinate initial reference in
cfg.anchorHistoricalEngine.(reactor), in [Kd,kSigma,Fdir,kG,tinf,Ai]. The field
name reflects the kinetic formulation, not a loaded historical fit. No such
reference result is included. The common numerical settings are visible in
jwpe_inf_config and jwpe_capacity_core_config. Capacity settings are constructed
by jwpe_03b_config_v1 / jwpe_03b_log2_config_v1 with explicit reference settings.
Reusing a G1 result requires matching observations and a completed own source.

The current capacity-comparison adapter requires 33 quantified observations
strictly above its configured detection limit. The censored M1 demonstration
inputs are not directly compatible with G1/A1/LOG2 comparison. Supporting
censored observations here requires an explicit adaptation; do not delete or
impute observations merely to pass the check. A manually constructed capacity
context also requires `dataFile` and `harmonization` with the actual input
provenance and preprocessing, as explained in [Input contracts](INPUTS.md).

## MCMC and selection

The controller requires `config.sampler.ramSweeps`,
`config.sampler.productionRows`, `config.sampler.checkpointEvery` and
`config.maximumRawPerChain`, together with the support, prior, solver and
diagnostic fields. `initial.physical` and `initial.sampled` are 4-by-7 arrays;
`initial.Qm0` is 5-by-5 and `initial.Qe0` is 2-by-2. For CS,
`initial.rng` is a four-element cell array containing one RNG state per chain.
PF uses the four seeds in `config.rng.fullSeeds`. Covariance matrices must be
positive definite in sampled coordinates. No article starting states or
proposals are supplied. `tb_xform_v1.m`, `tb_prior_v1.m`, `tb_like_v1.m` and
the PF likelihood adapter `pftb_like_v1.m` implement the transformations,
physical prior, Jacobian and likelihood. RAM warmup precedes frozen-MH
sampling, with no routine thinning.

Use `action='start'` or `'resume'`. `sweepLimit` accepts `Inf` or, if finite,
a positive integer multiple of `config.sampler.checkpointEvery`. It limits
work to complete checkpoint boundaries; it is not permission to drop an
incomplete block or restart it.
Production certification retains Rhat<1.01 and bulk/tail ESS>400 for all seven
parameters. Short examples cannot demonstrate those conditions.

Production selection additionally names chainSourceFolder containing the
closed own MCMC result. It selects 500 joint rows, 125 per chain, using complete
strata and a local RNG. Seven physical columns remain paired. It does not pool
CS and PF posterior populations.

## Propagation, evaluation and scenarios

Production propagation/holdout/external/PF scenario additionally specify
selectionSourceFolder. Their full controllers retain 500 selected rows. A smaller
table is not accepted as a production shortcut. Observation-error draws are
separate from parameter uncertainty. Phase III evaluation never refits parameters
or error scales. External studies have different forcing/clock/physics adapters;
do not reuse the original study's measurements as implicit defaults.

For OFL holdout, also specify acceptedFitFolder. For full CS time equivalence,
specify chainSourceCS and chainSourcePF; both must be closed certified sources,
and the arrays passed to the scenario must match them. There is no refit in the
CS algebraic normalization. PF dispersion changes only Dax and requires baseline
identity/prefix agreement; Dax=0 does not mean zero velocity.

Test mode cannot certify a production source. A result folder's existence is
not evidence of numerical completeness, convergence or scientific acceptance.
Do not bypass source/identity checks to force a downstream analysis to run.

## Production campaign configuration

A short functional run and a complete scientific campaign have different
purposes. Before production, define the data, model, bounds or priors,
numerical settings, total evaluation or iteration budget and acceptance
criteria. A larger budget alone does not establish convergence.

See [Increasing campaign budgets](CAMPAIGN_BUDGETS.md) for the source files,
configuration fields, coupled counter checks, examples and code-identity
procedure needed to enlarge each type of campaign in a separate copy.

For a measured dataset compatible with [the input contract](INPUTS.md),
the simple M1 production sequence is:

```matlab
% inputFolder and outputRoot are absolute paths chosen by the user.
% inputFolder contains the five prepared files for this reactor.
[job,inputs] = jwpe_prepare_m1(inputFolder,outputRoot,'CS','run01','production');
plan = jwpe_job(job,'prepare');
disp(inputs.cfg.budget)
disp(plan)
```

This block prepares and inspects the job without a forward. After reviewing
the specification and accepting up to 251 raw forwards, execute separately:

```matlab
result = jwpe_job(job,'execute');
```

Use `'PF'` for a separate PF job, with its own inputs and destination. Keep
generated synthetic inputs in `demo` mode. The current constructor fixes
production at 250 objective calls and one independent recheck (up to 251 raw
forwards), without a finite optimizer time limit. The runtime checks these
budgets. Editing a returned cfg or an old job is not a supported way to
increase them. A different M1 calibration budget requires a consistent change
to the configuration and its runtime checks in a separate code version,
followed by a new job and new output folder. Do not amend an existing checkpoint.

Other analyses require their own explicit nested configurations, as listed
above. For MCMC, production length and work per invocation are distinct:
`config.sampler.productionRows` defines the intended chain length, while
`sweepLimit` limits the invocation to complete checkpoint boundaries. Set
warmup, production length, checkpoint frequency and raw-forward cap together
before starting, preserving supports, priors and numerical settings across
continuations. The generic job writer is not a complete template or a
validation of these scientific choices.

For profile likelihood, a full campaign consists of separately configured
coordinate searches and its finalizer, not a larger budget on a single point.
See [Profile likelihood recipes](PROFILE_LIKELIHOOD.md). Sensitivity analysis,
selection, propagation and evaluation likewise retain their own configuration
and source requirements. The distributed five-file example does not configure
the entire analysis sequence automatically.

## Editing and resumption

For the PF axial-dispersion input requirements, explicit short-mode budget and
unchanged full-campaign defaults, see [PF dispersion](PF_DISPERSION.md).

code_manifest.json binds code, not prose. Changing a source or method recipe
requires intentionally rebuilding its code identity and starting a new run;
never substitute an identity into an old checkpoint. The distributed manifest
is generated for the distributed code. Keep a separate modified copy when
developing extensions. Rewriting the manifest alone does not validate a change.

The [resumption walkthrough](GETTING_STARTED.md#5-resumption) includes the
preparation and separate execution commands, checkpoint requirements and
the distinction between continuing an unfinished run and reopening a
completed result. Only M1 calibration and MCMC expose the generic resume
interface; do not apply it to other analysis types.
