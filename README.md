# MATLAB models for SMX removal in anaerobic fixed-bed reactors

[Português](README_PT_BR.md) · [Documentation index](docs/english%20version/INDEX.md)

This repository provides the MATLAB implementations of model calibration,
profile likelihood, sensitivity analysis, Bayesian inference, uncertainty
propagation, independent-data evaluations, OFL applicability and scenario
analysis used in the associated Journal of Water Process Engineering study.
CS-AnFBR and PF-AnFBR models share kinetic equations but use different hydraulic
representations. The hydrodynamic-characterization study itself is not included.

## Requirements

MATLAB R2022b or later. Global Optimization Toolbox is required for surrogateopt
and patternsearch; Optimization Toolbox is required for the observation-error
comparison using fmincon. MATLAB and these toolboxes are not redistributed.
The table-based input/output functions and JVM must be available. The tested
reference environment is MATLAB R2022b on Windows. A later release or another
operating system has not been independently qualified by this distribution.

## Start here

Open the package folder in MATLAB. Run:

```matlab
previousPath = path;
info = setup_jwpe();
disp(info)
which jwpe_prepare_m1 -all
which jwpe_job -all
```

These commands inspect code and configure only the current session. They do
not fit or simulate a model. To restore your previous path, save it before
setup and restore it afterwards with `path(previousPath)`.

The first effective entry reported by `which -all` must belong to this copy.
Later entries marked `Shadowed` are not used. If another copy is effective,
use a clean session or remove only that copy's session paths; do not delete
its files or reset unrelated MATLAB settings.

Follow [the walkthrough](docs/english%20version/GETTING_STARTED.md) to generate fictitious inputs
and prepare a small calibration. Preparation and execution are separate calls.
All generated inputs and outputs should be kept in a working folder outside
this distribution. No scientific analysis runs automatically when a file is opened.

For measured inputs or another compound, read
[Using the models with your own data](docs/english%20version/USING_YOUR_OWN_DATA.md) before
preparing a job. It distinguishes compatible inputs from changes that need
a model adapter or different scientific settings.

## What is and is not supplied

The repository contains code, method settings and code that generates synthetic
example inputs. It does not contain experimental measurements, retained article
chains, computed article results or graphical outputs. The examples demonstrate
software use, not reproduction of the article's numerical findings. Stochastic
optimization and Monte Carlo results can differ between independent runs.

Read [data access and preparation](docs/english%20version/DATA_ACCESS.md) before using measured
inputs. Complete numerical reproduction requires the corresponding materials,
available subject to an explicit request to the corresponding author and the
rights of the experimental data owners. Access is not automatically granted
by the code license.

## Structure

- `src/api`: user-facing setup information, input preparation and job management.
- `src/kernels`: model, likelihood, optimization and statistical functions.
- `analyses`: explicit-input execution controllers and source-validation functions.
- `examples`: generation of fictitious calibration inputs.
- `docs`: inputs, execution, results and analysis-specific requirements.
- `code_manifest.json`: integrity of executable code, independent of prose edits.

See [analysis interfaces](docs/english%20version/ANALYSES.md) for the complete execution registry,
dependencies between analyses and the advanced structured-input interface.
See [PL recipes](docs/english%20version/PROFILE_LIKELIHOOD.md) for the fixed-coordinate catalogues.
See [Global sensitivity analysis](docs/english%20version/GSA.md) for the short functional mode
and its distinction from production convergence.

See [Increasing campaign budgets](docs/english%20version/CAMPAIGN_BUDGETS.md) for the settings,
source files and consistency checks needed when preparing a larger campaign
in a separate modified copy.

## Interpretation and scope

Calibration and inferential examples retain the study's day-0 origin, I–II
boundaries at days 49/94 and 17/16 observation counts where required by the
controllers. New experiments with different calendars need an explicit model
adapter, not silent rescaling. Phase III responses must not enter the final
M1 calibration, PL, GSA or MCMC workflow.
Sensitivity is not identifiability. Conditional PL intervals with fixed Kd do
not include uncertainty in that externally informed value.

The optional observation-error comparison is a separate historical M0
analysis. Its joint finalizer expects 50 observations per reactor and a
145 d source horizon, including the historical Phase III records. It is not
the 33-observation Phase I–II M1 calibration; its historical sources must not
replace the final calibration or posterior sources. See
[Analysis interfaces](docs/english%20version/ANALYSES.md#modelerrorcapacity-comparison).

Short examples do not establish optimizer convergence, posterior convergence
or practical identifiability. Production downstream analyses require their
own closed, compatible and certified sources. Incomplete or stopped results
must not be treated as accepted inferences. The mean-response uncertainty band
and the posterior-predictive band are distinct outputs.

## License

Own code is provided under the MIT license. See `LICENSE` and
`THIRD_PARTY_NOTICES.md`. The MIT license does not grant rights to obtain or
redistribute third-party experimental data. Cite the associated article and
the experimental studies when using their methods or data.
