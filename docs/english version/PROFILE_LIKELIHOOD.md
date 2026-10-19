# Profile-likelihood recipes

[Português](../portuguese-br%20version/PROFILE_LIKELIHOOD_PT_BR.md) · [Documentation index](INDEX.md)

The four JSON files in analyses/recipes contain only method settings: exact
fixed coordinates, supports, maps, budgets and options. They omit the article's
fitted anchors, endpoints, objective values, initial banks and file identities.
They contain 92 M0-CS, 46 M0-PF, 39 M1-free and 50 M1-fixed search/closure recipes.
Some coordinates were diagnostics; category/official-support fields preserve
that distinction. Not every recipe belongs in a reported confidence interval.

Read without running a model:

```matlab
cases = jwpe_pl_cases('M1_FIXED','CS');
disp({cases.id}.')
```

`jwpe_pl_case(model,reactor,caseID,normalizedStarts,anchor)` fills one recipe with
new nuisance-coordinate starts on [0,1] and the user's own rechecked anchor
structure with theta/nll. No objective value is assigned to an unevaluated start.
For M1 it converts the symbolic MinSurrogatePoints option to the corresponding
number and supplies the catalogue identity. For M0 it supplies explicit initial
normalized rows; the outer catalogue must also carry the user's own anchor,
contextID and anchorChallengeTolerance=5e-4. An M0 anchor may be obtained from
a compatible own M0 calibration/error-comparison fit, not an article endpoint.

The M1 recipe constructor does not add the conditional observation-error
configuration. Before saving an executable M1 case, explicitly supply the
source likelihood settings and the row-vector layout used by its decoder:

```matlab
caseConfig.sigma = jwpe_sigma_config();
caseConfig.freeIndices = caseConfig.freeIndices(:).';
caseConfig.lower = caseConfig.lower(:).';
caseConfig.upper = caseConfig.upper(:).';
```

`jwpe_sigma_config` constructs settings only; it neither estimates the error
scales nor evaluates a likelihood. Its defaults belong to the source SMX
likelihood and detection limit, not arbitrary compounds. PF additionally needs
its explicit negative-state classification policy in `caseConfig.invalid`, as
consumed by `jwpe_m1_pl_evaluate`. A successful generic job preparation checks
the top-level contract but does not certify every nested execution setting.

The recipe is only one field of a complete execution payload: provide the
data/context/core and other fields listed by jwpe_job_contract. No search starts
when a recipe is read. Closures additionally need their explicit eligible own
candidate/state and unchanged budget; a recipe alone does not trigger one.

M0 uses native [Kd,kb,krev,kG,tinf,Ai] or the recorded [Kd,kSigma,Fdir,kG,tinf,Ai]
maps as declared per case. M1 removes krev. For fixed Kd, nuisance Ai remains
bounded by 0.300 even where a fixed profile coordinate extends beyond that value.
The profile-only extension is not a general prior bound.

For finalization, `model` is `'M0'`, `'M1_FREE'` or `'M1_FIXED'`. `nativeRuns` identifies
result/configuration files and their hashes; requiredOrigins declares the full
requested set; points maps each native coordinate to its own originating case;
anchorCaseId names the accepted own anchor. D95=3.84145882069412. An absent
origin must remain missing, and a HOLD/STOP cannot become a complete profile.
No new searches, automatic interpolation of confidence limits or inferred
data from the article are launched by the finalizer.

Run one case at a time into distinct folders. Recompute anchors, starts and
support choices as scientifically appropriate for a new dataset. The recorded
coordinate grids document this study; they are not universal physical limits.
