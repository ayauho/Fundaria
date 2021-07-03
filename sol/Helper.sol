// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "./ISwapRouter.sol";
import "./IPool.sol";

    struct InvestedData {
        address investmentGuide;
        bool rejectedWithdrawal;
        uint investmentGuideRewardAvailableTotal;
        uint investmentGuideReward;
        uint investmentGuideClaimedReward;
        uint scoin;
        uint quantity;      
        uint withdrawn;
        uint toTeam;
        uint toPlatform;        
    }    

    struct Voting {
        uint startTime;
        uint endTime;
        uint8 typo;
        uint quorumCount;
        uint adressMaxCount;
        address addressPropositionMaxCount;
        uint uintCount;
        uint uintSum;
        bool resultsApplied;
    }



library Helper {
    uint constant m = 1000000000;

    struct PrepareInvestData {
        uint8 phase;
        SwapRouter swapRouter; 
        address scoinAddress; 
        uint poolCap;
        uint sharePrice;
        address investmentGuide; 
        bool rejectedWithdrawal;    
    }

    struct PrepareWithdrawData {
        uint16 shortFinancePeriodsCount;
        uint igrat;
        uint nowShortFinancePeriodNum;
        uint scoinBalance;
        address platformAddress;
        uint8 phase;    
    }    

    function coinToScoin(uint coin, SwapRouter swapRouter, address scoinAddress) public view returns(uint[] memory amounts) {
        if(coin==0) return new uint[](2);
        address[] memory path = new address[](2);   
        path[0] = swapRouter.WETH();
        path[1] = scoinAddress;
        amounts = swapRouter.getAmountsOut(coin, path);
    }

    function scoinToCoin(uint scoin, SwapRouter swapRouter, address scoinAddress) public view returns(uint[] memory amounts) {
        if(scoin==0) return new uint[](2);
        address[] memory path = new address[](2);   
        path[1] = swapRouter.WETH();
        path[0] = scoinAddress;
        amounts = swapRouter.getAmountsOut(scoin, path);              
    }

	function swapCoinToScoin(uint coin, uint scoin, SwapRouter swapRouter, address scoinAddress) public returns(uint) {
    	if(coin==0) return 0;
        if(scoin==0) scoin = coinToScoin(coin, swapRouter, scoinAddress)[1] * 95/100;       
    	address[] memory path = new address[](2);
    	path[0] = swapRouter.WETH();
    	path[1] = scoinAddress;
    	return swapRouter.swapExactETHForTokens{value:coin}(scoin, path, address(this), block.timestamp+5)[1];         
    }
    function swapScoinToCoin(uint scoin, uint coin, SwapRouter swapRouter, address scoinAddress) public returns(uint) {
        if(scoin==0) return 0;
        if(coin==0) coin = scoinToCoin(scoin, swapRouter, scoinAddress)[1] * 95/100;        
        address[] memory path = new address[](2);
        path[1] = swapRouter.WETH();
        path[0] = scoinAddress;
        return swapRouter.swapExactTokensForETH(scoin, coin, path, address(this), block.timestamp+5)[1];           
    }
    function investStep1(InvestedData storage investedData, SwapRouter swapRouter, address scoinAddress, uint poolCap, uint sharePrice, address investmentGuide, bool rejectedWithdrawal, uint[] storage investedTotal, uint8 phase) public returns(uint, uint, uint) {
        require(msg.value>0, 'Coin sent should be positive number');                 
        PrepareInvestData memory prepareInvestData = PrepareInvestData(phase,swapRouter,scoinAddress,poolCap,sharePrice,investmentGuide,rejectedWithdrawal);
        if(investmentGuide!=address(0) && investmentGuide!=investedData.investmentGuide) 
           investedData.investmentGuide = prepareInvestData.investmentGuide;   
        investedData.rejectedWithdrawal = bool(prepareInvestData.rejectedWithdrawal);         
        uint scoin = swapCoinToScoin(msg.value, 0, prepareInvestData.swapRouter,prepareInvestData.scoinAddress);
        uint tryPool;
        uint scoinRemnant;
        if(prepareInvestData.poolCap>0) {
            tryPool = scoin + investedTotal[prepareInvestData.phase];
            if(tryPool>prepareInvestData.poolCap) {
                scoinRemnant = tryPool - prepareInvestData.poolCap;
                scoin -= scoinRemnant;
            }
        }
        require(scoin>=prepareInvestData.sharePrice, 'Not enough stable coin');
        uint quantity = scoin / prepareInvestData.sharePrice;       
        uint realScoin = quantity * prepareInvestData.sharePrice;        
        uint dif = scoin - realScoin;
        if(dif>0) scoinRemnant += dif;
        investedTotal[prepareInvestData.phase] += realScoin;
        return (quantity, realScoin, scoinRemnant);
    }

    function investStep2(InvestedData storage investedData, uint realScoin, uint8 investmentGuidesRewardShare, uint8 phase, uint[] storage investmentGuideRewards) public {
        investedData.scoin += realScoin;        
        if(investedData.investmentGuide != address(0) && investmentGuidesRewardShare > 0) {
           uint investmentGuideReward = (realScoin * investmentGuidesRewardShare) / 100;
           investedData.investmentGuideReward += investmentGuideReward;
           investmentGuideRewards[phase] += investmentGuideReward;
        }
    }

    function investStep3(InvestedData storage investedData, mapping(address => uint256) storage _balances, mapping(address => uint256)[16] storage balancesLocked, uint8 phase, uint8 saleShare, uint8 teamShare, uint8 platformShare, uint quantity, address owner, address platformAddress) public returns(uint256) {
        investedData.quantity += quantity;
        uint toPlatform;
        uint toTeam = (teamShare * quantity) / saleShare;
        investedData.toTeam += toTeam;                
        _balances[msg.sender] += quantity;
        balancesLocked[phase][owner] += toTeam;
        if(platformAddress != address(0)){
            toPlatform = (platformShare * quantity) / saleShare;
            investedData.toPlatform += toPlatform;
            balancesLocked[phase][platformAddress] += toPlatform;            
        }        
        return (quantity + toTeam + toPlatform);                        
    }

    function withdrawInvestment1(InvestedData storage investedData, address owner, mapping(address => uint256)[16] storage balancesLocked, uint8 phase, uint16 shortFinancePeriodsCount, uint igrat, uint nowShortFinancePeriodNum, uint scoinBalance, address platformAddress) public returns(uint toWithdraw, uint burned) {
        PrepareWithdrawData memory prepareWithdrawData = PrepareWithdrawData(shortFinancePeriodsCount,igrat,nowShortFinancePeriodNum,scoinBalance,platformAddress,phase);               
        require(!investedData.rejectedWithdrawal, 'Investor rejected to withdraw its investment');
        require(investedData.withdrawn==0, 'Investor withdrew its investment already');        
        toWithdraw = ((prepareWithdrawData.shortFinancePeriodsCount - prepareWithdrawData.nowShortFinancePeriodNum) * investedData.scoin) / prepareWithdrawData.shortFinancePeriodsCount;
        require(prepareWithdrawData.scoinBalance>=toWithdraw, 'Pool stable coin balance is not enough');       
        investedData.investmentGuideRewardAvailableTotal = prepareWithdrawData.igrat;
        investedData.withdrawn = toWithdraw;                       
        uint burnedFromTeam = (prepareWithdrawData.shortFinancePeriodsCount-prepareWithdrawData.nowShortFinancePeriodNum) * investedData.toTeam / prepareWithdrawData.shortFinancePeriodsCount;        
        investedData.toTeam -= burnedFromTeam;        
        uint burnedFromPlatform = (prepareWithdrawData.shortFinancePeriodsCount-prepareWithdrawData.nowShortFinancePeriodNum) * investedData.toPlatform / prepareWithdrawData.shortFinancePeriodsCount;
        if(prepareWithdrawData.platformAddress!=address(0)) {
            balancesLocked[prepareWithdrawData.phase][prepareWithdrawData.platformAddress] -= burnedFromPlatform;
            investedData.toPlatform -= burnedFromPlatform;            
        }
        balancesLocked[phase][owner] -= burnedFromTeam;
        burned = burnedFromTeam + burnedFromPlatform;
    }

    function withdrawInvestment2(InvestedData storage investedData, uint[] storage withdrawnTotal, mapping(uint => uint)[16] storage splitWithdrawnOnShortFinancePeriods, uint16 shortFinancePeriodsCount, uint nowShortFinancePeriodNum, uint igrat, uint8 phase, uint toWithdraw) public {               
        uint srosfp = (investedData.investmentGuideReward - igrat) / (shortFinancePeriodsCount - nowShortFinancePeriodNum);
        withdrawnTotal[phase] += toWithdraw;
        uint swosfp = toWithdraw / (shortFinancePeriodsCount - nowShortFinancePeriodNum);        
        for(uint i=nowShortFinancePeriodNum+1; i<=shortFinancePeriodsCount; i++)
            splitWithdrawnOnShortFinancePeriods[phase][i] += (swosfp-srosfp);
    }

    function rejectInvestmentWithdrawal(InvestedData storage investedData, uint[] storage rejectedInvestmentWithdrawals, uint8 phase) public {
        require(!investedData.rejectedWithdrawal, 'Investor rejected to withdraw investment already');
        investedData.rejectedWithdrawal = true;
        rejectedInvestmentWithdrawals[phase] += investedData.scoin;
        investedData.investmentGuideRewardAvailableTotal = investedData.investmentGuideReward;         
    }

    function claimInvestmentGuideReward(InvestedData storage investedData, uint available, uint8 phase, uint[] storage investmentGuideRewards, uint[] storage transactedOut, uint[] storage claimedIGRTotal) public {
        require(msg.sender == investedData.investmentGuide, 'Not investment guide of this investor');
        require(available > 0, 'No reward available to claim');
        investedData.investmentGuideClaimedReward += available;
        if(available>investmentGuideRewards[phase]) available = investmentGuideRewards[phase];
        investmentGuideRewards[phase] -= available;
        transactedOut[phase] += available;
        claimedIGRTotal[phase] += available;
    }
    
    function setVoting(Voting storage voting, uint sentAmount, uint votingPriceScoin, uint startTime, uint endTime, uint8 typo, uint[] storage transactedIn, uint8 phase) public {
        uint duration = endTime - startTime;
        require(sentAmount>=votingPriceScoin, 'Not enough stable coin sent to cover setting voting price');
        require(duration >= 2 days, 'Duration less then 2 days');
        require(duration <= 14 days, 'Duration more then 14 days');
        require(startTime < block.timestamp + 7 days, 'Start time later then in 7 days');
        require(startTime > block.timestamp, 'Start time less then block timestamp');        
        voting.typo = typo;
        voting.startTime = startTime;
        voting.endTime = endTime;
        transactedIn[phase] += sentAmount;          
    }

    function vote(Voting storage voting,  uint votingId, address addressProposition, uint uintProposition, mapping(address => address)[2**32] storage votingAdresses, mapping(address=>uint)[2**32] storage votingAdressesCounts, mapping(address=>uint)[2**32] storage votingUints, mapping(address=>uint256) storage _balances, mapping(address=>uint) storage _balancesLockedTill, mapping(address => uint256)[16] storage balancesLocked, uint8 phase) public {
        require(block.timestamp>voting.startTime && block.timestamp<voting.endTime, 'Now is not voting period');
        if(voting.typo==1||voting.typo==3){
           require(votingAdresses[votingId][msg.sender] == address(0), 'You have voted already'); 
           votingAdresses[votingId][msg.sender] = addressProposition;
           votingAdressesCounts[votingId][addressProposition] += _balances[msg.sender];
           votingAdressesCounts[votingId][addressProposition] += balancesLocked[phase][msg.sender];
           if(votingAdressesCounts[votingId][addressProposition] > voting.adressMaxCount) {
              voting.adressMaxCount = votingAdressesCounts[votingId][addressProposition];
              voting.addressPropositionMaxCount = addressProposition;            
            }
        }
        if(voting.typo==2){
           require(uintProposition>0 && uintProposition<100, 'Uint proposition is out of range'); 
           require(votingUints[votingId][msg.sender]==0, 'You have voted already'); 
           votingUints[votingId][msg.sender] = uintProposition;
           voting.uintSum += (uintProposition*_balances[msg.sender]);
           voting.uintSum += (uintProposition*balancesLocked[phase][msg.sender]);
           voting.uintCount += _balances[msg.sender];        
           voting.uintCount += balancesLocked[phase][msg.sender];
        }
        voting.quorumCount += _balances[msg.sender];
        voting.quorumCount += balancesLocked[phase][msg.sender];
        if(voting.endTime > _balancesLockedTill[msg.sender]) _balancesLockedTill[msg.sender] = voting.endTime;       
    }

    function applyVotingResults(Voting storage voting, address _owner, uint8 dividendsIncomePercentage, uint256 totalSupply, uint8 quorum) public returns(address owner, uint8 uintWinProposition) {        
        require(voting.quorumCount * 100 * m / totalSupply > quorum * m, 'No quorum');
        require(block.timestamp > voting.endTime, 'Voting time did not finished yet');
        require(!voting.resultsApplied, 'Results applied already');
        owner = _owner;
        uintWinProposition = dividendsIncomePercentage;
        if(voting.typo == 1) {
            require(voting.adressMaxCount > totalSupply * quorum / 100, 'Not enough votes');
            owner = voting.addressPropositionMaxCount;
        }        
        if(voting.typo == 2) {
            uintWinProposition = uint8(voting.uintSum / voting.uintCount);
        }
        if(voting.typo == 3) {
            IPool startup = IPool(payable(voting.addressPropositionMaxCount));
            startup.transfer(owner, startup.balanceOf(address(this)));
        }
        voting.resultsApplied = true;         
    }

    function receiveDividends(mapping(address=>uint) storage investorReceivedDividends, address investor, uint dividends, uint dividendsPaymentPeriodEndTime, mapping(address => uint) storage _balancesLockedTill, uint[] storage transactedOut, uint8 phase) public {
        require(block.timestamp < dividendsPaymentPeriodEndTime, 'Dividends payment period is over');        
        require(dividends>0, 'Dividends should be positive number');
        investorReceivedDividends[investor] += dividends;
        transactedOut[phase] += dividends;
        if(dividendsPaymentPeriodEndTime > _balancesLockedTill[msg.sender]) _balancesLockedTill[msg.sender] = dividendsPaymentPeriodEndTime;        
    }

    function transactOut(uint scoin, uint available, mapping(address=>uint) storage delegatedTransactOutTotal, uint[] storage transactedOut, uint8 phase) public {
        require(scoin > 0, 'Input stable coin amount should be positive number');
        require(available>0 && scoin<=available, 'Pool stable coin are not enough');       
        uint _delegatedTransactOutTotal = delegatedTransactOutTotal[msg.sender];
        if(_delegatedTransactOutTotal>0) {
            require(_delegatedTransactOutTotal>=scoin, 'Not enough delegated amount');
            delegatedTransactOutTotal[msg.sender] -= scoin;
        }
        transactedOut[phase] += scoin;
    }

    function delegateTransactOut(address to, uint amount, mapping(address=>uint) storage delegatedTransactOutTotal, mapping(address=>mapping(address=>uint)) storage delegatedTransactOut, address owner) public {
        require(to != owner, "Delegation to owner is not available");
        if(msg.sender!=owner) {
            if(amount==0) amount = delegatedTransactOutTotal[msg.sender];
            require(amount<=delegatedTransactOutTotal[msg.sender], 'Not enough delegated amount');   
            delegatedTransactOutTotal[msg.sender] -= amount;
        }           
        delegatedTransactOut[msg.sender][to] += amount;
        delegatedTransactOutTotal[to] += amount;        
    }

    function undelegateTransactOut(address to, mapping(address=>uint) storage delegatedTransactOutTotal, mapping(address=>mapping(address=>uint)) storage delegatedTransactOut, address owner) public {
        uint _delegatedTransactOut = delegatedTransactOut[msg.sender][to];
        if(_delegatedTransactOut>delegatedTransactOutTotal[to]) _delegatedTransactOut = delegatedTransactOutTotal[to];
        delegatedTransactOutTotal[to] -= _delegatedTransactOut;
        delegatedTransactOut[msg.sender][to] = 0;
        if(msg.sender!=owner) delegatedTransactOutTotal[msg.sender] += _delegatedTransactOut;        
    }
                       
}
