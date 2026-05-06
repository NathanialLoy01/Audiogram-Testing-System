function pink_noise = ATS_generatePinkNoise(Fs, duration_seconds)
% Generate normalized pink noise without relying on external audio files.

n_samples = max(1, round(Fs * duration_seconds));
white_noise = randn(n_samples, 1);

noise_spectrum = fft(white_noise);
bin_index = (0:n_samples-1)';
mirrored_bin = min(bin_index, n_samples - bin_index);

pink_scale = ones(n_samples, 1);
nonzero_bins = mirrored_bin > 0;
pink_scale(nonzero_bins) = 1 ./ sqrt(mirrored_bin(nonzero_bins));

pink_noise = real(ifft(noise_spectrum .* pink_scale));
pink_noise = pink_noise - mean(pink_noise);

peak_value = max(abs(pink_noise));
if peak_value > 0
    pink_noise = 0.35 * pink_noise / peak_value;
end
end
