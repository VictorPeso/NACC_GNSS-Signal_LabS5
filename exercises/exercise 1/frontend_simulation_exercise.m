%EXERCISE 1: front-end simulator and signal analysis
% Luis Esteve NACC QP2026
% luis.esteve@upc.edu
% Javier Arribas NACC 2018
% jarribas@cttc.es

clear all;
close all;
addpath('../../libs');

%% DEFINE THE SIGNAL PARAMETERS
%Define the sampling frequency [Hz]
% Fs>2Fc
Fs=4e6;
%Define the digitized signal duration [s]
Tsig=0.1; 
%Define the carrier frequency
%In order to not overload the MATLAB with high sampling frequency, 
% we use here a low carrier frequency.
Fc=800e3;

%generate the time vector
Ts=1/Fs;
t=0:Ts:(Tsig-Ts);
Nsamples=length(t);

%% Generate a BPSK baseband signal
initial_phase_rad=pi/4;
%BPSK symbol rate
f_symbol_hz=1e3;
%produce random symbols
bpsk_symbols=2*(rand(1,floor(f_symbol_hz*Tsig))>0.5)-1;
bpsk_symbols_resampled=resample(bpsk_symbols,Fs,f_symbol_hz,0);
s_bb_tx=bpsk_symbols_resampled*exp(1j*initial_phase_rad);

% Perform the FFT
% **** QUESTION 1 ****: 
% Perform the FFT of s_bb_tx.  
% Check MATLAB FFT help by typing help FFT
%S_bb_tx=?
S_bb_tx=fft(s_bb_tx);


%compute the frequency axis in Hz
f = Fs/2*linspace(-1,1,Nsamples);
%reorder the FFT results and compute the signal power spectrum in dBW/Hz
NFFT=Nsamples;
S_bb_tx_spectrum_db=10*log10((abs([S_bb_tx(floor((NFFT/2))+1:1:end) S_bb_tx(1:1:(NFFT/2))]).^2)/Nsamples);
S_bb_tx_spectrum_db2=10*log10((abs([S_bb_tx(floor((NFFT/2))+1:1:end) S_bb_tx(1:1:(NFFT/2))]).^2)/(Nsamples*Fs));

%plot the spectrum
% **** QUESTION 2 ****: 
% Capture a figure showing the spectrum of the BPSK signal from -3kHz to 3kHz. 
% Identify the main lobes and the secondary lobes of the modulation. 
% Which parameter of the BPSK modulation has an effect on the lobe spacing?
% Check the effect by variying such parameter and perform the plot again.
figure;
subplot(2,1,1)
plot(f,S_bb_tx_spectrum_db);
title('Transmitted baseband signal (QP2026) (power spectrium)');
xlabel('Hz');
ylabel('dBW/Hz');

subplot(2,1,2)
plot(f,S_bb_tx_spectrum_db2);
title('Transmitted baseband signal (QP2026) Corrected (power spectrium density)');
xlabel('Hz');
ylabel('dBW/Hz');


%% Generate a RF signal carrying the baseband signal
% notice the relation of the signal power of a sinusoid:
% power(s(t))= [s(t)]^2 -> a*cos(w)^2=(a^2/2)+(a^2/2)*cos(2w)
% average_power=avr((a^2/2)+(a^2/2)*cos(2w))=(a^2/2)

%Define the RF signal power
Psig=5;


% **** QUESTION 3 ****: 
% Write here the equation that produces an RF signal, modulating a
% carrier frequency Fc with the baseband signal s_bb_tx. Store it in 
% a vector named s_rf_tx. The obtained signal must have a signal power
% equal to Psig.

%Compute the signal amplitude
%Asig=?
Asig=sqrt(2*Psig);

%Compute the RF signal
%s_rf_tx=?
s_rf_tx=Asig*real(s_bb_tx .* exp(1j * 2 * pi * Fc * t));

% Perform the FFT
S_rf_tx=fft(s_rf_tx);
%compute the frequency axis in Hz
f = Fs/2*linspace(-1,1,Nsamples);
%reorder the FFT results and compute the signal power spectrum in dBW/Hz
NFFT=Nsamples;
S_rf_tx_spectrum_db=10*log10((abs([S_rf_tx(floor((NFFT/2))+1:1:end) S_rf_tx(1:1:(NFFT/2))]).^2)/Nsamples);
S_rf_tx_spectrum_db2=10*log10((abs([S_rf_tx(floor((NFFT/2))+1:1:end) S_rf_tx(1:1:(NFFT/2))]).^2)/(Nsamples*Fs));
%plot the spectrum
figure;
subplot(2,1,1)
plot(f,S_rf_tx_spectrum_db);
title('Transmitted RF signal (QP2026)');
xlabel('Hz');
ylabel('dBW/Hz');

subplot(2,1,2)
plot(f,S_rf_tx_spectrum_db2);
title('Transmitted RF signal (QP2026) Corrected');
xlabel('Hz');
ylabel('dBW/Hz');

% **** QUESTION 4 ****: 
% Capture the figure at maximum zoom out. Explain why it is symetrical.

%% simulate the received signal and add noise

%Define a Doppler shift
Fd=4e3;

% **** QUESTION 5 ****: 
% Write here the equation that produces an RF received signal, modulating a
% carrier frequency Fc with the baseband signal s_bb_tx, and affected by a
% Doppler shift Fd. Store it in a vector named s_rf_rx. The obtained signal
% must have a signal power equal to Psig.

%s_rf_rx=?
s_rf_rx=Asig*real(s_bb_tx .* exp(1j * 2 * pi * (Fc+Fd) * t));

%add noise
SNR_dB=3;
SNR_lin=10^(SNR_dB/10);

% **** QUESTION 6 ****: 
% Compute the noise amplitude (linear)
%An=?
An=sqrt(Psig / SNR_lin);

noise=An*randn(1,Nsamples);
RF_BW_Hz=Fs/2.1;
[b,a] = butter(5,RF_BW_Hz/(Fs/2),'low');
noise=filtfilt(b,a,noise);
y_rf_rx=s_rf_rx+noise;

% Perform the FFT
Y_rf_rx=fft(y_rf_rx);
%compute the frequency axis in Hz
f = Fs/2*linspace(-1,1,Nsamples);
%reorder the FFT results and compute the signal power spectrum in dBW/Hz
NFFT=Nsamples;
Y_rf_rx_spectrum_db=10*log10((abs([Y_rf_rx(floor((NFFT/2))+1:1:end) Y_rf_rx(1:1:(NFFT/2))]).^2)/Nsamples);
Y_rf_rx_spectrum_db2=10*log10((abs([Y_rf_rx(floor((NFFT/2))+1:1:end) Y_rf_rx(1:1:(NFFT/2))]).^2)/(Nsamples*Fs));
%plot the spectrum
figure;
subplot(2,1,1)
plot(f,Y_rf_rx_spectrum_db);
title('Received RF signal (QP2026)');
xlabel('Hz');
ylabel('dBW/Hz');

subplot(2,1,2)
plot(f,Y_rf_rx_spectrum_db2);
title('Received RF signal (QP2026) Corrected');
xlabel('Hz');
ylabel('dBW/Hz');

% **** QUESTION 7 ****: 
% Capture the figure at maximum zoom out. Explain the effects of noise.

% **** QUESTION 8 ****: 
% Perform a zoom in and measure the approximated center frequency 
% of the received signal.

%% SNR estimation
% **** QUESTION 9 ****: 
% Compute the SNR and the CNO in dB
% HINT: Consider RF_BW_Hz=Fs/2.
% HINT: Remember that the signal and noise power can be estimated by using the
% autocorrelation estimation Rxx=(1/K)*(x*x'), where x is a vector
% containing the signal or noise samples.
%SNR_estim_dB=?
P_sig_estim = (1/Nsamples) * (s_rf_rx * s_rf_rx');
P_noise_estim = (1/Nsamples) * (noise * noise');
SNR_estim_lin = P_sig_estim / P_noise_estim;
SNR_estim_dB = 10 * log10(SNR_estim_lin);


disp(['Estimated SNR is ' num2str(SNR_estim_dB) ' vs. desired SNR: ' num2str(SNR_dB) ' [dB]']);

%CN0_estim_dB=?
RF_BW_Hz = Fs / 2;
CN0_estim_dB = SNR_estim_dB + 10 * log10(RF_BW_Hz);

disp(['Estimated CN0 is ' num2str(CN0_estim_dB) ' [dBHz]']);

%% Downconvert the RF signal to baseband
% design the LPF filters
BB_BW_Hz=Fc/2;
[b,a] = butter(5,BB_BW_Hz/(Fs/2),'low');

% **** QUESTION 10 ****: 
% Perform the downconversion and IQ demodulation, considering
% the expected carrier frequency Fc. Store the baseband signal in s_bb_rx
% HINT: The Low Pass Filter (LPF) can be applied by using
% y=filtfilt(b,a,x), where x is the input signal vector and y is the filtered
% output signal vector.

%y_bb_rx_I_filt=?
%y_bb_rx_Q_filt=?

mixer_I = y_rf_rx .* cos(2*pi*Fc*t);
mixer_Q = y_rf_rx .* -sin(2*pi*Fc*t);

y_bb_rx_I_filt = filtfilt(b, a, mixer_I) * (2 / Asig);
y_bb_rx_Q_filt = filtfilt(b, a, mixer_Q) * (2 / Asig);


%ensamble the recovered baseband signal (complex envelope)
y_bb_rx=y_bb_rx_I_filt+1j*y_bb_rx_Q_filt;

% Perform the FFT
Y_bb_rx=fft(y_bb_rx);
%plot the spectrum magnitude
%compute the frequency axis in Hz
f = Fs/2*linspace(-1,1,Nsamples);
%reorder the FFT results and compute the signal power spectrum in dBW/Hz
NFFT=Nsamples;
Y_bb_rx_spectrum_db=10*log10((abs([Y_bb_rx(floor((NFFT/2))+1:1:end) Y_bb_rx(1:1:(NFFT/2))]).^2)/Nsamples);
Y_bb_rx_spectrum_db2=10*log10((abs([Y_bb_rx(floor((NFFT/2))+1:1:end) Y_bb_rx(1:1:(NFFT/2))]).^2)/(Nsamples*Fs));
figure;

% **** QUESTION 11 ****: 
% Capture the received baseband signal spectrum figure. Estimate
% the approximated LPF filter bandwidth and estimate the approximated BPSK signal bandwidth
% Explain how to calculate both bandwidths, the one of the filter and the one of the received BPSK signal

subplot(2,1,1)
plot(f,Y_bb_rx_spectrum_db);
title('Received baseband signal (QP2026)');
xlabel('Hz');
ylabel('dBW/Hz');

subplot(2,1,2)
plot(f,Y_bb_rx_spectrum_db2);
title('Received baseband signal (QP2026) Corrected');
xlabel('Hz');
ylabel('dBW/Hz');




