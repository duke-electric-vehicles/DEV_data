clear; %close all;
figure(1);clf;figure(2);clf;

global ACCEL_WINDOW ROT_INERTIA

ACCEL_WINDOW = 54;
ROT_INERTIA = 0.8489;
% ROT_INERTIA = 0.06175; % stock hub wheel

% filenames = sprintfc('spindown_noChain_jun2-2019_before.txt',0); % secret undocumented function ;)
filenames = sprintfc('motorUnplugged_spindown.txt',0); % secret undocumented function ;)
% filenames = sprintfc('unloaded_spindown.txt',0); % secret undocumented function ;)

allCoeffs = zeros(length(filenames),4);
allCoeffsLoss = zeros(length(filenames),4);
for i = 1:length(filenames)
    [coeffs, coeffsLoss] = spindownSingle(filenames{i}, true);
    fprintf('alpha (rps2) = (%0.2e)omega^3 + (%0.2e)omega^2 + (%0.2e)omega + (%0.2e)\n',...
        coeffs);
    fprintf('Ploss (rps2) = (%0.2e)rpm^3 + (%0.2e)rpm^2 + (%0.2e)rpm + (%0.2e)\n',...
        coeffsLoss);
    fprintf('Parasitic loss at 322RPM: %.5fW\n', polyval(coeffsLoss,322));
    allCoeffs(i,:) = coeffs;
    allCoeffsLoss(i,:) = coeffsLoss;
end

PARASITIC_LOSSES_ACC_OF_FLYWHEEL_RPS = mean(allCoeffs,1);
PARASITIC_LOSSES_POWER_OF_FLYWHEEL_RPM = mean(allCoeffsLoss,1);

fprintf('\n');
fprintf('alpha (rps2) = (%0.2e)omega^3 + (%0.2e)omega^2 + (%0.2e)omega + (%0.2e)\n',...
    PARASITIC_LOSSES_ACC_OF_FLYWHEEL_RPS);
fprintf('Ploss (rps2) = (%0.2e)rpm^3 + (%0.2e)rpm^2 + (%0.2e)rpm + (%0.2e)\n',...
    PARASITIC_LOSSES_POWER_OF_FLYWHEEL_RPM);
fprintf('Parasitic loss at 450RPM: %.5fW\n', polyval(PARASITIC_LOSSES_POWER_OF_FLYWHEEL_RPM,450));

% save('spindown_noRotor_jun1_after',...
%     'PARASITIC_LOSSES_ACC_OF_FLYWHEEL_RPS',...
%     'PARASITIC_LOSSES_POWER_OF_FLYWHEEL_RPM');