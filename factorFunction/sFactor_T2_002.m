function factorData = sFactor_T2_002(data,para)
% ===========期限结构变动因子==================
% 近月合约累计收益-远月合约累计收益
% 缺失数据做了时序上的补全
% -----------输入变量---------------
% data.Date;data.NPath;data.NAddPath;data.FPath;data.FAddPath;data.fut_variety
% Path：合约数据路径，到fut上一层
% fut_variety:不带后缀
% para.win;para.PType;para.dateST;para.dateED-需要的日期
% -----------输出变量---------------
% factorData:col1-日期，面板数据
% 用未复权数据去做，先分别计算近月和远月合约每日的收益率，然后再计算累计收益

dateBasic = data.Date;
NPath = data.NPath; %近月合约路径
NAddPath = data.NAddPath;
FPath = data.FPath; %远月合约路径
FAddPath = data.FAddPath;
fut_variety = data.fut_variety;

win = para.win;
PType = para.PType;
dateST = para.dateST;
dateED = para.dateED;

% 逐个品种计算每日的收益率-近月和远月
rtnN = getRtn(NPath,NAddPath,dateBasic,fut_variety,PType);
rtnF = getRtn(FPath,FAddPath,dateBasic,fut_variety,PType);

% 计算累计收益率之差
factorData = nan(length(dateBasic),length(fut_variety));
for d = win:length(dateBasic)
    cumRtnN = cumprod(1+rtnN(d-win+1:d,:));
    cumRtnF = cumprod(1+rtnF(d-win+1:d,:));
    factorData(d,:) = cumRtnN(end,:)-cumRtnF(end,:);
end

factorData = getFullTS(factorData); %时序上面补全数据
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据

end
   

function rtn = getRtn(ZPath,AddPath,dateBasic,fut_variety,PType)
% 计算每日的收益率

rtn = nan(length(dateBasic),length(fut_variety));
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % 导入合约数据
    load([ZPath,'\',fut,'.mat'])
    str = ['priceF = futureData.',PType,';'];
    eval(str)
    date = futureData.Date;
    priceF = getIntersect(priceF,dateBasic,date);
    priceF = getFullTS(priceF);
    try
        % 导入合约补充数据
        load([AddPath,'\',fut,'.mat'])
        dateA = futureData.Date;
        str = ['priceA = futureData.',PType,';'];
        eval(str)
    catch %该品种没换过月
        rtn(:,i_fut) = [nan;tick2ret(priceF)];
    end
    % 求收益率
    tmp = [nan;tick2ret(priceF)];
    % 对换月的数据进行调整
    [~,chgLBF,liA] = intersect(dateBasic,dateA); %换月的前一日所在行
    if isempty(chgLBF)
        rtn(:,i_fut) = tmp;
        continue;
    else
        if chgLBF(end)==length(dateBasic) %在数据截止日期的后一天换的月，那这一天在当前不用处理
            chgLBF(end) = [];
            liA(find(dateA==dateBasic(end),1)) = [];
        end
  
        tmp(chgLBF+1) = priceF(chgLBF+1)./priceA(liA)-1;
        rtn(:,i_fut) = tmp;
    end   
end
end


function dataAim = getIntersect(data,dateAim,dateD)
% 将数据与dateAim对齐

[~,li0,li1] = intersect(dateAim,dateD);
dataAim = nan(length(dateAim),1);
dataAim(li0) = data(li1);
end

function dnum = getDateNum(cont,dateBasic,ltdInfo)
% 计算合约距离到期日的自然日天数

info = zeros(length(dateBasic),3);
info(:,1:2) = [cont,dateBasic];
contUni = unique(cont);
for c = 1:length(contUni)
    info(cont==contUni(c),3) = ltdInfo(ltdInfo(:,1)==contUni(c),3);
end
dnum = datenum(num2str(info(:,3)),'yyyymmdd')-datenum(num2str(info(:,2)),'yyyymmdd');

end

    
    
