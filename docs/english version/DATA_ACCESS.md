# Data access and preparation

[Português](../portuguese-br%20version/DATA_ACCESS_PT_BR.md) · [Documentation index](INDEX.md)

Experimental observations, measured hydraulic/biomass inputs, retained chains
and computed article results are not distributed here. Request the materials
needed for complete reproduction explicitly from the corresponding author of
the associated article, who can identify the relevant data owners and access
conditions. This repository does not grant permission to redistribute those
materials or guarantee that a third party will grant access.

For original hydrodynamic measurements/modeling, contact Cottorello-Fonsêca and
the coauthors of that experimental study. For the independent UASB systems,
contact Soeira and coauthors. For the independent ASBR/APBR datasets, contact
Carneiro and coauthors. Use the original publications cited in the article to
identify the appropriate contacts.

After permission and access, prepare explicit tables and physical inputs using
INPUTS.md and the study-specific controller schemas. Record original units,
time origin, operational phases, censoring, LOD and any conversion. In
particular, ng/L and micrograms/L differ by a factor of 1000. Missing observations are not
zeros. Do not apply historical data corrections to an unrelated dataset.

The distribution contains a generator of fictitious values so that users can
learn the interface without access to measurements. These values are not a
substitute for the article's measurements and cannot reproduce its numerical
results. A generated short chain or fit is not a published or certified result.

The code's MIT license and permissions for experimental data are separate.
