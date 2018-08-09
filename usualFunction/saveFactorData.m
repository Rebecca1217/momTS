function saveFactorData(ttData,factorPathI,fut_variety)
% 将面板因子数据切成截面数据存储

date = ttData(:,1);
data = ttData(:,2:end);

for d = 1:length(date)
    factorData = [fut_variety,num2cell(data(d,:))'];
    save([factorPathI,'\',num2str(date(d)),'.mat'],'factorData')
end