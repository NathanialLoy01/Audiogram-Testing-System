function session_data = ATS_loadSessionData()
% Load the shared session state used across Steps 1, 2, and 3.

session_data = struct();
session_file = ATS_getSessionFile();

if ~exist(session_file, 'file')
    return;
end

loaded_data = load(session_file);

if isfield(loaded_data, 'session_data')
    session_data = loaded_data.session_data;
    return;
end

% Backward compatibility with earlier MAT-file fields.
if isfield(loaded_data, 'User_Name')
    session_data.User_Name = loaded_data.User_Name;
end
if isfield(loaded_data, 'user_group')
    session_data.User_Group = loaded_data.user_group;
end
if isfield(loaded_data, 'max_audiogram_value')
    session_data.Max_Audiogram_Value = loaded_data.max_audiogram_value;
end
if isfield(loaded_data, 'Audiogram')
    session_data.Audiogram = loaded_data.Audiogram;
    session_data.Audiogram_Data = loaded_data.Audiogram;
end
end
