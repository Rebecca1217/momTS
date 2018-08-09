function factorData = sFactor_T2_001(data,para)
% ===========展期收益率因子==================
% (lnC(t,n)-lnC(t,f))/D(t,f)-D(t,n)*365
% 缺失数据做了时序上的补全
% -----------输入变量---------------
% data.Date;data.ZPath;data.CPath;data.contPath;data.fut_variety
% Path：合约数据路径，到fut上一层
% fut_variety:不带后缀
% para.dateST;para.dateED-需要的日期
% -----------输出变量---------------
% factorData:col1-日期，面板数据
% 各个合约的数据先做补全，求距离到期日的天数时用自然日天数
% -----------补充说明--------------
% 未对异常值进行处理，如果合约有变更，产生跳价可能是合约变更造成的
% 但是如果合约没有变更，但出现跳价，是某个合约发生了大的波动，对这种情况目前没有处理
% 但是之后是否要当异常值处理，需要考虑一下

dateBasic = data.Date;
ZPath = data.ZPath; %主力合约路径
CPath = data.CPath; %次主力合约路径
contPath = data.contPath; %合约到期日数据路径
fut_variety = data.fut_variety;

dateST = para.dateST;
dateED = para.dateED;

% 逐个品种处理
factorData = nan(length(dateBasic),length(fut_variety));
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % 导入数据
    load([ZPath,'\',fut,'.mat']) %主力    
    dataZ = futureData;
    load([CPath,'\',fut,'.mat']) %次主力
    dataC = futureData;
    load([contPath,'\',fut,'.mat']) %合约到期日数据
    ltdInfo = [str2double(dateInfo(:,1)),cell2mat(dateInfo(:,2:3))];
    % 与总的日期对齐
    priceZ = getIntersect(dataZ.Close,dateBasic,dataZ.Date); %主力
    contZ = getIntersect(str2double(dataZ.mainCont),dateBasic,dataZ.Date); %主力代码
    priceC = getIntersect(dataC.Close,dateBasic,dataC.Date); %次主力
    contC = getIntersect(str2double(dataC.secondCont),dateBasic,dataC.Date); %次主力代码
    % 补全数据
    priceZ = getFullTS(priceZ);
    contZ = getFullTS(contZ);
    priceC = getFullTS(priceC);
    contC = getFullTS(contC);
    % 求各个合约距离到期日的自然日天数
    dnumZ = getDateNum(contZ,dateBasic,ltdInfo);
    dnumC = getDateNum(contC,dateBasic,ltdInfo);
    % 计算展期收益率
    factorData(:,i_fut) = (log(priceZ)-log(priceC))./(dnumC-dnumZ)*365;
end
    
factorData = getFullTS(factorData); %时序上面补全数据
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据

end
         


function dnum = getDateNum(cont,dateBasic,ltdInfo)
% 计算合约距离到期日的自然日天数

info = nan(length(dateBasic),3);
info(:,1:2) = [cont,dateBasic];
contUni = unique(cont);
for c = 1:length(contUni)
    info(cont==contUni(c),3) = ltdInfo(ltdInfo(:,1)==contUni(c),3);
end
dnum = nan(length(dateBasic),1);
stL = find(~isnan(info(:,1)),1,'first');
dnum(stL:end) = datenum(num2str(info(stL:end,3)),'yyyymmdd')-datenum(num2str(info(stL:end,2)),'yyyymmdd');

end

    
    
