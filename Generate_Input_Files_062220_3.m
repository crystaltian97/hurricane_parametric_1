close all; clear all;clc
%% Announcement
% Generation of the Input Files
disp('>> Generation of the Input Files:');

%% Load and modify Vendor Loss file
disp('   1. Loss File generation...');
tic
% Read the Loss file
raw_loss_file = readtable('C:\Capstone Project - Phase II\Task 1\Input files from model vendor\stochastic_losses_WIND_Jamaica.csv');
rate = repmat(1/10000,length(raw_loss_file.EventCode),1);                 % Calcolate the rate and associate the same rate to each event
raw_loss_file = addvars(raw_loss_file,rate,'After','Losses_USD_');         % Add the variable "rate" after Losses(USD)
raw_loss_file.Properties.VariableNames{1} = 'track_id';
raw_loss_file.Properties.VariableNames{2} = 'losses_usd';
% Write the Loss file
writetable(raw_loss_file,'C:\Capstone Project - Phase II\Task 1\Input files from model vendor\New_Jamaica_stochastic_loss_data.csv');
ElapsedTime = toc;
disp(['   Loss File generated in ' num2str(ElapsedTime) ' sec']);disp(' ');

%% Load and modify Vendor Hurricane data
disp('   2. Track File generation:    ');
% Read the Input Track file
raw_data_file = readtable('C:\Capstone Project - Phase II\Task 1\Input files from model vendor\concat_stochastic_data.csv');

%Rename code to track_id
raw_data_file = movevars(raw_data_file,'code','Before','date');            % Move the variable "code" before "Date"
raw_data_file.Properties.VariableNames{1} = 'track_id';

%% Generate maximum wind speed and assign a hurrican category to each point
% source: NOAA's standard on maximum wind speed:
% NOAA Hurricane Category Standard:
% Category 0: wind speed less than 74 mph ----> 64.3042 kt
% Category 1: wind speed between 74-95 mph ----> 64.3042-83.4217 kt
% Category 2: wind speed between 96-110 mph ----> 83.4217-96.4564 kt
% Category 3: wind speed between 111-129 mph ----> 96.4564-112.9669 kt
% Category 4: wind speed between 130-156 mph ----> 112.9669-136.4292 kt
% Category 5, wind speed equals 157 mph or higher ----> 136.4292 kt

disp('   Hurricane category calculation:    ');
wind_speed = raw_data_file.mws;
category = zeros(size(wind_speed));
nTotalPoints = size(wind_speed,1);
tic
for iPoint = 1:nTotalPoints
    if mod(iPoint,10) == 0
        fprintf('\b\b\b\b\b %3d%%',round(100*iPoint/nTotalPoints));        % plot the [%] progress
    end
    if isnan(wind_speed(iPoint))
        category(iPoint) = NaN;
    elseif round(wind_speed(iPoint),10) < 64.3042
        category(iPoint) = 0;
    elseif round(wind_speed(iPoint),10) < 83.4217
        category(iPoint) = 1;
    elseif round(wind_speed(iPoint),10) < 96.4564
        category(iPoint) = 2;
    elseif round(wind_speed(iPoint),10) < 112.9669
        category(iPoint) = 3;
    elseif round(wind_speed(iPoint),10) < 136.4292
        category(iPoint) = 4;
    else
        category(iPoint) = 5;
    end
end
ElapsedTime = toc;
raw_data_file = addvars(raw_data_file,category,'After','rmw');             % Add the variable "category" after rmw
disp(' ');
disp(['   Hurricane category calculation completed in ' num2str(ElapsedTime) ' sec']);disp(' ');

%% Generate Point ID
disp('   Point IDs generations:    ');
track_id=raw_data_file.track_id;
counts = histc(track_id, unique(track_id)); %histcounts is not working perfectly for the last two track_ids, use histc instead
nTracks = size(counts,2);
point_id = transpose(0 : counts(1)-1);                                     % Array of Points ID for Track 1
tic
for iTrack = 2 : nTracks
    if mod(iTrack,10) == 0
        fprintf('\b\b\b\b\b %3d%%',round(100*iTrack/nTracks));             % Plot the [%] progress
    end
    temp = transpose(0 : counts(iTrack)-1);                                % Array of Points ID for Track "temp"
    point_id = cat(1,point_id,temp);                                       % Concatenate the arrays of Points ID for each track
end
ElapsedTime = toc;
raw_data_file = addvars(raw_data_file,point_id,'After','track_id');
clear counts;
clear track_id;
disp(' ');
disp(['   Point IDs generated in ' num2str(ElapsedTime) ' sec']);disp(' ');

%% Store modified input file into the input folder
writetable(raw_data_file,'C:\Capstone Project - Phase II\Task 1\Input files from model vendor\new_stochastic_hurricane_data.csv');
disp('   Input Files generation completed');