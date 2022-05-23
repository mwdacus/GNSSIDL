%% Code Information
%*************************************************************************
%Michael Dacus                                               Stanford GPS

%Problem Statement: Upload and store the newest ADS-B Receiver Data in
%table for distance calculations
%*************************************************************************

function [rectable]=receiverdata()
    sensordata = webread('https://opensky-network.org/api/sensor/list');
    for i=1:length(sensordata)
        serial(i)= sensordata(i).serial;
        sensorlon(i)= sensordata(i).position.longitude;
        sensorlat(i)= sensordata(i).position.latitude;
        sensoralt(i)= sensordata(i).position.altitude;
    end
    %organize data into raw table
    rectable=table(serial',sensorlat',sensorlon',sensoralt');
    rectable.Properties.VariableNames=["serial","lat","lon","alt"];
end