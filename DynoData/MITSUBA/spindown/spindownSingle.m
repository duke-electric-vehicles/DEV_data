function [PARASITIC_LOSSES_ACC_OF_FLYWHEEL_RPS, PARASITIC_LOSSES_POWER_OF_FLYWHEEL_RPM] ...
    = spindownSingle(filename, toPlot);

    global ACCEL_WINDOW ROT_INERTIA
    data = importdata(filename);

    voltage = data(:, 1);
    current = data(:, 2);
    rpm_fly = data(:, 4); % /16 is a manual correction

    for i = 1:length(rpm_fly) - 2%fix glitches in rpm readout
       if (rpm_fly(i) > 0) && (rpm_fly(i+2) > 0) && (rpm_fly(i+1) == 0)
           rpm_fly(i+1) = rpm_fly(i);
       end
    end

    % rpm_fly = circshift(rpm_fly, -27);

    rpm_fly = 1./smooth(1./rpm_fly, 54, 'moving');
    rpm_fly = smooth(rpm_fly, 300, 'sgolay');

    velo = rpm_fly * 2 * pi / 60;
    time = data(:, 6) ./ 1000;

    accel = gradient(velo)./gradient(time);
    accel(isnan(accel)) = 0; % for some reason, moving average smooth takes a lot longer if there are nan's
    accel = smooth(accel,54);
    accel = smooth(accel,250,'sgolay');
    power = accel * ROT_INERTIA .* velo;

    startWindow = 250;
    endWindow = length(rpm_fly)-2000;

    dur = 50;
    for i = (dur+1):length(velo)
       if ((velo(i) > velo(i - dur)) && (velo(i) > velo(i + dur)) && (current(i+100) < .1))
           startWindow = i + 250;
           break;
       end
    end

    for i = startWindow:length(velo)-500
       if velo(i - 49) < 8 && velo(i) < 8
           endWindow = i;
           break;
       end
    end
    
    veloCut = velo(startWindow:endWindow);
    accelCut = accel(startWindow:endWindow);
    rpm_flyCut = rpm_fly(startWindow:endWindow);
    powerCut = power(startWindow:endWindow);

    rpmCutVals = linspace(rpm_flyCut(1),rpm_flyCut(end),100);
    indsCut = zeros(size(rpmCutVals));
    for i = 1:length(rpmCutVals)
        [~,indsCut(i)] = min((rpmCutVals(i)-rpm_flyCut).^2);
    end
    veloCut = veloCut(indsCut);
    accelCut = accelCut(indsCut);
    rpm_flyCut = rpm_flyCut(indsCut);
    powerCut = powerCut(indsCut);
    
    coeffs = polyfit(veloCut, accelCut, 3);
    coeffsLoss = polyfit(rpm_flyCut, powerCut, 3);

    PARASITIC_LOSSES_ACC_OF_FLYWHEEL_RPS = coeffs;
    PARASITIC_LOSSES_POWER_OF_FLYWHEEL_RPM = coeffsLoss;
    
    if (toPlot)
        figure(1); %clf;
        yyaxis left
        plot(rpm_fly); hold on;
        line([startWindow, startWindow], [0, 100], 'Color', 'black', 'LineWidth', 3);
        line([endWindow, endWindow], [0, 100], 'Color', 'red', 'LineWidth', 3);
        % yyaxis right
        % plot(current.*voltage)
        % plot(power)
        % ylim([-10,5]);
        grid on;

        figure(2); %clf;
        yyaxis left
        plot(rpm_flyCut, accelCut); hold on;
        plot(rpm_flyCut, polyval(coeffs, veloCut));
        yyaxis right;
        plot(rpm_flyCut, powerCut); hold on;
        plot(rpm_flyCut, polyval(coeffsLoss, rpm_flyCut));
        
        xlabel('v (RPM)');
        ylabel('a (RPM/s)');
        grid on;
    end
end