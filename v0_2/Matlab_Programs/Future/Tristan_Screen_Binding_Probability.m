clear
%% 1) Select Single Folder to Test
pathname = uigetdir();
pathname=[pathname,filesep];

allfiles = dir(pathname);
allfiles = allfiles(arrayfun(@(x) isfile([pathname,x.name]),allfiles));
allfilescells = arrayfun(@(y) [pathname,y.name],allfiles,'UniformOutput',false);

numofexps = size(allfilescells,1);
disp(['There are ' num2str(numofexps) ' files to analyse']);

[filepath,filename] = fileparts(fileparts(pathname));
workingDir = [filepath,filesep,filename,filesep,filename,'_Analysis',filesep];

if ~exist(workingDir, 'dir')
   mkdir(workingDir)%make a subfolder with that name
end

filteredDir = [workingDir,'Filtered_Data',filesep];
if ~exist(filteredDir, 'dir')
   mkdir(filteredDir)%make a subfolder with that name
end
%% 2) Write out raw traces
columnsInTables = 3;

rowsInTable = ceil(numofexps/columnsInTables);

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',[filename,' Raw Traces']);fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
for fileToCheck = 1:numofexps
    data = load(allfilescells{fileToCheck});
    subplot(rowsInTable,columnsInTables,fileToCheck)
    hold on
    plot(data(:,2),'-b')
    plot(-data(:,1),'-r')
    xlabel('Time (ms)');
    ylabel('Photon burst');
    hold off
end
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([workingDir [filename,'_Raw_Traces']], '-dpng', '-r600')
print([workingDir [filename,'_Raw_Traces']], '-depsc', '-r600')
%% 3) Write out scaled traces

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',[filename,' Scaled Traces']);fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
for fileToCheck = 1:numofexps
    data = load(allfilescells{fileToCheck});
    subplot(rowsInTable,columnsInTables,fileToCheck)
    hold on
    plot((data(:,2)-median(data(:,2)))./std(data(:,2))+1,'-b')
    plot(-(data(:,1)-median(data(:,1)))./std(data(:,1))-1,'-r')
    xlabel('Time (ms)');
    ylabel('std. devs.');
    ylim([-7 7])
    yticks([-7:2:7]);
    yticklabels(arrayfun(@(x)num2str(abs(x)-1),[-7:2:7],'UniformOutput',false));
    hold off
end
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([workingDir [filename,'_Scaled_Traces']], '-dpng', '-r600')
print([workingDir [filename,'_Scaled_Traces']], '-depsc', '-r600')
%% 4) Filter Data
alignData = false;

%cutoffs
ch1MinInt = 0;
ch1MaxInt = 10000;
ch2MinInt = 0;
ch2MaxInt = 10000;

minusMovingMedian = true; % I think this should always be run with moving median on
movingmedianwindow = 1001;

if alignData
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure('Name',[filename,' Time Offset Between Channels']);fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    title([filename,' Scaled Traces']);
end

for fileToCheck = 1:numofexps
    data = load(allfilescells{fileToCheck});
    
    if alignData
        crosscorr = xcorr(data(:,1),data(:,2));
        crosslen = (size(crosscorr,1)-1)/2;
        xcrosscorr = (-crosslen:crosslen)';
        [~,maxpos] = max(crosscorr);
        tOffset = xcrosscorr(maxpos);

        subplot(rowsInTable,columnsInTables,fileToCheck)
        hold on
        plot(xcrosscorr,crosscorr);
        xline(tOffset,'-r'); %local maxima of cross correlation where the x value is the amount of shift with respect to Ch1
        xlim([-10 10]);
        xlabel(['Offset between channels (frames)'])
        ylabel('Correlation (a.u.)')
        hold off
        
        if tOffset<0
            data = [data(1:end+tOffset,1) data(1-tOffset:end,2)];
        else
            data = [data(1+tOffset:end,1) data(1:end-tOffset,2)];
        end
    
    end
    
    
    data = data(data(:,1)>ch1MinInt & data(:,1)<ch1MaxInt & data(:,2)>ch2MinInt & data(:,2)<ch2MaxInt,:);
    
    if minusMovingMedian
        data(:,1) = data(:,1) - movmedian(data(:,1),movingmedianwindow);
        data(:,2) = data(:,2) - movmedian(data(:,2),movingmedianwindow);
    end
    
    csvwrite([filteredDir,'Repeat_',num2str(fileToCheck),'.csv'],data);
end
    
if alignData
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([workingDir [filename,'_Channel_Alignment']], '-dpng', '-r600')
    print([workingDir [filename,'_Channel_Alignment']], '-depsc', '-r600')
end
%% 5) Write out filtered raw traces

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',[filename,' Filtered Raw Traces']);fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
for fileToCheck = 1:numofexps
    data = csvread([filteredDir,'Repeat_',num2str(fileToCheck),'.csv']);
    subplot(rowsInTable,columnsInTables,fileToCheck)
    hold on
    plot(data(:,2),'-b')
    plot(-data(:,1),'-r')
    xlabel('Time (ms)');
    ylabel('Photon burst');
    hold off
end
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([workingDir [filename,'_Filtered_Raw_Traces']], '-dpng', '-r600')
print([workingDir [filename,'_Filtered_Raw_Traces']], '-depsc', '-r600')
%% 6) Write out filtered scaled traces


opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',[filename,' Filtered Scaled Traces']);fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
for fileToCheck = 1:numofexps
    data = csvread([filteredDir,'Repeat_',num2str(fileToCheck),'.csv']);
    subplot(rowsInTable,columnsInTables,fileToCheck)
    hold on
    plot((data(:,2)-median(data(:,2)))./std(data(:,2))+1,'-r')
    plot(-(data(:,1)-median(data(:,1)))./std(data(:,1))-1,'-b')
    xlabel('Time (ms)');
    ylabel('std. devs.');
    ylim([-7 7])
    yticks([-7:2:7]);
    yticklabels(arrayfun(@(x)num2str(abs(x)-1),[-7:2:7],'UniformOutput',false));
    hold off
end
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([workingDir [filename,'_Filtered_Scaled_Traces']], '-dpng', '-r600')
print([workingDir [filename,'_Filtered_Scaled_Traces']], '-depsc', '-r600')
%% 7) Find Probability of binding

probabilityIterations = 10000;

allData = [];
allResults = zeros(numofexps+3,1);

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',[filename,' Scatter Density Plots']);fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);

for fileToCheck = 4:4%1:numofexps
    data = csvread([filteredDir,'Repeat_',num2str(fileToCheck),'.csv']);

    xdata = data(:,1);
    ydata = data(:,2);

    alignedcross = dot(xdata,ydata);
    
    randbetter = 0;
    
    for i=1:probabilityIterations
        randcross = dot(xdata,ydata(randperm(length(ydata))));
        if randcross>alignedcross
            randbetter = randbetter+1;
        end
    end
    bindingProbability = 1-randbetter/probabilityIterations;
    allData = [allData;data];

    
    subplot(rowsInTable,columnsInTables,fileToCheck)
    hold on
    histogram2(data(:,1),data(:,2),'DisplayStyle','tile');
    xlabel('Channel 1 Signal');
    ylabel('Channel 2 Signal')
    hold off
    
    allResults(fileToCheck,1) = bindingProbability;
    
    
    %disp(['Channel 2 to Channel 1 Intensity Ratio of binding for file ' num2str(fileToCheck) ' is ' gradient]);

end
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([workingDir [filename,'_Density_Plots']], '-dpng', '-r600')
print([workingDir [filename,'_Density_Plots']], '-depsc', '-r600')

xdata = allData(:,1);
ydata = allData(:,2);

alignedcross = dot(xdata,ydata);

randbetter = 0;

for i=1:probabilityIterations
    randcross = dot(xdata,ydata(randperm(length(ydata))));
    if randcross>alignedcross
        randbetter = randbetter+1;
    end
end
bindingProbability = 1-randbetter/probabilityIterations;
allResults(numofexps+3,1) = bindingProbability;

allResults(numofexps+1,1) = mean(allResults(1:numofexps,1));
if numofexps>1
    allResults(numofexps+2,1) = std(allResults(1:numofexps,1));
end



opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',[filename,' Pooled Density Plot']); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
hold on
title(strrep(filename,'_','\_'))
histogram2(allData(:,1),allData(:,2),'DisplayStyle','tile');
xlabel('Channel 1 Signal');
ylabel('Channel 2 Signal');
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([workingDir [filename,'_Pooled_Density_Plot']], '-dpng', '-r600');
print([workingDir [filename,'_Pooled_Density_Plot']], '-depsc', '-r600');

f=figure;
set(gcf, 'Position', [100, 100, 350, 300])
t=uitable(f,'Data',allResults,'Position', [0, 0, 350, 300]);
t.ColumnName = {'Binding Probability'};
t.RowName = num2cell([1:numofexps]);
t.RowName(numofexps+1) = {'Mean'};
t.RowName(numofexps+2) = {'Std. Dev.'};
t.RowName(numofexps+3) = {'Pooled'};

T = array2table(allResults);
T.Properties.VariableNames= matlab.lang.makeValidName({'Binding_Probability'});
T.Properties.RowNames = t.RowName;
writetable(T, [workingDir,'Binding_Probability_Summary.csv'],'WriteRowNames',true);
   

 
%% Select Folder for batch analysis
foldername = uigetdir();
foldername=[foldername,filesep];

allfolders = dir(foldername);
allfolders = allfolders(arrayfun(@(x) x.isdir,allfolders));
allfolderscells = arrayfun(@(y) [foldername,y.name,filesep],allfolders(3:end),'UniformOutput',false);

numOfFolders = size(allfolderscells,1);

disp(['There are ' num2str(numOfFolders) ' folders to analyse']);
%% Run batch analysis
columnsInTables = 3;

alignData = true;

%cutoffs
ch1MinInt = 0;
ch1MaxInt = 10000;
ch2MinInt = 0;
ch2MaxInt = 10000;

minusMovingMedian = true;
movingmedianwindow = 1001;

probabilityIterations = 1000;

allResultTables = zeros(3,numOfFolders);

allFilenames = {};
allFilenames2 = {};


for folderToAnalyse = 1:1%numOfFolders
   
    pathname = allfolderscells{folderToAnalyse};
    allfiles = dir(pathname);
    allfiles = allfiles(arrayfun(@(x) isfile([pathname,x.name]),allfiles));
    allfilescells = arrayfun(@(y) [pathname,y.name],allfiles,'UniformOutput',false);

    numofexps = size(allfilescells,1);
    

    [filepath,filename] = fileparts(fileparts(pathname));
    workingDir = [filepath,filesep,filename,filesep,filename,'_Analysis',filesep];

    if ~exist(workingDir, 'dir')
       mkdir(workingDir)%make a subfolder with that name
    end

    filteredDir = [workingDir,'Filtered_Data',filesep];
    if ~exist(filteredDir, 'dir')
       mkdir(filteredDir)%make a subfolder with that name
    end
    disp(['Analysing ' filename]);
    disp(['There are ' num2str(numofexps) ' files to analyse']);

    rowsInTable = ceil(numofexps/columnsInTables);
    
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure('Name',[filename,' Raw Traces'],'visible','off');fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    for fileToCheck = 1:numofexps
        data = load(allfilescells{fileToCheck});
        subplot(rowsInTable,columnsInTables,fileToCheck)
        hold on
        plot(data(:,2),'-b')
        plot(-data(:,1),'-r')
        xlabel('Time (ms)');
        ylabel('Photon burst');
        hold off
    end
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([workingDir [filename,'_Raw_Traces']], '-dpng', '-r600')
    print([workingDir [filename,'_Raw_Traces']], '-depsc', '-r600')
    
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure('Name',[filename,' Scaled Traces'],'visible','off');fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    for fileToCheck = 1:numofexps
        data = load(allfilescells{fileToCheck});
        subplot(rowsInTable,columnsInTables,fileToCheck)
        hold on
        plot((data(:,2)-median(data(:,2)))./std(data(:,2))+1,'-r')
        plot(-(data(:,1)-median(data(:,1)))./std(data(:,1))-1,'-b')
        xlabel('Time (ms)');
        ylabel('std. devs.');
        ylim([-7 7])
        yticks([-7:2:7]);
        yticklabels(arrayfun(@(x)num2str(abs(x)-1),[-7:2:7],'UniformOutput',false));
        hold off
    end
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([workingDir [filename,'_Scaled_Traces']], '-dpng', '-r600')
    print([workingDir [filename,'_Scaled_Traces']], '-depsc', '-r600')
    
    if alignData
        opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
        fig = figure('Name',[filename,' Time Offset Between Channels'],'visible','off');fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
        set(fig.Children, 'FontName','Times', 'FontSize', 9);
        title([filename,' Scaled Traces']);
    end

    for fileToCheck = 1:numofexps
        data = load(allfilescells{fileToCheck});

        if alignData
            crosscorr = xcorr(data(:,1),data(:,2));
            crosslen = (size(crosscorr,1)-1)/2;
            xcrosscorr = (-crosslen:crosslen)';
            [~,maxpos] = max(crosscorr);
            tOffset = xcrosscorr(maxpos);

            subplot(rowsInTable,columnsInTables,fileToCheck)
            hold on
            plot(xcrosscorr,crosscorr);
            xline(tOffset,'-r'); %local maxima of cross correlation where the x value is the amount of shift with respect to Ch1
            xlim([-10 10]);
            xlabel(['Offset between channels (frames)'])
            ylabel('Correlation (a.u.)')
            hold off

            if tOffset<0
                data = [data(1:end+tOffset,1) data(1-tOffset:end,2)];
            else
                data = [data(1+tOffset:end,1) data(1:end-tOffset,2)];
            end

        end


        data = data(data(:,1)>ch1MinInt & data(:,1)<ch1MaxInt & data(:,2)>ch2MinInt & data(:,2)<ch2MaxInt,:);

        if minusMovingMedian
            data(:,1) = data(:,1) - movmedian(data(:,1),movingmedianwindow);
            data(:,2) = data(:,2) - movmedian(data(:,2),movingmedianwindow);
        end

        csvwrite([filteredDir,'Repeat_',num2str(fileToCheck),'.csv'],data);
    end

    if alignData
        set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
        fig.PaperPositionMode   = 'auto';
        print([workingDir [filename,'_Channel_Alignment']], '-dpng', '-r600')
        print([workingDir [filename,'_Channel_Alignment']], '-depsc', '-r600')
    end
    
    
    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure('Name',[filename,' Filtered Raw Traces'],'visible','off');fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    for fileToCheck = 1:numofexps
        data = csvread([filteredDir,'Repeat_',num2str(fileToCheck),'.csv']);
        subplot(rowsInTable,columnsInTables,fileToCheck)
        hold on
        plot(data(:,2),'-r')
        plot(-data(:,1),'-b')
        xlabel('Time (ms)');
        ylabel('Photon burst');
        hold off
    end
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([workingDir [filename,'_Filtered_Raw_Traces']], '-dpng', '-r600')
    print([workingDir [filename,'_Filtered_Raw_Traces']], '-depsc', '-r600')

    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure('Name',[filename,' Filtered Scaled Traces'],'visible','off');fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    for fileToCheck = 1:numofexps
        data = csvread([filteredDir,'Repeat_',num2str(fileToCheck),'.csv']);
        subplot(rowsInTable,columnsInTables,fileToCheck)
        hold on
        plot((data(:,2)-median(data(:,2)))./std(data(:,2))+1,'-r')
        plot(-(data(:,1)-median(data(:,1)))./std(data(:,1))-1,'-b')
        xlabel('Time (ms)');
        ylabel('std. devs.');
        ylim([-7 7])
        yticks([-7:2:7]);
        yticklabels(arrayfun(@(x)num2str(abs(x)-1),[-7:2:7],'UniformOutput',false));
        hold off
    end
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([workingDir [filename,'_Filtered_Scaled_Traces']], '-dpng', '-r600')
    print([workingDir [filename,'_Filtered_Scaled_Traces']], '-depsc', '-r600')
    
    allData = [];
    allResults = zeros(numofexps+3,1);

    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure('Name',[filename,' Scatter Density Plots'],'visible','off');fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);

    for fileToCheck = 1:numofexps
        data = csvread([filteredDir,'Repeat_',num2str(fileToCheck),'.csv']);

        xdata = data(:,1);
        ydata = data(:,2);

        alignedcross = dot(xdata,ydata);

        randbetter = 0;

        for i=1:probabilityIterations
            randcross = dot(xdata,ydata(randperm(length(ydata))));
            if randcross>alignedcross
                randbetter = randbetter+1;
            end
        end
        bindingProbability = 1-randbetter/probabilityIterations;
        allData = [allData;data];


        subplot(rowsInTable,columnsInTables,fileToCheck)
        hold on
        histogram2(data(:,1),data(:,2),'DisplayStyle','tile');
        xlabel('Channel 1 Signal');
        ylabel('Channel 2 Signal')
        hold off

        allResults(fileToCheck,1) = bindingProbability;


        %disp(['Channel 2 to Channel 1 Intensity Ratio of binding for file ' num2str(fileToCheck) ' is ' gradient]);

    end
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([workingDir [filename,'_Density_Plots']], '-dpng', '-r600')
    print([workingDir [filename,'_Density_Plots']], '-depsc', '-r600')

    xdata = allData(:,1);
    ydata = allData(:,2);

    alignedcross = dot(xdata,ydata);

    randbetter = 0;

    for i=1:probabilityIterations
        randcross = dot(xdata,ydata(randperm(length(ydata))));
        if randcross>alignedcross
            randbetter = randbetter+1;
        end
    end
    bindingProbability = 1-randbetter/probabilityIterations;
    allResults(numofexps+3,1) = bindingProbability;

    allResults(numofexps+1,1) = mean(allResults(1:numofexps,1));
    if numofexps>1
        allResults(numofexps+2,1) = std(allResults(1:numofexps,1));
    end

    allResultTables(1,folderToAnalyse) = allResults(numofexps+1,1);
    allResultTables(2,folderToAnalyse) = allResults(numofexps+2,1);
    allResultTables(3,folderToAnalyse) = allResults(numofexps+3,1);


    opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
    fig = figure('Name',[filename,' Pooled Density Plot']); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
    set(fig.Children, 'FontName','Times', 'FontSize', 9);
    hold on
    title(strrep(filename,'_','\_'))
    histogram2(allData(:,1),allData(:,2),'DisplayStyle','tile');
    xlabel('Channel 1 Signal');
    ylabel('Channel 2 Signal');
    hold off
    set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
    fig.PaperPositionMode   = 'auto';
    print([workingDir [filename,'_Pooled_Density_Plot']], '-dpng', '-r600');
    print([workingDir [filename,'_Pooled_Density_Plot']], '-depsc', '-r600');

    myrownames = arrayfun(@(y) num2str(y),1:numofexps,'UniformOutput',false);
    myrownames = [myrownames [{'Mean'} {'Std_Dev'} {'Pooled'}]];
    T = array2table(allResults);
    T.Properties.VariableNames= matlab.lang.makeValidName({'Binding_Probability'});
    T.Properties.RowNames = myrownames;
    writetable(T, [workingDir,'Binding_Probability_Summary.csv'],'WriteRowNames',true);

    
end

    f=figure;
    set(gcf, 'Position', [100, 100, 350, 300])
    t=uitable(f,'Data',allResultTables,'Position', [0, 0, 350, 300]);
    t.ColumnName = {'Mean Probability', 'Std Dev ','Pooled Probability'};
    t.RowName = allFilenames2;


 
    