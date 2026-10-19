# Using the models with your own data

[Português](../portuguese-br%20version/USING_YOUR_OWN_DATA_PT_BR.md) · [Documentation index](INDEX.md)

The package provides study-specific implementations, not a general fitting
application for any compound or reactor. You can reuse the equations and
analysis methods, but the input interfaces retain assumptions from the SMX
study. This guide explains what the existing interfaces accept and what needs
adaptation before analysing another experiment.

Start with the fictitious example in [Getting started](GETTING_STARTED.md).
It separates preparation from execution and explains the output files. A
successful short example establishes that the workflow runs; it does not
establish model suitability or optimizer convergence.

## Check compatibility before preparing files

The five-file constructor, `jwpe_prepare_m1`, prepares the fixed-Kd M1
calibration only. These restrictions apply to that constructor and its runtime;
they are not universal properties of micropollutants.

| Item | Current implementation | What to review for your experiment |
|---|---|---|
| Reactor representation | CS tanks in series or PF axial dispersion | Whether either hydraulic representation describes your reactor |
| Calibration calendar | Day 0 origin; Phase I through day 49; Phase II through day 94 | Time origin, operational changes and calibration endpoint |
| Sampling | 33 matching forcing and observation times, with 17 in Phase I and 16 in Phase II | Sampling frequency, inlet records and response availability |
| Initial conditions | Zero internal concentration in the M1 calibration simulations | Whether the compound was already present at the chosen time origin |
| Biomass | Scalar TSS and VSS concentrations, constant in time and space | Whether measured biomass supports this approximation |
| CS hydraulics | Two, two and three tanks in the three operational phases | Phase-specific hydraulic structure and residence times |
| PF hydraulics | 71 spatial nodes and 69 internal states | Geometry, velocity, dispersion and numerical resolution |
| Temporal capacity | Normalised Gompertz G1 | Whether changing apparent biotransformation capacity is supported |
| Partition coefficient | Kd fixed at 0.020 L/gTSS | Compound-specific evidence and treatment of its uncertainty |
| Observation model | Combined additive and proportional Gaussian errors with left censoring | Error behaviour and analytical censoring convention |
| Detection limit | 0.0163 micrograms/L | The limit applicable to your measurements |

The physical inputs include three sets of hydraulic conditions because the
source model also supports the later evaluation period. Calibration uses only
Phases I and II; supplying a third set does not include third-phase responses
in the fit.

Different concentration values can be supplied through the existing files
when these structural and numerical requirements are genuinely appropriate.
A different calendar, observation count, detection limit or fixed Kd requires
an explicit adapter or configuration change with corresponding changes to
validation checks. Do not discard or duplicate measurements, relabel phases
or rescale time just to satisfy the interface.

## Prepare compatible inputs

Keep original measurements unchanged. Prepare a separate input folder for each
reactor and a separate working folder for outputs. Obtain the necessary data
permissions as described in [Data access and preparation](DATA_ACCESS.md).
The required fields are defined in [Input contracts](INPUTS.md).

1. `forcing.csv` contains inlet concentrations and times, without measured
   effluent responses. The current method uses next-value zero-order-hold
   reconstruction; establish whether that convention represents your feeding
   and sampling procedure before using it.
2. `observations.csv` contains measured effluent concentrations, phases,
   detection limits and censoring flags. Missing observations are not zero.
   This recipe stores a censored response as zero and flags it; retain its
   original measurement separately. Positive values below the detection limit
   are rejected unless prepared using that convention.
3. `phases.csv` defines the calibration periods. The existing constructor
   requires the source boundaries and counts listed above.
4. `physical.json` contains your biomass and hydraulic inputs. Use days,
   micrograms/L, g/L for TSS and VSS, hours for residence times, m/day for
   velocity and square metres/day for dispersion. TSS and VSS have different
   roles and must not be substituted for one another.
5. `initialization.json` provides starting parameter vectors, their names,
   the random seed and `dataOrigin`. Declare the actual origin of your data;
   generated examples must remain labelled `SYNTHETIC`.

The parameter order is `[Kd,kb,kG,tinf,Ai]`. Only the last four parameters are
estimated by this constructor. Its search bounds are:

| Parameter | CS range | PF range | Unit |
|---|---|---|---|
| Kd | Fixed at 0.020 | Fixed at 0.020 | L/gTSS |
| kb | 0 to 6.250 | 0 to 0.240 | L/(gVSS day) |
| kG | 0.030 to 2.000 | 0.030 to 2.000 | 1/day |
| tinf | 10 to 60 | 10 to 60 | day |
| Ai | 0 to 0.300 | 0 to 0.300 | Dimensionless |

These bounds describe the supplied deterministic recipe, not general physical
limits or the supports of every analysis. In particular, the PF upper bound
for kb is not a universal bound for other compounds or Bayesian fits. The
`points` field must contain complete five-column vectors inside these bounds.
Starting points, priors and search ranges should reflect your scientific
question rather than a desire to recover the SMX article's estimates.

For compatible measured inputs, `jwpe_prepare_m1` with mode `production`
reads the files and saves a job without fitting the model. Production mode
budgets 250 objective calls and one independent recheck, with up to 251 raw
model evaluations; it has no finite optimizer time limit by default. The
synthetic `demo` mode budgets 24 objective calls and one recheck. Changing the
mode does not adapt an incompatible dataset or certify convergence. Follow
[Getting started](GETTING_STARTED.md) for preparation, inspection and the
separate execution call.

## Adapt the model when the experiment differs

A change of compound name does not change the equations. M1 represents an
apparent irreversible sink for the parent compound, with solid-liquid
partitioning and a temporal capacity multiplier. It does not explicitly
resolve liquid-solid mass-transfer kinetics. The Gompertz multiplier describes
apparent temporal capacity, not directly measured biomass growth or removal
efficiency. Check these assumptions against your experimental design before
interpreting fitted coefficients as compound-specific properties.

Work in a separate code copy when changes are needed. The main entry points
for assessing their scope are:

| File or location | Responsibility |
|---|---|
| `src/api/jwpe_prepare_m1.m` | Five-file preparation, phase and censoring checks, context and job creation |
| `src/kernels/jwpe_interface_tables_v1.m` | Input table reading and checks |
| `src/kernels/jwpe_interface_settings_v1.m` | Physical inputs and hydraulic settings |
| `src/kernels/jwpe_m1_calibration_config.m` | Fixed Kd, bounds, solver settings and calibration budgets |
| `src/kernels/m1_cs_sim_v1.m` and `src/kernels/m1_pf_sim_v1.m` | Initial states, time horizon and hydraulic simulations |
| `src/kernels/JWPE_activity_G1.m` | Normalised Gompertz capacity function |
| `analyses` | Analysis-specific controllers, source checks and downstream configurations |

A different observation schedule needs more than a revised `phases.csv`: the
constructor, simulation horizon, context, phase checks and any downstream
controllers must agree. A nonzero initial concentration requires an explicit
initial-state implementation; the five-file interface has no field that
replaces the zero initial state. Spatially varying biomass, another hydraulic
model or a different capacity law likewise requires a model adaptation,
not merely another JSON value.

Preserve units and the intended likelihood when making an adapter. Check its
input reading and settings first, then use a small bounded functional run
before a full analysis. Model or code changes require a consistent new code
identity and new jobs; do not bypass integrity checks or resume old checkpoints
under a changed method. Hash agreement alone does not validate a new model.

## Extend the analysis beyond fixed Kd calibration

[Analysis interfaces](ANALYSES.md) describes the controllers and their
dependencies. Other analyses use explicit structured inputs; they are not
automatically configured from the five M1 files. The top-level job contract
lists required fields but does not construct all nested scientific settings
for a new experiment.

The optional historical M0 observation-error comparison has its own source
requirements, including a joint finalizer for 50 observations per reactor
through 145 d. It is separate from final Phase I–II inference. The current
G1/A1/LOG2 capacity adapter requires 33 quantified observations above LOD,
not the censored M1 demonstration. Review these distinctions in
[Analysis interfaces](ANALYSES.md) before reusing a context.

Profile likelihood needs your own fitted anchor, appropriate coordinates,
starting points and search settings. The supplied coordinate catalogues
reproduce the study's search design, not a universal grid for another compound.
A fixed-Kd profile remains conditional on that value. See
[Profile likelihood recipes](PROFILE_LIKELIHOOD.md).

Bayesian inference needs justified priors, supports, starts and sampler
settings. Do not transfer the SMX Kd prior or fitted error scales without
independent justification. Short chains cannot establish posterior convergence.
Subsequent production analyses require compatible, closed and certified
sources; several controllers require the specified 500-draw joint selection
rather than an arbitrary smaller table. Keep the parameters within each draw
together and keep reactor posteriors separate.

For temporal holdout or independent-data evaluation, separate prediction
inputs from responses reserved for evaluation. Changing the prediction context
must not refit parameters using those responses. Mean-response bands represent
parameter uncertainty; posterior-predictive bands additionally include the
observation-error model. Report which band is used.

## Record the choices needed to interpret a new analysis

Before a full run, document the compound and reactor, data provenance and
permissions, units, time origin, initial state, phase boundaries, hydraulic
and biomass inputs, detection limit and censoring. Also record the equations,
fixed and estimated parameters, bounds or priors, solver settings, search or
sampler budgets, random-number settings and criteria for accepting the result.
Use distinct output folders for changed inputs or methods.

The associated article and its supplementary material explain the original
scientific choices. They provide a methodological reference, not automatic
validation for a different experiment. Complete reproduction of the published
numerical results requires the corresponding data and retained results,
subject to an explicit request and the relevant permissions.
