
mins = 33;
secs = 51;


%jouletotal = 17819; laps = 3; %practice 1
%jouletotal = 40601; laps = 7; %practice 2
%jouletotal = 39800; laps = 7; %dumb calc

jouletotal = 38264; laps = 7; %dumb calc


distance = laps * 6388.10 / 3.28084;
secs = secs + mins * 60;

avgSpeed = distance ./ secs;

kwh = jouletotal / 3.6e6;
kmkwh = distance / 1000 / kwh;
mikwh = kmkwh / 1.609;

wh100km = (kwh)/(distance/100e6)