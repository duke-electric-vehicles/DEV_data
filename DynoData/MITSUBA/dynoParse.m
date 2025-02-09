clear; clc; % close all;

ROT_INERTIA = 0.8489;

load spindown/spindown_noRotor % PARASITIC LOSSES
% data = importdata('16V_VESC/16V1A_FOC_sensorless.txt');
data = importdata('12V_DEVsensorless/12V_PS_D100_1.txt');

data = data(data(:,2)>.1,:); % current > .1

voltage = data(:, 1);
voltage = smooth(voltage, 100,'sgolay');
current = data(:, 2);
current = smooth(current, 100,'sgolay');
rpm = data(:, 4);
toShift = fix(1 / (rpm(end) * (data(2,6)-data(1,6))/1000 / 60));
for i=1:length(rpm)-toShift % compensate for moving average having phase lag
    rpm(i) = rpm(i+toShift);
    toShift = fix(1 / (rpm(i) * (data(2,6)-data(1,6))/1000 / 60));
end

rpmglitchoffset = 0;
newRPM(length(rpm)) = rpm(end);
for i = length(rpm) - 2: -1 : 1%fix glitches in rpm readout
   newRPM(i+1) = rpm(i+1) + rpmglitchoffset;
   if abs(rpm(i+1)-rpm(i)) > 2
       rpmglitchoffset = rpmglitchoffset + (rpm(i+1)-rpm(i)) - (newRPM(i+2)-newRPM(i+1));
   end
end
figure(4);clf;plot(rpm);hold on; plot(newRPM); yyaxis right;plot(diff(rpm)); grid on
rpm = newRPM;
% assert(abs(rpmglitchoffset) < 1, 'rpm glitch remover failure');

% rpm = smooth(rpm, 54);
rpm = smooth(rpm, 21);

omega = rpm * 2 * pi / 60;
rpm_motor = rpm * 54/72;
velo_mph = rpm_motor*(20/12/5280*pi)*60;
throttle = data(:, 5);
time = data(:, 6) ./ 1000;

ePower = voltage .* current;
ePower = smooth(ePower, 50, 'sgolay');

accel = gradient(omega)./gradient(time);

accel = smooth(accel, 101, 'sgolay');

accelComp = accel - polyval(PARASITIC_LOSSES_ACC_OF_FLYWHEEL_RPS, omega);


torque = ROT_INERTIA .* accelComp;
mPower = torque .* omega;
mPower = smooth(mPower, 50, 'sgolay');

eff = mPower ./ ePower;
% eff = smooth(eff, 101, 'sgolay');

figure(1);clf;
subplot(3,1,1);
plot(time, rpm_motor);
xlabel('Time (s)'); ylabel('Motor RPM');
subplot(3,1,2);
plot(rpm_motor, voltage, 'DisplayName','Voltage');
ylabel('Voltage (V)'); yyaxis right
plot(rpm_motor, current, 'DisplayName','Current');
ylabel('Current (A)'); xlabel('RPM of motor');
legend show
subplot(3,1,3);
plot(rpm_motor,ePower, 'DisplayName','Electrical Power');
hold on;
plot(rpm_motor,mPower, 'DisplayName','Mechanical Power');
ylim([0,100]); ylabel('Power (W)'); xlabel('RPM of motor');
legend show;
grid on;

figure(2);clf;
plot(velo_mph, eff);
ylim([0.6, 1]); xlim([0,max(velo_mph)]);
ylabel('efficiency');
xlabel('speed (mph)');
grid on;
title('efficiency vs speed');

figure(3);clf;
plot(ePower, eff);
ylim([0.6, 1]); xlim([0,100]);
ylabel('efficiency');
xlabel('Electrical power (W)');
grid on;
title('efficiency vs power');