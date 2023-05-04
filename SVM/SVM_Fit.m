%% Code Information
%************************************************************************
%Stanford GPS

%Function Description: Split ADS-B Airspace into layers, and determine the
%decision boundary between aircraft affected by interference (NIC<=7) and
%nominal reporting aircraft
%Input Information: ADS-B data
%Output Information: 

%************************************************************************

function SVM_Fit(adsbdata,Z,RZ,boxalt,icao)
    %Filter Data
    filt_data=Filter_Data(adsbdata,Z,RZ,icao);
    %Implement Density Weighting Scheme
    filt_data.Weights=Density_Weight(filt_data);
    %Split Airspace into layers every 1000'
    layerint=boxalt(1)*3.28:1000:boxalt(2)*3.28;
    nlayers=numel(layerint)-1;
    %Determine Decision Boundary for each layer
    bdata=cell(1,nlayers);
    for h=1:nlayers
        layerdata=filt_data((filt_data.Weights<=layerint(h) &&...
            filt_data.Weights>=layerint(h+1)),:);
        bdata(h)=DecisionBoundary(layerdata);
    end
    %plot data
    Plot_Boundary(bdata)
end

%% Other Functions 
%Find Decision Boundary for a set of data using Support Vector Machine
%(SVM)
function [h]=DecisionBoundary(layerdata)
    Tbl=layerdata(:,ismember(layerdata.Properties.VariableNames, ...
        {'lat','lon','alt','Weights'}));
    Y=layerdata.nic(layerdata.nic<=7);    
    model=fitcsvm(Tbl,Y,'KernelFunction','rbf','BoxConstraint',inf);
    [~,score]=predict(model,Tbl);
    h=contour(x1,x2,reshape(score(:,2),size(x1)),[0 0],'k');
end

%Plot function for adding decision boundaries
function Plot_Boundary()
    ADSBtools.plot.plot_3Dterrain(w,eventdata.RZ);
    hold on
    for i=1:numel(bdata)
        
    end
end
