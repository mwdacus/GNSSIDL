%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Problem Statement: Upload and store the newest ADS-B Receiver Data in
%table for distance calculations
%*************************************************************************

function [d] = Dist2Receiver(rectable,lat,lon,alt,rec_id)
    air_loc=[lat,lon,alt];
    %Determine lat, lon and alt coordinates of matched receiver
    rec_ind=find(rectable.serial==rec_id);
    rec_loc=[rectable.lat(rec_ind),rectable.lon(rec_ind),...
        rectable.alt(rec_ind)];
    %Convert to ENU for distance calculation
    distxyz=lla2enu(rec_loc,air_loc,'ellipsoid');
    d=sqrt(distxyz(1)^2+distxyz(2)^2+distxyz(3)^2); 
end
