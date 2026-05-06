function session_file = ATS_getSessionFile()
% Return the full path to the shared session MAT file.

session_file = fullfile(ATS_getProjectDir(), 'calibration_data.mat');
end
