pathname = uigetdir();
pathname=[pathname,filesep];

allfiles = dir(pathname);
allfiles = allfiles(arrayfun(@(x) isfile([pathname,x.name]) && startsWith(x.name,'.')==0,allfiles));
allfilescells = arrayfun(@(y) [pathname,y.name],allfiles,'UniformOutput',false);

numofexps = size(allfilescells,1);
disp(['There are ' num2str(numofexps) ' files to organise']);
%%
for fileNo = 1:numofexps
    masterFile = allfilescells{fileNo};
    matchingFiles = find(arrayfun(@(x)... 
    (size(masterFile,2) == size(allfilescells{x},2) && all(masterFile == allfilescells{x}))...
    ||(size(masterFile,2)+3 == size(allfilescells{x},2) && all(masterFile == (allfilescells{x}(1:end-3))) && allfilescells{x}(end-2)=='_')...
    ,1:numofexps));

    if(size(matchingFiles,2)>1)
        movefile(allfilescells{fileNo},[allfilescells{fileNo} '_01']);
        
        workingDir = [pathname,allfiles(fileNo).name,filesep];
        if ~exist(workingDir, 'dir')
            mkdir(workingDir)%make a subfolder with that name
        end
        
        allfilescells{fileNo}=[allfilescells{fileNo} '_01'];

        for i=1:size(matchingFiles,2)
            movefile(allfilescells{matchingFiles(i)},workingDir);
        end
    end

end
