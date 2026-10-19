# Code architecture

[Português](../portuguese-br%20version/ARCHITECTURE_PT_BR.md) · [Documentation index](INDEX.md)

The package separates user interfaces, analysis controllers and numerical functions. A job is a saved configuration for one invocation, not a copy of the numerical model and not necessarily an entire scientific campaign. A PL campaign, for example, contains several coordinate jobs followed by a finalizer.

| Location | Role | Typical entry points |
|---|---|---|
| `setup_jwpe.m` | Add explicit package folders to the current MATLAB path and verify code identity | `setup_jwpe` |
| `src/api` | User-facing preparation, schema inspection and job management | `jwpe_package_info`, `jwpe_prepare_m1`, `jwpe_job_contract`, `jwpe_job_template`, `jwpe_save_job`, `jwpe_job`, `jwpe_resume_job` |
| `src/kernels` | Reactor equations, numerical integration, likelihood, transformations, optimizer adapters and statistical calculations | `m1_cs_sim_v1`, `m1_pf_sim_v1`, `JWPE_activity_G1`, `tb_*`, `pftb_*` |
| `analyses` | Assemble explicit inputs, invoke kernels, track budgets, save results and check source compatibility | `run_m1_own_v1`, `run_m1_pl_own_v1`, `run_mcmc_own_v1` and the registry `jwpe_own_route_v1` |
| `analyses/recipes` | Search coordinates, supports and options for the article's PL design | Four JSON recipe catalogues |
| `examples` | Generate fictitious input files without evaluating a reactor | `jwpe_make_demo_inputs` |
| `docs` | Scientific usage and input/output instructions | [Index](INDEX.md) |
| `code_manifest.json` | Byte counts and hashes of MATLAB files and method recipes | Checked during setup and job preparation |

The API is not merely a collection of adjustable settings. It reads inputs and manages execution. Settings live in configuration functions and in each job's explicit structures. Likewise, kernels are reusable numerical functions; controllers determine which kernels run, in what order and with which acceptance checks.

## Execution sequence

1. `setup_jwpe` verifies this code copy and exposes its API.
2. A constructor such as `jwpe_prepare_m1`, or an advanced user assembling a payload, declares data, method, identity, cost and destination.
3. `jwpe_save_job` saves the payload and returns a descriptor with its file and hash. `jwpe_prepare_m1` already performs this step.
4. `jwpe_job(job,'prepare')` validates the top-level contract without a forward or optimizer. Nested scientific settings still require review.
5. `jwpe_job(job,'execute')` explicitly invokes the registered controller. This can be expensive.
6. Read the saved result, ledger, independent rechecks and diagnostics before using that source downstream.

The saved MAT contains `payload`; the returned descriptor contains `file`, `sha256`, `analysis`, `reactor` and `outputFolder`. Keep both. Functions and handles stored in MAT files require trusted sources. A hash detects changes relative to a known identity; it does not authenticate an unknown file.

## Analysis dependencies

Error and capacity comparisons, GSA and PL are distinct analyses, not mandatory automatic steps of one launcher. PL needs a rechecked anchor and its own conditional searches. Final deterministic calibration supplies starting information for Bayesian inference. Four separate chains feed convergence assessment and joint-row selection; the selection feeds uncertainty propagation, temporal holdout, external evaluation and PF dispersion. CS time equivalence uses the full separate retained CS/PF chains. OFL has its own fit and frozen holdout evaluation.

The dispatcher does not run the next reactor or next analysis automatically. `numeric_products` calculates supported numerical summaries from supplied results; it does not render figures. Generated data, jobs, checkpoints and results belong in a writable working folder outside the package.

## Modify a copy

Change numerical functions only after identifying all callers and paired validity checks. Keep an untouched original. [Campaign budgets](CAMPAIGN_BUDGETS.md) includes a MATLAB procedure to prepare an updated code manifest for edits to existing listed files. Adding or removing modules requires reviewing the inventory and unique function names explicitly. New code identity means new jobs, not rewriting old checkpoints. Documentation edits alone do not change executable identity.

## Glossary

| Term | Meaning in this package |
|---|---|
| PL | Profile likelihood: fix one coordinate and re-estimate the remaining parameters to examine likelihood support. |
| GSA | Global sensitivity analysis: assess response sensitivity over a declared parameter distribution, not practical identifiability. |
| MCMC | Markov chain Monte Carlo: sample the joint posterior under the declared likelihood, priors and numerical model. |
| NLL | Negative log-likelihood, the inferential objective. A lower value indicates a better likelihood for the same data and observation model. |
| LOD | Limit of detection applicable to the measurements, used with the explicit censoring convention. |
| TSS | Total suspended solids, the mass basis used for solid–liquid partitioning. It is not interchangeable with VSS. |
| VSS | Volatile suspended solids, the mass basis used to normalize the apparent biotransformation coefficient. |
| RNG | Random-number generator. Seeds and saved states support reproducible random sequences under compatible implementations. |
| SRRC | Standardized rank regression coefficient, a signed measure of sensitivity based on ranked variables. |
| ESS | Effective sample size accounting for dependence in a chain. Bulk and tail ESS assess different parts of the sampled distribution. |
| Rhat | Rank-based split-chain convergence diagnostic comparing behavior within and between chains. It is assessed with ESS and other diagnostics. |
| Forward | A numerical reactor simulation for a parameter vector and input context. Independent simulation rechecks also consume raw-forward allowance. |
| Warmup | Sampling stage used for adaptation. Its rows are excluded from retained posterior production. |
| Bracket | Two evaluated coordinates that enclose a threshold crossing; the bracket is not an exact interpolated confidence limit. |
| Closed source | Saved output whose required payloads are bound by an integrity receipt. Closure alone does not establish scientific adequacy. |
| Certified source | A compatible source that passed the controller's required acceptance checks, such as chain diagnostics. This is not certification of the model for another experiment. |
| HOLD or STOP | Algorithm status requiring review or indicating an incomplete/stopped calculation. It is not evidence of convergence or an accepted confidence limit. |
| Job descriptor | The small structure containing a saved job's path, hash and destination. The separate MAT payload holds its configuration; neither is a computed scientific result. |
