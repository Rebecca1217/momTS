function factorData = sFactor_T1_009(data,para)
% ===========沉淀资金因子==================
% sum(Price*OI*合约乘数*保证金比例)
% price用收盘价或者结算价
% 缺失数据做了时序上的补全
% -----------输入变量---------------
% data.FPath;data.fut_variety;data.punitPath;data.depPath;data.Date
% punit,dep路径具体到mat文件;FPath到fut的上一层
% para.dateST;para.dateED;para.priceType-需要的日期
% priceType:Close，Settle
% -----------输出变量---------------
% factorData:col1-日期，面板数据
% -----------处理过程---------------
% 先对单个月份合约进行补全，然后合成总的沉淀资金，再次补全

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;
depPath = data.depPath;
punitPath = data.punitPath;

dateST = para.dateST;
dateED = para.dateED;
pType = para.PType;

% 逐个品种处理-逐个合约
factorData = zeros(length(dateBasic),length(fut_variety));
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % 导入合约乘数和保证金比例
    load(depPath,fut)
    str = ['DepositInfo = ',fut,'.DepositInfo;'];
    eval(str)
    load(punitPath,fut)
    str = ['PunitInfo = ',fut,'.PunitInfo;'];
    eval(str)
    % 与总的日期对齐
    DepositInfo = getIntersect(DepositInfo(:,2),dateBasic,DepositInfo(:,1));
    PunitInfo = getIntersect(PunitInfo(:,2),dateBasic,PunitInfo(:,1));
    DepositInfo = getFullTS(DepositInfo);
    PunitInfo = getFullTS(PunitInfo);
    
    futFiles = dir([FPath,'\',fut]);
    futFiles = {futFiles(3:end).name};
    money = nan(length(dateBasic),1);
    for i = 1:length(futFiles) %逐个合约
        load([FPath,'\',fut,'\',futFiles{i}])
        str = ['price = futureData.',pType,';'];
        eval(str) %价格
        Interest = futureData.Interest; %持仓
        date = futureData.Date; %日期
        % 与总的日期对齐
        price = getIntersect(price,dateBasic,date);
        price = getFullTS(price);
        Interest = getIntersect(Interest,dateBasic,date);
        Interest = getFullTS(Interest);
        % 计算该合约的沉淀资金
        tmp = price.*Interest.*PunitInfo.*DepositInfo;
        nanL = find(and(isnan(money),isnan(tmp))); %找出数据缺失的行
        money = nansum([money,tmp],2); %因为如果money和tmp均为nan，使用nansum之后，和为0
        money(nanL) = nan;
        money = getFullTS(money); %数据补全
    end
    factorData(:,i_fut) = money;
end
        
factorData = getFullTS(factorData); %时序上面补全数据
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据
end

   
        
function dataAim = getIntersect(data,dateAim,dateD)
% 将数据与dateAim对齐

[~,li0,li1] = intersect(dateAim,dateD);
dataAim = nan(length(dateAim),1);
dataAim(li0) = data(li1);
end




    
    
