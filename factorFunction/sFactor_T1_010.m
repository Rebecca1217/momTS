function factorData = sFactor_T1_010(data,para)
% ===========RSI因子==================
% rsi(t)=sma(max(c(t)-c(t-1),0),win,1)/sma(abs(c(t)-c(t-1)),win,1)*100
% 缺失数据做了时序上的补全
% -----------输入变量---------------
% data.FPath;data.AddPath;data.Date;data.fut_variety
% FPath:期货数据路径，AddPath:补充数据路径
% para.win;para.PType;para.dateST;para.dateED-需要的日期
% -----------输出变量---------------
% factorData:col1-日期，面板数据
% 整理考虑了换月的影响，换月当日的价差，用新合约当天的价格与其前一天的价格计算

dateBasic = data.Date;
FPath = data.FPath; %主力合约数据路径
AddPath = data.AddPath; %主力合约补充数据路径
fut_variety = data.fut_variety;

win = para.win;
PType = para.PType; %价格数据
dateST = para.dateST;
dateED = para.dateED;

% 整理出价差数据
spread = nan(length(dateBasic),length(fut_variety));
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % 导入主力合约数据
    load([FPath,'\',fut,'.mat'])
    dateF = futureData.Date;
    str = ['priceF = futureData.',PType,';'];
    eval(str)
    % 数据补全
    priceF = getIntersect(priceF,dateBasic,dateF);
    priceF = getFullTS(priceF);
    try
        % 导入主力合约对应的补充数据
        load([AddPath,'\',fut,'.mat'])
        dateA = futureData.Date;
        str = ['priceA = futureData.',PType,';'];
        eval(str)
    catch %该品种还没换过月
        spread(:,i_fut) = [nan;diff(priceF)];
        continue;
    end
    % 求价差
    tmp = [nan;diff(priceF)];
    % 对换月的时候的数据进行调整
    [~,chgLBF,liA] = intersect(dateBasic,dateA); %换月的前一日所在行
    if isempty(chgLBF)
        spread(:,i_fut) = tmp;
        continue;       
    else
        if chgLBF(end)==length(dateBasic) %在数据截止日期的后一天换的月，那这一天在当前不用处理
            chgLBF(end) = [];
            liA(find(dateA==dateBasic(end),1)) = [];
        end
        tmp(chgLBF+1) = priceF(chgLBF+1)-priceA(liA); %新主力合约当天的收盘价与其前一天的收盘价之差
        spread(:,i_fut) = tmp;
    end
end
    

factorData = tech_RSI(spread,win);
factorData = getFullTS(factorData); %时序上面补全数据
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据

end

function rsi = tech_RSI(data,win)
% 计算RSI
% 输入的data为价差数据

rsi = nan(size(data));
for c = 1:size(data,2)
    dif = data(:,c); %差值
    maxD = nanmax([dif,zeros(length(dif),1)],[],2); %最大值
    absD = abs(dif); %绝对值
    st = find(~isnan(maxD),1,'first');
    if isempty(st)
        continue;
    else
        rsi(:,c) = sma(maxD,win,1)./sma(absD,win,1);
    end
end
end
    
    
function avg = sma(data,win,m)

avg = nan(length(data),1);
st = find(~isnan(data),1,'first');
avg(st) = data(st);
if st~=length(avg)
    for i = st+1:length(avg)
        avg(i) = avg(i-1)*(1-m/win)+data(i)*m/win;
    end
end
avg = avg*100;
end
