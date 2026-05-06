function [stimulus, Fs] = ATS_makePinkNoiseStimulus(duration_seconds, target_frequencies, q_factor, gains_db)
% Create a pink-noise stimulus with optional multiband EQ gains.

Fs = 44100;
stimulus = ATS_generatePinkNoise(Fs, duration_seconds);

if any(gains_db ~= 0)
    eq = multibandParametricEQ('NumEQBands', numel(target_frequencies), ...
        'Frequencies', target_frequencies, ...
        'QualityFactors', repmat(q_factor, 1, numel(target_frequencies)), ...
        'PeakGains', gains_db, ...
        'SampleRate', Fs);
    stimulus = eq(stimulus);
    release(eq);
end

stimulus = ATS_applySafetyLimiter(stimulus, 0.95);
end
