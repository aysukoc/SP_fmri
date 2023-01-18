2
%% Scene Perception fMRI 
% 1 run, repeated 8 times
% Aysu Nur KOÇ - 2022 - Neuroscience/Bilkent University

%%% DEFINE GREY WHITE BLACK ETC
% Based on the stimuli number 
% the categories are as follows:
%   1-8 access points    9-16 circulation    17-24 restrooms     25-32 eating/seating areas
% General categories:
%   1-16 built env elements
%   17-32 facilities

%% Open Screen
HideCursor;
clc;
close all;                                  % clean up
clear; 
Screen('CloseAll');
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'VisualDebugLevel', 0);
% Screen('Preference','TextRenderer',1);
screens=Screen('Screens');
screenNumber=max(screens); % 1 for only laptop max for telemed?
[win, winrect] = Screen('OpenWindow', screenNumber, [190 190 190]);
w=RectWidth(winrect);
h=RectHeight(winrect);
center= [winrect(3)/2 winrect(4)/2];
promptright = [winrect(3)/6 winrect(4)/4 winrect(3)*2/6 winrect(4)*3/4];
promptleft = [winrect(3)*4/6 winrect(4)/4 winrect(3)*5/6 winrect(4)*3/4];
%above right and left are calculated the opposite of the practice session
%bc it will be mirrored horizontally.
%% FPS, IFI and VBL %%From Hilal's code???
fps=Screen('FrameRate',win); % frames per second
ifi=Screen('GetFlipInterval', win);
if fps==0
    fps=1/ifi;
end
Priority(MaxPriority(win));
vbl=Screen('Flip', win); % initial flip

%% Paths
Experiment_path = 'C:\Users\aysu\Documents\MATLAB\ScenePerception';
cd(Experiment_path);
Stimuli_folder = 'C:\Users\aysu\Documents\MATLAB\ScenePerception\Stimuli';

%% Read images
Stimuli_list=cell(1,32);
cd(Stimuli_folder);
for fileNo=1:length(Stimuli_list)
    filename=sprintf('%d.jpg',fileNo);
    Stimuli_list{1,fileNo} = importdata(filename);
end

%% Demographic info and the xls document
%  8 runs of 2 blocks
%  Subject and session info
subNo = input('Enter subject no: ');
runNo = input('Enter run no: ');
Experiment_date = datestr(now, 'dd-mmm-yy_HH-MM');
data.subject=subNo;
data.runNo=runNo;
data.date=Experiment_date;
% Open an xls file to write the results -
cd(Experiment_path);
if ~exist([Experiment_path, '\Output\'], 'dir')
    mkdir([Experiment_path, '\Output\']);
else ~exist ([Experiment_path, '\Output\sub-' num2str(subNo)], 'dir');
    mkdir([Experiment_path, '\Output\sub-' num2str(subNo)]);
end
sub_path=[Experiment_path, '\Output\sub-' num2str(subNo)];
cd(sub_path);
if ~exist([sub_path, './run-' num2str(runNo)], 'dir')
    mkdir([sub_path, './run-' num2str(runNo)]);
end
runpath=[sub_path, '\run-' num2str(runNo)];
cd(runpath);

fname = ['Output_Sub' num2str(subNo) '_Run_no_' num2str(runNo) '_Date_' num2str(Experiment_date) '.xls'];
[outfile, message] = fopen(fname, 'a');
if outfile == -1
    fprintf('Cannot open the file.\n%s\n', message);
end
fprintf(outfile, 'Subject no: %d', subNo); fprintf(outfile, '\n');
fprintf(outfile, 'Run no: %d', runNo); fprintf(outfile, '\n');
fprintf(outfile, 'Date of experiment: %s', Experiment_date); fprintf(outfile, '\n\n');

%Blocks for this run - randomization can be changed
if mod(subNo, 2) == 1
    blocks={'AB', 'BA', 'BA', 'AB', 'BA', 'AB', 'AB', 'BA'};
else
    blocks={'BA', 'AB', 'AB', 'BA', 'AB', 'BA', 'BA', 'AB'};
end
cd(sub_path);
save blocks blocks;
data.blocks= blocks{1,runNo};
blocks_outfile= [blocks{1,1}, blocks{1,2}, blocks{1,3}, blocks{1,4}, blocks{1,5}, blocks{1,6}, blocks{1,7}, blocks{1,8}];
fprintf(outfile, 'Block Sequence for the run: %s', blocks{runNo});
fprintf(outfile, '\n\n');

%% preallocation of data fields
for b=1:2
    data.block(b).blockOnset=zeros(1);
    data.block(b).blockOffset=zeros(1);
    data.block(b).blockDur=zeros(1);
    data.block(b).blockType=strings(1);
    data.block(b).instOnset=zeros(1);
    data.block(b).instOffset=zeros(1);
    data.block(b).instDur=zeros(1);
    data.block(b).trialNo=zeros(1,32);
    data.block(b).stimuli=zeros(1,32);
    data.block(b).ISIOnset=zeros(1,32);
    data.block(b).ISIOffset=zeros(1,32);
    data.block(b).ISIDur=zeros(1,32);
    data.block(b).stimOnset=zeros(1,32);
    data.block(b).stimOffset=zeros(1,32);
    data.block(b).stimDur=zeros(1,32);
    data.block(b).response=strings(1,32);
    data.block(b).respOnset=zeros(1,32);
    data.block(b).respOffset=zeros(1,32);
    data.block(b).respTime=zeros(1,32);
    data.block(b).respDur=zeros(1,32);
    data.block(b).RT=zeros(1,32);
    data.block(b).restOnset=zeros(1);
    data.block(b).restOffset=zeros(1);
    data.block(b).restDur=zeros(1);
end

%% Trigger and Kb Settings
% Initialize trigger counter & Keyboard - MR trigger box sends 6^ at each
% TR when plugged. No need for serial no or specific signals.
KbName('UnifyKeyNames');
Key.trigger = KbName ('6^');%6^
Key.Escape = KbName('escape');
KbQueueCreate();
%Trigger
disp('Waiting for trigger ...');
textSizeSmall=40;
textSizeBig=50;
Screen('TextSize',win,textSizeSmall);
DrawFormattedText(win,'Hoş geldiniz!','center','center', [0 0 0], [], 1);
Screen('Flip',win);

KbQueueStart();
curTR=0;
while curTR==0
    [pressed, Keycode] = KbQueueCheck();
    timeSecs = Keycode(find(Keycode));
    if pressed && Keycode (Key.trigger)
        CurrTR=1;
        break;
    end
end
KbQueueStop();

disp('Trigger is received ...');

%% KEY SETTINGS
[id, name, allInfos] = GetKeyboardIndices();
KbName('UnifyKeyNames');
Key.blue = KbName('1!');
Key.yellow = KbName('2@');
Key.green = KbName ('3#');
Key.red = KbName('4$');
%% IMPORTANT - keys that I accept - button box all keys
keysOfInterest=zeros(1,256);
keysOfInterest(KbName({'1!', '2@', '3#', '4$'}))=1;
KbQueueCreate(id, keysOfInterest);

% A - categorization task
% B - approach-avoidance task
% dot= [8226]; %'•'; as unicode value
%% EXPERIMENT START
ExpStart=GetSecs; %% write at the enddddd below the excel
fprintf(outfile, 'Experiment Start: %8.1f', ExpStart);
fprintf(outfile, '\n\n');
fprintf(outfile, 'BlockType\tBlockOnset\tBlockOffset\tBlockDuration\tInstOnset\tInstOffset\tInstDur\tTrialNo\tStimuliNo\tStimuliOnset\tStimuliOffset\tStimuliDur\tResponseOnset\tResponseOffset\tResponseDur\tISIOnset\tISIOffset\tISIDuration\tRT\tResponseTime\tResponse\n');
%% blocks{1,runNo}(currBlock), blockOnset, blockOffset, blockDur, instOnset, instOffset, instDur, trialNo, stimNoArr(trialNo), stimulusOnset, stimulusOffset, stimulusDur responseOnset, responseOffset, responseDur, ISIOnset, ISIOffset, ISIDuration, RT, responseTime, response
%% 's\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%d\t%d\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%s\r'
% the comment above won't work bc i changed arrays with data.blabla fields
% to make things faster

for block=1:2 %tasks - blocks
    %% DEFINE THE JITTERS/ISI and randomization for each block
    a=randperm(32,32); %32 stimuli randomized each block
    data.block(block).stimuli=a;
    durationISI=[];
    durationResponse=2;
    durationStimulus= 2; %%%%%%%%%%%%%%
    durationISITotal=112; %(total jitter time=32x3500ms=112sec)
    ISI=0.001*(2999+randperm(1001, 32)); %random jitters betw 3000-4000ms
    data.block(block).ISIarray=ISI; %saving ISI org array just in case we have to calculate sth manually.
    while sum(ISI)~=durationISITotal
        ISI=0.001 *(2999+randperm(1001, 32));
        durationISI=ISI;
        if sum(ISI)==durationISITotal
            break
        end
    end
    KbQueueFlush();
    %block onset
    getBlockOnset=GetSecs;
    data.block(block).blockOnset=getBlockOnset-ExpStart;
    fprintf(outfile, '%s\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%d\t%d\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%s\r', ...
        [], data.block(block).blockOnset, [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []);
    %Show one of the instructions pseudorandomly
    if blocks{1,runNo}(block)=='A' %TASK A - Categorization
        Screen('FillRect', win,[190 190 190]);
        Screen('TextSize',win,textSizeSmall);
        DrawFormattedText(win,'Mimari eleman \n\n sol buton','center','center', [0 0 0], [], 1, [], [], 0, promptleft);
        DrawFormattedText(win,'İşlevsel alan \n\n sağ buton', 'center','center', [0 0 0], [], 1, [], [], 0, promptright);
        Screen('TextSize',win,textSizeBig);
        DrawFormattedText(win,'+', 'center', 'center', [0 0 0]);
        Screen('Flip',win);
        getInstOnset=GetSecs;
        WaitSecs(10);
        getInstOffset=GetSecs;
    else %%TASK B - Approach/Avoidance
        Screen('FillRect', win,[190 190 190]);
        Screen('TextSize',win,textSizeSmall);
        DrawFormattedText(win,'Girmek isterim \n\n sol buton','center','center', [0 0 0], [], 1, [], [], 0, promptleft);
        DrawFormattedText(win,'Girmek istemem \n\n sağ buton','center','center', [0 0 0], [], 1, [], [], 0, promptright);
        Screen('TextSize',win,textSizeBig);
        DrawFormattedText(win,'+', 'center', 'center', [0 0 0]);
        Screen('Flip',win);
        getInstOnset=GetSecs;
        WaitSecs(10);
        getInstOffset=GetSecs;
    end
    data.block(block).blockType(1)=blocks{1,runNo}(block);
    data.block(block).instOnset(1)=getInstOnset-ExpStart;
    data.block(block).instOffset(1)=getInstOffset-ExpStart;
    data.block(block).instDur(1)=data.block(block).instOffset-data.block(block).instOnset;
    %% Trials start
    for trialNo=1:length(Stimuli_list) %32
        data.block(block).trialNo(trialNo)=trialNo;
        %FLIP FIXATION HERE
        Screen('FillRect', win, [190 190 190]);   %%%whole screen
        Screen('TextSize',win,textSizeBig);
        DrawFormattedText(win,'+', 'center', 'center', [0 0 0]);
        Screen('Flip',win);
        getISIOnset=GetSecs;
        WaitSecs(durationISI(trialNo));
        getISIOffset=GetSecs;
        data.block(block).ISIOnset(trialNo)=getISIOnset-ExpStart;
        data.block(block).ISIOffset(trialNo)=getISIOffset-ExpStart;
        data.block(block).ISIDur(trialNo)=data.block(block).ISIOffset(trialNo)-data.block(block).ISIOnset(trialNo);
        % set up image in proper format and display
        textureIndex = Screen('MakeTexture', win, Stimuli_list{1,a(trialNo)}); % a(trialNo) here is the stimulus no, Stimuli_list{1,a(k)} is the photo
        Screen('DrawTexture', win, textureIndex);
        %Fixation on the image
        Screen('TextSize',win,textSizeBig);
        DrawFormattedText(win, '+', 'center', 'center', [10 10 10]);
        Screen(win, 'Flip');
        getStimOnset=GetSecs;
        WaitSecs(durationStimulus);
        getStimOffset=GetSecs;
        data.block(block).stimOnset(trialNo)=getStimOnset-ExpStart;
        data.block(block).stimOffset(trialNo)=getStimOffset-ExpStart;
        data.block(block).stimDur(trialNo)=data.block(block).stimOffset(trialNo)-data.block(block).stimOnset(trialNo);
        Screen('FillRect', win, [190 190 190]);
        %start queue to record button presses
        KbQueueStart();
        %white fixation - response period
        Screen('TextSize',win,textSizeBig);
        DrawFormattedText(win,'+', 'center', 'center', [255 255 255]);
        Screen('Flip', win);
        getResponseOnset=GetSecs;
        WaitSecs(durationResponse);
        getResponseOffset=GetSecs;
        data.block(block).respOnset(trialNo)=getResponseOnset-ExpStart;
        data.block(block).respOffset(trialNo)=getResponseOffset-ExpStart;
        data.block(block).respDur(trialNo)=data.block(block).respOffset(trialNo)-data.block(block).respOnset(trialNo);
        [pressed, firstPress] = KbQueueCheck();
        %Check if and what button was pressed during response period, and record it. also record response time and RT
        %% Since multiple presses resulted in an error in the previous code (bc one response gives a char array and multiple responses result 
        % in a cell array) I edited the code. when there are multiple presses, the firstPress gives the first press of each button, ordered not 
        % based on time but name of the key. so 1<2<3<4. timeSecs is the same, it records correspondingly - with the firstPress array. So timing 
        % of 1! is always at timeSecs(1) even if it was not the first press among all presses. here, to find the first ever press, i find the 
        % location of the smallest timeSecs using [M,I]=min, say its 2, then firstpress(2) - whatever key it is - is the button that was
        % pressed first. I save the arrays and data out of the loop below, in another loop, because during one right below it is updating
        % from char to cell, so it gives errors.
        if pressed
            timeSecs=firstPress(find(firstPress));
            [M,I]=min(timeSecs);
            if (timeSecs(I) >= getResponseOnset) && (timeSecs(I) <= getResponseOffset)
                firstResp=KbName(firstPress);
                getResponseTime=timeSecs(I);
                if isa(firstResp,'char')==1
                    firstRespName=firstResp;
                    data.block(block).response(trialNo)=firstRespName;
                    data.block(block).respTime(trialNo)=getResponseTime-ExpStart;
                    data.block(block).RT(trialNo)=getResponseTime-getResponseOnset;
                else
                    firstRespName=firstResp{I};
                    data.block(block).response(trialNo)=char(firstRespName);
                    data.block(block).respTime(trialNo)=getResponseTime-ExpStart;
                    data.block(block).RT(trialNo)=getResponseTime-getResponseOnset;
                end
                KbQueueStop();
            end
            %if no button presses during the response period, NA
        else
            data.block(block).response(trialNo)='NA';
            data.block(block).respTime(trialNo)=999;
            data.block(block).RT(trialNo)=999;
        end
        %flush the queue
        KbQueueFlush();
        %record data to the corresponding block and write to file.
        fprintf(outfile, '%s\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%d\t%d\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%s\r', ...
            data.block(block).blockType(1), [], [], [],data.block(block).instOnset(1), data.block(block).instOffset(1), data.block(block).instDur(1), trialNo, ...
            data.block(block).stimuli(trialNo), data.block(block).stimOnset(trialNo), data.block(block).stimOffset(trialNo), data.block(block).stimDur(trialNo), ...
            data.block(block).respOnset(trialNo),data.block(block).respOffset(trialNo), data.block(block).respDur(trialNo), data.block(block).ISIOnset(trialNo), ...
            data.block(block).ISIOffset(trialNo), data.block(block).ISIDur(trialNo), data.block(block).RT(trialNo), data.block(block).respTime(trialNo), ...
            data.block(block).response(trialNo));
        fprintf(outfile, '\n');
    end
    %end of the block, save block related data and write to file
    getBlockOffset=GetSecs;
    data.block(block).blockOffset(1)=getBlockOffset-ExpStart;
    data.block(block).blockDur(1)=data.block(block).blockOffset-data.block(block).blockOnset;
    fprintf(outfile, '%s\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%d\t%d\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%8.3f\t%s\r', ...
        [], data.block(block).blockOnset(1), data.block(block).blockOffset(1), data.block(block).blockDur(1), [], [], [], [], [], [], [], [], [], [], [], [], [], ...
        [], [], [], []);
    fprintf(outfile, '\n');
    fprintf(outfile, 'Block Duration: %8.1f', data.block(block).blockDur(1));
    fprintf(outfile, '\n\n');
    Screen('FillRect', win, [175 175 175]);   %%%whole screen
    Screen('TextSize',win,textSizeBig);
    DrawFormattedText(win,'+', 'center', 'center', [0 0 0]);
    Screen('Flip',win);
    getRestOnset=GetSecs;
    WaitSecs(10);
    getRestOffset=GetSecs;
    data.block(block).restOnset(1)=getRestOnset - ExpStart;
    data.block(block).restOffset(1)=getRestOffset - ExpStart;
    data.block(block).restDur(1)=data.block(block).restOffset(1)-data.block(block).restOnset(1);
end
%end of the experiment, write final info to file and save data struct.
ExpEnd=GetSecs;
data.expDur = ExpEnd - ExpStart;
fprintf(outfile, '\n');
fprintf(outfile, 'Experiment End: %8.1f', ExpEnd);
fprintf(outfile, '\n');
fprintf(outfile, 'Experiment Duration: %8.1f', data.expDur);
cd(runpath);
save data data
%close outfile - clear the screen and done!
fprintf(outfile, '\n\n');
fclose(outfile);
cd(Experiment_path);
clear screen;
Screen('CloseAll');