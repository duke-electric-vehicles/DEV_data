clear;
% data = importdata('12V_Stock_taughtchain/Gerry_0.txt');
% time = data(1:end-1,6) / 1000e3;
% rpm = data(1:end-1,4);
% rpmReal = rpm;
time = linspace(0,1,1000)';
rpmReal = 1 - exp(-5*time);
rpmReal = rpmReal*300;
rpm = rpmReal + 0.01*(rand(size(time))-.5);

rpmMA = smooth(time, rpm, 54);
simMA = zeros(size(rpm));
    for i = 54:length(simMA)
        simMA(i) = 54/sum(1./rpm(i-53:i));
    end
simMAcorr = circshift(simMA,-27);
rpmsgolay = smooth(time,rpm,200,'sgolay');

figure(1);clf;
plot(time, rpmReal, 'DisplayName','raw'); hold on;
plot(time, rpmMA, 'DisplayName','MA');
plot(time, simMA, 'DisplayName','simulated arduino MA');
plot(time, simMAcorr, 'DisplayName','simulated arduino MA corrected');
plot(time, rpmsgolay, 'DisplayName','sgolay')
% plot(time, 1./smoothdata(1./rpm), 'DisplayName','smoothdata');
legend show
xlim([time(1),time(end)]); ylim([min(rpmReal),max(rpmReal)]);
xlabel('time');ylabel('rpm'); title('rpm vs time');

accReal = gradient(rpmReal)./gradient(time);
accMA = gradient(rpmMA)./gradient(time);
accSim = gradient(simMA)./gradient(time);
accSimCorr = gradient(simMAcorr)./gradient(time);
accsgolay = gradient(rpmsgolay)./gradient(time);
accMA = smooth(accMA, 50, 'sgolay');
accSim = smooth(accSim, 50, 'sgolay');
accSimCorr = smooth(accSimCorr,50,'sgolay');
accsgolay = smooth(accsgolay, 50, 'sgolay');

figure(2);clf;
plot(rpmReal,accReal, '.','DisplayName','raw'); hold on;
plot(rpmMA, accMA, '.','DisplayName','MA');
plot(simMA, accSim, '.','DisplayName','simulated arduino MA');
plot(simMAcorr, accSimCorr, '.','DisplayName','simulated arduino MA corrected');
plot(rpmsgolay, accsgolay, '.','DisplayName','sgolay')
legend show
xlim([rpmReal(1),rpmReal(end)]); ylim([min(accReal),max(accReal)]);
xlabel('rpm');ylabel('acc'); title('acceleration vs speed');

powerReal = accReal.*rpmReal;
powerMA = accMA.*rpmMA;
powerSim = accSim.*simMA;
powerSimCorr = accSimCorr.*simMAcorr;
powersgolay = accsgolay.*rpmsgolay;

powerMA = smooth(powerMA, 100,'sgolay');
powerSim = smooth(powerSim, 100,'sgolay');
powerSimCorr = smooth(powerSimCorr, 100,'sgolay');
powersgolay = smooth(powersgolay, 100,'sgolay');

figure(3);clf;
plot(time, powerReal, '.','DisplayName','real'); hold on;
plot(time, powerMA, '.','DisplayName','MA');
plot(time, powerSim, '.','DisplayName','simulated arduino MA');
plot(time, powerSimCorr, '.','DisplayName','simulated arduino MA corrected');
plot(time, powersgolay, '.','DisplayName','sgolay')
legend show
xlim([time(1),time(end)]); ylim([min(powerReal),max(powerReal)]);
xlabel('time'); ylabel('power'); title('power vs time');