# Interpreting results and resolving errors

[Português](../portuguese-br%20version/RESULTS_AND_TROUBLESHOOTING_PT_BR.md) · [Documentation index](INDEX.md)

A completed computation and a scientifically adequate result are different. Read the effective configuration, actual counters, independent recheck, endpoint status and source identities before interpreting parameters or forwarding a result to another analysis. A short synthetic fit tests software operation, not parameter recovery or convergence.

## Optimizers and parameter bounds

Inspect objective traces, solver exit information, independent NLL recheck and parameters relative to supports. A solution at a bound is retained, but can indicate insufficient information, a restricted search or model mismatch. Do not discard it or enlarge supports merely to obtain an interior solution. Compare scientifically justified starts and alternative explanations with a separately declared budget. RMSE describes fit; the inferential objective is NLL. A more negative NLL is not intrinsically invalid: continuous densities depend on units and error scales.

## Profile likelihood

Re-estimate the nuisance parameters at each fixed coordinate and keep the validated lower envelope. Multiple numerical solutions at the same coordinate are not separate confidence limits. Use `D=2*(NLL_profile-NLL_min)` and the intended threshold; the source one-parameter threshold is 3.84145882069412. A lower conditional solution can challenge an anchor: follow the declared analysis policy rather than clipping negative deviances.

A profile staying below the threshold at the support edge does not have a closed confidence limit there. Search near suspected crossings with adequate resolution, retain non-monotonicity and disconnected regions, and distinguish a crossing bracket from an interpolated value. Compensation paths describe changes along re-estimated optima, not posterior correlations. Fixed-Kd intervals are conditional and exclude uncertainty in that fixed value. Sensitivity alone is not identifiability.

Closures are bounded local searches, not global proofs. `HOLD`, `STOP`, missing origins or exhausted incomplete meshes must remain incomplete in finalization. Increasing a point's budget does not fill the rest of a profile.

## MCMC

Check all four chains, mixing, rank-based split Rhat, bulk ESS and tail ESS for all sampled parameters. The source criteria are Rhat<1.01 and both ESS>400. A visually smooth trace, acceptance rate or a pooled histogram alone is insufficient. Review transformed proposals, physical supports, priors, Jacobian, starting states and relative parameter scales if chains mix poorly. Adaptation belongs to warmup; retained production uses the frozen proposals. Do not pool CS and PF chains or routinely thin to hide dependence.

Longer chains may improve Monte Carlo precision but cannot supply information absent from the likelihood. An informative Kd prior does not mean Kd has been independently identified by aqueous observations. Do not weaken convergence thresholds to certify a short example. Keep complete joint rows when selecting draws.

## Prediction and scenarios

Mean-response credible bands quantify parameter uncertainty under the model; posterior-predictive bands additionally include observation error. Their empirical coverage has different meanings. Holdout responses must be read only for evaluation after predictions are fixed, not used to reprofile error scales or refit parameters. External-study clocks, hydraulics, units and LOD need their own adapters.

Time-scale equivalence is an exposure-preserving coefficient normalization, not a causal decomposition of reactor differences or a recalibration. Ratio reduction and reduction in the gap between means have different denominators. PF zero dispersion retains advection; it does not mean a stopped liquid. The model does not explicitly resolve liquid-solid mass-transfer kinetics, so a mechanistic interpretation of mixing is not a simulated mass-transfer rate.

## Common errors

| Symptom | Check and next step |
|---|---|
| Code identity mismatch | Confirm the intended package and unmodified sources/recipes. Do not bypass the check. In a deliberately edited copy, review changes and rebuild its inventory before creating new jobs. Prose edits do not require code-hash changes. |
| Existing output folder or job | Inspect the earlier run. Use a distinct runID/new destination for a fresh run, or the supported resume path for an eligible unfinished run. |
| Missing function or toolbox/license error | Run `which functionName -all` for the named function and `ver`. Verify setup and a valid MATLAB/toolbox license. Installation and license availability are different. |
| Nested field missing after preparation | The generic top-level check does not construct all configurations. Read the selected controller, its helpers and the family guide; do not invent missing scientific values. |
| Rejected production source | Check closed-source identity, execution mode, convergence and row compatibility. Synthetic outputs cannot be promoted by renaming a status or editing a certificate. |
| Invalid or negative model state | Inspect units, physical inputs, initial state, numerical settings and the declared invalid-state policy. Do not relax tolerances to conceal a model failure. |
| Censoring or phase error | Compare the five-file schema, LOD, zero convention, sampling counts and phase dates. Do not relabel or duplicate observations to pass. |
| Timeout or budget exhausted | Preserve logs, state and charged attempts. Inspect whether the result is complete or resumable; a configured time option may not interrupt an in-progress solver call. |

Before requesting help, record the MATLAB release, function path, exact error/stack, analysis and mode, configured and consumed budgets, input schema and latest coherent state. Share only data you have permission to disclose. Keep a minimal reproducible example in a separate folder.
