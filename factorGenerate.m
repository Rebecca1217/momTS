% 生成因子
% 008-数据待补充

clear;
% 日期
stDate = 20080102;
edDate = 20180731;
ttDate = getDate(stDate,edDate);

% 路径
usualPath = '\\Cj-lmxue-dt\期货数据2.0\usualData';
dataPath = '\\Cj-lmxue-dt\期货数据2.0\dlyData';
factorPathT1 = 'E:\Repository\momTS\因子测试数据\T1';
factorPathT2 = 'E:\Repository\momTS\因子测试数据\T2';
% factorPathT3 = '\\Cj-lmxue-dt\期货数据2.0\因子测试数据\T3';
addpath('factorFunction')
addpath('usualFunction')
% 品种
load([usualPath,'\fut_variety.mat'])
fut_variety = regexp(fut_variety,'\w*(?=\.)','match');
fut_variety = reshape([fut_variety{:}],size(fut_variety));

% 流动性筛选之后的品种
load liquidityInfo.mat
[~,li0] = intersect(fut_variety,liquidityInfo); % 取交集
% 我理解~在这里是一个占位符，给[C, I(A), I(B)]中的C占位，但不保存结果，这里li0返回的是I(A）的值
% 交集的结果直接赋值给fut_liquid不可以吗，为什么要先给出index，后面也没有再用到..
fut_liquid = fut_variety(li0);

% 有对应现货的品种，没有对应现货的品种不计算年化升贴水
load([usualPath,'\spotGoods.mat'])
fut_spots = spotGoods(:,1);
%% 因子计算
% 价量因子
% 001-动量
D001.fut_variety = fut_variety;
D001.FPath = [dataPath,'\主力合约-比例后复权'];
D001.Date = ttDate;
P001.PType = 'Close';
P001.dateST = stDate;
P001.dateED = edDate;
winSet = 5:5:50; %序列初值：步长：终值
factorPathI = [factorPathT1,'\001\Ori\1'];
mkdir(factorPathI)
for w = 1:length(winSet)
    P001.win = winSet(w);
    factorData = sFactor_T1_001(D001,P001);
    mkdir([factorPathI,'\win',num2str(winSet(w))])
    saveFactorData(factorData,[factorPathI,'\win',num2str(winSet(w))],fut_variety);
end

% 002-开盘相对位置
D002.fut_variety = fut_variety;
D002.FPath = [dataPath,'\主力合约-比例后复权'];
D002.Date = ttDate;
P002.dateST = stDate;
P002.dateED = edDate;
winSet = 5:5:50;
factorPathI = [factorPathT1,'\002\Ori\1'];
mkdir(factorPathI)
for w = 1:length(winSet)
    P002.win = winSet(w);
    factorData = sFactor_T1_002(D002,P002);
    mkdir([factorPathI,'\win',num2str(winSet(w))])
    saveFactorData(factorData,[factorPathI,'\win',num2str(winSet(w))],fut_variety);
end

% 003-开盘跳价
D003.fut_variety = fut_variety;
D003.FPath = [dataPath,'\主力合约-比例后复权'];
D003.Date = ttDate;
P003.dateST = stDate;
P003.dateED = edDate;
factorPathI = [factorPathT1,'\003\Ori\1\win0'];
mkdir(factorPathI)
factorData = sFactor_T1_003(D003,P003);
saveFactorData(factorData,factorPathI,fut_variety);

% 004-上行波动率，两种类型，其中引用了factor001
D004.fut_variety = fut_variety;
D004.FPath = [dataPath,'\主力合约-比例后复权'];
D004.Date = ttDate;
P004.PType = 'Close';
P004.win1 = 1;
P004.dateST = stDate;
P004.dateED = edDate;
winSet = 10:5:50;
typeSet = 1:2;
factorPathI = [factorPathT1,'\004\Ori'];
mkdir(factorPathI)
for t = 1:length(typeSet)
    P004.type = typeSet(t);
    factorPathIt = [factorPathI,'\',num2str(P004.type)];
    mkdir(factorPathIt)
    for w = 1:length(winSet)
        P004.win2 = winSet(w);
        factorData = sFactor_T1_004(D004,P004);
        mkdir([factorPathIt,'\win',num2str(winSet(w))])
        saveFactorData(factorData,[factorPathIt,'\win',num2str(winSet(w))],fut_variety);
    end
end

% 005-下行波动率，两种类型，其中引用了factor001
D005.fut_variety = fut_variety;
D005.FPath = [dataPath,'\主力合约-比例后复权'];
D005.Date = ttDate;
P005.PType = 'Close';
P005.win1 = 1;
P005.dateST = stDate;
P005.dateED = edDate;
winSet = 10:5:50;
typeSet = 1:2;
factorPathI = [factorPathT1,'\005\Ori'];
mkdir(factorPathI)
for t = 1:length(typeSet)
    P005.type = typeSet(t);
    factorPathIt = [factorPathI,'\',num2str(P005.type)];
    mkdir(factorPathIt)
    for w = 1:length(winSet)
        P005.win2 = winSet(w);
        factorData = sFactor_T1_005(D005,P005);
        mkdir([factorPathIt,'\win',num2str(winSet(w))])
        saveFactorData(factorData,[factorPathIt,'\win',num2str(winSet(w))],fut_variety);
    end
end

    
% 006-上下行波动率，两种类型，其中引用了factor001
D006.fut_variety = fut_variety;
D006.FPath = [dataPath,'\主力合约-比例后复权'];
D006.Date = ttDate;
P006.PType = 'Close';
P006.win1 = 1;
P006.dateST = stDate;
P006.dateED = edDate;
winSet = 10:5:50;
typeSet = 1:2;
factorPathI = [factorPathT1,'\006\Ori'];
mkdir(factorPathI)
for t = 1:length(typeSet)
    P006.type = typeSet(t);
    factorPathIt = [factorPathI,'\',num2str(P006.type)];
    mkdir(factorPathIt)
    for w = 1:length(winSet)
        P006.win2 = winSet(w);
        factorData = sFactor_T1_006(D006,P006);
        mkdir([factorPathIt,'\win',num2str(winSet(w))])
        saveFactorData(factorData,[factorPathIt,'\win',num2str(winSet(w))],fut_variety);
    end
end
    
% 007-偏度，其中引用了factor001
D007.fut_variety = fut_variety;
D007.FPath = [dataPath,'\主力合约-比例后复权'];
D007.Date = ttDate;
P007.PType = 'Close';
P007.win1 = 1; %计算收益率的窗口期
P007.dateST = stDate;
P007.dateED = edDate;
winSet = 10:5:50;
factorPathI = [factorPathT1,'\007\Ori\1'];
mkdir(factorPathI)
for w = 1:length(winSet)
    P007.win2 = winSet(w); %计算偏度的窗口期
    factorData = sFactor_T1_007(D007,P007);
    mkdir([factorPathI,'\win',num2str(winSet(w))])
    saveFactorData(factorData,[factorPathI,'\win',num2str(winSet(w))],fut_variety);
end

% 008-换手率，现在用的是主力合约的换手率
type = 1; %1:主力合约数据，2：所有合约加总
D008.fut_variety = fut_variety;
if type==1
    D008.FPath = [dataPath,'\主力合约'];
end
D008.Date = ttDate;
P008.dateST = stDate;
P008.dateED = edDate;
factorPathI = [factorPathT1,'\008\Ori\',num2str(type)];
mkdir(factorPathI)
factorData = sFactor_T1_008(D008,P008);
saveFactorData(factorData,factorPathI,fut_variety);

% 009-沉淀资金,进行了流动性筛选
D009.fut_variety = fut_liquid;
D009.FPath = 'D:\期货数据2.0\ContinuousData00';
D009.depPath = [usualPath,'\DepositInfo.mat'];
D009.punitPath = [usualPath,'\PunitInfo.mat'];
D009.Date = ttDate;
P009.dateST = stDate;
P009.dateED = edDate;
typeSet = {'Settle';'Close'}; %Settle:1,Close:2
factorPathI = [factorPathT1,'\009\Ori'];
mkdir(factorPathI)
for t = 1:length(typeSet)
    P009.PType = typeSet{t};    
    factorData = sFactor_T1_009(D009,P009);
    mkdir([factorPathI,'\',num2str(t)])
    saveFactorData(factorData,[factorPathI,'\',num2str(t)],fut_liquid);
end

% 010-RSI
D010.fut_variety = fut_variety;
D010.FPath = [dataPath,'\主力合约'];
D010.AddPath = [dataPath,'\主力合约补充'];
D010.Date = ttDate;
P010.dateST = stDate;
P010.dateED = edDate;
P010.PType = 'Close';
winSet = [14,5:5:50];
factorPathI = [factorPathT1,'\010\Ori\1'];
mkdir(factorPathI)
for w = 1:length(winSet)
    P010.win = winSet(w);    
    factorData = sFactor_T1_010(D010,P010);
    mkdir([factorPathI,'\win',num2str(winSet(w))])
    saveFactorData(factorData,[factorPathI,'\win',num2str(winSet(w))],fut_variety);
end

%% 期现结构因子
% 001-展期收益率因子
D001.fut_variety = fut_liquid;
D001.ZPath = [dataPath,'\主力合约'];
D001.CPath = [dataPath,'\次主力合约'];
D001.contPath = [usualPath,'\ContractDateInfo'];
D001.Date = ttDate;
P001.dateST = stDate;
P001.dateED = edDate;
factorPathI = [factorPathT2,'\001\Ori\1'];
mkdir(factorPathI)
factorData = sFactor_T2_001(D001,P001);
saveFactorData(factorData,factorPathI,fut_liquid);

% 002-展期收益率因子
D002.fut_variety = fut_liquid;
D002.NPath = [dataPath,'\近远月合约\近月合约'];
D002.NAddPath = [dataPath,'\近远月合约\近月合约补充'];
D002.FPath = [dataPath,'\近远月合约\远月合约'];
D002.FAddPath = [dataPath,'\近远月合约\远月合约补充'];
D002.Date = ttDate;
P002.dateST = stDate;
P002.dateED = edDate;
P002.PType = 'Close';
winSet = 5:5:50;
factorPathI = [factorPathT2,'\002\Ori\1'];
mkdir(factorPathI)
for w = 1:length(winSet)
    P002.win = winSet(w);
    factorData = sFactor_T2_002(D002,P002);
    mkdir([factorPathI,'\win',num2str(P002.win)])
    saveFactorData(factorData,[factorPathI,'\win',num2str(P002.win)],fut_liquid);
end

% 003-年化升贴水因子
D003.fut_variety = fut_spots;
D003.FPath = [dataPath,'\主力合约'];
D003.SPath = 'D:\期货数据2.0\SpotGoodsData';
D003.contPath = [usualPath,'\ContractDateInfo'];
D003.Date = ttDate;
P003.dateST = stDate;
P003.dateED = edDate;
factorPathI = [factorPathT2,'\003\Ori\1'];
mkdir(factorPathI)
factorData = sFactor_T2_003(D003,P003);
saveFactorData(factorData,factorPathI,fut_spots);