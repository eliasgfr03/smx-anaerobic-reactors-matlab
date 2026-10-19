function index = ev2_phase_v1(time,cfg)
%EV2_PHASE_V1 Five EXTERNAL phases; not original-project Phase III.
index = 1+sum(time(:)>=cfg.phase.switchDays,2);
end
