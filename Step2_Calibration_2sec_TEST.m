% CalibrationTest.m

clear; clc; close all;

Session_Data = ATS_loadSessionData();

% Load user data from AudiogramTest
if ~exist('User_Name', 'var')
    if isfield(Session_Data, 'User_Name')
        User_Name = Session_Data.User_Name;
    else
        error('Please run AudiogramTest.m first');
    end
end

if ~exist('User_Group', 'var')
    if isfield(Session_Data, 'User_Group')
        User_Group = Session_Data.User_Group;
    else
        error('User group not defined. Run AudiogramTest.m first');
    end
end

if ~exist('Max_Audiogram_Value', 'var')
    if isfield(Session_Data, 'Max_Audiogram_Value')
        Max_Audiogram_Value = Session_Data.Max_Audiogram_Value;
    else
        Max_Audiogram_Value = 0;
    end
end

if ~exist('Audiogram_Data', 'var')
    if isfield(Session_Data, 'Audiogram_Data')
        Audiogram_Data = Session_Data.Audiogram_Data;
    elseif isfield(Session_Data, 'Audiogram')
        Audiogram_Data = Session_Data.Audiogram;
    else
        Audiogram_Data = [];
    end
end

% Constants
Q_FACTOR = sqrt(2);
Fs = 44100;
noise_duration = 2;  % TEST MODE: 2 seconds
Target_Frequencies = [125, 250, 500, 1000, 2500, 4000, 8000, 16000];
Freq_Labels = {'125 Hz', '250 Hz', '500 Hz', '1 kHz', '2.5 kHz', '4 kHz', '8 kHz', '16 kHz'};

Audio_Files{1} = 'C:\Users\Natha\OneDrive\Documents\MATLAB\Analog Circuits\3_24_26 Script\pop.wav';
Audio_Files{2} = 'C:\Users\Natha\OneDrive\Documents\MATLAB\Analog Circuits\3_24_26 Script\classical.wav';
Audio_Files{3} = 'C:\Users\Natha\OneDrive\Documents\MATLAB\Analog Circuits\3_24_26 Script\jazz.wav';
Audio_Files{4} = 'C:\Users\Natha\OneDrive\Documents\MATLAB\Analog Circuits\3_24_26 Script\classic_rock.wav';
Audio_Files{5} = 'C:\Users\Natha\OneDrive\Documents\MATLAB\Analog Circuits\3_24_26 Script\hip_hop.wav';
Audio_Files{6} = 'C:\Users\Natha\OneDrive\Documents\MATLAB\Analog Circuits\3_24_26 Script\folk.wav';
Audio_Files{7} = 'C:\Users\Natha\OneDrive\Documents\MATLAB\Analog Circuits\3_24_26 Script\classical_piano.wav';
Audio_Files{8} = 'C:\Users\Natha\OneDrive\Documents\MATLAB\Analog Circuits\3_24_26 Script\latin.wav';

% Calibration levels
Test_Boost_Levels = [12, 15, 18, 20];
CALIBRATION_TRIALS = 10;
PASS_THRESHOLD = 8;

% Audiogram processing
Audiogram_Frequencies = [125, 250, 500, 1000, 2000, 4000, 8000];
if ~isempty(Audiogram_Data)
    Baseline_Audiogram = interpGainFromAudiogram(Audiogram_Data, Audiogram_Frequencies, Target_Frequencies);
else
    Baseline_Audiogram = zeros(1, numel(Target_Frequencies));
end

% Initial audiogram gain
if strcmp(User_Group, 'Normal')
    Audiogram_Gain_Percentage = 0.0;
else
    Audiogram_Gain_Percentage = 1.0;
end

fprintf('\n========================================\n');
fprintf('CALIBRATION TEST - DEFENSIVE MODE\n');
fprintf('========================================\n');
fprintf('User: %s\n', User_Name);
fprintf('Group: %s\n', User_Group);
fprintf('Audiogram Gain: %.0f%%\n', Audiogram_Gain_Percentage * 100);
fprintf('========================================\n\n');

% Create UI
Fig_W = 700;
Fig_H = 550;
Main_Fig = uifigure('Name', sprintf('Calibration Test - %s [TEST MODE]', User_Name), ...
    'Position', [300, 150, Fig_W, Fig_H], 'Color', [0.94, 0.94, 0.94]);

% Title
uilabel(Main_Fig, 'Text', 'Initial Calibration Test', ...
    'Position', [50, 480, 600, 35], 'FontSize', 20, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'FontColor', [0.1, 0.1, 0.1]);  % Dark 

% Group info
uilabel(Main_Fig, 'Text', sprintf('Group: %s', User_Group), ...
    'Position', [50, 450, 300, 20], 'FontSize', 11, 'HorizontalAlignment', 'center', ...
    'FontColor', [0.25, 0.25, 0.25]);  % Dark gray 

% Audiogram compensation status - conditional based on group
if strcmp(User_Group, 'Normal')
    comp_msg = 'No audiogram compensation applied';
else
    comp_msg = 'Audiogram compensation will be applied';
end
uilabel(Main_Fig, 'Text', comp_msg, ...
    'Position', [350, 450, 300, 20], 'FontSize', 11, 'HorizontalAlignment', 'center', ...
    'FontColor', [0.25, 0.25, 0.25]);  % Dark gray 

% Instructions panel
Inst_Panel = uipanel(Main_Fig, 'Position', [50, 300, 600, 145], ...
    'Title', 'Instructions', 'FontSize', 11, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.85, 0.93, 1.0], ...  % Light blue background
    'ForegroundColor', [0.1, 0.1, 0.1]);  % Dark title

uilabel(Inst_Panel, 'Text', 'You will hear 10 audio clips.', ...
    'Position', [20, 95, 560, 18], 'FontSize', 10, ...
    'FontColor', [0.1, 0.1, 0.1]);  % Black text for contrast
uilabel(Inst_Panel, 'Text', 'Each clip has a frequency boost applied.', ...
    'Position', [20, 75, 560, 18], 'FontSize', 10, ...
    'FontColor', [0.1, 0.1, 0.1]);  % Black text for contrast
uilabel(Inst_Panel, 'Text', 'Click the button corresponding to the frequency you hear boosted.', ...
    'Position', [20, 50, 560, 18], 'FontSize', 10, ...
    'FontColor', [0.1, 0.1, 0.1]);  % Black text for contrast
uilabel(Inst_Panel, 'Text', 'This determines your starting training level.', ...
    'Position', [20, 30, 560, 18], 'FontSize', 10, ...
    'FontColor', [0.1, 0.1, 0.1]);  % Black text for contrast
uilabel(Inst_Panel, 'Text', 'Timing: This initial calibration test will take between 5-10 minutes to complete.', ...
    'Position', [20, 10, 560, 18], 'FontSize', 10, 'FontWeight', 'bold', ...
    'FontColor', [0.1, 0.1, 0.1]);  % Black text for contrast

% Progress labels
Progress_Label = uilabel(Main_Fig, 'Text', 'Ready to begin', ...
    'Position', [50, 265, 600, 25], 'FontSize', 12, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'FontColor', [0.3, 0.3, 0.3]);  % Dark gray 

Boost_Level_Label = uilabel(Main_Fig, 'Text', 'Current boost level: +12 dB', ...
    'Position', [50, 240, 600, 20], 'FontSize', 11, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'FontColor', [0.15, 0.15, 0.15]);

Score_Label = uilabel(Main_Fig, 'Text', '', ...
    'Position', [50, 215, 600, 20], 'FontSize', 10, ...
    'HorizontalAlignment', 'center', 'FontColor', [0.25, 0.25, 0.25]);  % Dark gray 

Status_Label = uilabel(Main_Fig, 'Text', '', ...
    'Position', [50, 190, 600, 20], 'FontSize', 11, ...
    'HorizontalAlignment', 'center', 'FontColor', [0.25, 0.25, 0.25]);  % Dark gray 

% Frequency buttons
Btn_W = 150;
Btn_H = 40;
Gap = 10;
Start_X = (Fig_W - 4*(Btn_W + Gap) + Gap) / 2;
Row1_Y = 140;
Row2_Y = 80;

Freq_Btns = cell(1, 8);
for i = 1:4
    Freq_Btns{i} = uibutton(Main_Fig, 'Text', Freq_Labels{i}, ...
        'Position', [Start_X + (i-1)*(Btn_W + Gap), Row1_Y, Btn_W, Btn_H], ...
        'FontSize', 11, 'Enable', 'off', ...
        'ButtonPushedFcn', @(src, evt) submitAnswer(Main_Fig, i));
end

for i = 5:8
    Freq_Btns{i} = uibutton(Main_Fig, 'Text', Freq_Labels{i}, ...
        'Position', [Start_X + (i-5)*(Btn_W + Gap), Row2_Y, Btn_W, Btn_H], ...
        'FontSize', 11, 'Enable', 'off', ...
        'ButtonPushedFcn', @(src, evt) submitAnswer(Main_Fig, i));
end

% Start button
Start_Btn = uibutton(Main_Fig, 'Text', 'Start Calibration Test', ...
    'Position', [250, 15, 200, 50], 'FontSize', 14, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.14, 0.50, 0.22], 'FontColor', [1, 1, 1], ...
    'ButtonPushedFcn', @(src, evt) startCalibration(Main_Fig));

% Store data
D.User_Name = User_Name;
D.User_Group = User_Group;
D.Max_Audiogram_Value = Max_Audiogram_Value;
D.Baseline_Audiogram = Baseline_Audiogram;
D.Audiogram_Gain_Percentage = Audiogram_Gain_Percentage;
D.Audio_Files = Audio_Files;
D.Target_Frequencies = Target_Frequencies;
D.Freq_Labels = Freq_Labels;
D.Q_FACTOR = Q_FACTOR;
D.Fs = Fs;
D.noise_duration = noise_duration;
D.Test_Boost_Levels = Test_Boost_Levels;
D.CALIBRATION_TRIALS = CALIBRATION_TRIALS;
D.PASS_THRESHOLD = PASS_THRESHOLD;
D.Current_Test_Level_Index = 1;
D.Trial = 0;
D.Correct = 0;
D.Answered = false;
D.Calibration_Complete = false;
D.Freq_Btns = Freq_Btns;
D.Progress_Label = Progress_Label;
D.Boost_Level_Label = Boost_Level_Label;
D.Score_Label = Score_Label;
D.Status_Label = Status_Label;
D.Start_Btn = Start_Btn;
D.Session_Data = Session_Data;

Main_Fig.UserData = D;

% CALLBACK FUNCTIONS

function startCalibration(Fig)
    fprintf('[START] Beginning calibration\n');
    D = Fig.UserData;
    D.Start_Btn.Enable = 'off';
    D.Trial = 0;
    D.Correct = 0;
    D.Answered = false;
    Fig.UserData = D;
    
    pause(0.5);
    playNextTrial(Fig);
end

function playNextTrial(Fig)
    try
        D = Fig.UserData;
        
        D.Trial = D.Trial + 1;
        D.Answered = false;
        
        fprintf('[TRIAL %d] Starting\n', D.Trial);
        
        if D.Trial > D.CALIBRATION_TRIALS
            evaluateCalibration(Fig);
            return;
        end
        
        verifyCalibrationState(D);
        
        D.Progress_Label.Text = sprintf('Trial: %d / %d', D.Trial, D.CALIBRATION_TRIALS);
        D.Boost_Level_Label.Text = sprintf('Current boost level: +%d dB', ...
            D.Test_Boost_Levels(D.Current_Test_Level_Index));
        D.Score_Label.Text = sprintf('Correct: %d / %d', D.Correct, D.Trial - 1);
        D.Status_Label.Text = 'Playing audio...';
        setStatusColor(D.Status_Label, 'playing');
        
        forceDisableButtons(D.Freq_Btns);
        
        Fig.UserData = D;
        drawnow;
        
        % Select random target frequency (pink noise only)
        correct_freq_idx = randi(8);

        % Calculate gains
        current_boost = D.Test_Boost_Levels(D.Current_Test_Level_Index);
        Round_Gains = D.Baseline_Audiogram .* D.Audiogram_Gain_Percentage;
        Round_Gains(correct_freq_idx) = Round_Gains(correct_freq_idx) + current_boost;

        D.Correct_Idx = correct_freq_idx;
        
        Fig.UserData = D;
        
        % Play audio
        [filtered_signal, audio_Fs] = ATS_makePinkNoiseStimulus(D.noise_duration, ...
            D.Target_Frequencies, D.Q_FACTOR, Round_Gains);
        
        clear sound;
        sound(filtered_signal, audio_Fs);
        pause(length(filtered_signal) / audio_Fs + 0.1);
        clear sound;
        
        % Re-fetch UserData
        D = Fig.UserData;
        D.Status_Label.Text = 'Select the boosted frequency:';
        setStatusColor(D.Status_Label, 'waiting');
        
        fprintf('[BUTTONS] Enabling frequency buttons\n');
        forceEnableButtons(D.Freq_Btns);
        
        Fig.UserData = D;
        
    catch ME
        fprintf('[ERROR] in playNextTrial: %s\n', ME.message);
        for k = 1:length(ME.stack)
            fprintf('  %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
        end
        
        D = Fig.UserData;
        forceEnableButtons(D.Freq_Btns);
        D.Status_Label.Text = 'Error - Please contact administrator';
        setStatusColor(D.Status_Label, 'error');
        Fig.UserData = D;
    end
end

function submitAnswer(Fig, guess_idx)
    D = Fig.UserData;
    
    if D.Answered
        return;
    end
    
    D.Answered = true;
    
    forceDisableButtons(D.Freq_Btns);
    
    if guess_idx == D.Correct_Idx
        D.Correct = D.Correct + 1;
        D.Status_Label.Text = sprintf('Correct! It was %s', D.Freq_Labels{D.Correct_Idx});
        D.Status_Label.FontColor = [0.1, 0.6, 0.1];
        setStatusColor(D.Status_Label, 'success');
    else
        D.Status_Label.Text = sprintf('Incorrect. It was %s, not %s', ...
            D.Freq_Labels{D.Correct_Idx}, D.Freq_Labels{guess_idx});
        D.Status_Label.FontColor = [0.8, 0.1, 0.1];
        setStatusColor(D.Status_Label, 'error');
    end
    
    D.Score_Label.Text = sprintf('Correct: %d / %d', D.Correct, D.Trial);
    
    Fig.UserData = D;
    pause(1.5);
    
    D = Fig.UserData;
    D.Status_Label.FontColor = [0, 0, 0];
    setStatusColor(D.Status_Label, 'normal');
    Fig.UserData = D;
    
    playNextTrial(Fig);
end

function evaluateCalibration(Fig)
    D = Fig.UserData;
    
    fprintf('[EVALUATE] Score: %d/%d\n', D.Correct, D.CALIBRATION_TRIALS);
    
    passed = D.Correct >= D.PASS_THRESHOLD;
    current_boost = D.Test_Boost_Levels(D.Current_Test_Level_Index);
    
    if strcmp(D.User_Group, 'Normal')
        % NORMAL USER EVALUATION
        if passed
            % Passed - calibration complete
            D.Calibration_Complete = true;
            D.Status_Label.Text = sprintf('Calibration Complete! Starting at +%d dB', current_boost);
            D.Status_Label.FontColor = [0.1, 0.6, 0.1];
            D.Status_Label.FontSize = 13;
            D.Status_Label.FontWeight = 'bold';
            setStatusColor(D.Status_Label, 'success');
            
            Fig.UserData = D;
            drawnow;
            
            fprintf('[SUCCESS] Calibrated at %d dB\n', current_boost);
            pause(2);
            
            D = Fig.UserData;
            D.Status_Label.Text = 'Launching training...';
            Fig.UserData = D;
            drawnow;
            pause(1);
            
            launchMainTraining(Fig, current_boost);
            
        else
            % Failed - try next level
            if D.Current_Test_Level_Index < length(D.Test_Boost_Levels)
                fprintf('[RETEST] Moving to next level\n');
                
                D.Current_Test_Level_Index = D.Current_Test_Level_Index + 1;
                D.Trial = 0;
                D.Correct = 0;
                D.Answered = false;
                
                forceDisableButtons(D.Freq_Btns);
                
                next_boost = D.Test_Boost_Levels(D.Current_Test_Level_Index);
                
                % Countdown message (NO uialert)
                D.Status_Label.Text = sprintf('Score: %d/%d. Moving to +%d dB in 3...', ...
                    D.Correct, D.CALIBRATION_TRIALS, next_boost);
                D.Status_Label.FontSize = 13;
                D.Status_Label.FontWeight = 'bold';
                setStatusColor(D.Status_Label, 'waiting');
                Fig.UserData = D;
                drawnow;
                pause(1);
                
                D = Fig.UserData;
                D.Status_Label.Text = sprintf('Moving to +%d dB in 2...', next_boost);
                Fig.UserData = D;
                drawnow;
                pause(1);
                
                D = Fig.UserData;
                D.Status_Label.Text = sprintf('Moving to +%d dB in 1...', next_boost);
                Fig.UserData = D;
                drawnow;
                pause(1);
                
                D = Fig.UserData;
                D.Status_Label.FontSize = 11;
                D.Status_Label.FontWeight = 'normal';
                setStatusColor(D.Status_Label, 'normal');
                Fig.UserData = D;
                
                playNextTrial(Fig);
                
            else
                % Failed at highest level - use 20 dB
                D.Calibration_Complete = true;
                
                D.Status_Label.Text = 'Starting at +20 dB (highest level)';
                D.Status_Label.FontSize = 13;
                setStatusColor(D.Status_Label, 'waiting');
                Fig.UserData = D;
                drawnow;
                
                fprintf('[INFO] Using 20 dB (highest level)\n');
                pause(2);
                
                launchMainTraining(Fig, 20);
            end
        end
        
    else
        % ADJUSTED USER EVALUATION
        if passed && D.Audiogram_Gain_Percentage > 0
            % Passed - reduce audiogram gain
            D.Audiogram_Gain_Percentage = D.Audiogram_Gain_Percentage - 0.25;
            D.Trial = 0;
            D.Correct = 0;
            D.Answered = false;
            
            forceDisableButtons(D.Freq_Btns);
            
            if D.Audiogram_Gain_Percentage >= 0
                % Countdown for gain reduction
                D.Status_Label.Text = sprintf('Passed! Reducing to %.0f%% in 3...', ...
                    D.Audiogram_Gain_Percentage * 100);
                D.Status_Label.FontSize = 13;
                D.Status_Label.FontWeight = 'bold';
                setStatusColor(D.Status_Label, 'success');
                Fig.UserData = D;
                drawnow;
                pause(1);
                
                D = Fig.UserData;
                D.Status_Label.Text = sprintf('Reducing to %.0f%% in 2...', ...
                    D.Audiogram_Gain_Percentage * 100);
                Fig.UserData = D;
                drawnow;
                pause(1);
                
                D = Fig.UserData;
                D.Status_Label.Text = sprintf('Reducing to %.0f%% in 1...', ...
                    D.Audiogram_Gain_Percentage * 100);
                Fig.UserData = D;
                drawnow;
                pause(1);
                
                D = Fig.UserData;
                D.Status_Label.FontSize = 11;
                D.Status_Label.FontWeight = 'normal';
                setStatusColor(D.Status_Label, 'normal');
                Fig.UserData = D;
                
                playNextTrial(Fig);
            else
                % Reached 0% - calibration complete
                D.Audiogram_Gain_Percentage = 0.0;
                D.Calibration_Complete = true;
                
                D.Status_Label.Text = 'Calibration Complete! 0% compensation reached';
                D.Status_Label.FontSize = 13;
                setStatusColor(D.Status_Label, 'success');
                Fig.UserData = D;
                drawnow;
                pause(2);
                
                launchMainTraining(Fig, current_boost);
            end
            
        elseif passed && D.Audiogram_Gain_Percentage == 0
            % Passed at 0% - calibration complete
            D.Calibration_Complete = true;
            
            D.Status_Label.Text = sprintf('Calibration Complete at +%d dB!', current_boost);
            D.Status_Label.FontSize = 13;
            setStatusColor(D.Status_Label, 'success');
            Fig.UserData = D;
            drawnow;
            pause(2);
            
            launchMainTraining(Fig, current_boost);
            
        else
            % Failed - increase boost level
            if D.Current_Test_Level_Index < length(D.Test_Boost_Levels)
                D.Current_Test_Level_Index = D.Current_Test_Level_Index + 1;
                D.Trial = 0;
                D.Correct = 0;
                D.Answered = false;
                
                forceDisableButtons(D.Freq_Btns);
                
                next_boost = D.Test_Boost_Levels(D.Current_Test_Level_Index);
                
                % Countdown for boost increase
                D.Status_Label.Text = sprintf('Increasing to +%d dB in 3...', next_boost);
                D.Status_Label.FontSize = 13;
                D.Status_Label.FontWeight = 'bold';
                setStatusColor(D.Status_Label, 'waiting');
                Fig.UserData = D;
                drawnow;
                pause(1);
                
                D = Fig.UserData;
                D.Status_Label.Text = sprintf('Increasing to +%d dB in 2...', next_boost);
                Fig.UserData = D;
                drawnow;
                pause(1);
                
                D = Fig.UserData;
                D.Status_Label.Text = sprintf('Increasing to +%d dB in 1...', next_boost);
                Fig.UserData = D;
                drawnow;
                pause(1);
                
                D = Fig.UserData;
                D.Status_Label.FontSize = 11;
                D.Status_Label.FontWeight = 'normal';
                setStatusColor(D.Status_Label, 'normal');
                Fig.UserData = D;
                
                playNextTrial(Fig);
                
            else
                % Failed at highest level - use 20 dB
                D.Calibration_Complete = true;
                
                D.Status_Label.Text = 'Starting at +20 dB with current compensation';
                D.Status_Label.FontSize = 13;
                setStatusColor(D.Status_Label, 'waiting');
                Fig.UserData = D;
                drawnow;
                pause(2);
                
                launchMainTraining(Fig, 20);
            end
        end
    end
    
    Fig.UserData = D;
end

function launchMainTraining(Fig, calibration_boost_level)
    D = Fig.UserData;
    
    % Pass calibration results to main training
    assignin('base', 'Calibration_Boost_Level', calibration_boost_level);
    assignin('base', 'Calibration_Complete', true);
    assignin('base', 'Audiogram_Gain_Percentage', D.Audiogram_Gain_Percentage);
    assignin('base', 'Baseline_Audiogram', D.Baseline_Audiogram);
    assignin('base', 'User_Name', D.User_Name);
    assignin('base', 'User_Group', D.User_Group);
    
    fprintf('\n========================================\n');
    fprintf('Calibration Results\n');
    fprintf('========================================\n');
    fprintf('User: %s\n', D.User_Name);
    fprintf('Group: %s\n', D.User_Group);
    fprintf('Calibration Boost Level: %d dB\n', calibration_boost_level);
    fprintf('Audiogram Gain: %.0f%%\n', D.Audiogram_Gain_Percentage * 100);
    fprintf('========================================\n\n');
    
    session_data = D.Session_Data;
    session_data.User_Name = D.User_Name;
    session_data.User_Group = D.User_Group;
    session_data.Max_Audiogram_Value = D.Max_Audiogram_Value;
    session_data.Baseline_Audiogram = D.Baseline_Audiogram;
    session_data.Calibration_Boost_Level = calibration_boost_level;
    session_data.Calibration_Complete = true;
    session_data.Audiogram_Gain_Percentage = D.Audiogram_Gain_Percentage;
    ATS_saveSessionData(session_data);
    
    % COMPREHENSIVE CLEANUP TO PREVENT CALLBACK ERRORS
    fprintf('Cleaning up Step2 callbacks...\n');
    
    % Clear all button callbacks to prevent "Invalid object" errors
    try
        if isfield(D, 'Freq_Btns') && ~isempty(D.Freq_Btns)
            for i = 1:length(D.Freq_Btns)
                if isvalid(D.Freq_Btns{i})
                    D.Freq_Btns{i}.ButtonPushedFcn = '';
                end
            end
        end
        if isfield(D, 'Start_Btn') && isvalid(D.Start_Btn)
            D.Start_Btn.ButtonPushedFcn = '';
        end
    catch
        % Ignore cleanup errors
    end
    
    fprintf('Closing calibration figure...\n');
    if isvalid(Fig)
        close(Fig);
    end
    
    % Longer pause for cleanup
    pause(0.25);
    
    % Launch main training
    fprintf('Launching Step3 Training System...\n\n');
    Step3_Training_System_2sec_TEST;
end

% HELPER FUNCTIONS

function forceEnableButtons(button_list)
    % Aggressively enable buttons with verification
    fprintf('[BUTTONS] Force enabling %d buttons\n', numel(button_list));
    for i = 1:numel(button_list)
        button_list{i}.Enable = 'on';
    end
    drawnow;
    pause(0.05);
    % Verify
    for i = 1:numel(button_list)
        if ~strcmp(button_list{i}.Enable, 'on')
            fprintf('[WARNING] Button %d not enabled, forcing again\n', i);
            button_list{i}.Enable = 'on';
        end
    end
    drawnow;
end

function forceDisableButtons(button_list)
    % Aggressively disable buttons
    fprintf('[BUTTONS] Force disabling %d buttons\n', numel(button_list));
    for i = 1:numel(button_list)
        button_list{i}.Enable = 'off';
    end
    drawnow;
end

function verifyCalibrationState(D)
    % Verify state consistency
    if D.Trial < 0 || D.Trial > D.CALIBRATION_TRIALS + 1
        fprintf('[WARNING] Trial out of bounds: %d\n', D.Trial);
    end
    
    if D.Correct < 0 || D.Correct > D.CALIBRATION_TRIALS
        fprintf('[WARNING] Correct out of bounds: %d\n', D.Correct);
    end
    
    fprintf('[STATE] Trial=%d, Correct=%d, Answered=%d, Level=%d\n', ...
        D.Trial, D.Correct, D.Answered, D.Current_Test_Level_Index);
end

function setStatusColor(label, color_name)
    % Set status label background color
    switch color_name
        case 'playing'
            label.BackgroundColor = [0.9, 0.9, 1.0];  % Light blue
        case 'waiting'
            label.BackgroundColor = [1.0, 1.0, 0.9];  % Light yellow
        case 'success'
            label.BackgroundColor = [0.9, 1.0, 0.9];  % Light green
        case 'error'
            label.BackgroundColor = [1.0, 0.9, 0.9];  % Light red
        case 'normal'
            label.BackgroundColor = [0.94, 0.94, 0.94];  % Default gray
    end
    drawnow;
end

function Corrections = interpGainFromAudiogram(Audiogram, Audiogram_Freqs, Target_Freqs)
    dB_Values = zeros(1, numel(Audiogram_Freqs));
    
    for k = 1:numel(Audiogram_Freqs)
        Field_Name = sprintf('Hz_%d', Audiogram_Freqs(k));
        dB_Values(k) = Audiogram.(Field_Name);
    end
    
    Corrections = zeros(1, numel(Target_Freqs));
    
    for k = 1:numel(Target_Freqs)
        f = Target_Freqs(k);
        
        if f <= Audiogram_Freqs(1)
            slope = (dB_Values(2) - dB_Values(1)) / (Audiogram_Freqs(2) - Audiogram_Freqs(1));
            Corrections(k) = dB_Values(1) + slope * (f - Audiogram_Freqs(1));
        elseif f >= Audiogram_Freqs(end)
            n = numel(Audiogram_Freqs);
            slope = (dB_Values(n) - dB_Values(n-1)) / (Audiogram_Freqs(n) - Audiogram_Freqs(n-1));
            Corrections(k) = dB_Values(n) + slope * (f - Audiogram_Freqs(n));
        else
            Corrections(k) = interp1(Audiogram_Freqs, dB_Values, f, 'linear');
        end
    end
end
