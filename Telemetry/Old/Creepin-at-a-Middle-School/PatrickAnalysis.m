%% Patrick Grady
%  Nov. 2017

clear; clc; close all;

FILENAME = 'all.TXT';

ACCEL_WINDOW = 100;

%CAR MODEL---------------------------
crr = 0.0015;
gravitationalMass = 21 + 67;

densityAir = 1.184;
frontalArea = 0.353;
cd = 0.13;

rollingForce = crr * gravitationalMass * 9.8;
airForce = @(v) 0.5 * cd * densityAir * frontalArea * v.^2;

ca = 100; %tire cornering stiffness, newtons per degree
cornerRadius = 35; %turn radius in meters
percentageCorner = 0.5;

corneringDragForce = @(v) ca .* ((gravitationalMass .* v.^2 ./ cornerRadius) ./ ca) .^ 2 .* pi ./ 180 .* percentageCorner; %traction force needed

accelModel = @(v) -(rollingForce + airForce(v) + corneringDragForce(v)) / gravitationalMass;

%END CAR MODEL-----------------------


data = importdata(FILENAME);

voltage = data(:, 1);
current = data(:, 2);
power = data(:, 3);
velo = data(:, 4) .* 7 ./ 8;
energy = data(:, 5);
dist = data(:, 6);
elapsed = data(:, 10) ./ 1000;
lat = data(:, 11);
lon = data(:, 12);
accel = zeros(size(velo));

velo = smooth(velo, 21);
ke = 0.5 * (60.1 + 21.1 + 0.8) .* (velo .^2);

windowPoints = PatrickWindow(velo, power, elapsed);

for i = ACCEL_WINDOW + 1: length(velo) - ACCEL_WINDOW
   dv = velo(i + ACCEL_WINDOW) - velo(i - ACCEL_WINDOW);
   dt = elapsed(i + ACCEL_WINDOW) - elapsed(i - ACCEL_WINDOW);
   
   accel(i) = dv / dt;
   data(i, 11) = dv / dt;
end

%% Plot start/stop lines--------------------------------------------
figure(1); clf;
plot(elapsed, velo); hold on;
for i = 1:size(windowPoints, 1) 
    start = elapsed(windowPoints(i, 1));
    stop = elapsed(windowPoints(i, 2));
    
    line([start, start], [0, 10], 'Color', 'black', 'LineWidth', 3);
    line([stop, stop], [0, 10], 'Color', 'red', 'LineWidth', 3);
end
title('Start/Stop Lines');xlabel('time (s)');ylabel('velocity (m/s)');

%% Plot decelerations------------------------------------------------
figure(2); clf;
for window = 1 : size(windowPoints, 1)
   start = windowPoints(window, 1);
   stop = windowPoints(window, 2);
   
   plot(velo(start:stop), accel(start: stop)); hold on;
   ylim([-0.10 0]);
end

% Plot fit
veloSweep = linspace(0, 10, 1000);
plot(veloSweep, accelModel(veloSweep));
plot(veloSweep, -rollingForce / gravitationalMass .* veloSweep ./ veloSweep);
plot(veloSweep, -airForce(veloSweep) / gravitationalMass);
plot(veloSweep, -corneringDragForce(veloSweep) / gravitationalMass);
title('Acceleration vs Velocity');
xlabel('Velocity (m/s)');ylabel('Acceleration(m/s^2)');
legend('Data 1','Data 2','Fit');

%% Plot decel vs map


for window = 1 : size(windowPoints, 1)
   figure();clf;
   start = windowPoints(window, 1);
   stop = windowPoints(window, 2);
   
    wLat = lat(start : stop);
    wLon = lon(start : stop);
    wAccel = accel(start : stop);
    wVelo = velo(start : stop);

    %scatter(wLat, wLon, 1, wAccel); %hold on;
    
    scatter3(wLat, wLon, wAccel, 3, 'filled'); hold on;
    scatter3(wLat, wLon, accelModel(wVelo), 2, 'filled'); hold on;
    
    xlim([35.9712 35.9730]);
    ylim([-78.9348 -78.9334]);
    zlim([-0.07 0]);
end
