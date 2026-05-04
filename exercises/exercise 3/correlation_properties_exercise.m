% EXERCISE 3: GPS L1 CA correlation properties
% Luis Esteve NACC QP2026
% luis.esteve@upc.edu
% Javier Arribas NACC 2018
% jarribas@cttc.es

clear all;
close all;
addpath('../../libs');
%% DEFINE THE SIGNAL PARAMETERS
%Define the sampling frequency [Hz]
Fs=10e6;
%Define the digitized signal duration [s]
T_prn=1e-3;
Tsig=T_prn; 
%define chip frequency
Rc_L1_CA=1.023e6;
% **** QUESTION 1 ****:
% Compute the number of chips that fits in Tsig and store it in num_chips
% Considering that the GPS L1 CA PRN sequence has 1023 chips and a chip rate of 1.023 MChips/s, compute the
% duration of the GPS L1 CA complete sequence.
% num_chips=?
num_chips = round(Rc_L1_CA * Tsig);


%generate the time vector
Ts=1/Fs;
t=0:Ts:(Tsig-Ts);
Nsamples=length(t);

%% generate the transmitted satellite baseband signal
NSATS=31;
 %satellite PRN 1
 for numsat=1:1:NSATS
    s_bb_sat(numsat,:)=digitGPS_L1_CA(num_chips,Fs,0,numsat,1); % PRN C_E1_B muestreada a Rc_E1_B (directamente chip rate)
 end
 
%% GPS L1 CA autocorrelation Rdd

d=s_bb_sat(1,:);
shift_samples=-floor(Nsamples/2):1:floor(Nsamples/2);

% **** QUESTION 2 ****:
% compute the circular autocorrelation estimation of the satellite signal stored in the vector
% d for all the possible delays, using the formula
% Rdd(tau)=(1/K)*(d*d(tau)'), where tau is the delay in samples. All the
% possible delay values are stored in the vector shift_samples.
% HINT: in order to perform a circular shift of a vector, use the built-in
% MATLAB function circshift. Use the MATLAB help to learn how to use
% circshift

Rdd = zeros(1,length(shift_samples));

for n = 1:length(shift_samples)
    d_shift = circshift(d, shift_samples(n));
    Rdd(n) = (1/Nsamples) * (d * d_shift');
end

% **** QUESTION 3 ****:
% Analize the following two figures. Check the X axis units. Measure the
% autocorrelation lag (or code phase shift) in CHIPS UNITS that produces a reduction of
% 50% of the autocorrelation gain. Convert the result to samples. Check the
% theory slides.
plot(shift_samples,Rdd)
title('Circular Autocorrelation Rdd(tau) (QP2026)');
xlabel('Samples');
ylabel('Rdd');

figure;
fchip=Rc_L1_CA;
samples_per_chip=Fs/fchip;
shift_chips=shift_samples/samples_per_chip;
plot(shift_chips,Rdd)
title('Circular Autocorrelation Rdd(tau) (QP2026)');
xlabel('Chips');
ylabel('Rdd');

chips_50_percent = 0.5;
samples_50_percent = chips_50_percent * samples_per_chip;

disp(' ***** Q2 *****');
disp(['50 percent autocorrelation reduction at approximately ' num2str(chips_50_percent) ' chips']);
disp(['Equivalent to approximately ' num2str(samples_50_percent) ' samples']);
disp('');

% **** QUESTION 4 ****:
% Compute the estimation of the autocorrelation gain defined as the ratio 
% between abs(Rdd(tau=0)) and abs(Rdd(tau>>1chip)). Convert it to dB.

idx_zero = find(shift_samples == 0);

main_lobe_mask = abs(shift_chips) < 1;

Rdd_peak = abs(Rdd(idx_zero));
Rdd_sidelobe = max(abs(Rdd(~main_lobe_mask)));

autocorr_gain_dB = 20*log10(Rdd_peak / Rdd_sidelobe);

disp(' ***** Q4 *****');
disp(['Estimated autocorrelation gain is ' num2str(autocorr_gain_dB) ' [dB]']);
disp('');

% **** QUESTION 5 ****:
% Compute the estimation of the cross-correlation gain between different satellite's PRNs defined as the ratio 
% between abs(R_(d_sat1,d_sat1)(tau=0)) and abs(R_(d_sat1,d_sat2)(tau=0)). Convert it to dB.

d_sat1 = s_bb_sat(1,:);
d_sat2 = s_bb_sat(2,:);

Rd_sat1_sat2_0 = (1/Nsamples) * (d_sat1 * d_sat2');

crosscorr_gain_dB = 20*log10(abs(Rdd(idx_zero)) / max(abs(Rd_sat1_sat2_0),eps));

disp(' ***** Q5 *****');
disp(['Estimated cross-correlation gain is ' num2str(crosscorr_gain_dB) ' [dB]']);
disp('');

%% Autocorrelation vs. frequency shift
%autocorrelation maximum abs(Rdd(tau=0)) vs. frequency shift

d=s_bb_sat(1,:);
Fd_error_max_hz=4000;
shift_hz=-Fd_error_max_hz:10:Fd_error_max_hz;

% **** QUESTION 6 ****:
% compute the autocorrelation estimation of Rdd(tau=0,f) vs. a frequency
% doppler error simulated as a frequency shift.
% HINT: R_(d,d(f))=(1/K)*(d*d*exp(-jW))'
% where w is expressed in rad/s

Rdd_doppler_error = zeros(1,length(shift_hz));

for n = 1:length(shift_hz)
    d_freq = d .* exp(1j*2*pi*shift_hz(n)*t);
    Rdd_doppler_error(n) = (1/Nsamples) * (d * d_freq');
end

% **** QUESTION 7 ****:
% Measure the 50% autocorrelation gain reduction vs. frequency. Express the
% result in Hz. Define the Doppler shift acquisition grid granularity based on the
% result.

Rmax = max(abs(Rdd_doppler_error));
target = 0.5 * Rmax;

positive_freq_idx = find(shift_hz >= 0);

[~,idx_50_local] = min(abs(abs(Rdd_doppler_error(positive_freq_idx)) - target));

idx_50 = positive_freq_idx(idx_50_local);

freq_50_percent = shift_hz(idx_50);

disp(' ***** Q7 *****');
disp(['50 percent correlation reduction at approximately ' num2str(freq_50_percent) ' Hz']);
disp(' ');

figure;
plot(shift_hz,abs(Rdd_doppler_error))
title('Circular Autocorrelation Rdd(tau=0,f) (QP2026)');
xlabel('Freq error [Hz]');
ylabel('abs(Rdd)');


% **** QUESTION 8 ****:

% Increase now the signal duration Tsig from 1ms to several ms. Plot again
% the sinc-shaped curve. Recompute the 50% gain reduction and the
% Doppler shift grid granularity and discuss the results. Compare the value 
% obtained in the simulation with the theoretical value explained in the theory
% sessions (check the theory slides). 

Tsig_long = 5e-3;
num_chips_long = round(Rc_L1_CA * Tsig_long);

t_long = 0:Ts:(Tsig_long-Ts);
Nsamples_long = length(t_long);

for numsat = 1:1:NSATS
    s_bb_sat_long(numsat,:) = digitGPS_L1_CA(num_chips_long,Fs,0,numsat,1);
end

d_long = s_bb_sat_long(1,:);

shift_hz_long = -Fd_error_max_hz:10:Fd_error_max_hz;

Rdd_doppler_error_long = zeros(1,length(shift_hz_long));

for n = 1:length(shift_hz_long)
    d_freq_long = d_long .* exp(1j*2*pi*shift_hz_long(n)*t_long);
    Rdd_doppler_error_long(n) = (1/Nsamples_long) * (d_long * d_freq_long');
end

figure;
plot(shift_hz_long,abs(Rdd_doppler_error_long))
title('Circular Autocorrelation Rdd(tau=0,f), Tsig = 5 ms (QP2026)');
xlabel('Freq error [Hz]');
ylabel('abs(Rdd)');

Rmax_long = max(abs(Rdd_doppler_error_long));
target_long = 0.5 * Rmax_long;

positive_freq_idx_long = find(shift_hz_long >= 0);

[~,idx_50_local_long] = min(abs(abs(Rdd_doppler_error_long(positive_freq_idx_long)) - target_long));

idx_50_long = positive_freq_idx_long(idx_50_local_long);

freq_50_percent_long = shift_hz_long(idx_50_long);

disp(' ***** Q8 *****');
disp(['For Tsig = 5 ms, 50 percent Doppler correlation reduction at approximately ' num2str(freq_50_percent_long) ' Hz']);
disp(['Theoretical value for Tsig = 5 ms is approximately ' num2str(0.603/Tsig_long) ' Hz']);