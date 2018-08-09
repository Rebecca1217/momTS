function factorData = sFactor_T2_003(data,para)
% ===========年化升贴水因子==================
% (Spot-Price)/Price*365/N(d)
% 缺失数据做了时序上的补全
% -----------输入变量---------------
% data.Date;data.FPath;data.SPath;data.contPath;data.fut_variety
% Path：合约数据路径，到fut上一层
% fut_variety:不带后缀
% para.dateST;para.dateED-需要的日期
% -----------输出变量---------------
% factorData:col1-日期，面板数据
% 各个合约的数据先做补全，求距离到期日的天数时用自然日天数

dateBasic = data.Date;
FPath = data.FPath; %期货数据路径
SPath = data.SPath; %现货数据路径
contPath = data.contPath; %合约到期日数据路径
fut_variety = data.fut_variety; %

dateST = para.dateST;
dateED = para.dateED;

% 逐个品种处理
factorData = nan(length(dateBasic),length(fut_variety));
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % 导入数据
    load([FPath,'\',fut,'.mat']) %期货数据
    dataF = futureData;
    load([SPath,'\',fut,'.mat']) %现货数据
    dataS = futureData;
    load([contPath,'\',fut,'.mat']) %合约到期日
    ltdInfo = [str2double(dateInfo(:,1)),cell2mat(dateInfo(:,2:3))];
    % 与总的日期对齐
    priceF = getIntersect(dataF.Close,dateBasic,dataF.Date); %主力
    contF = getIntersect(str2double(dataF.mainCont),dateBasic,dataF.Date); %主力代码
    priceS = getIntersect(dataS.Close,dateBasic,dataS.Date); %现货
    % 补全数据
    priceF = getFullTS(priceF);
    contF = getFullTS(contF);
    priceS = getFullTS(priceS);
    % 求合约距离到期日的自然日天数
    dnumF = getDateNum(contF,dateBasic,ltdInfo);
    % 计算年化升贴水率
    factorData(:,i_fut) = (priceS-priceF)./priceF*365./dnumF;
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




