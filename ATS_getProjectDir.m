function project_dir = ATS_getProjectDir()
% Return the directory that contains the Auditory Training System scripts.

project_dir = fileparts(mfilename('fullpath'));
end
