function limited_signal = ATS_applySafetyLimiter(signal, peak_limit)
% Apply conservative peak protection without strong normalization.

if nargin < 2
    peak_limit = 0.95;
end

limited_signal = signal;
current_peak = max(abs(limited_signal));

if current_peak > peak_limit && current_peak > 0
    limited_signal = limited_signal * (peak_limit / current_peak);
end
end
