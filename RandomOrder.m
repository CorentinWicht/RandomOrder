% RANDOMIZATION Script for CAF STUDY

% 16.12.2019
% Author: Corentin Wicht (corentin.wicht@unifr.ch)
clear variables; clc;

%% Prompts
% Displaying the first prompt
Run = questdlg(['Would you like to run this randomization script for the...' newline,...
    newline 'A) 1st time on this group of participants',...
    newline newline	'B) 2nd/3rd... time (add more participants to existing file)'],...
    'Running script','Option A','Option B','Option A');

% Displaying the second prompt
if strcmpi(Run,'Option A')
    PromptInstructions = {'How many participants do you want to include ?',...
        'How many sessions do you have (repeated-measures) ?',...
        [newline 'WITHIN-SUBJECT' newline '1st sequence (Title : file1, file2, file3, ...)'],...
        '2nd sequence (Title : file1, file2, file3, ...)',...
        '3rd sequence (Title : file1, file2, file3, ...)',...
        '4th sequence (Title : file1, file2, file3, ...)',...
        '5th sequence (Title : file1, file2, file3, ...)', ...
        [newline 'BETWEEN-SUBJECT' newline '1st sequence (Title : file1, file2, file3, ...)'],...
        '2nd sequence (Title : file1, file2, file3, ...)',...
        '3rd sequence (Title : file1, file2, file3, ...)',...
        '4th sequence (Title : file1, file2, file3, ...)',...
        '5th sequence (Title : file1, file2, file3, ...)'};
    PromptValues = {'38','3','Questionnaires:NEO_FFI,STAI,B-CaffEQ',...
        'CogTasks:RVIP,GNG','','','','Sessions:Session_1,Session_2,Session_3','','','',''};
else
    PromptInstructions = {'How many participants do you want to include? '};
    PromptValues = {'38'};
end

% Running the 2nd prompt
PromptInputs = inputdlg(PromptInstructions,'Randomization parameters',1,PromptValues);

if strcmpi(Run,'Option A')
    % Detecting design type
    Design = {};
    for f=3:length(PromptInputs)
        if ~isempty(PromptInputs{f})
           if f < 8
               Design = [Design {'W'}];
           else
               Design = [Design {'B'}];
           end
        end
    end
end

% Removing empty lines
PromptInputs = PromptInputs(cellfun(@(x) ~isempty(x),PromptInputs));

%% Initializing variables
rng('shuffle') % Set the seed at startup to random
NumberSubj = str2double(PromptInputs{1});
date_name = datestr(now,'dd-mm-yy_HHMM');
Numbers = 1:1000; 

if strcmpi(Run,'Option A')
    for k=3:length(PromptInputs)
        Temp = strsplit(PromptInputs{k},':');
        Title = Temp(1);
        Files = strsplit(Temp{2},',');
        Test.(Title{1}) = Files;
    end
    NumSessions = str2double(PromptInputs{2});
    NumserSessions = str2double(PromptInputs{2});
    ExcelOutputP = repelem(strcat(repmat({'P'},[NumberSubj,1]),cellfun(@(x) num2str(x), num2cell([1:NumberSubj]'),'UniformOutput',0)),NumSessions);
    ExcelOutputS = repmat(strcat(repmat({'S'},[NumSessions,1]),cellfun(@(x) num2str(x), num2cell([1:NumSessions]'),'UniformOutput',0)),[NumberSubj,1]);
    ExcelOutput = strcat(ExcelOutputP,'_',ExcelOutputS);
    Titles = {'PARTICIPANTS_SESSIONS'};
    Pos2 = 2;
    Fields = fieldnames(Test);
end

%% Pseudo-random shuffling of sequences algorithm (homemade)

% If first time running the script on this group of participant
if strcmpi(Run,'Option A')

    % For each category
    for k=1:numel(Fields)
        
        % If within-subject process all session else only run it once
        if strcmpi(Design{k},'B')
            NumserSessions = 1;
        end
        
        % Positions of columns
        Pos = size(ExcelOutput,2); 
        
        % For each session
        for f = 1:NumserSessions
        
            % All possible combinations 
            AllCombin.(Fields{k}) = perms(Test.(Fields{k})); 
            NumCombin = length(AllCombin.(Fields{k}));

            % Sequences with no remainder after division
            ShuffleAvailable = repmat(NumberSubj/NumCombin,[1,NumCombin]);

            % Sequences with remainder after division
            Modulo = mod(NumberSubj,length(AllCombin.(Fields{k})));
            ShuffleAvailable = floor(ShuffleAvailable);
            ShuffleAvailable(1:Modulo) = ShuffleAvailable(1:Modulo)+1;
            ShuffleAvailable = ShuffleAvailable(randperm(length(ShuffleAvailable)));
%             ShuffleAvailable = shuffle(ShuffleAvailable);

            % Saving parameters for further use
            Out.Parameters.ShuffleAvailable.(Fields{k})(f,:) = ShuffleAvailable;

            % Run algorithm
            Shuffles = [];
            for m=1:length(ShuffleAvailable)
                Shuffles = [Shuffles repmat(m,[1,ShuffleAvailable(m)])];
            end
%             Shuffles = shuffle(Shuffles);
            Shuffles = Shuffles(randperm(length(Shuffles)));
            Out.(Fields{k}){f} = AllCombin.(Fields{k})(Shuffles,:)';

            % Saving parameters for further use
            Out.Parameters.AllCombin.(Fields{k}) = AllCombin.(Fields{k});

            % Saving results in an excel file 
            Line = f:NumSessions:NumberSubj*NumSessions;
            Col = Pos+1:Pos+length(Test.(Fields{k}));
            ExcelOutput(Line,Col) = Out.(Fields{k}){f}';
            if f == 1
                for m=1:length(Test.(Fields{k}))
                    Titles(:,Pos2) = {upper([(Fields{k}) '_' num2str(Numbers(m))])}; 
                    Pos2 = Pos2 + 1;
                end
            end
        end
    end
    
    % Saving parameters for further use
    Out.Parameters.NumberSubj = NumberSubj;
    Out.Parameters.NumbSessions = NumSessions;
    Out.Parameters.Design = Design;
    
    % Saving excel file
    ExcelOutput = cell2table(ExcelOutput);
    ExcelOutput.Properties.VariableNames = Titles;
    writetable(ExcelOutput,['RandomOrder_' date_name '.xlsx']);
    fprintf('Excel file exported in %s\n',[pwd '\RandomOrder_' date_name '.xlsx']);
 
    % saving mat file for further use
    Out.Parameters.ExcelPath = [pwd '\RandomOrder_' date_name '.xlsx'];
    uisave('Out',['RandomParameters_' date_name])
   
else
    %% When importing data
   
    % Loading mat file
    [file,path] = uigetfile('*.mat','Load the .mat file that you saved last time');
    load([path file])
    fprintf('%s file loaded successfully \n',file);
    
    % Parameters
    Fields = fieldnames(Out);
    Fields = Fields(2:end);
    NumSessions = Out.Parameters.NumbSessions;
    NumberSessions = NumSessions;
    
    % Loading excel file
    ExcelOutput = readtable(Out.Parameters.ExcelPath);
    
    % Temporary storage of new shuffling
    OldNumData = Out.Parameters.NumberSubj*NumSessions;
    ExcelOutputP = repelem(strcat(repmat({'P'},[NumberSubj,1]),cellfun(@(x) num2str(x),...
        num2cell([OldNumData+1:OldNumData+NumberSubj]'),'UniformOutput',0)),NumSessions);
    ExcelOutputS = repmat(strcat(repmat({'S'},[NumSessions,1]),cellfun(@(x) num2str(x),...
        num2cell([1:NumSessions]'),'UniformOutput',0)),[NumberSubj,1]);
    NewShuffles = strcat(ExcelOutputP,'_',ExcelOutputS);

    % For each category
    for k=1:length(Fields)
        
        % If within-subject process all session else only run it once
        if strcmpi(Out.Parameters.Design{k},'B')
            NumberSessions = 1;
        end
        
        % Initialize the temp variable
        TEMP = cell(NumberSubj*NumSessions,length(Out.(Fields{k}){1}(:,1)));
        
        % For each session (repeated-measures)
        for f=1:NumberSessions
        
            % Number of shuffles from previous run
            ShuffleAvailable = Out.Parameters.ShuffleAvailable.(Fields{k})(f,:);

            % Pseudo-random incrementation with new subjects
            for m=1:NumberSubj
                MinIdx = find(ShuffleAvailable == min(ShuffleAvailable));
                RandIdx = MinIdx(randi(length(MinIdx)));
                ShuffleAvailable(RandIdx) = ShuffleAvailable(RandIdx) + 1;

                % Add new line in excel file
                Line = f:NumSessions:NumberSubj*NumSessions;
                TEMP(Line(m),:) = Out.Parameters.AllCombin.(Fields{k})(RandIdx,:);
            end

            % Update the Out structure 
            Out.Parameters.ShuffleAvailable.(Fields{k})(f,:) = ShuffleAvailable;
        end
        
        % Store in cells
        NewShuffles = [NewShuffles TEMP];
    end
    
    % Adding the new data to the old excel file data
    NewShufflesTable = cell2table(NewShuffles);
    NewShufflesTable.Properties.VariableNames = ExcelOutput.Properties.VariableNames;
    ExcelOutput = [ExcelOutput;NewShufflesTable];
    
    % Saving excel file
    writetable(ExcelOutput,['RandomOrder_' date_name '.xlsx']);
    fprintf('Excel file exported in %s\n',[pwd '\RandomOrder_' date_name '.xlsx']);
    
    % saving mat file for further use
    Out.Parameters.ExcelPath = [pwd '\RandomOrder_' date_name '.xlsx'];
    uisave('Out',['RandomParameters_' date_name])
end