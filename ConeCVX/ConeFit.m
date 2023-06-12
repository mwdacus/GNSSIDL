%% Code Information
%************************************************************************
%Stanford GPS

%Function Description: Solves convex formulation for a 3D Euclidean Cone
%using ADS-B data indicating interference (NIC=0)

%Input Information: ADS-B data (lat, lon, alt), 
%MAY ADJUST FOR LOOP OVER TIME (NOT GENERATE RANDOM SAMPLES)    
%************************************************************************

function ConeFit(adsbdata,Z,RZ,icao,origin,boxlon,boxlat,airport,cvxchoice)
    %Filter data to NIC=0 data
    
    filt_data=Filter_Data(adsbdata,Z,RZ,icao);
    filt_data.Weights=Density_KDE(filt_data.lon,filt_data.lat,boxlon,boxlat);
    nic0data=filt_data(filt_data.nic==0,:);
    points=[nic0data.x nic0data.y nic0data.alt];
    if cvxchoice=="ConeCVX"
        gamma=1;
        [A,r]=ConeCVX(points,nic0data.Weights,gamma,Z,RZ);
    else
        [A,r]=NonCVX_Cone(points,nic0data.Weights,gamma);
    end
    %Calculate the center of the cone
    [lon_xx,lat_yy,alt_zz]=Util_Cone.ConeConvert(nic0data,origin,A,r);
    [lat_center,lon_center]=Util_Cone.LocateCenter(lat_yy,lon_xx,alt_zz);

    %plot original data in 2D;
    ADSBtools.plot.plot_3Dterrain(nic0data.Time,nic0data.lat,nic0data.lon,...
        nic0data.alt,Z,RZ,nic0data.icao,nic0data.nic);
    %plot original data, and cone in 3d
    Util_Cone.Plot_Cone(lat_yy,lon_xx,alt_zz);   
    %plot center of cone
    Util_Cone.PlotCenter(lat_center,lon_center,Z,RZ,origin,airport)
end


