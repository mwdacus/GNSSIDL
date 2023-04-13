%% Code Information
%************************************************************************
%Stanford GPS

%Function Description: Solves convex formulation for a 3D Euclidean Cone
%using ADS-B data indicating interference (NIC=0)

%Input Information: ADS-B data (lat, lon, alt), 
%MAY ADJUST FOR LOOP OVER TIME (NOT GENERATE RANDOM SAMPLES)    
%************************************************************************

function ConeFit(eventdata,cvxchoice)
    %Filter data to NIC=0 data
    nic0data=eventdata.adsbdata(eventdata.adsbdata.nic==0,:);
    %Generate random samples of the data
    nsamples=20;
    lat_center=zeros(nsamples,1);
    lon_center=zeros(nsamples,1);
    %MAY WANT TO CHANGE THIS TO LOOP OVER TIME
    for i=1:nsamples
        randomdata=Filter_Data(nic0data,eventdata.Z,eventdata.RZ);
        randomdata_cvx=[randomdata.x randomdata.y randomdata.alt];
        if cvxchoice=="ConeCVX"
            gamma=1;
            [A,r]=ConeCVX(randomdata_cvx,gamma);
        else
            [A,r]=NonCVX_Cone(randomdata_cvx);
        end
        %Calculate the center of the cone
        [lon_xx,lat_yy,alt_zz]=Util_Cone.ConeConvert(randomdata,origin,A,r);
        [lat_center(i),lon_center(i)]=Util_Cone.LocateCenter(lat_yy,lon_xx,alt_zz);
    end
    %plot original data in 3d [fig]=baselayer_KDEN();
    fig=ADSBtools.plot.plot_3Dterrain(nic0data,eventdata.RZ);
    %plot original data, and cone in 3d
    Util_Cone.Plot_Cone(fig,lat_yy,lon_xx,alt_zz);   
    %plot center of cone
    Util_Cone.PlotCenter(lat_center,lon_center)
end


