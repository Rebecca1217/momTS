function TargetPortfolio = get_ContiPortfolio(HoldingPortfolio,totalDate,futMainContPath)
% 将不连续的交易日持仓变为连续的交易日持仓
% t日记录t+1日的目标持仓
% 中间填补的时候要注意是否有合约发生换月！！！！！！不能简单的填充上去
if nargin==2
    futMainContPath = 'D:\期货数据2.0\商品期货主力合约代码';
end
tradeDate = cell2mat(HoldingPortfolio(:,2));
contiDate = totalDate(find(totalDate==tradeDate(1),1):end-1);
if length(tradeDate)==length(contiDate)
    TargetPortfolio = HoldingPortfolio;
    return;
end

TargetPortfolio = cell(length(contiDate),2);
TargetPortfolio(:,2) = num2cell(contiDate);

locs = find(ismember(contiDate,tradeDate));
locsPd = [locs,[locs(2:end);length(contiDate)]-1]; %要补充持仓的区间
locsPd(end,2) = length(contiDate);
for l = 1:size(locsPd,1)
    HoldingCont = HoldingPortfolio{l,1}(:,1);
    HoldingFut = regexp(HoldingCont,'\D*(?=\d)','match');
    HoldingFut = reshape([HoldingFut{:}],size(HoldingFut));
    HoldingHands = HoldingPortfolio{l,1}(:,2);
    tmpL = locsPd(l,1):locsPd(l,2);
    for t = tmpL(1):tmpL(end)
        dateI = contiDate(t);
        % 导入主力合约代码
        load([futMainContPath,'\',num2str(dateI),'.mat'])
        futcont = regexp(maincont(:,1),'\w*(?=\.)','match');
        futcont = reshape([futcont{:}],size(futcont)); %品种
        maincont = regexp(maincont(:,2),'\w*(?=\.)','match');
        maincont = reshape([maincont{:}],size(maincont)); %代码+月份
        %
        [~,~,li1] = intersect(HoldingFut,futcont,'stable');
        HoldingContI = maincont(li1);        
        TargetPortfolio{t,1} = [HoldingContI,HoldingHands];
    end
end

