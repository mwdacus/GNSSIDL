%% Code Information
%************************************************************************
%Stanford GPS

%Function Description: Split ADS-B Airspace into layers, and determine the
%decision boundary between aircraft affected by interference (NIC<=7) and
%nominal reporting aircraft
%Input Information: ADS-B data
%Output Information: 

%************************************************************************

function SVM_Fit(adsbdata,Z,RZ,icao)
    %Filter Data
    filt_data=Filter_Data(adsbdata,Z,RZ,icao);
    %Implement Density Weighting Scheme
    filt_data.Weights=Density_Euclid(filt_data.x,filt_data.y,filt_data.alt);
    %Split Airspace into layers every 1000'
    layerint=min(filt_data.alt)*3.28:1000:max(filt_data.alt)*3.28;
    nlayers=numel(layerint)-1;
    %Determine Decision Boundary for each layer
    bdata=cell(1,nlayers);
    for h=1:nlayers
        layerdata=filt_data((filt_data.alt*3.28<=layerint(h+1) &...
            filt_data.alt*3.28>=layerint(h)),:);
        if isempty(layerdata)
            continue
        end
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
        {'x','y','Weights'}));
    Y=double(layerdata.nic<=7);    
    model=fitcsvm(Tbl,Y,'ClassNames',[0 1],'Standardize',true,...
        'KernelFunction','rbf','BoxConstraint',1);


    [x1Grid,x2Grid] = meshgrid(linspace(min(Tbl.x),max(Tbl.x),1000),...
        linspace(min(Tbl.y),max(Tbl.y),1000));
    xGrid = [x1Grid(:),x2Grid(:),ones(size(x1Grid(:),1),1)];
    [~,scores] = predict(model,xGrid);
    
    figure
    h(1:2) = gscatter(Tbl.x,Tbl.y,Y,'rb','.');
    hold on
    contour(x1Grid,x2Grid,reshape(scores(:,2),size(x1Grid)),[0,0],'k');
end

%Plot function for adding decision boundaries
function Plot_Boundary()
    ADSBtools.plot.plot_3Dterrain(w,eventdata.RZ);
    hold on
    for i=1:numel(bdata)
        
    end
end
