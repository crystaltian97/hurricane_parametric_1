clear all; close all; clc;
%% Announcement
%    This function filters the hurricane tracks that
%    have at least one point passing through the domain
%    or at least one line segment pass through the domain edge
fprintf(['\n'...
    'This function filters the hurricane tracks that \n'...
    'have at least one point passing through the domain  \n'...
    'or at least one line segment pass through the domain edge.\n'])
Directory_Input = '/Users/xy_tian/Desktop/Columbia/Summer/GUY_Capstone/Task1/Data/Input_data/';
Directory_Output = '/Users/xy_tian/Desktop/Columbia/Summer/GUY_Capstone/Task1/Output/';
disp(' ');disp('>> Reading the input files...');
tic;
raw_data_file = readtable([Directory_Input 'new_stochastic_hurricane_data.csv']);
raw_loss_file = readtable([Directory_Input 'new_stochastic_jamairca_loss_data.csv']);
ElapsedTime1 = toc;
disp(['   Input files read in ' num2str(ElapsedTime1) ' sec.']);disp(' ');

%% Initiate Interested Domain Parame
x_center=-77;
y_center=18;
x_len=4;
y_len=4;
MinX = x_center - x_len/2;
MaxX = x_center + x_len/2;
MinY = y_center - y_len/2;
MaxY = y_center + y_len/2;

%% Filter ONE: Find Hurricane Tracks ID that have at least one point in the domain
tic;
trackid_in_zone1 = unique(...
    raw_data_file.track_id(...                                             % Returns a vector of unique track_id in zone
    (round(raw_data_file.x,10) >= round(MinX,10)) &...                     % Rounding for precision issues
    (round(raw_data_file.x,10) <  round(MaxX,10)) &...                     % North and East edges excluded
    (round(raw_data_file.y,10) >= round(MinY,10)) &...
    (round(raw_data_file.y,10) <  round(MaxY,10)) ) );
ElapsedTime2 = toc;
disp(['>> Initial Filter to find tracks with points within domain completed in ' num2str(ElapsedTime2) ' sec']);

%% Filter TWO: Find Hurricane Tracks ID that has line segment pass through the domain edge if no points found within
tic
track_to_examine=raw_data_file(~ismember(raw_data_file.track_id, trackid_in_zone1),:);
track_id_examine=unique(track_to_examine.track_id); % Vector of Tracks ID to be examined
trackid_in_zone2 = []; % Output for Filter Two: vector of satisfied track_id
% Loop through all tracks id
nTracks = length(track_id_examine);
% draw a rectangular domain edge
PolyXLim = [MinX MaxX];
PolyYLim = [MinY MaxY];
PolyX = PolyXLim([1 1 2 2 1]);
PolyY = PolyYLim([1 2 2 1 1]);
disp('>> Final Filter application:    ')
%for iTrack = 1:length(track_id_examine(1:1000))  % sample 250 tracks in track_to_examine
for iTrack = 1:length(track_id_examine)
    if mod(iTrack,1000) == 0
        fprintf('\b\b\b\b\b %3d%%',round(100*iTrack/nTracks));
    end
    track = track_to_examine(track_to_examine.track_id==track_id_examine(iTrack),:);
    point_id=track.point_id;
    % Loop through each line segments between two consecutive points using point_id
    for iDataPoint = 0:point_id(end)-1
        % X1 Y1 is the coordinates of the first point
        X1 = track(track.point_id==iDataPoint,:).x;
        Y1 = track(track.point_id==iDataPoint,:).y;
        % X2 Y2 is the coordinates of the second point
        X2 = track(track.point_id==iDataPoint+1,:).x;
        Y2 = track(track.point_id==iDataPoint+1,:).y;
        if (round(min([X1 X2]),10) <  round(MaxX,10)) &&...
                (round(max([X1 X2]),10) >= round(MinX,10)) &&...
                (round(min([Y1 Y2]),10) <  round(MaxY,10)) &&...
                (round(max([Y1 Y2]),10) >= round(MinY,10))
            SegmentX = [X1 X2];   % SegmentX, Y will be passed into polyxpoly as line
            SegmentY = [Y1 Y2];
            % overlap segment X Y with the rectangular domain
            [xi, yi] = polyxpoly(SegmentX,SegmentY,PolyX,PolyY);
            % Store current track_id if intersect with domain edge
            if ~isempty([xi, yi])
                % append track_id of the intersected tracks to the vector trackid_in_zone2
                trackid_in_zone2 = [trackid_in_zone2 ; track_id_examine(iTrack)];
                break
            end
        end
    end
end
ElapsedTime3 = toc;
disp(' ');disp(['   Final Filter to find tracks with edges within domain completed in ' num2str(ElapsedTime3) ' sec']);disp(' ');

%% Generation of table with tracks passing through the domain
% Concatenate the trackid_in_zone in Filter 1 & 2 into one vector
trackid_in_zone = unique([trackid_in_zone1;trackid_in_zone2]); %vector
% Generate intermediate table to store tracks passing through the domain: tracks_in_zone
tracks_in_zone = raw_data_file(ismember(raw_data_file.track_id, trackid_in_zone),:);

%% Diagnosis on Hurricane Tracks passed through domain
disp('>> Diagnostic:    ')
% Hurricane falls into Filter 1
nTracks = length(unique(raw_data_file.track_id));
fprintf('   Tracks from Filter 1:                                    %d of %d (%0.2f%%)\n',length(unique(trackid_in_zone1)),nTracks,round(100*length(unique(trackid_in_zone1))/nTracks,2));
fprintf('   Tracks from Filter 2:                                    %d of %d (%0.2f%%)\n',length(unique(trackid_in_zone2)),nTracks,round(100*length(unique(trackid_in_zone2))/nTracks,2));
fprintf('   Tracks passing through the domain:                       %d of %d (%0.2f%%)\n',length(unique(trackid_in_zone)),nTracks,round(100*length(unique(trackid_in_zone))/nTracks,2));
% Loss Diagnosis on Hurricane Tracks passed through domain
nTracks_inzone = length(unique(tracks_in_zone.track_id));
nTracks_loss = length(unique(raw_loss_file.track_id));
tracks_in_zone_loss = tracks_in_zone(ismember(tracks_in_zone.track_id, unique(raw_loss_file.track_id)),:);
fprintf('   Tracks with loss passing through the domain:             %d of %d (%0.2f%%)\n',length(unique(tracks_in_zone_loss.track_id)),nTracks_loss,round ( 100 * length(unique(tracks_in_zone_loss.track_id))/nTracks_loss , 2));
fprintf('   Tracks with loss among those passing through the domain: %d of %d (%0.2f%%)\n',length(unique(tracks_in_zone_loss.track_id)),nTracks_inzone,round ( 100 * length(unique(tracks_in_zone_loss.track_id))/nTracks_inzone, 2));

%% Store intermediate filtered hurricane data to csv file
writetable(tracks_in_zone,[Directory_Output 'hurricane_inzone_data_4_4.csv']);
TotalElapsedTime = ElapsedTime1 + ElapsedTime2 + ElapsedTime3;
disp(' ');disp(['>> Generated table with stochastic tracks passing through domain in ' num2str(TotalElapsedTime) ' sec']);disp(' ');
