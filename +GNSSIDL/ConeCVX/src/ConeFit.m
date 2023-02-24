%% Code Information
%***********************    *************************************************
%Stanford GPS

%Function Description: Process data into local ENU coordinate system, and
%calls Julia Module (ConeCVX.jl) to extract parameters

%Input Information: ADS-B data (lat, lon, alt), 
    %varargin: axis (3d figure)
    %convex problem formulation (c=0 (ConeForm1), c=1 (ConeForm 2)
%Output Information: 
%************************************************************************


function [idl] = ConeFit(adsbdata,varargin)
    %Determine if figure, localization type is included
    for idx = 1:2:length(varargin)
        switch lower(varargin{idx})
            case 'axis'
                fig=varargin{idx+1};
            case 'centoption'
                centoption=varargin{idx+1};
            case 'boxlat'
                boxlat=varargin{idx+1};
            case 'boxlon'
                boxlon
        %throw error if variable is unrecognized
            otherwise
                error(['Unrecognized variable: ' varargin{idx}])
        end
    end  
    %set default parameters if not given
    if ~any(strcmp(varargin,'axis'))
        fig=figure('color','w');
    elseif ~any(strcmp(varargin,'centoption'))
        centoption=1;
    elseif ~any(strcmp(varargin,'boxlat'))
        boxlat=[min(adsbdata.lat),max(adsbdata.lat)];
    elseif ~any(strcmp(varargin,'boxlon'))
        boxlon=[min(adsbdata.lon),max(adsbdata.lon)];
    else

    end



    %Ask User for local origin for ENU, organize data into ENU coordinates
    origin
    %Convert Data to ENU Coordinates
    lladata=[adsbdata.lat,adsbdata.lon,adsbdata.alt];
    enudata=lla2enu(lladata,origin,'ellipsoid');
    
    %start up julia server
    jlcall('','restart',true)
    %load Project
    jlcall('','project',path,modules,{'ConeCVX'})
    %Call module, solve convex problem, convert to lla
    if centoption==0
        [A,r]=jlcall('ConeCVX.ConeForm1',{enudata},'modules',{'ConeCVX'});
        [llaconedata]=ConeConvert1(boxlat,boxlon,A,r,origin);
    else
        [A,Q,r]=jlcall('ConeCVX.ConeForm2',{enudata},'modules',{'ConeCVX'});
        [llaconedata]=ConeConvert2(boxlat,boxlon,A,Q,r,origin);
    end

    
    
    
    %plot original data, and cone in 3d
    GNSSIDL.Con

    

end

%% Other Functions
%Convert Cone from ENU to LLA using parameters
function ConeConvert1(boxlat,boxlon,A,r,origin)
    
    zz=meshgrid(xx,yy)
    f=@(x,y,z) norm(A*[x;y]+b(1:2),2)+b(3)-z;




end

