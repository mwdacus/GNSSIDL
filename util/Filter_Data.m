%% Code Information
%*************************************************************************
%Stanford GPS

%Function Description: Filter Full ADS-B Data based on a variety of
%conditions:
    %remove data below 100 ft AGL (using geointerp)
    %only include commercial aircraft (part 121)

%*************************************************************************    

function [final_data]=Filter_Data(adsbdata,Z,RZ,origin)
    %Filter data to 500' AGL
    aglheight_m=500/3.28;
    agl_h=geointerp(Z,RZ,adsbdata.lat,adsbdata.lon,"spline");
    data=adsbdata(agl_h>=aglheight_m,:);
    %Filter data by commerical aircraft 
    filename_opensky="aircraftDatabase_Opensky.csv";
    filename_mitre="aircraftDatabase_MITRE.xlsx";
    registry_dir=fileparts(string(which('ADSBtools.util.loadAircraftDatabase')));
    aircraft_reg_mitre=readtable(strcat(registry_dir,filename_mitre));
    aircraft_reg_opensky=readtable(strcat(reigstry_dir,filename_opensky));
    %Gather tail numbers from opensky directory
    ac=unique(agl_data.icao24);
    ac_ind=ismember(ac,aircraft_reg_opensky.icao24);
    tailno=aircraft_reg_opensky.registration(ac_ind);
    data.tailno=tailno;
    %Find Part 121 Aircraft in Mitre Directory
    mitre_ind=ismember(tailno,aircraft_reg_mitre.Reg);
    part121_ac=aircraft_reg_mitre.Reg(mitre_ind);
    %Find part 121 aircraft in final table
    final_ind=ismember(part121_ac,data.tailno);
    data=data(final_ind,:);
    %Determine if ENU is available in table, if not, add it to adsbdata
    if any(contains(data.Properties.VariableNames,{'x','y','z'}))==0
        [enudata]=ENUData(data.lat,data.lon,data.alt,origin);
        final_data=[data enudata];
    else
        final_data=data;
    end
end

%% Local Functions
%Add ENU table to existing dataset
function [data]=ENUData(lat,lon,alt,origin)
    enudata=lla2enu([lat,lon,alt],origin,'ellipsoid');
    data=array2table(enudata,'VariableNames',{'x','y','z'});
end