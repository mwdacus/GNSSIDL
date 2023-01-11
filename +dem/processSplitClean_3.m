function processSplitClean_3(inFile,varargin)
% Copyright 2018 - 2020, MIT Lincoln Laboratory
% SPDX-License-Identifier: BSD-2-Clause

%% Input parser
p = inputParser;

% Required
addRequired(p,'inFile'); % Input directory

% Optional - Directories
addOptional(p,'outDir',[getenv('AEM_DIR_OPENSKY') filesep 'output' filesep '3_process']); % Input filename convention

% Optional - Outlier Thresholds
addOptional(p,'outlierVertRate_ft_s', 6000 / 60,@isnumeric); % Maximum absolute vertical rate
addOptional(p,'outlierSpeed_kt', 600,@isnumeric); % Maximum absolute speed
addOptional(p,'outlierTurnRate_deg_s', 12,@isnumeric); % Maximum absolute turn rate
addOptional(p,'outlierAccel_kts_s', 6,@isnumeric); % Maximum absolute acceleration

% Optional - Filtering
addOptional(p,'minSegPoints',10,@(x) @isnumeric && x > 0); % Minimum number of points a segment must have (10 has been the default historically)
addOptional(p,'thresTimeUpdate_s',seconds(20),@isduration); % Maximum time difference between updates...a value of 20 Ensures there at least 3 data points per minute
addOptional(p,'maxAlt_ft_msl',85000,@isnumeric); % U2 service ceiling is 80K
addOptional(p,'minAlt_ft_msl',-115,@isnumeric); % KTRM elevation, https://en.wikipedia.org/wiki/List_of_lowest_airports

% Optional - Segement Processing
addOptional(p,'interpTimeStep',seconds(1),@isduration);

% Optional - Altitude
addOptional(p,'altMode','both',@(x) ischar(x) && any(strcmpi(x,{'baro','geo','both'})));

% Optional - Elevation related
addOptional(p,'demDir',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-SRTM3'],@isstr); % Directory containing DEM
addOptional(p,'dem','srtm3',@isstr); % Digital elevation model name
addOptional(p,'demDirBackup',[getenv('AEM_DIR_CORE') filesep 'data' filesep 'DEM-GLOBE'],@isstr); % Directory containing DEM
addOptional(p,'demBackup','globe',@isstr); % Digital elevation model name

% Optional - Airspace
addOptional(p,'fileAirspace',[getenv('AEM_DIR_CORE') filesep 'output' filesep 'airspace-B-C-D-24-Oct-2019.mat']);

% Optional - Adminstrative Boundaries
addOptional(p,'Tadmin',table(),@istable);
addOptional(p,'Tland',table(),@istable);

% Optional - Plot and Display
addOptional(p,'isPlotSeg',true,@islogical);
addOptional(p,'isPlotRates',true,@islogical);
addOptional(p,'isVerbose',false,@islogical);

% Parse
parse(p,inFile,varargin{:});

% Set other variables or parse out inputparser
spheroid_ft = wgs84Ellipsoid('ft');
myColorOrder = get(groot,'defaultAxesColorOrder'); % Set in startup_opensky
Tadmin = p.Results.Tadmin;

%% Create temp directory and extract archive to it
temp = tempdir;
C = strsplit(inFile,'/');
tempFolder = [temp C{end-3} '_' C{end-2} '_' C{end-1} '_' C{end}(1:end-4)];
unzip(inFile,tempFolder);

%% Parse .csv filenames
% Idenitfy all .csv files in temp directory
listing = dir([tempFolder filesep '*.csv']);

% Split filenames
% Assumes ICAO24 is always last
% Specifically, if Monday data:
% 1st: Date, YYYY-mm-DD
% 2nd: Hour, [0-23]
% 3rd: ICAO24 address + .csv suffix
fnsplit = cellfun(@(x)(strsplit(x,'_')),{listing.name}','uni',false);

nf = cellfun(@numel,fnsplit,'uni',false);

% Parse icao24 address and remove .csv suffix
icao24 = cellfun(@(x,n)(string(x{n}(1:end-4))),fnsplit,nf,'uni',true);

% Identify unique iaco24 addresses
[u24,~,ic] = unique(icao24,'stable');
n = numel(u24);

% Create full path names for each .csv file
csvFiles = strcat(string({listing.folder})',filesep, string({listing.name})');

%% Load airspace
% Load airspace
load(p.Results.fileAirspace,'airspace');

% Airspace
airB = airspace(airspace.CLASS == 'B',:);
airC = airspace(airspace.CLASS == 'C',:);
airD = airspace(airspace.CLASS == 'D',:);
%airE = airspace(airspace.CLASS == 'E',:); % Not used
%airF = airspace(airspace.CLASS == 'F',:); % Not used

%% Split track using splitTrack function
% Iterate over iaco24 addresses
for i=1:1:n
    % Identify all files for ith icao24 address
    iFiles = csvFiles(ic==i);
    
    % Iterate over files
    for j=1:1:numel(iFiles)
        % Open, read, and close file
        % The format needs to be the similar to what fprintf uses in organizeraw_1()
        fid = fopen(iFiles(j),'r');
        headerLine = textscan(fid,'%s %s %s %s %s %s %s %s %s %s %s',1,'HeaderLines',0,'Delimiter',',','EndOfLine','\n');
        raw = textscan(fid,'%s %f %f %f %f %f %f %f %f %f %f','HeaderLines',0,'Delimiter',',','EndOfLine','\n');
        fclose(fid);
        
        % Clean up header line
        % There was a bug where a ; was added to a column name in organizeraw_1
        % So we do the regexprep to mitigate that bug...this needs to be fixed in the future
        headerLine = string(cellfun(@(x)(regexprep(x{1},'[;]','')),headerLine,'uni',false));
        
        % Parse raw data and assign to variables named using header
        % This is done solely to improve readability
        for k=1:1:numel(headerLine)
            if j==1
                eval(sprintf('%s=raw{k};',headerLine{k})); % Create
            else
                eval(sprintf('%s=[%s ;raw{k}];',headerLine{k},headerLine{k})); % Append
            end
        end
    end
    
    % Check if these variables exists, if not create a placeholders
    % The onground variable is associated with ADS-B data, we do this
    % check so this function can be used when this variable doesn't exist
    % For OpenSky...The relationship between the three timestamps are
    % time_s > lastcontact_s >= lastposupdate_s
    if ~exist('onground','var') | all(isnan(onground)); onground = false(size(time_s)); end
    if ~exist('speed_ground_kt','var'); speed_ground_kt = nan(size(time_s)); end
    if ~exist('lastcontact_s','var'); lastcontact_s = time_s; end
    if ~exist('lastposupdate_s','var'); lastposupdate_s = time_s; end
    
    % Sort by squawk
    % This will help promote splitting tracks if squawk is changed
    [~,I] = sort(squawk);
    for k=1:1:numel(headerLine)
        eval(sprintf('%s=%s(I);',headerLine{k},headerLine{k}));
    end
    
    % Only use observations with unique lastcontact_s
    % From OpenSky documentation about lastcontact_s:
    % This unix timestamp indicates the time at which OpenSky received the last signal of the aircraft.
    % As long as the aircraft is flying in an airspace which is well-covered by OpenSky's receivers
    % this timestamp should never be older than 1-2 seconds compared to the state vectors timestamp (time).
    [~,I,~] = unique(lastcontact_s,'sorted');
    for k=1:1:numel(headerLine)
        eval(sprintf('%s=%s(I);',headerLine{k},headerLine{k}));
    end
    
    % Sort by unique time
    [~,I,~] = unique(time_s,'sorted');
    for k=1:1:numel(headerLine)
        eval(sprintf('%s=%s(I);',headerLine{k},headerLine{k}));
    end
    
    % Convert time_s to datetime
    rowTimes = datetime(time_s, 'ConvertFrom', 'posixtime' );
    
    % Create track segement and filter to unique position updates
    % Note in organizeraw_1() we do not output the last times of
    % position update and contract, rather we'll effectively estimate these values here
    [iTrack,iia,~] = unique([lat_deg, lon_deg],'rows','stable');
    
    % Create timetable with position
    iTrack = timetable(rowTimes(iia),lat_deg(iia),lon_deg(iia),alt_baro_ft_msl(iia),alt_geo_ft_msl(iia), speed_ground_kt(iia),logical(onground(iia)),string(squawk(iia)),'VariableNames',{'lat_deg','lon_deg','alt_baro_ft_msl','alt_geo_ft_msl','speed_direct_kt','onground','squawk'});
    
    % Check to see if we have altitude data geometric data, if it is "null", and below the maximum assumed absolute ceiling
    isGoodAltBaro = iTrack.alt_baro_ft_msl ~= 0 & ~isnan(iTrack.alt_baro_ft_msl) & iTrack.alt_baro_ft_msl <= p.Results.maxAlt_ft_msl & iTrack.alt_baro_ft_msl >= p.Results.minAlt_ft_msl;    % non-zero barometric altitude feet msl
    isGoodAltGeo = iTrack.alt_geo_ft_msl ~= 0 & ~isnan(iTrack.alt_geo_ft_msl) & iTrack.alt_geo_ft_msl <= p.Results.maxAlt_ft_msl & iTrack.alt_geo_ft_msl >= p.Results.minAlt_ft_msl;       % non-zero geometric altitude feet msl
    
    switch p.Results.altMode
        case 'baro'
            isGoodAlt = isGoodAltBaro;
        case 'geo'
            isGoodAlt = isGoodAltGeo;
        case 'both'
            isGoodAlt =  isGoodAltBaro & isGoodAltGeo;
        otherwise
            error('altMode:unknown','altMode must be either ''baro'', ''geo'', or ''both'' ... %s is invalid\n',altMode);
    end
    
    % Keep points with good altitude and don't have an empty squawk
    l = isGoodAlt & ~strcmpi(iTrack.squawk,"NaN");
    iTrack = iTrack(l,:);
    if isempty(iTrack)
        if p.Results.isVerbose
            fprintf('icao24 = %s, i = %i, n = %i, Not sufficient data...CONTINUE\n',u24(i), i, n);
        end
        continue
    end
    
    % Calculate time difference between observations
    diffTime_s = diff(iTrack.Time);
    isTimely = abs(diffTime_s) <= p.Results.thresTimeUpdate_s;
    
    % Find sequences of consecutive non-zero values
    % Assign a g (group) for each observation
    % https://www.mathworks.com/matlabcentral/answers/404502-find-the-longest-sequence-of-consecutive-non-zero-values-in-a-vector#answer_323627
    segPos = find(~[0 isTimely']);
    g = ones(size(iTrack,1),1);
    counterG = 1;
    for j=1:1:numel(segPos)
        if j < numel(segPos)
            idx = segPos(j):segPos(j+1)-1;
        else
            idx = segPos(j):numel(g);
        end
        % Find groups with enough points
        if numel(idx) >= p.Results.minSegPoints
            g(idx) = counterG;
            counterG = counterG + 1; % Advance counter
        else
            g(idx) = 0; % If not enough points, set group to zero
        end
    end
    
    % Append remove segments that are not long enough
    iTrack.g = g;
    iTrack = iTrack(iTrack.g~=0,:);
    
    % Check again if data exists after more filtering
    if isempty(iTrack)
        if p.Results.isVerbose
            fprintf('icao24 = %s, i = %i, n = %i, No segments long enough...CONTINUE\n',u24(i), i, n);
        end
        continue
    end
    
    % Plot segements
    if p.Results.isPlotSeg
        figure(hex2dec(u24{i})); set(gcf,'name',sprintf('segments: %s',u24(i)));
        if max(iTrack.g) <=  size(myColorOrder,1)
            colors = myColorOrder(iTrack.g,:);
        else
            colors = repmat(myColorOrder,ceil(max(iTrack.g) / size(myColorOrder,1)),1);
            colors = colors(iTrack.g,:);
        end
        geoscatter(iTrack.lat_deg,iTrack.lon_deg,10,colors,'.');
        geobasemap streets-dark;
        set(gcf,'Units','inches','Position',[1*i 1*i 11.94 5.28]); % Adjust figure size
    end
    
    % Calculate rates
    nSeg = max(iTrack.g);
    isFileOpen = false;
    for j = 1:1:nSeg
        % Close just in case
        if isFileOpen & j==1; fclose(fid); isFileOpen = false; end
        
        % Filter  segement
        l = iTrack.g == j;
        jTrack = iTrack(l,1:7);
        
        % Outlier detection with altitude
        switch p.Results.altMode
            case 'baro'
                isOutAlt = isoutlier(jTrack.alt_baro_ft_msl,'median','SamplePoints',jTrack.Time,'ThresholdFactor',1.5);
            case 'geo'
                isOutAlt = isoutlier(jTrack.alt_geo_ft_msl,'median','SamplePoints',jTrack.Time,'ThresholdFactor',1.5);
            case 'both'
                isOutAlt = any(isoutlier([jTrack.alt_baro_ft_msl,jTrack.alt_geo_ft_msl],'median','SamplePoints',jTrack.Time,'ThresholdFactor',1.5),2);
        end
        
        % Smooth and append variables not smoothed
        jTrackSmooth = smoothdata(jTrack(~isOutAlt,1:5),'gaussian',seconds(30));
        jTrackSmooth = [jTrackSmooth jTrack(~isOutAlt,6:end)];
        
        if size(jTrackSmooth,1) < p.Results.minSegPoints
            if p.Results.isVerbose
                fprintf('icao24 = %s, j = %i, nSeg = %i, i = %i, n = %i, Segment not long enough after altitude outlier detection...CONTINUE\n',u24(i), j, nSeg, i, n);
            end
            continue
        end
        
        % Calculate dynamics (speed, turn rate, acceleration, vertical rate)
        [jTrackSmooth, ~] = CalcDynamics(jTrackSmooth);
        
        % Identify outliers
        [isGood, ~, ~, ~, ~, ~] = IdentifyOutliers(jTrackSmooth,p);
        
        % Make sure there are enough points
        if sum(isGood) < p.Results.minSegPoints
            if p.Results.isVerbose
                fprintf('icao24 = %s, j= %i, nSeg = %i, i = %i, n = %i, Segment not long enough after dynamics outlier detection...CONTINUE\n',u24(i), j, nSeg, i, n);
            end
            continue
        end
        
        % Interpolate
        jTrackInterp = InterpolateTrack(jTrackSmooth, isGood, p.Results.interpTimeStep);
        
        % Identify Airspace Variable
        % Individual airspace classes parsed out above for speed improvements
        [jTrackInterp.A, alt4Airspace_ft_msl] = IdentifyAirspaceVariable(jTrackInterp, p.Results.altMode, airB, airC, airD);
        
        % Identify adminstrative boundary
        jTrackInterp.geoname_id = IdentifyGeoname(jTrackInterp,Tadmin);
        
        % Identify elevation and altitude AGL
        [jTrackInterp,isEmptyEl] = IdentifyAltAGL(jTrackInterp,p);
        if isEmptyEl
            warning('el_ft_msl:empty','icao24 = %s, i = %i, j = %i, el_ft_msl is empty, skipping track segement...CONTINUE\n',u24(i),i,j);
            continue
        end
        
        % Transform geodetic coordinates to geocentric Earth-centered Earth-fixed
        [xECEF,yECEF,zECEF]=geodetic2ecef(jTrackInterp.lat_deg, jTrackInterp.lon_deg, alt4Airspace_ft_msl, spheroid_ft,'degrees');
        
        % Transform geocentric Earth-centered Earth-fixed coordinates to local east-north-up
        [jTrackInterp.xLocalEast_ft,jTrackInterp.yLocalNorth_ft,~] = ecef2enu(xECEF,yECEF,zECEF,jTrackInterp.lat_deg(1),jTrackInterp.lon_deg(1),0,spheroid_ft,'degrees');
        
        % Plot
        if p.Results.isPlotRates
            figure; set(gcf,'name',sprintf('Rates: %s - %i',u24(i),j));
            stackedplot(jTrackInterp(:,3:end),{{'alt_baro_ft_msl','alt_geo_ft_msl'},{'dh_baro_ft_s','dh_geo_ft_s'},{'speed_estimate_kt','speed_direct_kt'},{'dv_estimate_kt_s','dv_direct_kt_s'},'dpsi_deg_s'}); grid on
        end
        
        % Write to file
        outFileFull = strcat(p.Results.outDir, filesep, u24(i), '.csv');
        
        % Open file and write header if first segment
        if ~isFileOpen
            fid = fopen(outFileFull,'w+','native','UTF-8');
            if fid == -1
                fid = fopen(outFileFull,'w+','native','UTF-8'); % try again
                if fid == -1
                    warning('organizeraw:fid','Cannot open %s, skipping via CONTINUE',outFileFull)
                    continue
                end
            end
            isFileOpen = true; % Denote file is open
            
            colNames = 'id,time_s,lat_deg,lon_deg,local_east_ft,local_north_ft,alt_baro_ft_msl,alt_geo_ft_msl,alt_baro_ft_agl,alt_geo_ft_agl,el_ft_msl,dh_baro_ft_s,dh_geo_ft_s,course_deg,dpsi_deg_s,speed_estimate_kt,speed_direct_kt,dv_estimate_kt_s,dv_direct_kt_s,onground,squawk,A,geoname_id';
            colNum = numel(strfind(colNames,',')) + 1;
            fprintf(fid,[colNames '\n']);
        end
        
        % Write to file
        fprintf(fid,['%0.0f,%0.0f,%0.16f,%0.16f,%0.16f,%0.16f,' repmat('%0.2f,',1,colNum-10) '%0.0f,%s,%0.2f,%0.0f\n'],[repmat(j,size(jTrackInterp,1),1),posixtime(jTrackInterp.Time),jTrackInterp.lat_deg,jTrackInterp.lon_deg,jTrackInterp.xLocalEast_ft,jTrackInterp.yLocalNorth_ft,jTrackInterp.alt_baro_ft_msl,jTrackInterp.alt_geo_ft_msl,jTrackInterp.alt_baro_ft_agl,jTrackInterp.alt_geo_ft_agl,jTrackInterp.el_ft_msl,jTrackInterp.dh_baro_ft_s,jTrackInterp.dh_geo_ft_s,jTrackInterp.course_deg,jTrackInterp.dpsi_deg_s,jTrackInterp.speed_estimate_kt,jTrackInterp.speed_direct_kt,jTrackInterp.dv_estimate_kt_s,jTrackInterp.dv_direct_kt_s,jTrackInterp.onground,jTrackInterp.squawk,jTrackInterp.A,jTrackInterp.geoname_id]');
        
        % Close file on last segment
        if j==nSeg; closeStatus = fclose(fid); isFileOpen = false; end
    end % End j loop
    
    % Make sure everything is closed
    fclose('all');
    
    % Display status
    if p.Results.isVerbose; fprintf('i = %i, n = %i\n',i,n); end
end % End i loop
