% Step3_Training_System_2sec_TEST.m - TEST MODE
% Full training system with calibration integration
% - 7 boost levels: 20, 18, 15, 12, 9, 6, 3 dB
% - 7 cut levels: -20, -18, -15, -12, -9, -6, -3 dB
% - Receives calibration results
% - Handles audiogram gain progression for Adjusted users
% - Standard keyboard characters only

% Keep variables from calibration
clc; close all;

Session_Data = ATS_loadSessionData();

%%% Audio file paths ***
Audio_Files{1} = '/.pop.wav'; 
Audio_Files{2} = '/.classical.wav'; 
Audio_Files{3} = '/.jazz.wav'; 
Audio_Files{4} = '/.classic_rock.wav'; 
Audio_Files{5} = '/.hip_hop.wav'; 
Audio_Files{6} = '/.folk.wav'; 
Audio_Files{7} = '/.classical_piano.wav'; 
Audio_Files{8} = '/.latin.wav';

Genre_Labels = {'Pop', 'Orchestral', 'Jazz', 'Classic Rock', 'Hip Hop', 'Folk', 'Classical Piano', 'Latin'};

Q_FACTOR = sqrt(2);
Fs = 44100;
noise_duration = 2;  % *** TEST MODE: 2 seconds instead of 10 ***
Target_Frequencies = [125, 250, 500, 1000, 2500, 4000, 8000, 16000];
Freq_Labels = {'125 Hz', '250 Hz', '500 Hz', '1 kHz', '2.5 kHz', '4 kHz', '8 kHz', '16 kHz'};

%%% 7 boost and 7 cut levels ***
Boost_Levels = [20, 18, 15, 12, 9, 6, 3];
Cut_Levels = [-20, -18, -15, -12, -9, -6, -3];
Boost_Labels = {'+20 dB', '+18 dB', '+15 dB', '+12 dB', '+9 dB', '+6 dB', '+3 dB'};
Cut_Labels = {'-20 dB', '-18 dB', '-15 dB', '-12 dB', '-9 dB', '-6 dB', '-3 dB'};

Test_Rounds_Required = 10;
Test_Pass_Threshold = 0.8;

% Load user info
if ~exist('User_Name', 'var') || isempty(User_Name)
    if isfield(Session_Data, 'User_Name')
        User_Name = Session_Data.User_Name;
    else
        User_Name = 'unknown';
    end
end

if ~exist('User_Group', 'var')
    if isfield(Session_Data, 'User_Group')
        User_Group = Session_Data.User_Group;
    else
        User_Group = 'Normal';
    end
end

% Load calibration results
if ~exist('Calibration_Boost_Level', 'var')
    if isfield(Session_Data, 'Calibration_Boost_Level')
        Calibration_Boost_Level = Session_Data.Calibration_Boost_Level;
    else
        Calibration_Boost_Level = 12;
    end
end

if ~exist('Calibration_Complete', 'var')
    if isfield(Session_Data, 'Calibration_Complete')
        Calibration_Complete = Session_Data.Calibration_Complete;
    else
        Calibration_Complete = false;
    end
end

% Load audiogram data
if ~exist('Baseline_Audiogram', 'var')
    if isfield(Session_Data, 'Baseline_Audiogram')
        Baseline_Audiogram = Session_Data.Baseline_Audiogram;
    else
        Baseline_Audiogram = zeros(1, numel(Target_Frequencies));
    end
end

if ~exist('Audiogram_Gain_Percentage', 'var')
    if isfield(Session_Data, 'Audiogram_Gain_Percentage')
        Audiogram_Gain_Percentage = Session_Data.Audiogram_Gain_Percentage;
    elseif strcmp(User_Group, 'Normal')
        Audiogram_Gain_Percentage = 0.0;
    else
        Audiogram_Gain_Percentage = 1.0;
    end
end

% Calculate active compensation
Active_Compensation = Baseline_Audiogram .* Audiogram_Gain_Percentage;
Audiogram_Gain_Corrections = Active_Compensation;

% EQ setup
eq = multibandParametricEQ('NumEQBands', numel(Target_Frequencies), ...
    'Frequencies', Target_Frequencies, ...
    'QualityFactors', repmat(Q_FACTOR, 1, numel(Target_Frequencies)), ...
    'PeakGains', zeros(1, numel(Target_Frequencies)), ...
    'SampleRate', Fs);

% Initialize unlocked levels based on calibration
% Start with ONLY the calibration level unlocked
Boost_Unlocked = false(1, 7);
Cut_Unlocked = false(1, 7);

calib_idx = find(Boost_Levels == Calibration_Boost_Level);
if isempty(calib_idx)
    calib_idx = 4;
end

if isfield(Session_Data, 'Boost_Unlocked') && numel(Session_Data.Boost_Unlocked) == 7
    Boost_Unlocked = logical(Session_Data.Boost_Unlocked);
else
    Boost_Unlocked(1:calib_idx) = true;
end
Boost_Unlocked(1:calib_idx) = true;

if isfield(Session_Data, 'Cut_Unlocked') && numel(Session_Data.Cut_Unlocked) == 7
    Cut_Unlocked = logical(Session_Data.Cut_Unlocked);
else
    Cut_Unlocked(1:calib_idx) = true;
end
Cut_Unlocked(1:calib_idx) = true;

fprintf('\n========================================\n');
fprintf('Training Session Started\n');
fprintf('========================================\n');
fprintf('User: %s\n', User_Name);
fprintf('Group: %s\n', User_Group);
fprintf('Calibration Level: %d dB\n', Calibration_Boost_Level);
fprintf('Audiogram Gain: %.0f%%\n', Audiogram_Gain_Percentage * 100);
fprintf('\nUnlocked Boost Levels: ');
for i = 1:7
    if Boost_Unlocked(i)
        fprintf('%d ', Boost_Levels(i));
    end
end
fprintf('dB\n');
fprintf('========================================\n\n');

%% Main GUI Setup
App.User_Name = User_Name;
App.User_Group = User_Group;
App.Trial_Number = 0;
App.Round = 0;
App.Num_Correct = 0;
App.Result_Log = [];
App.Freq_Log = [];
App.Correct_Idx = 0;
App.Current_Genre = '';
App.Answered = false;
App.Session_Active = false;
App.Cumulative_Correct = zeros(1, numel(Target_Frequencies));
App.Cumulative_Total = zeros(1, numel(Target_Frequencies));
App.Export_Log = table('Size', [0, 5], ...
    'VariableTypes', {'double', 'string', 'string', 'string', 'string'}, ...
    'VariableNames', {'Trial_Number', 'Frequency', 'Genre', 'Mode', 'Result'});
App.Audio_Files = Audio_Files;
App.Genre_Labels = Genre_Labels;
App.Q_FACTOR = Q_FACTOR;
App.Fs = Fs;
App.noise_duration = noise_duration;
App.eq = eq;
App.Session_Data = Session_Data;

% Calibration and compensation
App.Calibration_Boost_Level = Calibration_Boost_Level;
App.Baseline_Audiogram = Baseline_Audiogram;
App.Active_Compensation = Active_Compensation;
App.Audiogram_Gain_Percentage = Audiogram_Gain_Percentage;
App.Audiogram_Gain_Corrections = Audiogram_Gain_Corrections;

% Practice mode
App.Practice_Mode = 'Boost';
App.Practice_Gain_dB = Calibration_Boost_Level;

% Test configuration
App.Test_Rounds_Required = Test_Rounds_Required;
App.Test_Pass_Threshold = Test_Pass_Threshold;

% Test state
App.T.Mode = '';
App.T.Active_Level = 0;
App.T.Round = 0;
App.T.Num_Correct = 0;
App.T.Correct_Idx = 0;
App.T.Current_Genre = '';
App.T.Answered = false;
App.T.Boost_Unlocked = Boost_Unlocked;
App.T.Cut_Unlocked = Cut_Unlocked;

% Create figure
Fig_W = 950;
Fig_H = 700;
Main_Fig = uifigure('Name', sprintf('Critical Listening Trainer - %s [TEST MODE - 2s AUDIO]', User_Name), ...
    'Position', [150, 50, Fig_W, Fig_H], 'Color', [0.94, 0.94, 0.94]);

% Create tab group
Tab_Group = uitabgroup(Main_Fig, 'Position', [10, 10, Fig_W-20, Fig_H-20]);

% PRACTICE TAB
Practice_Tab = uitab(Tab_Group, 'Title', 'Practice Mode [TEST: 2s clips]');

uilabel(Practice_Tab, 'Text', 'Practice Mode [TEST: 2s clips]', ...
    'Position', [0, 610, 930, 30], 'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'FontColor', [0.1, 0.1, 0.1]);

% Mode selection
Mode_Panel = uipanel(Practice_Tab, 'Position', [165, 520, 600, 80], ...
    'Title', 'Select Practice Type', 'FontSize', 12, 'FontWeight', 'bold');

Mode_Group = uibuttongroup(Mode_Panel, 'Position', [20, 0, 560, 55], ...
    'BorderType', 'none');

Boost_Radio = uiradiobutton(Mode_Group, 'Text', 'Boost (Increase frequency)', ...
    'Position', [95, 20, 220, 20], 'Value', true);
Cut_Radio = uiradiobutton(Mode_Group, 'Text', 'Cut (Decrease frequency)', ...
    'Position', [340, 20, 220, 20]);

% Level selection - 7 levels
Level_Panel = uipanel(Practice_Tab, 'Position', [165, 390, 600, 110], ...
    'Title', 'Select Difficulty Level', 'FontSize', 12, 'FontWeight', 'bold');

Level_Group = uibuttongroup(Level_Panel, 'Position', [20, 0, 560, 85], ...
    'BorderType', 'none');

Level_Btns = cell(1, 7);
for i = 1:7
    row = floor((i-1)/4);
    col = mod(i-1, 4);
    Level_Btns{i} = uiradiobutton(Level_Group, ...
        'Text', sprintf('%+d dB', Boost_Levels(i)), ...
        'Position', [55 + col*135, 55 - row*30, 85, 20]);
    if i == calib_idx
        Level_Btns{i}.Value = true;
    end
end

% Session controls
Session_Panel = uipanel(Practice_Tab, 'Position', [165, 260, 600, 115], ...
    'Title', 'Session Controls', 'FontSize', 12, 'FontWeight', 'bold');

Begin_Btn = uibutton(Session_Panel, 'Text', 'Begin Round', ...
    'Position', [60, 55, 210, 38], 'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2, 0.6, 0.3], 'FontColor', [1, 1, 1], ...
    'ButtonPushedFcn', @(src, evt) beginRound(Main_Fig, Boost_Levels, Cut_Levels, Freq_Labels, Target_Frequencies));

Finish_Btn = uibutton(Session_Panel, 'Text', 'Finish Session', ...
    'Position', [330, 55, 210, 38], 'FontSize', 12, ...
    'Enable', 'off', ...
    'ButtonPushedFcn', @(src, evt) finishSession(Main_Fig, Tab_Group, [], Freq_Labels));

Status_Label = uilabel(Session_Panel, 'Text', 'Ready to begin practice session', ...
    'Position', [20, 25, 560, 25], 'FontSize', 11, ...
    'HorizontalAlignment', 'center');

Score_Label = uilabel(Session_Panel, 'Text', '', ...
    'Position', [20, 5, 560, 20], 'FontSize', 10, ...
    'HorizontalAlignment', 'center', 'FontColor', [0.4, 0.4, 0.4]);

% Frequency selection buttons
Freq_Panel = uipanel(Practice_Tab, 'Position', [55, 50, 820, 190], ...
    'Title', 'Which frequency was boosted/cut?', 'FontSize', 12, 'FontWeight', 'bold');

Freq_Btns = cell(1, 8);
for i = 1:4
    Freq_Btns{i} = uibutton(Freq_Panel, 'Text', Freq_Labels{i}, ...
        'Position', [25 + (i-1)*195, 100, 180, 50], 'FontSize', 12, ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @(src, evt) submitGuess(Main_Fig, i, Freq_Labels));
end

for i = 5:8
    Freq_Btns{i} = uibutton(Freq_Panel, 'Text', Freq_Labels{i}, ...
        'Position', [25 + (i-5)*195, 35, 180, 50], 'FontSize', 12, ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @(src, evt) submitGuess(Main_Fig, i, Freq_Labels));
end

Feedback_Label = uilabel(Freq_Panel, 'Text', '', ...
    'Position', [20, 5, 780, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');

% TEST TAB
Test_Tab = uitab(Tab_Group, 'Title', 'Test Mode');

uilabel(Test_Tab, 'Text', 'Test Mode - Unlock New Levels [TEST: 2s clips]', ...
    'Position', [20, 610, 400, 30], 'FontSize', 18, 'FontWeight', 'bold');

% Boost section
Boost_Test_Panel = uipanel(Test_Tab, 'Position', [20, 350, 440, 250], ...
    'Title', 'Boost Tests', 'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.941, 0.973, 1.0], 'ForegroundColor', [0, 0.2, 0.4]);  % Light blue bg, dark blue title

uilabel(Boost_Test_Panel, 'Text', 'Complete 10 rounds at 80% accuracy to unlock next level', ...
    'Position', [15, 205, 410, 20], 'FontSize', 9, 'FontColor', [0.3, 0.3, 0.3]);

Boost_Test_Btns = cell(1, 7);
for i = 1:7
    row = floor((i-1)/2);
    col = mod(i-1, 2);
    
    Boost_Test_Btns{i} = uibutton(Boost_Test_Panel, ...
        'Text', Boost_Labels{i}, ...
        'Position', [15 + col*210, 150 - row*50, 200, 45], ...
        'FontSize', 13, 'Enable', 'off', ...
        'ButtonPushedFcn', @(src, evt) startTest(Main_Fig, 'Boost', i, Boost_Levels, Cut_Levels, Boost_Labels, Cut_Labels, Freq_Labels, Target_Frequencies));
    
    if Boost_Unlocked(i)
        % Unlocked state: White background, dark blue text, bold
        Boost_Test_Btns{i}.Enable = 'on';
        Boost_Test_Btns{i}.BackgroundColor = [1.0, 1.0, 1.0];  % White
        Boost_Test_Btns{i}.FontColor = [0, 0.2, 0.4];  % Dark blue
        Boost_Test_Btns{i}.FontWeight = 'bold';
    else
        % Locked state: Light gray background, medium gray text, normal weight
        Boost_Test_Btns{i}.BackgroundColor = [0.91, 0.91, 0.91];  % Light gray
        Boost_Test_Btns{i}.FontColor = [0.53, 0.53, 0.53];  % Medium gray
        Boost_Test_Btns{i}.FontWeight = 'normal';
    end
end

% Cut section
Cut_Test_Panel = uipanel(Test_Tab, 'Position', [480, 350, 440, 250], ...
    'Title', 'Cut Tests', 'FontSize', 13, 'FontWeight', 'bold', ...
    'BackgroundColor', [1.0, 0.941, 0.961], 'ForegroundColor', [0.4, 0, 0]);  % Light pink bg, dark red title

uilabel(Cut_Test_Panel, 'Text', 'Complete 10 rounds at 80% accuracy to unlock next level', ...
    'Position', [15, 205, 410, 20], 'FontSize', 9, 'FontColor', [0.3, 0.3, 0.3]);

Cut_Test_Btns = cell(1, 7);
for i = 1:7
    row = floor((i-1)/2);
    col = mod(i-1, 2);
    
    Cut_Test_Btns{i} = uibutton(Cut_Test_Panel, ...
        'Text', Cut_Labels{i}, ...
        'Position', [15 + col*210, 150 - row*50, 200, 45], ...
        'FontSize', 13, 'Enable', 'off', ...
        'ButtonPushedFcn', @(src, evt) startTest(Main_Fig, 'Cut', i, Boost_Levels, Cut_Levels, Boost_Labels, Cut_Labels, Freq_Labels, Target_Frequencies));
    
    if Cut_Unlocked(i)
        % Unlocked state: White background, dark red text, bold
        Cut_Test_Btns{i}.Enable = 'on';
        Cut_Test_Btns{i}.BackgroundColor = [1.0, 1.0, 1.0];  % White
        Cut_Test_Btns{i}.FontColor = [0.4, 0, 0];  % Dark red
        Cut_Test_Btns{i}.FontWeight = 'bold';
    else
        % Locked state: Light gray background, medium gray text, normal weight
        Cut_Test_Btns{i}.BackgroundColor = [0.91, 0.91, 0.91];  % Light gray
        Cut_Test_Btns{i}.FontColor = [0.53, 0.53, 0.53];  % Medium gray
        Cut_Test_Btns{i}.FontWeight = 'normal';
    end
end

% Test controls
Test_Control_Panel = uipanel(Test_Tab, 'Position', [20, 80, 900, 260], ...
    'Title', 'Test Controls', 'FontSize', 12, 'FontWeight', 'bold');

Test_Status_Label = uilabel(Test_Control_Panel, 'Text', 'Select a test level above to begin', ...
    'Position', [20, 210, 860, 25], 'FontSize', 12, 'HorizontalAlignment', 'center');

Test_Progress_Label = uilabel(Test_Control_Panel, 'Text', '', ...
    'Position', [20, 185, 860, 20], 'FontSize', 10, ...
    'HorizontalAlignment', 'center', 'FontColor', [0.4, 0.4, 0.4]);

Test_Freq_Btns = cell(1, 8);
for i = 1:4
    Test_Freq_Btns{i} = uibutton(Test_Control_Panel, 'Text', Freq_Labels{i}, ...
        'Position', [20 + (i-1)*210, 100, 200, 50], 'FontSize', 12, ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @(src, evt) submitTestGuess(Main_Fig, i, Boost_Levels, Cut_Levels, Boost_Labels, Cut_Labels, Freq_Labels, Target_Frequencies));
end

for i = 5:8
    Test_Freq_Btns{i} = uibutton(Test_Control_Panel, 'Text', Freq_Labels{i}, ...
        'Position', [20 + (i-5)*210, 35, 200, 50], 'FontSize', 12, ...
        'Enable', 'off', ...
        'ButtonPushedFcn', @(src, evt) submitTestGuess(Main_Fig, i, Boost_Levels, Cut_Levels, Boost_Labels, Cut_Labels, Freq_Labels, Target_Frequencies));
end

Test_Feedback_Label = uilabel(Test_Control_Panel, 'Text', '', ...
    'Position', [20, 5, 860, 25], 'FontSize', 11, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');

% RESULTS TAB
Results_Tab = uitab(Tab_Group, 'Title', 'Results');

uilabel(Results_Tab, 'Text', 'Session Results', ...
    'Position', [20, 610, 300, 30], 'FontSize', 18, 'FontWeight', 'bold');

Results_Ax = uiaxes(Results_Tab, 'Position', [50, 200, 850, 380]);
title(Results_Ax, 'Correct Answers per Frequency (Practice Sessions)');
xlabel(Results_Ax, 'Frequency');
ylabel(Results_Ax, 'Correct (%)');
ylim(Results_Ax, [0, 110]);
grid(Results_Ax, 'on');

Sessions_Label = uilabel(Results_Tab, 'Text', 'No data yet - complete a practice session to see results', ...
    'Position', [50, 160, 850, 25], 'FontSize', 11, ...
    'HorizontalAlignment', 'center', 'FontColor', [0.4, 0.4, 0.4]);

Export_Btn = uibutton(Results_Tab, 'Text', 'Export Results to CSV', ...
    'Position', [380, 100, 180, 40], 'FontSize', 12, ...
    'ButtonPushedFcn', @(src, evt) exportResults(Main_Fig));

% Store all handles
App.H.Main_Fig = Main_Fig;
App.H.Tab_Group = Tab_Group;
App.H.Practice_Tab = Practice_Tab;
App.H.Test_Tab = Test_Tab;
App.H.Results_Tab = Results_Tab;
App.H.Boost_Radio = Boost_Radio;
App.H.Cut_Radio = Cut_Radio;
App.H.Level_Btns = Level_Btns;
App.H.Begin_Btn = Begin_Btn;
App.H.Finish_Btn = Finish_Btn;
App.H.Status_Label = Status_Label;
App.H.Score_Label = Score_Label;
App.H.Freq_Btns = Freq_Btns;
App.H.Feedback_Label = Feedback_Label;
App.H.Boost_Test_Btns = Boost_Test_Btns;
App.H.Cut_Test_Btns = Cut_Test_Btns;
App.H.Test_Status_Label = Test_Status_Label;
App.H.Test_Progress_Label = Test_Progress_Label;
App.H.Test_Freq_Btns = Test_Freq_Btns;
App.H.Test_Feedback_Label = Test_Feedback_Label;
App.H.Results_Ax = Results_Ax;
App.H.Sessions_Label = Sessions_Label;

Main_Fig.UserData = App;
applyTrainingLightTheme(Main_Fig);
Mode_Group.SelectionChangedFcn = @(src, evt) refreshPracticeLevelButtons(Main_Fig);
refreshPracticeLevelButtons(Main_Fig);

% CALLBACK FUNCTIONS

function beginRound(Fig, Boost_Levels, Cut_Levels, Freq_Labels, Target_Frequencies)
    App = Fig.UserData;
    
    if App.Answered && App.Session_Active
        App.Answered = false;
        App.H.Feedback_Label.Text = '';
        Fig.UserData = App;
        playNextRound(Fig, Boost_Levels, Cut_Levels, Freq_Labels, Target_Frequencies);
        return;
    end
    
    App.Session_Active = true;
    App.Round = App.Round + 1;
    
    % Get selected mode and level
    Practice_Level_Idx = 0;
    if App.H.Boost_Radio.Value
        App.Practice_Mode = 'Boost';
        Practice_Gain = 0;
        for i = 1:7
            if App.H.Level_Btns{i}.Value
                Practice_Gain = Boost_Levels(i);
                Practice_Level_Idx = i;
                break;
            end
        end
        Unlocked_Levels = App.T.Boost_Unlocked;
    else
        App.Practice_Mode = 'Cut';
        Practice_Gain = 0;
        for i = 1:7
            if App.H.Level_Btns{i}.Value
                Practice_Gain = Cut_Levels(i);
                Practice_Level_Idx = i;
                break;
            end
        end
        Unlocked_Levels = App.T.Cut_Unlocked;
    end
    
    if Practice_Level_Idx == 0 || ~Unlocked_Levels(Practice_Level_Idx)
        App.H.Status_Label.Text = 'That practice level is locked. Pass its test sequence to unlock it.';
        App.H.Begin_Btn.Enable = 'on';
        Fig.UserData = App;
        refreshPracticeLevelButtons(Fig);
        return;
    end
    
    App.Practice_Gain_dB = Practice_Gain;
    App.Practice_Level_Index = Practice_Level_Idx;
    
    App.H.Status_Label.Text = 'Playing audio...';
    App.H.Begin_Btn.Enable = 'off';
    App.H.Finish_Btn.Enable = 'off';
    
    for b = 1:numel(App.H.Freq_Btns)
        App.H.Freq_Btns{b}.Enable = 'off';
    end
    
    Fig.UserData = App;
    drawnow;
    
    try
        [audio_signal, audio_Fs, Selected_Genre, App] = loadRandomTrack(App);
        App.Current_Genre = Selected_Genre;
        Correct_Idx = randi(8);
        
        App.eq = multibandParametricEQ('NumEQBands', numel(Target_Frequencies), ...
            'Frequencies', Target_Frequencies, ...
            'QualityFactors', repmat(App.Q_FACTOR, 1, numel(Target_Frequencies)), ...
            'PeakGains', zeros(1, numel(Target_Frequencies)), ...
            'SampleRate', audio_Fs);
        
        if strcmp(App.Practice_Mode, 'Boost')
            Signed_Gain = abs(App.Practice_Gain_dB);
        else
            Signed_Gain = -abs(App.Practice_Gain_dB);
        end
        
        % Apply compensation percentage
        Round_Gains = App.Baseline_Audiogram .* App.Audiogram_Gain_Percentage;
        Round_Gains(Correct_Idx) = Round_Gains(Correct_Idx) + Signed_Gain;
        App.Active_Compensation = Round_Gains;
        
        App.eq.PeakGains = Round_Gains;
        App.Correct_Idx = Correct_Idx;
        App.Freq_Log = [App.Freq_Log, Correct_Idx];
        Fig.UserData = App;
        
        n_play = min(length(audio_signal), App.noise_duration * audio_Fs);
        filtered_signal = App.eq(audio_signal(1:n_play));
        release(App.eq);
        filtered_signal = ATS_applySafetyLimiter(filtered_signal, 0.95);
        
        % Clear any previous audio
        clear sound;
        
        % Play audio
        sound(filtered_signal, audio_Fs);
        
        % Wait for audio to finish
        pause(length(filtered_signal) / audio_Fs + 0.1);
        
        % Clear audio player
        clear sound;
    catch ME
        % Error during audio processing
        fprintf('Error in beginRound: %s\n', ME.message);
        App.H.Status_Label.Text = 'Error playing audio - click Next Round to try again';
        App.H.Begin_Btn.Enable = 'on';
        Fig.UserData = App;
        return;
    end
    
    % Re-fetch UserData
    App = Fig.UserData;
    
    % Enable all frequency buttons
    for b = 1:numel(App.H.Freq_Btns)
        App.H.Freq_Btns{b}.Enable = 'on';
    end
    
    App.H.Status_Label.Text = 'Select the frequency that was boosted/cut:';
    
    % Save and force update
    Fig.UserData = App;
    drawnow;
end

function playNextRound(Fig, Boost_Levels, Cut_Levels, Freq_Labels, Target_Frequencies)
    beginRound(Fig, Boost_Levels, Cut_Levels, Freq_Labels, Target_Frequencies);
end

function submitGuess(Fig, Guess_Idx, Freq_Labels)
    App = Fig.UserData;
    
    if App.Answered
        return;
    end
    
    App.Answered = true;
    App.Trial_Number = App.Trial_Number + 1;
    
    for b = 1:numel(App.H.Freq_Btns)
        App.H.Freq_Btns{b}.Enable = 'off';
    end
    
    if Guess_Idx == App.Correct_Idx
        App.Num_Correct = App.Num_Correct + 1;
        App.Result_Log = [App.Result_Log, 1];
        Result_Str = 'Correct';
        App.H.Feedback_Label.Text = sprintf('Correct! The frequency was %s.', Freq_Labels{App.Correct_Idx});
        App.H.Feedback_Label.FontColor = [0.1, 0.6, 0.1];
    else
        App.Result_Log = [App.Result_Log, 0];
        Result_Str = 'Incorrect';
        App.H.Feedback_Label.Text = sprintf('Incorrect. It was %s, not %s.', Freq_Labels{App.Correct_Idx}, Freq_Labels{Guess_Idx});
        App.H.Feedback_Label.FontColor = [0.8, 0.1, 0.1];
    end
    
    Mode_Str = sprintf('Practice %s %+d dB', App.Practice_Mode, App.Practice_Gain_dB);
    New_Row = {App.Trial_Number, string(Freq_Labels{App.Correct_Idx}), string(App.Current_Genre), string(Mode_Str), string(Result_Str)};
    App.Export_Log = [App.Export_Log; New_Row];
    App.H.Score_Label.Text = sprintf('Session score so far: %d / %d', App.Num_Correct, App.Round);
    App.H.Begin_Btn.Text = 'Next Round';
    App.H.Begin_Btn.Enable = 'on';
    App.H.Finish_Btn.Enable = 'on';
    App.H.Status_Label.Text = 'Press Next Round to continue or Finish to end the session.';
    Fig.UserData = App;
end

function finishSession(Fig, Tab_Group, Results_Tab, Freq_Labels)
    App = Fig.UserData;
    
    for r = 1:numel(App.Freq_Log)
        f = App.Freq_Log(r);
        App.Cumulative_Total(f) = App.Cumulative_Total(f) + 1;
        App.Cumulative_Correct(f) = App.Cumulative_Correct(f) + App.Result_Log(r);
    end
    
    App.H.Sessions_Label.Text = sprintf('Frequencies attempted across all sessions. Total rounds: %d', sum(App.Cumulative_Total));
    cla(App.H.Results_Ax);
    Bar_Colors = zeros(numel(Freq_Labels), 3);
    
    for f = 1:numel(Freq_Labels)
        if App.Cumulative_Total(f) == 0
            Bar_Colors(f, :) = [0.7, 0.7, 0.7];
        elseif App.Cumulative_Correct(f) / App.Cumulative_Total(f) >= 0.7
            Bar_Colors(f, :) = [0.2, 0.7, 0.3];
        else
            Bar_Colors(f, :) = [0.85, 0.2, 0.2];
        end
    end
    
    Pct_Data = zeros(1, numel(Freq_Labels));
    for f = 1:numel(Freq_Labels)
        if App.Cumulative_Total(f) > 0
            Pct_Data(f) = 100 * App.Cumulative_Correct(f) / App.Cumulative_Total(f);
        end
    end
    
    bar(App.H.Results_Ax, 1:numel(Freq_Labels), Pct_Data, 'FaceColor', 'flat', 'CData', Bar_Colors);
    App.H.Results_Ax.XTick = 1:numel(Freq_Labels);
    App.H.Results_Ax.XTickLabel = Freq_Labels;
    App.H.Results_Ax.XTickLabelRotation = 20;
    App.H.Results_Ax.YLabel.String = 'Correct (%)';
    ylim(App.H.Results_Ax, [0, 110]);
    title(App.H.Results_Ax, 'Correct Answers per Frequency (Practice Sessions)');
    grid(App.H.Results_Ax, 'on');
    
    for f = 1:numel(Freq_Labels)
        if App.Cumulative_Total(f) > 0
            text(App.H.Results_Ax, f, Pct_Data(f) + 2, sprintf('%.0f%%', Pct_Data(f)), ...
                'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
        end
    end
    
    App.Round = 0;
    App.Num_Correct = 0;
    App.Result_Log = [];
    App.Freq_Log = [];
    App.Correct_Idx = 0;
    App.Answered = false;
    App.Session_Active = false;
    
    App.H.Begin_Btn.Text = 'Begin Round';
    App.H.Begin_Btn.Enable = 'on';
    App.H.Finish_Btn.Enable = 'off';
    App.H.Status_Label.Text = 'Session finished. View Results tab.';
    App.H.Score_Label.Text = '';
    App.H.Feedback_Label.Text = '';
    
    Tab_Group.SelectedTab = App.H.Results_Tab;
    
    Fig.UserData = App;
end

function startTest(Fig, Mode, Level_Idx, Boost_Levels, Cut_Levels, Boost_Labels, Cut_Labels, Freq_Labels, Target_Frequencies)
    App = Fig.UserData;
    
    App.T.Mode = Mode;
    App.T.Active_Level = Level_Idx;
    App.T.Round = 0;
    App.T.Num_Correct = 0;
    App.T.Answered = false;
    
    if strcmp(Mode, 'Boost')
        level_val = Boost_Levels(Level_Idx);
        App.H.Test_Status_Label.Text = sprintf('Test Mode: Boost %+d dB', level_val);
    else
        level_val = Cut_Levels(Level_Idx);
        App.H.Test_Status_Label.Text = sprintf('Test Mode: Cut %d dB', level_val);
    end
    
    App.H.Test_Progress_Label.Text = sprintf('Round 0 / %d', App.Test_Rounds_Required);
    
    % Disable all test buttons and reset appearance
    for i = 1:7
        App.H.Boost_Test_Btns{i}.Enable = 'off';
        App.H.Cut_Test_Btns{i}.Enable = 'off';
        % Reset to default unlocked/locked state colors
        if App.T.Boost_Unlocked(i)
            App.H.Boost_Test_Btns{i}.BackgroundColor = [1.0, 1.0, 1.0];  % White
            App.H.Boost_Test_Btns{i}.FontColor = [0, 0.2, 0.4];  % Dark blue 
            App.H.Boost_Test_Btns{i}.FontWeight = 'bold';
        else
            App.H.Boost_Test_Btns{i}.BackgroundColor = [0.91, 0.91, 0.91];  % Light gray
            App.H.Boost_Test_Btns{i}.FontColor = [0.53, 0.53, 0.53];  % Medium gray
            App.H.Boost_Test_Btns{i}.FontWeight = 'normal';
        end
        if App.T.Cut_Unlocked(i)
            App.H.Cut_Test_Btns{i}.BackgroundColor = [1.0, 1.0, 1.0];  % White
            App.H.Cut_Test_Btns{i}.FontColor = [0.4, 0, 0];  % Dark red 
            App.H.Cut_Test_Btns{i}.FontWeight = 'bold';
        else
            App.H.Cut_Test_Btns{i}.BackgroundColor = [0.91, 0.91, 0.91];  % Light gray
            App.H.Cut_Test_Btns{i}.FontColor = [0.53, 0.53, 0.53];  % Medium gray
            App.H.Cut_Test_Btns{i}.FontWeight = 'normal';
        end
    end
    
    % Highlight the active test button with high-contrast
    if strcmp(Mode, 'Boost')
        App.H.Boost_Test_Btns{Level_Idx}.BackgroundColor = [0, 0.4, 0.8];  % blue
        App.H.Boost_Test_Btns{Level_Idx}.FontColor = [1.0, 1.0, 1.0];  % White text 
        App.H.Boost_Test_Btns{Level_Idx}.FontWeight = 'bold';
    else
        App.H.Cut_Test_Btns{Level_Idx}.BackgroundColor = [0.8, 0, 0];  % red
        App.H.Cut_Test_Btns{Level_Idx}.FontColor = [1.0, 1.0, 1.0];  % White text 
        App.H.Cut_Test_Btns{Level_Idx}.FontWeight = 'bold';
    end
    
    Fig.UserData = App;
    
    pause(0.5);
    beginTestRound(Fig, Boost_Levels, Cut_Levels, Boost_Labels, Cut_Labels, Freq_Labels, Target_Frequencies);
end

function beginTestRound(Fig, Boost_Levels, Cut_Levels, Boost_Labels, Cut_Labels, Freq_Labels, Target_Frequencies)
    App = Fig.UserData;
    
    if App.T.Round >= App.Test_Rounds_Required
        evaluateTest(Fig, Boost_Levels, Cut_Levels);
        return;
    end
    
    App.T.Round = App.T.Round + 1;
    App.T.Answered = false;
    
    App.H.Test_Progress_Label.Text = sprintf('Round %d / %d', App.T.Round, App.Test_Rounds_Required);
    App.H.Test_Status_Label.Text = 'Playing audio...';
    
    for b = 1:numel(App.H.Test_Freq_Btns)
        App.H.Test_Freq_Btns{b}.Enable = 'off';
    end
    
    App.H.Test_Feedback_Label.Text = '';
    
    Fig.UserData = App;
    drawnow;
    
    try
        [audio_signal, audio_Fs, Selected_Genre, App] = loadRandomTrack(App);
        App.T.Current_Genre = Selected_Genre;
        Correct_Idx = randi(8);
        
        if strcmp(App.T.Mode, 'Boost')
            Active_Gain = Boost_Levels(App.T.Active_Level);
        else
            Active_Gain = Cut_Levels(App.T.Active_Level);
        end
        
        App.eq = multibandParametricEQ('NumEQBands', numel(Target_Frequencies), ...
            'Frequencies', Target_Frequencies, ...
            'QualityFactors', repmat(App.Q_FACTOR, 1, numel(Target_Frequencies)), ...
            'PeakGains', zeros(1, numel(Target_Frequencies)), ...
            'SampleRate', audio_Fs);
        
        % Apply compensation percentage
        Round_Gains = App.Baseline_Audiogram .* App.Audiogram_Gain_Percentage;
        Round_Gains(Correct_Idx) = Round_Gains(Correct_Idx) + Active_Gain;
        App.Active_Compensation = Round_Gains;
        
        App.eq.PeakGains = Round_Gains;
        App.T.Correct_Idx = Correct_Idx;
        Fig.UserData = App;
        
        n_play = min(length(audio_signal), App.noise_duration * audio_Fs);
        filtered_signal = App.eq(audio_signal(1:n_play));
        release(App.eq);
        filtered_signal = ATS_applySafetyLimiter(filtered_signal, 0.95);
        
        clear sound;
        sound(filtered_signal, audio_Fs);
        pause(length(filtered_signal) / audio_Fs + 0.1);
        clear sound;
    catch ME
        fprintf('Error in beginTestRound: %s\n', ME.message);
        App = Fig.UserData;
        App.T.Round = max(0, App.T.Round - 1);
        App.H.Test_Status_Label.Text = 'Error playing audio - select a test level to retry';
        App.H.Test_Feedback_Label.Text = ME.message;
        App.H.Test_Feedback_Label.FontColor = [0.8, 0.1, 0.1];
        for b = 1:numel(App.H.Test_Freq_Btns)
            App.H.Test_Freq_Btns{b}.Enable = 'off';
        end
        Fig.UserData = App;
        refreshTestLevelButtons(Fig);
        return;
    end
    
    % Re-fetch UserData
    App = Fig.UserData;
    
    % Enable all test frequency buttons
    for b = 1:numel(App.H.Test_Freq_Btns)
        App.H.Test_Freq_Btns{b}.Enable = 'on';
    end
    
    App.H.Test_Status_Label.Text = 'Select the frequency:';
    
    % Save and force update
    Fig.UserData = App;
    drawnow;
end

function submitTestGuess(Fig, Guess_Idx, Boost_Levels, Cut_Levels, Boost_Labels, Cut_Labels, Freq_Labels, Target_Frequencies)
    App = Fig.UserData;
    
    if App.T.Answered
        return;
    end
    
    App.T.Answered = true;
    
    for b = 1:numel(App.H.Test_Freq_Btns)
        App.H.Test_Freq_Btns{b}.Enable = 'off';
    end
    
    if Guess_Idx == App.T.Correct_Idx
        App.T.Num_Correct = App.T.Num_Correct + 1;
        App.H.Test_Feedback_Label.Text = sprintf('Correct! (%d / %d)', App.T.Num_Correct, App.T.Round);
        App.H.Test_Feedback_Label.FontColor = [0.1, 0.6, 0.1];
    else
        App.H.Test_Feedback_Label.Text = sprintf('Incorrect. It was %s. (%d / %d)', Freq_Labels{App.T.Correct_Idx}, App.T.Num_Correct, App.T.Round);
        App.H.Test_Feedback_Label.FontColor = [0.8, 0.1, 0.1];
    end
    
    Fig.UserData = App;
    pause(1);
    
    beginTestRound(Fig, Boost_Levels, Cut_Levels, Boost_Labels, Cut_Labels, Freq_Labels, Target_Frequencies);
end

function evaluateTest(Fig, Boost_Levels, Cut_Levels)
    App = Fig.UserData;
    
    accuracy = App.T.Num_Correct / App.Test_Rounds_Required;
    passed = accuracy >= App.Test_Pass_Threshold;
    
    if strcmp(App.T.Mode, 'Boost')
        level_val = Boost_Levels(App.T.Active_Level);
        mode_str = 'Boost';
    else
        level_val = Cut_Levels(App.T.Active_Level);
        mode_str = 'Cut';
    end
    
    if passed
        msg = sprintf('Test Passed!\n\n%s %+d dB\nScore: %d / %d (%.0f%%)\n\n', ...
            mode_str, level_val, App.T.Num_Correct, App.Test_Rounds_Required, accuracy * 100);
        
        % Unlock the next lower-dB level (for example: 12 -> 9 -> 6 -> 3).
        if App.T.Active_Level < numel(Boost_Levels)
            next_idx = App.T.Active_Level + 1;
            
            if strcmp(App.T.Mode, 'Boost')
                if ~App.T.Boost_Unlocked(next_idx)
                    App.T.Boost_Unlocked(next_idx) = true;
                    App.H.Boost_Test_Btns{next_idx}.Enable = 'on';
                    App.H.Boost_Test_Btns{next_idx}.BackgroundColor = [0.9, 1.0, 0.9];
                    next_val = Boost_Levels(next_idx);
                    msg = [msg sprintf('Unlocked: %+d dB boost!', next_val)];
                end
            else
                if ~App.T.Cut_Unlocked(next_idx)
                    App.T.Cut_Unlocked(next_idx) = true;
                    App.H.Cut_Test_Btns{next_idx}.Enable = 'on';
                    App.H.Cut_Test_Btns{next_idx}.BackgroundColor = [1.0, 0.9, 0.9];
                    next_val = Cut_Levels(next_idx);
                    msg = [msg sprintf('Unlocked: %d dB cut!', next_val)];
                end
            end
        else
            msg = [msg 'All levels unlocked!'];
        end
        
        uialert(Fig, msg, 'Test Passed', 'Icon', 'success');
    else
        msg = sprintf('Test Failed\n\n%s %+d dB\nScore: %d / %d (%.0f%%)\nNeed: %.0f%%\n\nKeep practicing!', ...
            mode_str, level_val, App.T.Num_Correct, App.Test_Rounds_Required, accuracy * 100, App.Test_Pass_Threshold * 100);
        
        uialert(Fig, msg, 'Test Failed', 'Icon', 'warning');
    end
    
    App.H.Test_Status_Label.Text = 'Select a test level to begin';
    App.H.Test_Progress_Label.Text = '';
    App.H.Test_Feedback_Label.Text = '';
    
    Fig.UserData = App;
    refreshTestLevelButtons(Fig);
    refreshPracticeLevelButtons(Fig);
    App = Fig.UserData;
    saveTrainingSessionState(App);
    drawnow;  % Force UI update
end

function exportResults(Fig)
    App = Fig.UserData;
    
    if height(App.Export_Log) == 0
        uialert(Fig, 'No data to export yet. Complete some practice rounds first.', 'No Data');
        return;
    end
    
    [file, path] = uiputfile('*.csv', 'Save Results As', sprintf('%s_results.csv', App.User_Name));
    
    if file ~= 0
        writetable(App.Export_Log, fullfile(path, file));
        uialert(Fig, sprintf('Results exported to:\n%s', fullfile(path, file)), 'Export Successful');
    end
end

function [audio_signal, audio_Fs, Selected_Genre, App] = loadRandomTrack(App)
    track_idx = randi(length(App.Audio_Files));
    Selected_Genre = App.Genre_Labels{track_idx};
    
    try
        [audio_signal, audio_Fs] = audioread(App.Audio_Files{track_idx});
        if size(audio_signal, 2) > 1
            audio_signal = mean(audio_signal, 2);
        end
    catch
        audio_signal = randn(App.Fs * App.noise_duration, 1);
        audio_Fs = App.Fs;
        Selected_Genre = 'White Noise (file not found)';
    end
end

function updateCompensationLevel(Fig, new_percentage)
    
    App = Fig.UserData;
    
    new_percentage = max(0.0, min(1.0, new_percentage));
    old_percentage = App.Audiogram_Gain_Percentage;
    
    App.Audiogram_Gain_Percentage = new_percentage;
    App.Active_Compensation = App.Baseline_Audiogram .* new_percentage;
    
    assignin('base', 'Audiogram_Gain_Percentage', new_percentage);
    assignin('base', 'Active_Compensation', App.Active_Compensation);
    saveTrainingSessionState(App);
    
    fprintf('\n========================================\n');
    fprintf('COMPENSATION LEVEL UPDATED\n');
    fprintf('========================================\n');
    fprintf('Previous: %.0f%%\n', old_percentage * 100);
    fprintf('New:      %.0f%%\n', new_percentage * 100);
    fprintf('Change:   %+.0f%%\n', (new_percentage - old_percentage) * 100);
    fprintf('\nUpdated Gains:\n');
    freqs = [125, 250, 500, 1000, 2500, 4000, 8000, 16000];
    for k = 1:8
        fprintf('  %d Hz: %.1f dB (was %.1f dB)\n', ...
            freqs(k), App.Active_Compensation(k), ...
            App.Baseline_Audiogram(k) * old_percentage);
    end
    fprintf('========================================\n\n');
    
    if new_percentage < old_percentage
        if new_percentage == 0
            msg = sprintf('Compensation Reduced to 0%%!\n\nYou are now training with NO compensation!\nRelying entirely on natural ability.\nIncredible achievement!');
            title_str = 'Achievement Unlocked!';
        elseif new_percentage <= 0.25
            msg = sprintf('Compensation: %.0f%% to %.0f%%\n\nAmazing! Training with minimal help.\nDiscrimination greatly improved!', old_percentage*100, new_percentage*100);
            title_str = 'Amazing Progress!';
        elseif new_percentage <= 0.50
            msg = sprintf('Compensation: %.0f%% to %.0f%%\n\nHalfway there! Great work!', old_percentage*100, new_percentage*100);
            title_str = 'Great Progress!';
        else
            msg = sprintf('Compensation: %.0f%% to %.0f%%\n\nGood progress! Keep it up!', old_percentage*100, new_percentage*100);
            title_str = 'Compensation Reduced';
        end
        uialert(Fig, msg, title_str, 'Icon', 'success');
    elseif new_percentage > old_percentage
        msg = sprintf('Compensation: %.0f%% to %.0f%%\n\nAdjusted to help you succeed.\nProgress is not always linear!', old_percentage*100, new_percentage*100);
        uialert(Fig, msg, 'Compensation Adjusted', 'Icon', 'info');
    end
    
    Fig.UserData = App;
end

function refreshPracticeLevelButtons(Fig)
    App = Fig.UserData;
    unlocked_color = [0.1, 0.1, 0.1];
    locked_color = [0.50, 0.50, 0.50];
    
    if App.H.Boost_Radio.Value
        Unlocked_Levels = App.T.Boost_Unlocked;
    else
        Unlocked_Levels = App.T.Cut_Unlocked;
    end
    
    selected_idx = 0;
    for i = 1:numel(App.H.Level_Btns)
        if App.H.Level_Btns{i}.Value
            selected_idx = i;
        end
    end
    
    for i = 1:numel(App.H.Level_Btns)
        if Unlocked_Levels(i)
            App.H.Level_Btns{i}.Enable = 'on';
            App.H.Level_Btns{i}.FontColor = unlocked_color;
        else
            App.H.Level_Btns{i}.Enable = 'off';
            App.H.Level_Btns{i}.FontColor = locked_color;
            App.H.Level_Btns{i}.Value = false;
        end
    end
    
    if selected_idx == 0 || ~Unlocked_Levels(selected_idx)
        first_unlocked = find(Unlocked_Levels, 1, 'first');
        if ~isempty(first_unlocked)
            App.H.Level_Btns{first_unlocked}.Value = true;
        end
    end
    
    Fig.UserData = App;
    drawnow;
end

function refreshTestLevelButtons(Fig)
    App = Fig.UserData;
    
    for i = 1:7
        if App.T.Boost_Unlocked(i)
            App.H.Boost_Test_Btns{i}.Enable = 'on';
            App.H.Boost_Test_Btns{i}.BackgroundColor = [1.0, 1.0, 1.0];
            App.H.Boost_Test_Btns{i}.FontColor = [0, 0.2, 0.4];
            App.H.Boost_Test_Btns{i}.FontWeight = 'bold';
        else
            App.H.Boost_Test_Btns{i}.Enable = 'off';
            App.H.Boost_Test_Btns{i}.BackgroundColor = [0.91, 0.91, 0.91];
            App.H.Boost_Test_Btns{i}.FontColor = [0.53, 0.53, 0.53];
            App.H.Boost_Test_Btns{i}.FontWeight = 'normal';
        end
        
        if App.T.Cut_Unlocked(i)
            App.H.Cut_Test_Btns{i}.Enable = 'on';
            App.H.Cut_Test_Btns{i}.BackgroundColor = [1.0, 1.0, 1.0];
            App.H.Cut_Test_Btns{i}.FontColor = [0.4, 0, 0];
            App.H.Cut_Test_Btns{i}.FontWeight = 'bold';
        else
            App.H.Cut_Test_Btns{i}.Enable = 'off';
            App.H.Cut_Test_Btns{i}.BackgroundColor = [0.91, 0.91, 0.91];
            App.H.Cut_Test_Btns{i}.FontColor = [0.53, 0.53, 0.53];
            App.H.Cut_Test_Btns{i}.FontWeight = 'normal';
        end
    end
    
    Fig.UserData = App;
    drawnow;
end

function saveTrainingSessionState(App)
    session_data = App.Session_Data;
    session_data.User_Name = App.User_Name;
    session_data.User_Group = App.User_Group;
    session_data.Calibration_Boost_Level = App.Calibration_Boost_Level;
    session_data.Calibration_Complete = true;
    session_data.Baseline_Audiogram = App.Baseline_Audiogram;
    session_data.Audiogram_Gain_Percentage = App.Audiogram_Gain_Percentage;
    session_data.Boost_Unlocked = App.T.Boost_Unlocked;
    session_data.Cut_Unlocked = App.T.Cut_Unlocked;
    ATS_saveSessionData(session_data);
end

function applyTrainingLightTheme(Fig)

    bg = [0.96, 0.96, 0.96];
    panel_bg = [0.98, 0.98, 0.98];
    text = [0.10, 0.10, 0.10];
    muted = [0.25, 0.25, 0.25];
    border = [0.70, 0.70, 0.70];
    
    App = Fig.UserData;
    Fig.Color = bg;
    
    light_surfaces = [App.H.Practice_Tab, App.H.Test_Tab, App.H.Results_Tab];
    for i = 1:numel(light_surfaces)
        if isprop(light_surfaces(i), 'BackgroundColor')
            light_surfaces(i).BackgroundColor = bg;
        end
    end
    
    panels = findall(Fig, 'Type', 'uipanel');
    for i = 1:numel(panels)
        panels(i).BackgroundColor = panel_bg;
        panels(i).ForegroundColor = text;
        panels(i).HighlightColor = border;
    end
    
    button_groups = findall(Fig, 'Type', 'uibuttongroup');
    for i = 1:numel(button_groups)
        button_groups(i).BackgroundColor = panel_bg;
        button_groups(i).ForegroundColor = text;
    end
    
    labels = findall(Fig, 'Type', 'uilabel');
    for i = 1:numel(labels)
        if isempty(labels(i).FontColor) || all(labels(i).FontColor == [0, 0, 0])
            labels(i).FontColor = text;
        elseif all(labels(i).FontColor == [0.4, 0.4, 0.4])
            labels(i).FontColor = muted;
        end
    end
    
    radios = [App.H.Boost_Radio, App.H.Cut_Radio, App.H.Level_Btns{:}];
    for i = 1:numel(radios)
        radios(i).FontColor = text;
        if isprop(radios(i), 'BackgroundColor')
            radios(i).BackgroundColor = panel_bg;
        end
    end
    
    passive_buttons = [App.H.Freq_Btns{:}, App.H.Test_Freq_Btns{:}, App.H.Finish_Btn, App.H.Begin_Btn];
    for i = 1:numel(passive_buttons)
        if strcmp(passive_buttons(i).Enable, 'off')
            passive_buttons(i).BackgroundColor = [0.92, 0.92, 0.92];
            passive_buttons(i).FontColor = [0.45, 0.45, 0.45];
        end
    end
    App.H.Begin_Btn.BackgroundColor = [0.14, 0.50, 0.22];
    App.H.Begin_Btn.FontColor = [1, 1, 1];
    
    App.H.Results_Ax.Color = [1, 1, 1];
    App.H.Results_Ax.XColor = text;
    App.H.Results_Ax.YColor = text;
    App.H.Results_Ax.GridColor = [0.80, 0.80, 0.80];
    
    Fig.UserData = App;
end
