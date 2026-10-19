function folders=jwpe_make_demo_inputs(destination)
%JWPE_MAKE_DEMO_INPUTS Generate fictitious inputs; no scientific model is run.
% Refuses an existing destination. Values are not observations from the article.
assert(java.io.File(char(destination)).isAbsolute() && ~isfolder(destination) && ...
    ~isfile(destination),'JWPE:Demo:Destination','Choose a new absolute destination.');
mkdir(destination);folders=struct();times=[1:3:49,50:3:92,94].';
for reactor={'CS','PF'}
    key=reactor{1};folder=fullfile(destination,key);mkdir(folder);folders.(key)=folder;
    index=(0:32).';offset=0;if strcmp(key,'PF'),offset=0.4;end
    inlet=2.0+offset+0.07*mod(index,7);outlet=0.5+offset/4+0.03*mod(index,5);
    censored=ismember(index,[3 22]);outlet(censored)=0;
    phase=repmat("I",33,1);phase(times>49)="II";
    forcing=table(repmat(string(key),33,1),times,inlet, ...
        'VariableNames',{'Reactor','Time_d','Cin_ug_L'});
    observations=table(repmat(string(key),33,1),times,phase,outlet,censored, ...
        repmat(0.0163,33,1),'VariableNames', ...
        {'Reactor','Time_d','Phase','Cout_ug_L','CensorFlag','LOD_ug_L'});
    phases=table(repmat(string(key),2,1),["I";"II"],[0;49],[49;94], ...
        repmat("calibration",2,1),'VariableNames',{'Reactor','Phase','Start_d','End_d','Use'});
    writetable(forcing,fullfile(folder,'forcing.csv'));
    writetable(observations,fullfile(folder,'observations.csv'));
    writetable(phases,fullfile(folder,'phases.csv'));
    physical=struct('XTSS_g_L',8,'XVSS_g_L',4,'switchDays',[49 94]);
    if strcmp(key,'CS')
        physical.hydraulicModel='CS_TIS';physical.phaseResidenceTime_h=[3 2 1];
        physical.tanksPerPhase=[2 2 3];points=[.02 1.2 .1 25 .1;.02 2.4 .2 40 .2];seed=901;
    else
        physical.hydraulicModel='PF_ADM';physical.length_m=1;physical.reportingVolume_L=2;
        physical.velocity_m_d=[1 1.5 2];physical.Dax_m2_d=[.002 .003 .004];
        points=[.02 .12 .1 20 .08;.02 .18 .2 35 .2];seed=902;
    end
    initial=struct('parameterNames',{{'Kd','kb','kG','tinf','Ai'}}, ...
        'points',points,'seed',seed,'dataOrigin','SYNTHETIC');
    write_json(fullfile(folder,'physical.json'),physical);
    write_json(fullfile(folder,'initialization.json'),initial);
end
end
function write_json(file,value)
fid=fopen(file,'w');assert(fid>=0);clean=onCleanup(@()fclose(fid));
assert(isa(clean,'onCleanup'));fprintf(fid,'%s\n',jsonencode(value));
end
