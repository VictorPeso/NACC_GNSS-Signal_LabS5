% EXERCISE 4: GNSS acquisition engine
% GNSS Signal Acquisition Laboratory
% This script uses pcps_acquisition.m without modifying it.

clear all;
close all;
clc;

addpath('../../libs');

%% Load captured GPS L1 C/A signal

load('../../signals/gps_l1_ca_2msps.mat');

BB_signal = rawSignal;

%% Acquisition parameters

Fs = 2e6;                  % Sampling frequency [Hz]
doppler_min_hz = -25e3;    % Minimum Doppler search frequency [Hz]
doppler_max_hz =  25e3;    % Maximum Doppler search frequency [Hz]
doppler_step_hz = 250;     % Doppler grid step [Hz]
threshold = 5;             % Acquisition threshold

prn_min = 1;
prn_max = 32;

%% Output folders for acquisition figures

results_folder = 'acquisition_results';

if ~exist(results_folder, 'dir')
    mkdir(results_folder);
end

%% Initialise result storage

acq_table = [];

fprintf('\n');
fprintf('================ EXERCISE 4 ACQUISITION SUMMARY ================\n');
fprintf('Sampling frequency is %.4f MHz\n', Fs/1e6);
fprintf('Doppler search range is %.0f Hz to %.0f Hz\n', doppler_min_hz, doppler_max_hz);
fprintf('Doppler grid step is %.0f Hz\n', doppler_step_hz);
fprintf('Acquisition threshold is %.2f\n', threshold);
fprintf('\n');

%% Acquisition loop for all GPS L1 C/A PRNs

for SV = prn_min:prn_max

    % Store the figures currently open before calling pcps_acquisition.
    figures_before = findall(0, 'Type', 'figure');

    % Run PCPS acquisition for the current satellite PRN.
    acqResults = pcps_acquisition( ...
        BB_signal, ...
        Fs, ...
        doppler_min_hz, ...
        doppler_max_hz, ...
        doppler_step_hz, ...
        threshold, ...
        SV);

    % Detect the new acquisition grid figure created by pcps_acquisition.
    figures_after = findall(0, 'Type', 'figure');
    new_figures = setdiff(figures_after, figures_before);

    if acqResults.satellite_detected == 1

        % Store detection results.
        acq_table = [acq_table; ...
            SV, ...
            acqResults.codePhase, ...
            acqResults.carrFreq, ...
            acqResults.peakMetric];

        % Save the acquisition grid figure for detected satellites.
        if ~isempty(new_figures)
            fig = new_figures(1);
            figure(fig);
            saveas(fig, fullfile(results_folder, ...
                sprintf('acquisition_grid_PRN_%02d.png', SV)));
        end

    else
        % Close the acquisition grid figure for non-detected satellites
        % to avoid keeping too many unnecessary figures open.
        if ~isempty(new_figures)
            close(new_figures);
        end
    end
end

%% Display detected satellites table

if isempty(acq_table)

    fprintf('No satellites were detected with the selected threshold.\n');
    fprintf('Try reducing the threshold or using a different Doppler step.\n');

else

    detected_PRN = acq_table(:,1);
    code_delay_samples = acq_table(:,2);
    doppler_hz = acq_table(:,3);
    peak_metric = acq_table(:,4);

    fprintf('\n');
    fprintf('Detected satellites:\n');
    fprintf('PRN    Code delay [samples]    Doppler [Hz]    Test statistic\n');
    fprintf('---    --------------------    ------------    --------------\n');

    for k = 1:length(detected_PRN)
        fprintf('%02d     %20.0f    %12.0f    %14.4f\n', ...
            detected_PRN(k), ...
            code_delay_samples(k), ...
            doppler_hz(k), ...
            peak_metric(k));
    end

    %% Parasitic IF estimation and Doppler correction

    parasitic_IF_hz = mean(doppler_hz);
    corrected_doppler_hz = doppler_hz - parasitic_IF_hz;

    fprintf('\n');
    fprintf('Estimated parasitic IF is %.4f Hz\n', parasitic_IF_hz);
    fprintf('\n');

    fprintf('Detected satellites with corrected Doppler:\n');
    fprintf('PRN    Code delay [samples]    Doppler [Hz]    Corrected Doppler [Hz]    Test statistic\n');
    fprintf('---    --------------------    ------------    ----------------------    --------------\n');

    for k = 1:length(detected_PRN)
        fprintf('%02d     %20.0f    %12.0f    %22.4f    %14.4f\n', ...
            detected_PRN(k), ...
            code_delay_samples(k), ...
            doppler_hz(k), ...
            corrected_doppler_hz(k), ...
            peak_metric(k));
    end

    %% Identify strongest and weakest detected satellites

    [~, strongest_idx] = max(peak_metric);
    [~, weakest_idx] = min(peak_metric);

    strongest_PRN = detected_PRN(strongest_idx);
    weakest_PRN = detected_PRN(weakest_idx);

    fprintf('\n');
    fprintf('Most powerful detected satellite is PRN %02d with test statistic %.4f\n', ...
        strongest_PRN, peak_metric(strongest_idx));

    fprintf('Least powerful detected satellite is PRN %02d with test statistic %.4f\n', ...
        weakest_PRN, peak_metric(weakest_idx));

    fprintf('\n');
    fprintf('The acquisition grid figures of detected satellites have been saved in folder: %s\n', ...
        results_folder);

    fprintf('Use acquisition_grid_PRN_%02d.png as the strongest satellite acquisition grid.\n', ...
        strongest_PRN);

    fprintf('Use acquisition_grid_PRN_%02d.png as the weakest satellite acquisition grid.\n', ...
        weakest_PRN);

    %% Save numerical results to CSV files

    results_table = table( ...
        detected_PRN, ...
        code_delay_samples, ...
        doppler_hz, ...
        corrected_doppler_hz, ...
        peak_metric, ...
        'VariableNames', { ...
            'PRN', ...
            'CodeDelay_samples', ...
            'Doppler_Hz', ...
            'CorrectedDoppler_Hz', ...
            'TestStatistic'});

    writetable(results_table, fullfile(results_folder, 'acquisition_results.csv'));

end

fprintf('================================================================\n');

%% Optional: Doppler grid granularity comparison

run_doppler_step_comparison = true;

if run_doppler_step_comparison && ~isempty(acq_table)

    doppler_steps_to_test = [1000, 500, 250, 100];

    granularity_summary = [];

    fprintf('\n');
    fprintf('================ DOPPLER GRID GRANULARITY TEST ================\n');

    for step_idx = 1:length(doppler_steps_to_test)

        current_step = doppler_steps_to_test(step_idx);
        detected_count = 0;
        detected_prns_current = [];

        fprintf('\n');
        fprintf('Testing Doppler step %.0f Hz\n', current_step);

        for SV = prn_min:prn_max

            figures_before = findall(0, 'Type', 'figure');

            acqResults_step = pcps_acquisition( ...
                BB_signal, ...
                Fs, ...
                doppler_min_hz, ...
                doppler_max_hz, ...
                current_step, ...
                threshold, ...
                SV);

            figures_after = findall(0, 'Type', 'figure');
            new_figures = setdiff(figures_after, figures_before);

            % Close all figures generated during the granularity test.
            if ~isempty(new_figures)
                close(new_figures);
            end

            if acqResults_step.satellite_detected == 1
                detected_count = detected_count + 1;
                detected_prns_current = [detected_prns_current, SV];
            end
        end

        granularity_summary = [granularity_summary; current_step, detected_count];

        fprintf('Detected satellites with Doppler step %.0f Hz: %d\n', ...
            current_step, detected_count);

        fprintf('Detected PRNs: ');
        fprintf('%02d ', detected_prns_current);
        fprintf('\n');
    end

    fprintf('\n');
    fprintf('Doppler step [Hz]    Number of detected satellites\n');
    fprintf('-----------------    -----------------------------\n');

    for k = 1:size(granularity_summary,1)
        fprintf('%17.0f    %29.0f\n', ...
            granularity_summary(k,1), ...
            granularity_summary(k,2));
    end

    granularity_table = table( ...
        granularity_summary(:,1), ...
        granularity_summary(:,2), ...
        'VariableNames', {'DopplerStep_Hz','DetectedSatellites'});

    writetable(granularity_table, fullfile(results_folder, 'doppler_grid_granularity.csv'));

    fprintf('================================================================\n');
end