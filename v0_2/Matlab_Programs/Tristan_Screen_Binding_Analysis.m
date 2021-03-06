clear
%% 1) Select Single Folder to Test
pathname = uigetdir();
pathname=[pathname,filesep];

allfiles = dir(pathname);
allfiles = allfiles(arrayfun(@(x) isfile([pathname,x.name]) && startsWith(x.name,'.')==0,allfiles));
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

maxCharLength = max(arrayfun(@(x) size(x.name,2),allfiles));
constStringEnd = find(all(cell2mat(arrayfun(@(x) (pad(allfiles(1).name,maxCharLength)==pad(x.name,maxCharLength)),allfiles,'UniformOutput',false)))==0,1,'first');
%% 2) Write out raw traces

columnsInTables = floor(sqrt(numofexps));
%columnsInTables = 3; Uncomment this to manually set it

topColour = [1, 0, 0];
bottomColour = [0, 0, 1];

bottomChannel1 = true;

%don't touch from here

rowsInTable = ceil(numofexps/columnsInTables);

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',[filename,' Raw Traces']);fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
for fileToCheck = 1:numofexps
    data = load(allfilescells{fileToCheck});
    subplot(rowsInTable,columnsInTables,fileToCheck)
    hold on
    title(allfiles(fileToCheck).name(constStringEnd:end), 'interpreter', 'none')
    plot(data(:,1+bottomChannel1),'Color',topColour)
    plot(-data(:,2-bottomChannel1),'Color',bottomColour)
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
    title(allfiles(fileToCheck).name(constStringEnd:end), 'interpreter', 'none')
    plot((data(:,1+bottomChannel1)-median(data(:,1+bottomChannel1)))./std(data(:,1+bottomChannel1))+1,'Color',topColour)
    plot(-(data(:,2-bottomChannel1)-median(data(:,2-bottomChannel1)))./std(data(:,2-bottomChannel1))-1,'Color',bottomColour)
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
columnsInTablesAlignPlots = floor(sqrt(numofexps));
%columnsInTablesAlignPlots = 3; Uncomment this to manually set it

%cutoffs
ch1MinInt = 0;
ch1MaxInt = 10000;
ch2MinInt = 0;
ch2MaxInt = 10000;

minusMovingMedian = true;
movingmedianwindow = 1001;


rowsInTableAlignPlots = ceil(numofexps/columnsInTables);

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

        subplot(rowsInTableAlignPlots,columnsInTablesAlignPlots,fileToCheck)
        hold on
        title(allfiles(fileToCheck).name(constStringEnd:end), 'interpreter', 'none')
        plot(xcrosscorr,crosscorr);
        xline(tOffset,'-r'); %local maxima of cross correlation where the x value is the amount of shift with respect to Ch1
        xlim([-10 10]);
        xlabel(['Offset (frames)'])
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
    
    csvwrite([filteredDir,allfiles(fileToCheck).name,'_Filtered.csv'],data);
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
    data = csvread([filteredDir,allfiles(fileToCheck).name,'_Filtered.csv']);
    subplot(rowsInTable,columnsInTables,fileToCheck)
    hold on
    title(allfiles(fileToCheck).name(constStringEnd:end), 'interpreter', 'none')
    plot(data(:,1+bottomChannel1),'Color',topColour)
    plot(-data(:,2-bottomChannel1),'Color',bottomColour)
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
    data = csvread([filteredDir,allfiles(fileToCheck).name,'_Filtered.csv']);
    subplot(rowsInTable,columnsInTables,fileToCheck)
    hold on
    title(allfiles(fileToCheck).name(constStringEnd:end), 'interpreter', 'none')
    plot((data(:,1+bottomChannel1)-median(data(:,1+bottomChannel1)))./std(data(:,1+bottomChannel1))+1,'Color',topColour)
    plot(-(data(:,2-bottomChannel1)-median(data(:,2-bottomChannel1)))./std(data(:,2-bottomChannel1))-1,'Color',bottomColour)
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
%% 7) Linearly Fit
weightChannel1Only = false;

allData = [];
allResults = zeros(numofexps+3,14);

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 17.8;opts.height= 12;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',[filename,' Scatter Density Plots']);fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);

for fileToCheck = 1:numofexps
    data = csvread([filteredDir,allfiles(fileToCheck).name,'_Filtered.csv']);
    
    xmode = mode(data(:,1));
    ymode =  mode(data(:,2));
    if weightChannel1Only
        dists = sqrt((data(:,1)-xmode).^2);
    else
        dists = sqrt((data(:,1)-xmode).^2+(data(:,2)-ymode).^2);
    end

    linearfit  = LinearModel.fit(data(:,1)-xmode,data(:,2)-ymode,'Weights',dists,'intercept',false);
    fit = linearfit.Coefficients.Estimate;
    mgradient = fit(1);
    moffset = ymode - mgradient.*xmode;

    linearfit  = LinearModel.fit(data(:,1),data(:,2),'Weights',dists);
    fit = linearfit.Coefficients.Estimate;
    offset = fit(1);
    gradient = fit(2);
    
    allResults(fileToCheck,1) = xmode;
    allResults(fileToCheck,2) = ymode;
    allResults(fileToCheck,3) = offset;
    allResults(fileToCheck,4) = gradient;
    allResults(fileToCheck,5) = moffset;
    allResults(fileToCheck,6) = mgradient;
    allResults(fileToCheck,7) = mean(data(:,1));
    allResults(fileToCheck,8) = mean(data(:,2));
    allResults(fileToCheck,9) = std(data(:,1));
    allResults(fileToCheck,10) = std(data(:,2));
    allResults(fileToCheck,11) = median(data(:,1));
    allResults(fileToCheck,12) = median(data(:,2));
    allResults(fileToCheck,13) = std(data(:,1)).*std(data(:,1))./mean(data(:,1));
    allResults(fileToCheck,14) = std(data(:,2)).*std(data(:,2))./mean(data(:,2));
    
    allData = [allData;data];
    
    bxout = min(data(:,1)):max(data(:,1));
    byout = offset+gradient*bxout;
    byout2 = moffset+mgradient*bxout;
    
    subplot(rowsInTable,columnsInTables,fileToCheck)
    hold on
    histogram2(data(:,1),data(:,2),'DisplayStyle','tile');
    title(allfiles(fileToCheck).name(constStringEnd:end), 'interpreter', 'none')
    plot(bxout,byout,'LineWidth',1)
    plot(bxout,byout2,'LineWidth',1)
    xlabel('Channel 1 Signal');
    ylabel('Channel 2 Signal')
    hold off
    %disp(['Channel 2 to Channel 1 Intensity Ratio of binding for file ' num2str(fileToCheck) ' is ' gradient]);

end
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([workingDir [filename,'_Density_Plots']], '-dpng', '-r600')
print([workingDir [filename,'_Density_Plots']], '-depsc', '-r600')

xmode = mode(allData(:,1));
ymode =  mode(allData(:,2));
if weightChannel1Only
    dists = sqrt((allData(:,1)-xmode).^2);
else
    dists = sqrt((allData(:,1)-xmode).^2+(allData(:,2)-ymode).^2);
end

linearfit  = LinearModel.fit(allData(:,1)-xmode,allData(:,2)-ymode,'Weights',dists,'intercept',false);
fit = linearfit.Coefficients.Estimate;
mgradient = fit(1);
moffset = ymode - mgradient.*xmode;

linearfit  = LinearModel.fit(allData(:,1),allData(:,2),'Weights',dists);
fit = linearfit.Coefficients.Estimate;
offset = fit(1);
gradient = fit(2);

allResults(numofexps+3,1) = xmode;
allResults(numofexps+3,2) = ymode;
allResults(numofexps+3,3) = offset;
allResults(numofexps+3,4) = gradient;
allResults(numofexps+3,5) = moffset;
allResults(numofexps+3,6) = mgradient;
allResults(numofexps+3,7) = mean(allData(:,1));
allResults(numofexps+3,8) = mean(allData(:,2));
allResults(numofexps+3,9) = std(allData(:,1));
allResults(numofexps+3,10) = std(allData(:,2));
allResults(numofexps+3,11) = median(allData(:,1));
allResults(numofexps+3,12) = median(allData(:,2));
allResults(numofexps+3,13) = std(allData(:,1)).*std(allData(:,1))./mean(allData(:,1));
allResults(numofexps+3,14) = std(allData(:,2)).*std(allData(:,2))./mean(allData(:,2));

csvwrite([workingDir,'Combined_Data.csv'],allData);

bxout = min(allData(:,1)):max(allData(:,1));
byout = offset+gradient*bxout;
byout2 = moffset+mgradient*bxout;

opts.Colors= get(groot,'defaultAxesColorOrder');opts.width= 8;opts.height= 6;opts.fontType= 'Times';opts.fontSize= 9;
fig = figure('Name',[filename,' Pooled Density Plot']); fig.Units= 'centimeters';fig.Position(3)= opts.width;fig.Position(4)= opts.height;
set(fig.Children, 'FontName','Times', 'FontSize', 9);
hold on
title(strrep(filename,'_','\_'))
histogram2(allData(:,1),allData(:,2),'DisplayStyle','tile');
plot(bxout,byout,'LineWidth',1)
plot(bxout,byout2,'LineWidth',1)
xlabel('Channel 1 Signal');
ylabel('Channel 2 Signal')
hold off
set(gca,'LooseInset',max(get(gca,'TightInset'), 0.02));
fig.PaperPositionMode   = 'auto';
print([workingDir [filename,'_Pooled_Density_Plot']], '-dpng', '-r600');
print([workingDir [filename,'_Pooled_Density_Plot']], '-depsc', '-r600');

for i=1:size(allResults,2)
    allResults(numofexps+1,i) = mean(allResults(1:numofexps,i));
    if numofexps>1
        allResults(numofexps+2,i) = std(allResults(1:numofexps,i));
    end
end
%% Write our result tables

f=figure;
set(gcf, 'Position', [100, 100, 1400, 300])
t=uitable(f,'Data',allResults,'Position', [0, 0, 1400, 300]);
t.ColumnName = {'Ch1 Mode','Ch2 Mode','Offset','Gradient','Offset (Mode Constrained)','Gradient (Mode Constrained)', 'Ch1 Mean','Ch2 Mean', 'Ch1 Std. Dev.','Ch2 Std. Dev.','Ch1 Median','Ch2 Median','Ch1 B-value','Ch2 B-value'};
myrownames = arrayfun(@(y) ['_' allfiles(y).name(constStringEnd:end)],1:numofexps,'UniformOutput',false);
myrownames = [myrownames [{'Mean'} {'Std. Dev.'} {'Pooled'}]];
t.RowName = myrownames;

T = array2table(allResults);
T.Properties.VariableNames= matlab.lang.makeValidName({'Ch1_Mode','Ch2_Mode','Offset','Gradient','Offset(Mode_Constrained)','Gradient(Mode_Constrained)', 'Ch1_Mean','Ch2_Mean', 'Ch1_Std_Dev','Ch2_Std_Dev','Ch1_Median','Ch2_Median','Ch1_B-value','Ch2_B-value'});

T.Properties.RowNames = myrownames;
writetable(T, [workingDir,filename,'_Correlation_Summary.csv'],'WriteRowNames',true);
    

    