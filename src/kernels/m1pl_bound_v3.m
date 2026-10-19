function out = m1pl_bound_v3(sigmas,lower,upper,fraction)
%M1PL_BOUND_V3 Classify an eligible sigma pair against frozen supports.

sigmas = double(sigmas(:).');
lower = double(lower(:).');
upper = double(upper(:).');
assert(numel(sigmas)==2 && numel(lower)==2 && numel(upper)==2, ...
    'JWPE:M1PL:SigmaBoundary','Expected two sigma coordinates.');
assert(all(isfinite(lower)) && all(isfinite(upper)) && ...
    all(lower>0) && all(upper>lower) && isscalar(fraction) && ...
    isfinite(fraction) && fraction>=0 && fraction<1, ...
    'JWPE:M1PL:SigmaBoundary','Invalid sigma support policy.');

finiteSigma = all(isfinite(sigmas));
withinSupport = finiteSigma && all(sigmas>=lower) && all(sigmas<=upper);
distanceLower = sigmas-lower;
distanceUpper = upper-sigmas;
span = upper-lower;
distanceLowerFraction = distanceLower./span;
distanceUpperFraction = distanceUpper./span;
nearLower = false(1,2);
nearUpper = false(1,2);
if withinSupport
    nearLower = sigmas<=lower.*(1+fraction);
    nearUpper = sigmas>=upper.*(1-fraction);
end

flagNames = ["SIGMA_A_LOWER_BOUNDARY_RETAINED", ...
    "SIGMA_A_UPPER_BOUNDARY_RETAINED", ...
    "SIGMA_P_LOWER_BOUNDARY_RETAINED", ...
    "SIGMA_P_UPPER_BOUNDARY_RETAINED"];
flagMask = [nearLower(1),nearUpper(1),nearLower(2),nearUpper(2)];
if ~withinSupport
    classification = "ERROR_MODEL_NUMERICAL_HOLD";
elseif any(flagMask)
    classification = "ERROR_SUPPORT_BOUNDARY_RETAINED";
else
    classification = "ERROR_MODEL_INTERIOR_SOLUTION";
end

out = struct();
out.classification = char(classification);
out.finiteSigma = finiteSigma;
out.withinSupport = withinSupport;
out.errorSupportBoundaryReview = withinSupport && any(flagMask);
out.flagNames = flagNames(flagMask);
out.flagMask = flagMask;
out.sigmaALowerBoundaryRetained = flagMask(1);
out.sigmaAUpperBoundaryRetained = flagMask(2);
out.sigmaPLowerBoundaryRetained = flagMask(3);
out.sigmaPUpperBoundaryRetained = flagMask(4);
out.distanceSigmaAFromLower = distanceLower(1);
out.distanceSigmaAFromUpper = distanceUpper(1);
out.distanceSigmaPFromLower = distanceLower(2);
out.distanceSigmaPFromUpper = distanceUpper(2);
out.distanceSigmaAFromLowerFraction = distanceLowerFraction(1);
out.distanceSigmaAFromUpperFraction = distanceUpperFraction(1);
out.distanceSigmaPFromLowerFraction = distanceLowerFraction(2);
out.distanceSigmaPFromUpperFraction = distanceUpperFraction(2);
end
