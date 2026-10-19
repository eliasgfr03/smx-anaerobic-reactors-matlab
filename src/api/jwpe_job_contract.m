function contract=jwpe_job_contract(analysis,reactor)
%JWPE_JOB_CONTRACT List required fields and controller for an explicit job.
% This reports a schema, not a runnable configuration or a scientific result.
contract=jwpe_own_route_v1(char(analysis),char(reactor));
contract.baseFields={'schemaVersion','analysis','reactor','mode','runID','folder','identity'};
contract.executionFlag='executeScientific=true required by execute';
end
