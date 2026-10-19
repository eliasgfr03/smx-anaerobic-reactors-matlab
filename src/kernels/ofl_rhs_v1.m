function dy = ofl_rhs_v1(~,y,ctx,kb,h)
%OFL_RHS_V1 Isolated exact M1 algebra, sole activity delta A=1.
s = ctx.settings;
if strcmp(ctx.reactor,'CS')
    y = y(:);
    upstream = [h.Cin;y(1:end-1)];
    dy = (h.N/(h.tm_d*ctx.R))*(upstream-y)-s.XVSS_g_L*kb*y;
else
    C = [h.Cin;y(:);y(end)];
    first = PF_minmod_derivative(C,s.dz);
    second = PF_second_order_dispersion(C,s.dz);
    assert(numel(y)==69 && s.node_count==71,'OFL:State','PF requires 69 states.');
    dy = (-h.v*first(2:end-1)+h.Dax*second(2:end-1))/ctx.R-s.XVSS_g_L*kb*y(:);
end
end
