function factorData = sFactor_T1_006(data,para)
% ====================上下行波动率因子==================
% type1:对应上下行的Type1
% type2:对应上下行的Type2
% 上行波动率/下行波动率
% --------------输入变量-------------------
% data.Price;data.Date;
% para.dateST;para.dateED;para.type;para.win1;para.win2
% win1:计算收益率的win，win2:计算波动率的win
% --------------输出变量------------------
% factorData:col1-日期，面板数据
% --------------处理过程------------------
% 上行inf,下行有值:全为负收益，-inf
% 上行有值，下行inf:全为正收益，inf
% 上下行均为nan:数据缺失，nan
% 数据不做时序上的补全

dateBasic = data.Date;

dateST = para.dateST;
dateED = para.dateED;

paraR.PType = para.PType;
paraR.win1 = para.win1;
paraR.dateST = dateBasic(1);
paraR.dateED = dateBasic(end);
paraR.type = para.type;
paraR.win2 = para.win2;
upV = sFactor_T1_004(data,paraR);
dnV = sFactor_T1_005(data,paraR);

upV(:,1) = []; %去掉日期序列
dnV(:,1) = [];

factorData = nan(size(upV));
for d = 1:length(dateBasic) %按天
    upVtmp = upV(d,:);
    dnVtmp = dnV(d,:);
    upNan = find(isinf(upVtmp));
    dnNan = find(isinf(dnVtmp));
    onlyUpNan = setdiff(upNan,dnNan); %仅上行为nan
    onlyDnNan = setdiff(dnNan,upNan); %仅下行为nan
    vltmp = upVtmp./dnVtmp;
    vltmp(onlyUpNan) = -inf;
    vltmp(onlyDnNan) = inf;
    factorData(d,:) = vltmp;
end

factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据