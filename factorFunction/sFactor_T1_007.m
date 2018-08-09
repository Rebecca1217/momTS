function factorData = sFactor_T1_007(data,para)
% ===========偏度因子==================
% skewness(win)
% 缺失数据做了时序上的补全
% -----------输入变量---------------
% data.Price;data.Date-数据缺失值为nan，用比例后复权数据；原始的日期
% para.win1;para.win2;para.dateST;para.dateED-需要的日期
% win1:计算收益率的窗口期参数；win2:计算偏度的窗口期参数
% -----------输出变量---------------
% factorData:col1-日期，面板数据
% 做时序上的补全

dateBasic = data.Date;


win2 = para.win2;
dateST = para.dateST;
dateED = para.dateED;

% 计算收益率-调用动量因子
paraR.win = para.win1;
paraR.PType = para.PType;
paraR.dateST = dateBasic(1);
paraR.dateED = dateBasic(end);
rtnData = sFactor_T1_001(data,paraR); %加上了日期序列
rtnData = rtnData(:,2:end); %去掉日期序列

factorData = nan(size(rtnData));
for d = win2:length(dateBasic)
    tmp = rtnData(d-win2+1:d,:);
    factorData(d,:) = skewness(tmp,0);
end

factorData = getFullTS(factorData); %时序上面补全数据
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据


