# OFL calibration budgets

[Português](../portuguese-br%20version/OFL_CALIBRATION_PT_BR.md) · [Documentation index](INDEX.md)

OFL calibration uses two global searches followed by a local search. The fitted
mechanistic coefficient is kb; Kd and the activity multiplier remain fixed by
the supplied OFL configuration. The combined observation-error model is profiled
under that configuration, and each optimizer block has an independent raw recheck.

## Short execution example

For an already constructed own-input OFL bundle `b`, request the explicit short
mode before saving the job:

```matlab
b.analysis = 'ofl_calibration';
b.mode = 'test';
b.shortBudget = struct('outerCalls',[20 20 10],'rawMax',53);
```

This runs at most 20 global A, 20 global B and 10 local objective calls. Three
independent rechecks bring the raw-forward ceiling to 53; exact cache hits do
not consume another forward. Each global block must reach at least 10 objective
calls and the local block at least eight. A short run checks execution and
persistence, not optimization convergence or a scientifically adequate fit.
The starting points, bounds, local mesh, likelihood and inner error-profile
settings are not relaxed. The G1 screen uses its separate short budget below.

## Full campaign

Omit `shortBudget` to retain the full OFL controller: 200, 200 and 125 outer
calls, with a raw ceiling of 528 including the three rechecks. Supplying
`shortBudget` in production mode is rejected. Budget reductions do not certify
an optimum; inspect rechecks, error-profile eligibility, support boundaries and
fit diagnostics. See `ANALYSES.md` for bundle inputs and `CAMPAIGN_BUDGETS.md`
for coupled budget fields. Save a new job when changing its configuration;
completed jobs and outputs must not be overwritten.

## OFL with G1 capacity

The `ofl_g1_screen` route estimates kb, kG, tinf and Ai with the supplied
normalized-Gompertz activity law and fixed Kd. It retains its own supports,
initial point/seed policy, numerical settings and combined-error profiling.
For an already configured own-input bundle, a short execution is:

```matlab
b.analysis = 'ofl_g1_screen';
b.mode = 'test';
b.shortBudget = struct('outerCalls',[20 10],'rawMax',32);
```

This permits 20 global and 10 local objective calls plus two independent
rechecks. Exact cache hits need no additional forward. The global/local
blocks must exercise at least 10 global and eight local calls. The short budget
is rejected outside test mode and is not an optimization-convergence or
model-selection certificate. Omitting `shortBudget` preserves this route's
full defaults of 100 global and 60 local calls, with 162 raw forwards including
the two rechecks. The A=1 budgets described above remain unchanged.
