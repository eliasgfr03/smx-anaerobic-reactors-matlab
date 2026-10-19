function coordinates = pf_dax_coordinates_v1(cfg)
%PF_DAX_COORDINATES_V1 Construct the exact multiplier, D and Peclet table.

n = numel(cfg.f);
coordinateID = (1:n).'; multiplier = cfg.f(:);
D = multiplier.*cfg.D0_m2_d;
Pe = inf(n,3); finite = multiplier>0;
for j = 1:3
    Pe(finite,j) = cfg.u_m_d(j)*cfg.length_m./D(finite,j);
end
meanPe = inf(n,1); meanPe(finite) = mean(Pe(finite,:),2);
isBaseline = coordinateID==cfg.baselineIndex;
regime = strings(n,1);
regime(multiplier<=10) = "CONVECTIVE";
regime(multiplier>10 & multiplier<100) = "TRANSITION";
regime(multiplier>=100) = "DISPERSIVE";
coordinates = table(coordinateID,multiplier,D(:,1),D(:,2),D(:,3), ...
    Pe(:,1),Pe(:,2),Pe(:,3),meanPe,isBaseline,regime, ...
    'VariableNames',{'CoordinateID','Multiplier','D_PhaseI_m2_d', ...
    'D_PhaseII_m2_d','D_PhaseIII_m2_d','Pe_PhaseI','Pe_PhaseII', ...
    'Pe_PhaseIII','MeanPe','IsBaseline','Regime'});
assert(isequal(multiplier,cfg.f(:)) && all(D(1,:)==0) && ...
    all(isinf(Pe(1,:))) && isinf(meanPe(1)) && ...
    all(isfinite(Pe(2:end,:)),'all'),'JWPE:PFDAX:Coordinates', ...
    'Coordinate or explicit infinity contract failed.');
end
