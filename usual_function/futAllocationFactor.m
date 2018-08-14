function [HoldingInfo,HoldingInfoTM] = futAllocationFactor(wgtType,Cap,paraAlc,totaldate)
% 根据不同权重配置方式确定各个品种的持仓手数和权重
% 要考虑各期的样本池，在样本池内确定权重和手数
% 仅对板块内符合流动性要求的品种分配权重
% t日的开仓手数就记录在t行

% 本金
capital = Cap.Capital; %开仓市值
% 通用路径
tdDPath = paraAlc.tdDPath;
usualPath = paraAlc.usualPath;
futLiquidPath = paraAlc.futLiquidPath;
futSectorPath = paraAlc.futSectorPath;

% 板块对应的品种
IndustryChoice = paraAlc.IndustryChoice;
load(futSectorPath,IndustryChoice)
str = ['fut_variety = ',IndustryChoice,';'];
eval(str) 

% 合约乘数
% 合约乘数会变的话是不是不能用最新，要每天用自己的？
% 目前先暂时用edDate的乘数
load([usualPath,'\PunitInfo\', num2str(edDate), '.mat'])
[~,~,li1] = intersect(fut_variety,infoData(:,1),'stable'); %顺序问题
contMulti = infoData(li1,:);
contMulti = cell2mat(contMulti(:,2)); % 这里出的结果比fut_variety少一个种类。。
% 顺序问题都可以用table join来解决
% 
if strcmpi(wgtType,'eqATR')
    ATRpath = paraAlc.ATRpath;
    budget = paraAlc.budget;
    % 导入ATR数据
    ATRData = nan(length(totaldate),length(fut_variety)+1);
    ATRData(:,1) = totaldate;
    for i_fut = 1:length(fut_variety)
        fut = fut_variety{i_fut};
        % 导入数据
        load([ATRpath,'\',fut,'.mat'])
        dateATR = ATRindex(:,1);
        dataATR = ATRindex(:,end);
        % 数据对齐
        [~,li0,li1] = intersect(dateATR,totaldate);
        ATRData(li1,i_fut+1) = dataATR(li0)*contMulti(i_fut); %ATR数据用合约乘数调整了
    end
    % 计算持仓比例
    % 0.按照流动性对品种进行筛选
    % 1.按照风险配平确定每个品种的手数
    % 2.将手数换算成每个品种的开仓市值
    % 3.根据可开仓的初始市值计算出每个品种实际可开仓市值
    % 4.将实际开仓市值换算成每个品种的开仓手数
    % 0.流动性
    for d = 1:length(totaldate)
        load([futLiquidPath,'\',num2str(totaldate(d)),'.mat'])
        [~,li0] = setdiff(fut_variety,liquidityInfo);
        ATRData(d,li0+1) = nan;
    end
    % 1.手数
    HoldingHandsOri = round(budget./ATRData(:,2:end)); %手数
    % 2.按照手数换算成开仓市值
    % 导入主力合约价格数据-用来计算真实占比
    mainData = nan(length(totaldate),length(fut_variety)+1);
    mainData(:,1) = totaldate;
    for i_fut = 1:length(fut_variety)
        fut = fut_variety{i_fut};
        % 导入数据
        load([tdDPath,'\',fut,'.mat']) %真实合约数据
        clData = futureData.Close;
        dateMain = futureData.Date;
        % 数据对齐
        [~,li0,li1] = intersect(dateMain,totaldate);
        mainData(li1,i_fut+1) = clData(li0)*contMulti(i_fut); %收盘价数据用合约乘数调整了
    end
    for d = 1:length(totaldate)
        load([futLiquidPath,'\',num2str(totaldate(d)),'.mat'])
        [~,li0] = setdiff(fut_variety,liquidInfo);
        mainData(d,li0+1) = nan;
    end
    totalSize = HoldingHandsOri.*mainData(:,2:end);
    totalSizeDly = nansum(totalSize,2);
    HoldingWgtOri = bsxfun(@times,totalSize,repmat(1./totalSizeDly,1,size(totalSize,2)));
    % 3.市值换算
    HoldingSize = HoldingWgtOri*capital; %预先分配的开仓市值
    % 4.手数换算
    HoldingHands = round(HoldingSize./mainData(:,2:end));
    realSize = HoldingHands.*mainData(:,2:end);
    realSizeDly = nansum(realSize,2);
    HoldingWgt = bsxfun(@times,realSize,repmat(1./realSizeDly,1,size(realSize,2)));
    %
    HoldingInfo.Hands = [totaldate,[nan(1,length(fut_variety));HoldingHands(1:end-1,:)]];
    HoldingInfo.Size = [totaldate,[nan(1,length(fut_variety));realSize(1:end-1,:)]]; %实际开仓市值（根据前一天的收盘价计算）
    HoldingInfo.NomSize = [totaldate,[nan(1,length(fut_variety));HoldingSize(1:end-1,:)]]; %分配的开仓市值
    HoldingInfo.Weight = [totaldate,[nan(1,length(fut_variety));HoldingWgt(1:end-1,:)]]; %实际的权重占比
    HoldingInfo.NomWeight = [totaldate,[nan(1,length(fut_variety));HoldingWgtOri(1:end-1,:)]]; %分配的权重
elseif strcmpi(wgtType,'eqSize')
    % 导入主力合约数据
    mainData = nan(length(totaldate),length(fut_variety)+1);
    mainData(:,1) = totaldate;
    % 下面这个for 用来获取收盘价*合约乘数数据集
    for i_fut = 1:length(fut_variety)
        fut = fut_variety{i_fut};
        % 导入数据
        load([tdDPath,'\',fut,'.mat']) %真实合约数据
        clData = futureData.Close;
        dateMain = futureData.Date;
        % 数据对齐
        [~,li0,li1] = intersect(dateMain,totaldate);
        mainData(li1,i_fut+1) = clData(li0)*contMulti(i_fut); %收盘价数据用合约乘数调整了
    end % 如果用table的数据格式，这个for是没有必要的，这个for完成的是每个品种做一次一共循环了48次得到mainData的每一列
    % 下面这个for用于去掉非流动性部分的数据
    for d = 1:length(totaldate)
        load([futLiquidPath,'\',num2str(totaldate(d)),'.mat'])
        [~,li0] = setdiff(fut_variety,liquidityInfo);
        mainData(d,li0+1) = nan;
    end
    % 手数换算
    ListNum = sum(~isnan(mainData(:,2:end)),2); %计算当期上市的品种数
    HoldingSize = repmat(capital./ListNum,1,length(fut_variety));
    HoldingSize(isnan(mainData(:,2:end))) = nan; % 对每天的可流动品种平均分配本金
    HoldingHands = round(HoldingSize./mainData(:,2:end)); 
    realSize = HoldingHands.*mainData(:,2:end);
    realSizeDly = nansum(realSize,2);
    HoldingWgt = bsxfun(@times,realSize,repmat(1./realSizeDly,1,size(realSize,2)));
    HoldingWgtOri = repmat(1./ListNum,1,size(realSize,2));
    HoldingWgtOri(isnan(mainData(:,2:end))) = nan;
    % 都往下挪一行，根据t-1日的价格确定t日的开仓手数，记录在t行
    HoldingInfo.Hands = [totaldate,[nan(1,length(fut_variety));HoldingHands(1:end-1,:)]];
    HoldingInfo.Size = [totaldate,[nan(1,length(fut_variety));realSize(1:end-1,:)]]; %实际开仓市值
    HoldingInfo.NomSize = [totaldate,[nan(1,length(fut_variety));HoldingSize(1:end-1,:)]]; %分配的开仓市值
    HoldingInfo.Weight = [totaldate,[nan(1,length(fut_variety));HoldingWgt(1:end-1,:)]];
    HoldingInfo.NomWeight = [totaldate,[nan(1,length(fut_variety));HoldingWgtOri(1:end-1,:)]]; %分配的权重

elseif strcmpi(wgtType,'fixSize') %单个品种的开仓市值是固定的
    % 导入主力合约数据
    mainData = nan(length(totaldate),length(fut_variety)+1);
    mainData(:,1) = totaldate;
    for i_fut = 1:length(fut_variety)
        fut = fut_variety{i_fut};
        % 导入数据
        load([tdDPath,'\',fut,'.mat']) %真实合约数据
        clData = futureData.Close;
        dateMain = futureData.Date;
        % 数据对齐
        [~,li0,li1] = intersect(dateMain,totaldate);
        mainData(li1,i_fut+1) = clData(li0)*contMulti(i_fut); %收盘价数据用合约乘数调整了
    end
    % 手数换算
    HoldingSize = repmat(capital,length(mainData),length(fut_variety));
    HoldingSize(isnan(mainData(:,2:end))) = nan;
    HoldingHands = round(HoldingSize./mainData(:,2:end));
    realSize = HoldingHands.*mainData(:,2:end);
    realSizeDly = nansum(realSize,2);
    HoldingWgt = bsxfun(@times,realSize,repmat(1./realSizeDly,1,size(realSize,2)));
    %
    HoldingInfo.Hands = [totaldate,[nan(1,length(fut_variety));HoldingHands(1:end-1,:)]];
    HoldingInfo.Size = [totaldate,[nan(1,length(fut_variety));realSize(1:end-1,:)]]; %实际开仓市值
    HoldingInfo.NomSize = [totaldate,[nan(1,length(fut_variety));HoldingSize(1:end-1,:)]]; %分配的开仓市值
    HoldingInfo.Weight = [totaldate,[nan(1,length(fut_variety));HoldingWgt(1:end-1,:)]]; %实际的权重占比
end

HoldingInfoTM.Hands = HoldingInfo.Hands(end,:);
HoldingInfoTM.Size = HoldingInfo.Size(end,:);
HoldingInfoTM.NomSize = HoldingInfo.NomSize(end,:);
HoldingInfoTM.Weight = HoldingInfo.Weight(end,:);
HoldingInfoTM.NomWeight = HoldingInfo.NomWeight(end,:);

HoldingInfo.Hands(end,:) = [];
HoldingInfo.Size(end,:) = [];
HoldingInfo.NomSize(end,:) = [];
HoldingInfo.Weight(end,:) = [];
HoldingInfo.NomWeight(end,:) = [];

HoldingInfo.fut_variety = fut_variety;
