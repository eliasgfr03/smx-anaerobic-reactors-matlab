# PF axial dispersion execution

[Português](../portuguese-br%20version/PF_DISPERSION_PT_BR.md) · [Documentation index](INDEX.md)

The dispersion scenario transfers the same joint parameter rows to each dispersion multiplier and changes only axial dispersion. For each row, it simulates the full history at nonbaseline multipliers and reuses that row's own saved response curve without observation error at f=1. This is not a single curve averaged over the posterior and shared by all rows. The scenario does not refit parameters or add observation-error realizations; its saved outputs contain summaries rather than individual simulated curves.

## Short execution

For a prepared own-input bundle `b`, use an explicit test job:

```matlab
b.analysis = 'pf_dispersion';
b.mode = 'test';
b.shortBudget = struct('selectedRows',4,'rawMax',8);
```

The supplied configuration must have `f=[0 1 2]`, `baselineIndex=2`, `selectedRows=4`, `logicalPairs=12` and `rawForwardHardMax=8`. Supply matching multiplier labels, physical baseline dispersion/velocity/length, quantile policy, a four-row `selected` table and an exact corresponding `baseline`. The baseline has `times_d`, `selected` and `mu`; its four curves and row identities must match the supplied context and selected joint rows. The context remains response-free and supplies the full history and monitoring times.

At f=0 and f=2, the controller runs four full histories each. At f=1, it uses four saved baseline curves and performs no forward. This checks execution and aggregation, not a calibrated posterior or scientific uncertainty interval. A short budget is rejected in production mode before creating output.

## Full campaign and output

Omit `shortBudget` to retain the full controller defaults: 500 selected rows, 12 coordinates, 6000 logical pairs and exactly 5500 new forwards. The full configuration and frozen source requirements remain necessary; omitting the short field does not construct them automatically. Production jobs require the existing certified selection-source contract.

Save a new job and use a new output directory when changing inputs or mode. The controller saves coordinate checkpoints in `latest.mat` and final summaries, paired draw-level changes, mean removals and coordinates in `result.mat`. It does not save individual simulated curves or emit a closed-source receipt. The public dispatcher appends the execution-mode record. Paired effects are calculated against each row's own baseline before summarization. The f=0 coordinate has zero dispersion and infinite Peclet number; it is not replaced by a small positive dispersion.
