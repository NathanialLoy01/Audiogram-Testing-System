function ATS_CriticalListeningIntro(audio_duration, next_step_name, title_suffix)
% Familiarization page shown between audiogram entry and calibration.

if nargin < 3
    title_suffix = '';
end

Fs = 44100;
Q_FACTOR = sqrt(2);
Target_Frequencies = [125, 250, 500, 1000, 2500, 4000, 8000, 16000];
Freq_Labels = {'125 Hz', '250 Hz', '500 Hz', '1 kHz', '2.5 kHz', '4 kHz', '8 kHz', '16 kHz'};
preview_duration = min(audio_duration, 3);

Fig_W = 740;
Fig_H = 560;
Main_Fig = uifigure('Name', sprintf('Critical Listening Familiarization%s', title_suffix), ...
    'Position', [300, 110, Fig_W, Fig_H], 'Color', [0.96, 0.96, 0.96]);

uilabel(Main_Fig, 'Text', 'Critical Listening Familiarization', ...
    'Position', [20, 510, 700, 30], 'FontSize', 18, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', 'FontColor', [0.10, 0.10, 0.10]);

Explain_Panel = uipanel(Main_Fig, 'Position', [70, 345, 600, 150], ...
    'Title', 'How to listen for boosted frequencies', 'FontSize', 12, ...
    'FontWeight', 'bold', 'BackgroundColor', [0.85, 0.93, 1.0], ...
    'ForegroundColor', [0.10, 0.10, 0.10]);

explanation_text = ['Start by listening to the unboosted pink noise reference. ' ...
    'Then compare it with the +12 dB examples below. Low-frequency boosts ' ...
    '(125-500 Hz) tend to add rumble, weight, or fullness. Mid-frequency boosts ' ...
    '(1-2.5 kHz) tend to sound more forward, nasal, or present. High-frequency ' ...
    'boosts (4-16 kHz) tend to add sharpness, hiss, brightness, or air. ' ...
    'Replay any example as often as needed before continuing to calibration.'];

uilabel(Explain_Panel, 'Text', explanation_text, ...
    'Position', [18, 12, 564, 110], 'FontSize', 10, 'WordWrap', 'on', ...
    'FontColor', [0.10, 0.10, 0.10]);

Reference_Btn = uibutton(Main_Fig, 'Text', 'Play Unboosted Pink Noise', ...
    'Position', [250, 295, 240, 38], 'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.16, 0.36, 0.62], 'FontColor', [1, 1, 1], ...
    'ButtonPushedFcn', @(src, evt) playIntroExample(Main_Fig, 0));

Example_Panel = uipanel(Main_Fig, 'Position', [115, 130, 510, 145], ...
    'Title', '+12 dB Pink Noise Examples', 'FontSize', 12, ...
    'FontWeight', 'bold', 'BackgroundColor', [0.98, 0.98, 0.98], ...
    'ForegroundColor', [0.10, 0.10, 0.10]);

Btn_W = 110;
Btn_H = 35;
Gap_X = 14;
Row1_Y = 80;
Row2_Y = 28;
Start_X = 20;

for i = 1:4
    uibutton(Example_Panel, 'Text', Freq_Labels{i}, ...
        'Position', [Start_X + (i-1)*(Btn_W + Gap_X), Row1_Y, Btn_W, Btn_H], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(src, evt) playIntroExample(Main_Fig, i));
end

for i = 5:8
    uibutton(Example_Panel, 'Text', Freq_Labels{i}, ...
        'Position', [Start_X + (i-5)*(Btn_W + Gap_X), Row2_Y, Btn_W, Btn_H], ...
        'FontSize', 11, 'FontWeight', 'bold', ...
        'ButtonPushedFcn', @(src, evt) playIntroExample(Main_Fig, i));
end

Status_Label = uilabel(Main_Fig, 'Text', 'Listen to the reference and examples, then continue when ready.', ...
    'Position', [70, 92, 600, 24], 'FontSize', 11, 'HorizontalAlignment', 'center', ...
    'FontColor', [0.25, 0.25, 0.25]);

Continue_Btn = uibutton(Main_Fig, 'Text', 'Continue to Calibration', ...
    'Position', [520, 30, 180, 42], 'FontSize', 12, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.14, 0.50, 0.22], 'FontColor', [1, 1, 1], ...
    'ButtonPushedFcn', @(src, evt) continueToCalibration(Main_Fig, next_step_name));

Main_Fig.UserData.Target_Frequencies = Target_Frequencies;
Main_Fig.UserData.Freq_Labels = Freq_Labels;
Main_Fig.UserData.Q_FACTOR = Q_FACTOR;
Main_Fig.UserData.Fs = Fs;
Main_Fig.UserData.preview_duration = preview_duration;
Main_Fig.UserData.Status_Label = Status_Label;
Main_Fig.UserData.Reference_Btn = Reference_Btn;
Main_Fig.UserData.Continue_Btn = Continue_Btn;

function playIntroExample(Fig, freq_idx)
    D = Fig.UserData;
    
    gains_db = zeros(1, numel(D.Target_Frequencies));
    if freq_idx > 0
        gains_db(freq_idx) = 12;
        D.Status_Label.Text = sprintf('Playing +12 dB example at %s...', D.Freq_Labels{freq_idx});
    else
        D.Status_Label.Text = 'Playing unboosted pink noise reference...';
    end
    
    Fig.UserData = D;
    drawnow;
    
    try
        [stimulus, audio_Fs] = ATS_makePinkNoiseStimulus(D.preview_duration, ...
            D.Target_Frequencies, D.Q_FACTOR, gains_db);
        clear sound;
        sound(stimulus, audio_Fs);
        pause(length(stimulus) / audio_Fs + 0.05);
        clear sound;
        
        D = Fig.UserData;
        D.Status_Label.Text = 'Replay examples as needed, then continue when ready.';
        Fig.UserData = D;
    catch ME
        D = Fig.UserData;
        D.Status_Label.Text = sprintf('Audio preview error: %s', ME.message);
        D.Status_Label.FontColor = [0.80, 0.10, 0.10];
        Fig.UserData = D;
    end
end

function continueToCalibration(Fig, next_step)
    if isvalid(Fig)
        close(Fig);
    end
    evalin('base', next_step);
end
end
