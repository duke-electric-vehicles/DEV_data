function [Rs, Kv] = analyzeSingle(filePath, linecolor, toPlot, duty)

    global PARASITIC_LOSSES_ACC_OF_FLYWHEEL_RPS PARASITIC_LOSSES_POWER_OF_FLYWHEEL_RPM
    global ROT_INERTIA
    global HALLTEETH FLYTEETH MOTORTEETH
    global isRegen
    
    persistent legendShow
    if (isempty(legendShow))
        legendShow = 'on';
    end
    
    filename = split(filePath, '/');
    filename = filename{end};
    
    data = importdata(filePath);
    if (isRegen)
        data = data(data(:,2)<-.1,:); % current < -.1
    else
        data = data(data(:,2)>.1,:); % current > .1
    end
    badInds = find(data(:,4)>1000); % sometimes noise causes bad readings at start
    badInds = [1;badInds];
    startInd = badInds(end)+50;
    data = data(startInd:end-5,:);
    
    throttle = data(:, 5);
    time = data(:, 6) ./ 1000;
    voltage = data(:, 1);
    current = data(:, 2);
    power = data(:,3);
    rpm_fly = data(:, 4);
    energy = data(:,9);
    
    for i = 1:length(rpm_fly) - 2%fix glitches in rpm readout
       if (rpm_fly(i) > 0) && (rpm_fly(i+2) > 0) && (rpm_fly(i+1) == 0)
           rpm_fly(i+1) = rpm_fly(i);
       end
    end
%     glitches = find(abs(diff(rpm_fly))>5);
%     for glitch = glitches'
%         rpm_fly(glitch+1) = rpm_fly(glitch);
%     end
    rpm_fly = 1./smooth(1./rpm_fly, HALLTEETH);

%     rpm_fly = smooth(time, rpm_fly, 1001, 'sgolay', 5);
    rpm_motor = rpm_fly * FLYTEETH/MOTORTEETH;
    omega_fly = rpm_fly * 2 * pi / 60;

%     ePower = voltage .* current;
%     ePower = power;
    ePower = gradient(energy)./gradient(time);
    ePower = smooth(ePower, HALLTEETH*MOTORTEETH/FLYTEETH);
%     ePower = smooth(ePower, 500, 'sgolay');

    accel = gradient(omega_fly)./gradient(time);
    smooth(accel, HALLTEETH);

    accel = smooth(time, accel, 401, 'sgolay');
%     accelInterp = fit(omega_fly, accel, 'smoothingspline', 'SmoothingParam', 0.99);
%     accel = accelInterp(omega_fly);

    accelComp = accel - polyval(PARASITIC_LOSSES_ACC_OF_FLYWHEEL_RPS, omega_fly);

    torque = ROT_INERTIA .* accelComp;
    mPower = torque .* omega_fly;
    eff = mPower ./ ePower;
    eff = smooth(eff, 501, 'sgolay');
    if (isRegen)
        eff = 1./eff;
    end
    
    model = load('../MotorLossModel.mat');
    indsToAnalyze = rpm_motor > 200;
    Padj = current.*voltage - ...
        model.PlossMag_W(rpm_motor) - ...
        model.PlossMech_W(rpm_motor) - ...
        model.PlossContr_W(voltage, duty, rpm_motor, 6e3);
    currentAdj = Padj ./ voltage;
    [CoRV,int,~,~,stats] = regress(currentAdj(indsToAnalyze),...
                                   [rpm_motor(indsToAnalyze),voltage(indsToAnalyze)*duty]);
    R2 = stats(1);
%     assert (R2 > 0.95, sprintf('Kv calculation bad due to excessive nonlinearity: R2=%.4f\n',R2));
%     assert (abs(CoRV(3)) < 0, 'y intercept problem');
    Rs = 1/CoRV(2);
    Ke = -CoRV(1) * Rs;
    Kv = 1/Ke;
    
    fprintf('%s:\n',filename);
    fprintf('\tI = '); fprintf('(%.3f)RPM + (%.3f)V', CoRV);
    fprintf('(R2 = %.5f)\n', R2);
    fprintf('\tRs = %.6fohms\n\tKv = %.6f\n',Rs,Kv);
    
    filename = strrep(filename,'_',' ');
    filename = strrep(filename,',','.');
    
    %%
    figure(6); % clf;
    Kv = 24.34
    Rsfit = polyfit(current(indsToAnalyze), voltage(indsToAnalyze) - rpm_motor(indsToAnalyze)/Kv,1)
    scatter(current(indsToAnalyze),voltage(indsToAnalyze) - rpm_motor(indsToAnalyze)/Kv,3,1:sum(indsToAnalyze));
%     plot(current(indsToAnalyze),voltage(indsToAnalyze) - rpm_motor(indsToAnalyze)/Kv,'.', 'Color',linecolor);
    hold on
    currentVals = linspace(0,6);
    plot(currentVals, polyval(Rsfit, currentVals), 'Color',linecolor);
    grid on;
    xlabel('current'); ylabel('voltage');
    
    %%
    
    if (toPlot)
        figure(1);
    %     yyaxis left
        plot(rpm_motor, eff, '-', 'Color',linecolor, 'DisplayName', filename); hold on;
    %     yyaxis right
    %     plot(rpmMotor, mPower, '-');

        figure(2);
        plot3(rpm_motor, mPower, eff, '.', 'Color',linecolor, 'DisplayName', filename); hold on;

        figure(3);
%         indsToAnalyze = rpm_motor>-999;
        ax1 = subplot(2,1,1);
        plot(rpm_motor(indsToAnalyze), voltage(indsToAnalyze), '.', 'Color',linecolor, 'DisplayName', filename); hold on;
        ax2 = subplot(2,1,2);
        plot(rpm_motor(indsToAnalyze), current(indsToAnalyze), '.', 'Color',linecolor, 'DisplayName', filename); hold on;
        plot(rpm_motor(indsToAnalyze), [rpm_motor(indsToAnalyze),voltage(indsToAnalyze)]*CoRV, ':', 'Color',linecolor, 'DisplayName', filename);
        linkaxes([ax1,ax2],'x');

        figure(4);
        plot(rpm_motor, accel, 'Color',linecolor, 'DisplayName',filename); hold on;

        currentPlot = smooth(current, 54*72/60);
        figure(5);
        yyaxis left
        plot(currentPlot, rpm_motor, '-', 'Color',linecolor, 'DisplayName','RPM','HandleVisibility',legendShow); hold on;
        yyaxis right
        plot(currentPlot(1:100:end), -torque(1:100:end)/9.81*100, '^', 'Color',linecolor, 'DisplayName','Torque (kgf.cm)','HandleVisibility',legendShow,'MarkerSize',5); hold on;
        plot(currentPlot, eff*100, '.', 'Color',linecolor, 'DisplayName','Efficiency (%)','HandleVisibility',legendShow,'MarkerSize',1);
        legendShow = 'off';
    end
end