function factorData = sFactor_T1_005(data,para)
% ==================下行波动率因子================
% Type1:过去win天中找rtn<0
% Type2:找过去win个rtn<0
% --------------输入变量-------------------
% para.dateST;para.dateED;para.type;para.win1;para.win2
% win1:计算收益率的win，win2:计算波动率的win
% --------------输出变量------------------
% factorData:col1-日期，面板数据
% --------------处理过程------------------
% type1:数据缺失超过一半，记为nan；都是上行的收益，值为-inf
% type2:满足条件的收益个数不足窗口期长度，记为nan
% 不能做时序上面的数据补全

dateBasic = data.Date;

type = para.type;
win = para.win2;
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
if type==1 %过去win天找rtn<0
    % 先按日期，再按品种
    for d = win:length(dateBasic)
        tmp = rtnData(d-win+1:d,:);
        vltmp = nan(1,size(tmp,2));
        for c = 1:size(tmp,2)
            if sum(isnan(tmp(:,c)))>=win/2 %缺失的数据超过了窗口期长度的一半
                vltmp(c) = nan;
            else
                if sum(tmp(:,c)<0)==0 %窗口期内的收益均为正
                    vltmp(c) = -inf;
                else
                    vltmp(c) = std(tmp(tmp(:,c)<0,c));
                end
            end
        end
        factorData(d,:) = vltmp;
    end
elseif type==2 %找过去win个rtn<0
    % 按品种
    for c = 1:size(rtnData,2)
        tmp = rtnData(:,c);
        vltmp = nan(size(tmp));
        li = find(tmp<0); %负收益所在行
        if length(li)<win %负收益的个数达不到窗口期长度
            vltmp(:) = nan;
        else
            for d = li(win):length(tmp)
                litmp = li(find(li<=d,10,'last'));
                vltmp(d) = std(tmp(litmp));
            end
        end
        factorData(:,c) = vltmp;
    end
end
            
% factorData = getFullTS(factorData); %时序上面补全数据
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据