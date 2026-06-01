% project.m
function project()
    clc;
    disp('======================================');
    disp('     Live Match Commentary System     ');
    disp('======================================');
    
    % Launch the Initial Language Selection UI
    createStartupScreen();
end

% =========================================================================
% 1. STARTUP SCREEN (Language Selector)
% =========================================================================
function createStartupScreen()
    startFig = uifigure('Name', 'Select Language', 'Position', [400 300 300 200]);
    
    uilabel(startFig, 'Text', 'Choose Language', ...
        'Position', [40 130 220 30], 'FontSize', 15, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    
    % English Button
    uibutton(startFig, 'Text', 'English', 'Position', [50 70 200 40], ...
        'FontSize', 14, 'ButtonPushedFcn', @(~,~) initMainApp(1, startFig));
    
    % Khmer Button
    uibutton(startFig, 'Text', 'ភាសាខ្មែរ (Khmer)', 'Position', [50 20 200 40], ...
        'FontSize', 14, 'ButtonPushedFcn', @(~,~) initMainApp(2, startFig));
end

function initMainApp(langChoice, startFig)
    % Change text to show it is loading
    startFig.Name = 'Loading...';
    drawnow; % Force UI update
    
    % Pre-load both models so the app doesn't freeze later
    disp('Loading match databases into memory...');
    models = struct();
    try
        models.english = buildLanguageModel(1);
        models.khmer = buildLanguageModel(2);
    catch ME
        errordlg(['Failed to load match data: ', ME.message], 'Initialization Error');
        close(startFig);
        return;
    end
    disp('Databases loaded successfully!');
    
    % Close startup screen and launch main app
    close(startFig);
    launchUI(langChoice, models);
end

% =========================================================================
% 2. MAIN APP: LIVE MATCH COMMENTARY UI
% =========================================================================
function launchUI(initialLangChoice, models)
    
    % Initialize State variables
    langChoice = initialLangChoice;
    if langChoice == 1
        currentModel = models.english;
    else
        currentModel = models.khmer;
    end
    txtWords = '';
    currentText = '';
    
    % Create Figure (Themed for Live Match)
    fig = uifigure('Name', 'Live Match Commentary', 'Position', [200 200 520 440]);
    
    % --- UI Elements ---
    lblTitle   = uilabel(fig, 'Position', [20 395 310 28], 'FontSize', 16, 'FontWeight', 'bold');
    
    btnSwitch  = uibutton(fig, 'Position', [340 395 160 28], 'FontSize', 12, 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) onSwitchLang());
    
    lblOut     = uilabel(fig, 'Position', [20 360 200 20], 'FontSize', 12, 'FontWeight', 'bold');
    outputArea = uitextarea(fig, 'Position', [20 230 480 125], 'Editable', 'off', 'FontSize', 14);
    
    lblSug     = uilabel(fig, 'Position', [20 200 200 18], 'FontSize', 12, 'FontWeight', 'bold');
    
    sugBtn(1)  = uibutton(fig, 'Position', [20 170 230 26], 'Enable', 'off', 'ButtonPushedFcn', @(btn,~) onSuggest(btn.Text));
    sugBtn(2)  = uibutton(fig, 'Position', [270 170 230 26], 'Enable', 'off', 'ButtonPushedFcn', @(btn,~) onSuggest(btn.Text));
    
    lblIn      = uilabel(fig, 'Position', [20 135 200 18], 'FontSize', 12, 'FontWeight', 'bold');
    
    % Notice: ValueChangingFcn used here so it updates as you type!
    inputField = uieditfield(fig, 'text', 'Position', [20 105 380 30], 'FontSize', 14, 'ValueChangingFcn', @(~,event) onTyping(event));
    
    btnAdd     = uibutton(fig, 'Position', [408 105 92 30], 'FontSize', 13, 'ButtonPushedFcn', @(~,~) onAdd());
    btnClr     = uibutton(fig, 'Position', [20 60 120 30], 'FontSize', 12, 'ButtonPushedFcn', @(~,~) onClear());
    
    statusLbl  = uilabel(fig, 'Position', [20 30 480 20], 'FontSize', 11, 'FontColor', [0.4 0.4 0.4]);
    
    % Apply Translations and initialize text
    applyTranslations();
    
    % Fetch Initial Suggestions
    refreshSuggestions('', '');

    % CALLBACK: Switch Language (Instantaneous)
    function onSwitchLang()
        if langChoice == 1
            langChoice = 2;
            currentModel = models.khmer;
        else
            langChoice = 1;
            currentModel = models.english;
        end
        onClear();
    end

    % TRANSLATION MANAGER (Football Theme)
    function applyTranslations()
        if langChoice == 2 % Khmer Theme
            fig.Name       = 'ការអត្ថាធិប្បាយការប្រកួតផ្ទាល់';
            lblTitle.Text  = 'ការផ្សាយបន្តផ្ទាល់បាល់ទាត់';
            btnSwitch.Text = 'ប្តូរទៅភាសាអង់គ្លេស';
            lblOut.Text    = 'ព័ត៌មានអត្ថាធិប្បាយ:';
            lblSug.Text    = 'ព្រឹត្តិការណ៍ដែលបានណែនាំ:';
            lblIn.Text     = 'បញ្ចូលការលេងទីនេះ:';
            btnAdd.Text    = 'បញ្ជូន';
            btnClr.Text    = 'លុបការប្រកួត';
            txtWords       = 'ចំនួនព្រឹត្តិការណ៍: ';
            statusLbl.Text = 'ត្រៀមខ្លួនជាស្រេចសម្រាប់ការប្រកួត។';
        else % English Theme
            fig.Name       = 'Live Match Commentary';
            lblTitle.Text  = 'Live Football Commentary';
            btnSwitch.Text = 'Switch to Khmer';
            lblOut.Text    = 'Commentary Feed:';
            lblSug.Text    = 'Suggested Events:';
            lblIn.Text     = 'Type Play Here:';
            btnAdd.Text    = 'Send';
            btnClr.Text    = 'Clear Match';
            txtWords       = 'Events: ';
            statusLbl.Text = 'Ready for kickoff.';
        end
    end

    % EVENT LOGIC
    function refreshSuggestions(cw, pw)
        topWords = getBlendedTopWords(cw, pw, currentModel, 2);
        
        for s = 1:2
            if s <= numel(topWords) && ~isempty(topWords{s})
                sugBtn(s).Text   = topWords{s};
                sugBtn(s).Enable = 'on';
            else
                sugBtn(s).Text   = '';
                sugBtn(s).Enable = 'off';
            end
        end
    end

    function onTyping(event)
        raw = strtrim(event.Value);
        combined = strtrim([currentText, ' ', raw]);
        [cw, pw] = lastTwoWords(combined);
        refreshSuggestions(cw, pw);
    end

    function onAdd()
        raw = strtrim(inputField.Value);
        if isempty(raw), return; end
        
        if isempty(currentText), currentText = raw; else, currentText = [currentText, ' ', raw]; end
        
        % Fixed: Strictly generate only 1 next word
        currentText = appendPredictions(currentText, 1); 
        
        outputArea.Value = {currentText};
        inputField.Value = '';
        [cw, pw] = lastTwoWords(currentText);
        refreshSuggestions(cw, pw);
        
        statusLbl.Text = [txtWords, num2str(numel(strsplit(strtrim(currentText))))];
        try focus(inputField); catch; end 
    end

    function onSuggest(word)
        word = strtrim(word);
        if isempty(word), return; end
        
        if isempty(currentText), currentText = word; else, currentText = [currentText, ' ', word]; end
        
        % Fixed: Strictly generate only 1 next word
        currentText = appendPredictions(currentText, 1); 
        
        outputArea.Value = {currentText};
        inputField.Value = '';
        [cw, pw] = lastTwoWords(currentText);
        refreshSuggestions(cw, pw);
        
        statusLbl.Text = [txtWords, num2str(numel(strsplit(strtrim(currentText))))];
        try focus(inputField); catch; end 
    end

    function onClear()
        currentText = '';
        outputArea.Value = {''};
        inputField.Value = '';
        applyTranslations();
        refreshSuggestions('', ''); 
        try focus(inputField); catch; end 
    end

    function txt = appendPredictions(txt, n)
        for k = 1:n
            [cw, pw] = lastTwoWords(txt);
            predArray = getBlendedTopWords(cw, pw, currentModel, 1);
            
            if isempty(predArray), break; end
            pred = char(predArray{1});
            
            txt = [txt, ' ', pred];
        end
    end
end  

% =========================================================================
% 3. BACKGROUND ENGINE: Data Preparation & Training
% =========================================================================
function model = buildLanguageModel(langChoice)
    if langChoice == 2
        fileName = 'data_khmer.txt';
    else
        fileName = 'data_english.txt';
    end
    
    if ~isfile(fileName)
        error(['File ', fileName, ' not found.']);
    end
    
    rawText = fileread(fileName);
    cleanedText = lower(rawText);
    
    % Completely strip out all punctuation so words connect seamlessly across lines
    cleanedText = regexprep(cleanedText, '[".?!,''()\[\]{}។]', ' '); 
    
    tokens = strsplit(cleanedText);
    tokens = tokens(~cellfun('isempty', tokens));
    
    splitIdx = floor(length(tokens) * 0.8);
    trainTokens = tokens(1:splitIdx);
    
    vocab = unique(trainTokens);
    model.vocabSize = length(vocab);
    
    model.wordToIndex = containers.Map(vocab, num2cell(1:model.vocabSize));
    model.indexToWord = containers.Map(num2cell(1:model.vocabSize), vocab);
    
    model.coMatrix = zeros(model.vocabSize, model.vocabSize);
    for i = 1:(length(trainTokens)-1)
        id1 = model.wordToIndex(trainTokens{i});
        id2 = model.wordToIndex(trainTokens{i+1});
        model.coMatrix(id1, id2) = model.coMatrix(id1, id2) + 1;
    end
    model.globalCounts = sum(model.coMatrix, 1);
    
    model.trigramMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
    for i = 1:(length(trainTokens)-2)
        key = [trainTokens{i}, ' ', trainTokens{i+1}];
        w3  = trainTokens{i+2};
        if isKey(model.trigramMap, key)
            m = model.trigramMap(key);
            if isKey(m, w3), m(w3) = m(w3) + 1; else, m(w3) = 1; end
            model.trigramMap(key) = m;
        else
            model.trigramMap(key) = containers.Map({w3}, {1});
        end
    end
end

% =========================================================================
% 4. HELPER FUNCTIONS
% =========================================================================
function [currWord, prevWord] = lastTwoWords(txt)
    txt = lower(strtrim(txt));
    % Strip punctuation out of live text input to match database tokens
    txt = regexprep(txt, '[".?!,''()\[\]{} ]', ' ');
    
    parts = strsplit(txt);
    parts = parts(~cellfun('isempty', parts));
    currWord = ''; prevWord = '';
    if ~isempty(parts), currWord = parts{end}; end
    if numel(parts) >= 2, prevWord = parts{end-1}; end
end

% STRICT TRI-GRAM SELECTION ENGINE
function topWords = getBlendedTopWords(cw, pw, model, numToPick)
    topWords = {};
    
    % If two words are available, FORCE the engine to ONLY look at the Trigram database
    if ~isempty(pw) && ~isempty(cw)
        key = [pw, ' ', cw];
        if isKey(model.trigramMap, key)
            m = model.trigramMap(key);
            wds = keys(m); cts = cell2mat(values(m));
            [~, idx] = sort(cts, 'descend');
            actualToPick = min(numToPick, length(idx));
            topWords = wds(idx(1:actualToPick));
            return; % Exit instantly so bigram/global scopes never pollute the choices
        end
    end
    
    % Bigram Fallback (Only used for typewriter suggestions when a 2nd word isn't ready)
    if ~isempty(cw) && isKey(model.wordToIndex, cw)
        rowIdx = model.wordToIndex(cw);
        rowScores = model.coMatrix(rowIdx, :);
        [sortedScores, sortedIndices] = sort(rowScores, 'descend');
        valid = sortedScores > 0;
        sortedIndices = sortedIndices(valid);
        actualToPick = min(numToPick, length(sortedIndices));
        topWords = cell(1, actualToPick);
        for i = 1:actualToPick
            topWords{i} = model.indexToWord(sortedIndices(i));
        end
        return;
    end
    
    % Global Fallback (Only used if workspace text field is completely empty)
    if isempty(cw)
        [sortedScores, sortedIndices] = sort(model.globalCounts, 'descend');
        valid = sortedScores > 0;
        sortedIndices = sortedIndices(valid);
        actualToPick = min(numToPick, length(sortedIndices));
        topWords = cell(1, actualToPick);
        for i = 1:actualToPick
            topWords{i} = model.indexToWord(sortedIndices(i));
        end
    end
end
