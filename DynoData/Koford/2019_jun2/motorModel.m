%% process Model

if (exist('p1','var'))
    delete(p1);
    delete(p2);
    delete(p3);
end
load ../noLoad/nonElectricalLosses
% load ../spindown/chain+mag_sketchy
% mystery = mean(allMys(allR2>.35,:),1);
modelKv = mean(allKv);
modelRs = mean(allRs)*1.1;
modelKt = 1./(modelKv*2*pi/60);
paramSets = table();
for i = 1:length(allParameters)
    paramSets.Kv(i) = mean(allKv(allChar==i));
    paramSets.Rs(i) = mean(allRs(allChar==i)) * 1.15;
    paramSets.Mys(i,:) = mean(allMys(allChar==i,:),1);
    paramSets.Kt(i) = 1./(paramSets.Kv(i)*2*pi/60);
    
%     fields = fieldnames(allParameters(i));
%     vals = cellfun(@(f) getfield(allParameters(i),f),fields,'UniformOutput',false);
    for field = fieldnames(allParameters(i))'
        field = field{1};
        paramSets.(field)(i,:) = getfield(allParameters(i),field);
    end
    
    V = str2num(paramSets.voltage(i,:));
    IVals = linspace(0,18,99)';
%     modelRPM = (V - IVals*paramSets.Rs(i)) * paramSets.Kv(i);
%     modelTorque = IVals * paramSets.Kt(i) * 1;
%     modelLosses = [IVals.^2*paramSets.Rs(i), polyval(PvsERPM,modelRPM*2)];
    modelRPM = (V - IVals*modelRs) * modelKv;
    modelTorque = IVals * modelKt * 1;
    modelLosses = [IVals.^2*modelRs, polyval(PvsERPM,modelRPM*2)];
%     modelLosses = [IVals.^2*paramSets.Rs(i), polyval(paramSets.Mys(i,:),modelRPM)];
    modelEff = 1 - sum(modelLosses,2) ./ (IVals * V);
    
%     linecolor = allPlotColors{mod(i-1,length(allPlotColors))+1};
    linecolor = 'r';
    
    figure(1);
    plot(modelRPM, modelEff, '-', 'Color',linecolor,'DisplayName', ['model - ',num2str(V),'V']); hold on;
    
    figure(5);
    yyaxis left
    p1(i)=plot(IVals, modelRPM, [linecolor,'-'],'HandleVisibility','off'); hold on;
    yyaxis right
    p2(i)=plot(IVals(1:2:end), modelTorque(1:2:end)*100, [linecolor,'-'], 'MarkerSize',5,'HandleVisibility','off'); hold on;
    p3(i)=plot(IVals, modelEff*100, [linecolor,'-'], 'MarkerSize',1,'HandleVisibility','off');
    legendShow = 'off';
    
    figure(6);
    plot(IVals, sum(modelLosses,2), '-', 'Color',linecolor,'DisplayName', ['model - ',num2str(V),'V']); hold on;
end
paramSets.Kv(length(allParameters)+1) = modelKv;
paramSets.Rs(length(allParameters)+1) = modelRs;
paramSets.Kt(length(allParameters)+1) = modelKt;
for field = fieldnames(allParameters(i))'
    n = 'model';
    paramSets.(field{1})(i+1,:) = n(1:length(paramSets.(field{1})(1,:)));
end