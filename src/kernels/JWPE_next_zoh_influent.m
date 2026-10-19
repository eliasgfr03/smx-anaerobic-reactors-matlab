function Cin = JWPE_next_zoh_influent(t,data)
% Right-endpoint/NEXT-ZOH forcing: the next measured feed value applies until its sampling day.
i=find(data.Time_d>t+1e-12,1,'first'); if isempty(i); i=height(data); end; Cin=data.Cin_ug_L(i);
end
