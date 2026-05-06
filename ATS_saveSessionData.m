function ATS_saveSessionData(session_data)
% Save the shared session state used across Steps 1, 2, and 3.

session_file = ATS_getSessionFile();
save(session_file, 'session_data');
end
