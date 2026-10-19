# Explicit input contracts

[Português](../portuguese-br%20version/INPUTS_PT_BR.md) · [Documentation index](INDEX.md)

Do not use data without the appropriate permission. Generated example inputs
are entirely fictitious. Missing response is not zero or a censored observation.

Read [Using the models with your own data](USING_YOUR_OWN_DATA.md) for a
compatibility checklist and the adaptations needed for other experiments.

## Fixed-Kd M1 recipe

The five files in a reactor-specific input folder are:

| File | Fields | Meaning |
|---|---|---|
| forcing.csv | Reactor,Time_d,Cin_ug_L | Strictly increasing days and nonnegative inlet concentration; no effluent column |
| observations.csv | Reactor,Time_d,Phase,Cout_ug_L,CensorFlag,LOD_ug_L | Separate measured response, explicit phase/censoring and units |
| phases.csv | Reactor,Phase,Start_d,End_d,Use | I:[0,49], II:(49,94], Use=calibration |
| physical.json | Fields below | Biomass and hydraulic inputs supplied by user |
| initialization.json | parameterNames,points,seed,dataOrigin | Start rows, explicit random seed and origin |

For this recipe, forcing and observations have 33 matching times, 17 in I and 16
in II, last time 94 d. All times are positive and on the constructed audit grid.
No Phase III rows belong in these calibration files. Next-value zero-order-hold
reconstruction is retained; do not substitute an interpolation method silently.

Units: days, micrograms/L, TSS and VSS in g/L, residence times in hours,
velocity in m/day, axial dispersion in m2/day. TSS and VSS are not interchangeable.

Physical fields common to both models: hydraulicModel,XTSS_g_L,XVSS_g_L,
switchDays=[49,94]. CS uses hydraulicModel='CS_TIS', phaseResidenceTime_h with
three positive values, and tanksPerPhase=[2,2,3]. PF uses hydraulicModel='PF_ADM',
length_m,reportingVolume_L,velocity_m_d and Dax_m2_d, with one velocity/dispersion
value per phase. Its source discretization remains 71 nodes/69 internal states.
No measured biomass or hydraulic coefficients are provided as defaults.

Initialization order is [Kd,kb,kG,tinf,Ai]. `points` is an N-by-5 numeric matrix
within the declared supports, Kd=0.020. `seed` is an integer in [0,2^32-1].
`dataOrigin` identifies the source; demo mode requires the literal 'SYNTHETIC'.
The generator writes complete examples of these schemas.

### Censoring

The source deterministic likelihood encodes a censored response as stored zero,
with CensorFlag=true and LOD=0.0163 micrograms/L. A zero does not mean measured
absence. Preserve original values separately before preparing this representation.
The reader rejects a positive sub-LOD concentration with this recipe rather
than silently changing it. If such observations exist, explicitly encode their
censoring and retain their raw values/provenance outside the calibration table.
Different compounds/studies have their own LOD/configuration; do not transfer
this SMX LOD or fitted error scales automatically.

## Advanced execution specifications

`jwpe_job_contract(analysis,reactor)` lists required top-level fields and the
controller. A specification is a trusted MAT containing scalar `payload`.
Base fields: schemaVersion='JWPE_OWN_EXECUTION_v1',analysis,reactor,mode,
runID,folder,identity. mode is 'test' or 'production'; folder is an absolute new
destination. identity declares datasetID,methodID,codeHash; jwpe_save_job assigns
the codeHash of this code copy. Input identity must reflect all actual sources.
For a runID compatible with all documented controllers, start with a letter
and use only letters, digits and underscores, with at most 32 characters.
The corresponding pattern is `^[A-Za-z][A-Za-z0-9_]{0,31}$`.
Some controller checks are narrower than the generic top-level validator;
in particular, GSA and MCMC do not accept hyphens in runID.
`executeScientific=true` is needed for execution, never sufficient by itself
to bypass certification, horizon or source checks.

For model jobs, `context` is a scalar structure carrying reactor, settings,
forcingData, observationTimes_d, observed_ug_L, observationPhaseI,
observationPhaseII, auditTimes_d and phaseAudit as applicable. Preparing M1
returns a complete source-shaped context in inputs.context. Its forcingData
contains Time_d,Cin_ug_L and an entirely NaN Cout_ug_L compatibility column.
The prepared M1 context also includes `start_d`, `end_d`, `dataFile` and
`harmonization`. The capacity-comparison adapter consumes `dataFile` as input
provenance and `harmonization` as the record of actual preprocessing. Supply
these fields explicitly when constructing that context manually; do not
invent a source path or claim that no preprocessing occurred when it did.
Inferential contexts must not contain future responses. Prediction contexts use
only known forcing/physics/initial state until the prediction is saved and closed.

Context compatibility is analysis-specific. In particular, G1/A1/LOG2
capacity comparison currently requires 33 quantified responses strictly
above the configured LOD; the censored M1 example context cannot be reused
unchanged. Do not remove or impute observations to satisfy this restriction.

Schemas are analysis-specific, not interchangeable. In particular M0 has six
native mean parameters; M1 has five; MCMC adds both error scales. External and
OFL adapters have their own clocks, units and physical schemas. Inspect the
controller and its helper signatures before constructing an advanced payload.
The generic job writer validates top-level contracts but does not prove every
nested scientific setting or certify an arbitrary caller-supplied function handle.

Only open trusted MAT files. Hash identity detects accidental changes relative
to a known specification; it is not authentication of an unknown download.
