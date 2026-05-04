
clear all
close all
addpath('../../libs');
load('../../signals/gps_l1_ca_2msps.mat');
Fs = 2e6;
SV = 1;
threshold = 5;
%To.Do.. write here the acquisition engine
pcps_acquisition(rawSignal, Fs, -5e3, 5e3, 250, threshold, SV);
