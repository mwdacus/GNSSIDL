%% Code Information
%************************************************************************
%Stanford GPS

%Function Description: Split ADS-B Airspace into layers, and determine the
%decision boundary between aircraft affected by interference (NIC<=7) and
%nominal reporting aircraft
%Input Information: ADS-B data
%Output Information: 

%************************************************************************

function SVM_Fit(eventdata)
    %Filter Data
    filt_data=Filter_Data(eventdata.adsbdata,eventdata.Z,eventdata.RZ);
    %Implement Density Weighting Scheme
    weight_data=Density_Weight(filt_data);
    %Split Airspace into 10 layers (by altitude)
    layerheight=linspace(eventdata.boxalt(1),eventdata.boxalt(2),10);
    nlayers=numel(layerheight)-1;
    %Determine Decision Boundary for each layer
    bdata=cell(1,nlayers);
    for h=1:nlayers
        heightdata=weight_data((weight_data<=layerheight(h) && weight_data>=layerheight(h+1)),:);
        bdata(h)=DecisionBoundary(heightdata);
    end
    %plot data
    fig=ADSBtools.plot.plot_3Dterrain(weight_data,eventdata.RZ);
    %plot boundary
    Plot_Boundary(fig,bdata)
end

%% Other Functions 
%Find Decision Boundary for a set of data using Support Vector Machine
%(SVM)
function DecisionBoundary()

end

%Plot function for adding decision boundaries
function Plot_Boundary()

end
