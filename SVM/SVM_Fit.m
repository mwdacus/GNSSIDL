%% Code Information
%************************************************************************
%Stanford GPS

%Function Description: Split ADS-B Airspace into layers, and determine the
%decision boundary between aircraft affected by interference (NIC<=7) and
%nominal reporting aircraft
%Input Information: ADS-B data
%Output Information: 

%************************************************************************

function SVM_Fit(adsbdata,Z,RZ,icao,origin)
    %Filter Data
    filt_data=Filter_Data(adsbdata,Z,RZ,icao);
    %Find box airspace from filtered data
    %[box_x,box_y]=BoxENU(filt_data);
    %Implement Density Weighting Scheme
    filt_data.Weights=Density_KDE(filt_data.lon,filt_data.lat,boxlon,boxlat);

    %Split Airspace into layers every 1000'
    harddeck=round(min(filt_data.alt)*3.28,-2);
    ceiling=round(max(filt_data.alt)*3.28,-2);
    layerint=harddeck:3000:ceiling;
    nlayers=numel(layerint)-1;
    %Determine Decision Boundary for each layer, fit model to each altitude
    boundary=cell(1,nlayers);
    for alt=1:nlayers
        layerdata=filt_data(filt_data.alt*3.28<=layerint(alt+1),:);
        if isempty(layerdata)
            continue
        end
        boundary{alt}=FitModel(layerdata,layerint(alt),origin,box_x,box_y);
    end
    %plot data
    all_contours=horzcat(boundary{:});
    Plot_Boundary(filt_data,all_contours);
end

%% Other Functions 
%Plot function for adding decision boundaries
function Plot_Boundary(adsbdata,contdata)
    %plot ADS-B Data
    ADSBtools.plot.plot_geo(adsbdata.time,adsbdata.lat,adsbdata.lon,adsbdata.nic,...
        adsbdata.icao)
    hold on
    ax=gca;
    %plot contours
    cTbl = getContourLineCoordinates(contdata); % from the file exchange
    % Plot contour lines
    nContours = max(cTbl.Group); 
    colors = autumn(nContours);
    for i = 1:nContours
        gidx = cTbl.Group == i; 
        geoplot(ax, cTbl.Y(gidx), cTbl.X(gidx), ... % note: x & y switched 
            'LineWidth', 2, 'Color', colors(i,:))
    end
end

%Find box airspace enu coordinates
function [boxx,boxy]=BoxENU(filt_data)
    cols={'x','y'};
    for i=1:2
        minind(i)=find(filt_data.(cols{i})==min(filt_data.(cols{i})));
        maxind(i)=find(filt_data.(cols{i})==max(filt_data.(cols{i})));
        
    end
    boxx=[filt_data.x(minind(1)) filt_data.x(maxind(1))];
    boxy=[filt_data.y(minind(2)) filt_data.y(maxind(2))];
end