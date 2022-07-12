function [] = WormTracker3000()
%%WormTracker3000 Hallem Lab general purpose software for analysis and plotting on worm tracks
%   The Worm Tracker 3000 is a unified codebase for the analysis and
%   plotting of worm tracks collected during the course of behavioral
%   assays, including: thermotaxis, odor tracking, C02 tracking, etc...
%
%   Code designed and created by Astra S. Bryant, PhD
%
%   Version 0.3
%   Version Date: July 2022

close all; clear all
warning('off');
global info
global dat
global vals
global tracks

% %% User Provided Variables (used during plotting) - logical values
% subsetplot = 1; %Generate subset plot y/n (logical)? Note: if there are less than 10 worms, the subset plot won't be generated anyway.
% individualplots = 0; % Generate individual plots for each track y/n (logical)?

%% Load experimental parameters and data
load_files();
[info.pathstr, info.name, ~] = fileparts(info.calledfile);

%% Load experimental information and parameters
load_params()

%% Load track data
load_tracks()

%% Process data
if contains(info.assaytype, 'Bact_4.9') || contains(info.assaytype, 'C02_3.75') ...
        || contains(info.assaytype, 'Pher_5') || contains(info.assaytype, 'Odor_5')...
        || contains(info.assaytype, 'Custom_linear') ...
        || contains(info.assaytype, 'Basic_info') ...
    [info.ref, info.pixelpercmarray] = adjust_port_scaling (dat.Xvals.Pixels, dat.Yvals.Pixels, info.pixelspercm, info.ref); %converts tracks from pixels to cm
    [info.refcm] = align_to_ROIs (dat.Xvals.Pixels, dat.Yvals.Pixels, info.ref, info.pixelpercmarray);
elseif contains(info.assaytype, 'Thermo_22')
    [tracks.xvalsgradient] = convert_to_thermo(dat.Xvals.Pixels, dat.Yvals.Pixels,info.pixelspercm); %converts tracks from pixels to cm then to temperature
end

%% Standard Quantifications
path_statistics();

if contains(info.assaytype, 'Bact_4.9') || contains(info.assaytype, 'C02_3.75') ...
        || contains(info.assaytype, 'Pher_5') || contains(info.assaytype, 'Odor_5')
    orient_to_odorant(info.plateorient);
    elseif contains(info.assaytype, 'Custom_linear')
        adjust_orientation(info.plateorient);
end

%% Run additional analyses depending on the type of assay (Odor vs CO2)
if contains(info.assaytype, 'C02_3.75')
    [vals.zonetime, vals.nfinal, vals.neutZone] = quant_specific_co2(tracks.plotxvals, vals.CportStdLoc);

elseif contains(info.assaytype, 'Bact_4.9') ...
        || contains(info.assaytype, 'Pher_5') || contains(info.assaytype, 'Odor_5')
    [vals.zonetime, vals.nfinal, vals.neutZone] = quant_specific_odor(tracks.plotxvals, tracks.plotyvals, vals.CportStdLoc);

elseif contains(info.assaytype, 'Custom_linear')
    [tracks.xvalsgradient] = convert_to_gradient(tracks.plotxvals, tracks.plotyvals);
    [vals.finalgradientval,vals.gradientdiff] = quant_specific_linear(tracks.xvalsgradient);
    
elseif contains(info.assaytype, 'Thermo_22')
    [vals.finalgradientval,vals.gradientdiff] = quant_specific_linear(tracks.xvalsgradient);
end

%% Plotting and Saving
if ~exist(fullfile(info.pathstr,info.name),'dir')
    mkdir([fullfile(info.pathstr,info.name)]);
end

%% Generate track plots for chemotaxis assays
if contains(info.assaytype, 'Bact_4.9') || contains(info.assaytype, 'C02_3.75') ...
        || contains(info.assaytype, 'Pher_5') || contains(info.assaytype, 'Odor_5')
    plot_chemotaxis(tracks.plotxvals, tracks.plotyvals, vals.CportStdLoc, vals.neutZone, info.name, info.pathstr)
elseif contains(info.assaytype, 'Custom_linear') || contains(info.assaytype, 'Thermo_22')
    plot_linear(tracks.xvalsgradient, tracks.plotyvals, info.name, info.pathstr); 
elseif contains(info.assaytype, 'Basic_info')
    plot_basic(tracks.xvalscm, tracks.yvalscm, info.name, info.pathstr);    
end

%% Save data
save_data();

close all
disp('Finished Analyzing Worm Tracks!');


end

