// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;
pragma abicoder v1;

import "./ES1.sol";
import "./ISwapRouter.sol";
import "./Helper.sol";

contract Pool is ES1 {

    uint public constant e18 = 1e18;
    uint8 public phase = 1;
    uint16 public shortFinancePeriodsCount;
    uint public longFinancePeriodEndTime;   

    uint public saleStartTime;
    uint public saleEndTime;
    uint public sharePrice;
    uint32 public shortFinancePeriod;
    uint32 public longFinancePeriod;

    uint8 public period; 

    ES1 public Scoin;
    address public scoinAddress;
    address public platformAddress;
    SwapRouter public swapRouter;
    address public swapRouterAddress;
    Pool public Startup;

    uint public poolCap;

    mapping(address => InvestedData[16]) public invested;
    mapping(address => uint) public investorReceivedDividends;

    uint8 public saleShare;
    uint8 public teamShare;
    uint8 public platformShare;
    uint8 public investmentGuidesRewardShare;

    uint[] public investedTotal = new uint[](16);
    uint[] public withdrawnTotal = new uint[](16);
    uint[] public claimedIGRTotal = new uint[](16);
    uint[] public suppliedTotal = new uint[](16);
    mapping(uint=>uint)[16] splitWithdrawnOnShortFinancePeriods;

    bool[] public longFinancePeriodPrepared = new bool[](16);

    uint[] public rejectedInvestmentWithdrawals = new uint[](16);

    uint[] public investmentGuideRewards = new uint[](16);

    uint constant votingPriceScoin = 1e18 * 30;

    mapping(address=>address)[2**32] votingAdresses; 
    mapping(address=>uint)[2**32] votingAdressesCounts;
    mapping(address=>uint)[2**32] votingUints;    
    uint public votingId;
    Voting[2**32] public votings;
    uint8 constant quorum = 50;

    uint8 public dividendsIncomePercentage = 50;

    uint[] public transactedIn = new uint[](16);
    uint[] public transactedOut = new uint[](16);

    uint public dividendingIncome;
    uint public totalDividendedIncome;    
    uint public dividendsPaymentPeriodEndTime;

    uint public bountyCap;
    uint public presaleCap;
    uint public airdropCap;

    mapping(address => uint256)[16] public balancesUnlocked;
    mapping(address => uint256)[16] public balancesLocked;

    mapping(address=>mapping(address=>uint)) public delegatedTransactOut;
    mapping(address=>uint) public delegatedTransactOutTotal;

    fallback() external payable {
        processInvest();    
    }
    receive() external payable {
        if(msg.sender != swapRouterAddress) processInvest();     
    }

    function processInvest() public payable {
        require(setPeriod() > 0, 'The sale has not yet begun');
        if(period == 1) invest(platformAddress, false);
        else if(period==2 && block.timestamp > saleEndTime + 1 hours && msg.value > 0) transactIn(0);
        else revert();        
    }    

    constructor(address _platformAddress, address _scoinAddress, address _swapRouterAddress) {
        platformAddress = _platformAddress;
        scoinAddress = _scoinAddress;
        platform = Platform(platformAddress);
        Scoin = ES1(_scoinAddress);
        swapRouter = SwapRouter(_swapRouterAddress);
        swapRouterAddress = _swapRouterAddress;
    }

    modifier needPeriod(uint8 _period, bool not) {
        setPeriod();
        require(!not&&_period==period || not&&_period!=period, 'Inappropriate period');
        _;
    }

    modifier onlyInvestor {
        require(_balances[msg.sender]>0||balancesLocked[phase][msg.sender]>0, 'Only for investor');
        _;
    }

    modifier ownerOrDelegated(uint8 typo) {
        if(msg.sender!=_owner && typo==1) require(delegatedTransactOutTotal[msg.sender]>0, 'Not delegeted');
        _;
    }
    
    modifier wasLongFinancePeriodPrepared {
        require(longFinancePeriodPrepared[phase], 'Pool was not swaped to stable coin');
        _;    
    }   

    event PrepareSale(uint8 _phase, uint _poolCap, uint _saleStartTime, uint _saleEndTime, uint32 _shortFinancePeriod, uint32 _longFinancePeriod, uint _sharePrice, uint8 _saleShare, uint8 _teamShare, uint8 _platformShare, uint8 _investmentGuidesRewardShare, uint _bountyCap, uint _presaleCap, uint _airdropCap);
    function prepareSale(uint _poolCap, uint _saleStartTime, uint _saleEndTime, uint32 _shortFinancePeriod, uint32 _longFinancePeriod, uint _sharePrice, uint8 _saleShare, uint8 _teamShare, uint8 _platformShare, uint8 _investmentGuidesRewardShare, uint _bountyCap, uint _presaleCap, uint _airdropCap) public onlyOwner {
        require(_platformShare>0);
        require(setPeriod()==0, 'Only available before sale start time');
        require(_saleEndTime > block.timestamp);
        require(block.timestamp > dividendsPaymentPeriodEndTime);                     
        if(block.timestamp > longFinancePeriodEndTime && longFinancePeriodEndTime > 0) {
            uint scoinBalance = Scoin.balanceOf(address(this));
            uint av = available(block.timestamp);
            uint transfer = investmentGuideRewards[phase]+av;
            if(transfer>scoinBalance)transfer=scoinBalance;
            transactedIn[phase+1] += transfer;
            unlockTeamAndPlatformShares();
            phase++;
        }                
        setPeriods(_saleStartTime, _saleEndTime, _shortFinancePeriod, _longFinancePeriod);
        setSharePrice(_sharePrice);        
        setShares(_saleShare, _teamShare, _platformShare, _investmentGuidesRewardShare);
        setCaps(_poolCap, _bountyCap, _presaleCap, _airdropCap);
        emit PrepareSale(phase, _poolCap, _saleStartTime, _saleEndTime, _shortFinancePeriod, _longFinancePeriod, _sharePrice, _saleShare, _teamShare, _platformShare, _investmentGuidesRewardShare, _bountyCap, _presaleCap, _airdropCap);
    }

    function setPeriods(uint _saleStartTime, uint _saleEndTime, uint32 _shortFinancePeriod, uint32 _longFinancePeriod) internal {        
        require(_longFinancePeriod % _shortFinancePeriod == 0, 'The remainder of the division should be 0');
        shortFinancePeriod = _shortFinancePeriod;
        longFinancePeriod = _longFinancePeriod;
        shortFinancePeriodsCount = uint16(_longFinancePeriod / _shortFinancePeriod);
        longFinancePeriodEndTime = uint(_saleEndTime + _longFinancePeriod);
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
    }

    function setSharePrice(uint _sharePrice) internal {
        require(_sharePrice>0, 'Share price should be more then 0');
        sharePrice = 1e14 * _sharePrice;
    }

    function setShares(uint8 _saleShare, uint8 _teamShare, uint8 _platformShare, uint8 _investmentGuidesRewardShare) internal {
        saleShare = _saleShare;
        teamShare = _teamShare;
        platformShare = _platformShare;
        investmentGuidesRewardShare = _investmentGuidesRewardShare;
    }     

    function setCaps(uint _poolCap, uint _bountyCap, uint _presaleCap, uint _airdropCap) internal {
        poolCap = _poolCap;
        bountyCap = _bountyCap;
        presaleCap = _presaleCap;
        airdropCap = _airdropCap;        
    }

    function setPeriod() internal returns(uint8 _period) {
        period = block.timestamp>=saleStartTime&&block.timestamp<=saleEndTime ? 1 : ( block.timestamp<longFinancePeriodEndTime && block.timestamp>saleEndTime ? 2 : 0 );
        _period = period;
    }

    event Invested(address investor, address investmentGuide, uint scoin, uint quantity, bool rejectedWithdrawal, uint8 _phase, uint256 time);
    function invest(address investmentGuide, bool rejectedWithdrawal) public payable needPeriod(1,false) returns(uint) {       
        require(platform.kycApprovedOf(msg.sender), 'ES1: sender KYC not approved yet'); 
        (uint quantity, uint scoin, uint scoinRemnant) = Helper.investStep1(invested[msg.sender][phase], swapRouter, scoinAddress, poolCap, sharePrice, investmentGuide, rejectedWithdrawal, investedTotal, phase);
        Helper.investStep2(invested[msg.sender][phase], scoin, investmentGuidesRewardShare, phase, investmentGuideRewards);
        uint supplied = Helper.investStep3(invested[msg.sender][phase], _balances, balancesLocked, phase, saleShare, teamShare, platformShare, quantity, _owner, platformAddress);
        _totalSupply += supplied;
        suppliedTotal[phase] += supplied;
        if(scoinRemnant>0) Scoin.transfer(msg.sender,scoinRemnant);
        emit Transfer(address(0), msg.sender, quantity);
        emit Invested(msg.sender, investmentGuide, scoin, quantity, rejectedWithdrawal, phase, block.timestamp);
        return scoin;
    }

    event LongFinancePeriodPrepared(address by, uint256 time);
    function prepareLongFinancePeriod() public {
        setPeriod();    
        if(block.timestamp > saleEndTime) longFinancePeriodPrepared[phase] = true;
        emit LongFinancePeriodPrepared(msg.sender, block.timestamp);
    }

    function swapCoinToScoin(uint coin, uint scoin) internal returns(uint) {
        return Helper.swapCoinToScoin(coin, scoin, swapRouter, scoinAddress);    
    }

    event InvestmentWithdrawn(address investor, uint returnedScoin, uint returnedShares, uint8 _phase, uint256 time);
    function withdrawInvestment() public needPeriod(2, false) wasLongFinancePeriodPrepared returns(uint) {
        InvestedData storage investedData = invested[msg.sender][phase]; 
        require(_balances[msg.sender]>=investedData.quantity, "Not enough shares on investor's balance");
        require(investedData.quantity > 0, 'No investment shares');
        _balances[msg.sender] -= investedData.quantity; 
        uint igrat = investmentGuideRewardAvailableTotal(block.timestamp, msg.sender, phase);
        uint _nowShortFinancePeriodNum = nowShortFinancePeriodNum(block.timestamp);
        (uint toWithdraw, uint burned) = Helper.withdrawInvestment1(investedData, _owner, balancesLocked, phase, shortFinancePeriodsCount, igrat, _nowShortFinancePeriodNum, Scoin.balanceOf(address(this)), platformAddress);
        uint totalBurned = investedData.quantity + burned;
        _totalSupply -= totalBurned;
        suppliedTotal[phase] -= totalBurned;
        Helper.withdrawInvestment2(investedData, withdrawnTotal, splitWithdrawnOnShortFinancePeriods, shortFinancePeriodsCount, _nowShortFinancePeriodNum, igrat, phase, toWithdraw);
        Scoin.transfer(msg.sender, toWithdraw);
        emit Transfer(msg.sender, address(0), investedData.quantity);
        emit Transfer(address(0), address(0), burned);
        emit InvestmentWithdrawn(msg.sender, toWithdraw, investedData.quantity, phase, block.timestamp);
        investedData.quantity = 0;
        return toWithdraw;             
    }

    event InvestmentWithdrawalRejected(address investor, uint8 phase, uint256 time);
    function rejectInvestmentWithdrawal() public {
        Helper.rejectInvestmentWithdrawal(invested[msg.sender][phase], rejectedInvestmentWithdrawals, phase);
        emit InvestmentWithdrawalRejected(msg.sender, phase, block.timestamp);    
    }      

    function investmentGuideRewardAvailableTotal(uint time, address investor, uint8 _phase) public view returns(uint igrat) {
        if(time < saleEndTime || shortFinancePeriodsCount==0) igrat = 0;
        else if(invested[investor][_phase].withdrawn > 0 || invested[investor][_phase].rejectedWithdrawal) 
            igrat = invested[investor][_phase].investmentGuideRewardAvailableTotal;
        else igrat = nowShortFinancePeriodNum(time) * invested[investor][_phase].investmentGuideReward / shortFinancePeriodsCount;       
    }

    function investmentGuideRewardAvailable(uint time, address investor, uint8 _phase) public view returns(uint) {
        uint igrat = investmentGuideRewardAvailableTotal(time, investor, _phase);
        uint igcr = invested[investor][_phase].investmentGuideClaimedReward; 
        if(igcr > igrat) igcr = igrat;
        return (igrat - igcr);    
    } 

    event InvestmentGuideRewardClaimed(address investmentGuide, address investor, uint amountScoin, uint8 _phase, uint256 time);
    function claimInvestmentGuideReward(address investor) public wasLongFinancePeriodPrepared needPeriod(1,true) returns(uint _available) {        
        _available = investmentGuideRewardAvailable(block.timestamp, investor, phase);
        Helper.claimInvestmentGuideReward(invested[investor][phase], _available, phase, investmentGuideRewards, transactedOut, claimedIGRTotal);
        Scoin.transfer(msg.sender, _available);
        emit InvestmentGuideRewardClaimed(msg.sender, investor, _available, phase, block.timestamp);
    }

    function nowShortFinancePeriodNum(uint time) public view returns(uint) {
        if(time > saleEndTime && time < longFinancePeriodEndTime) return (time - saleEndTime) / shortFinancePeriod + 1;
        else if(time > longFinancePeriodEndTime) return shortFinancePeriodsCount;
        else return 0;        
    }

    function coinToScoin(uint coin) public view returns(uint[] memory) {
        return Helper.coinToScoin(coin, swapRouter, scoinAddress);    
    }

    function ScoinToCoin(uint scoin) public view returns(uint[] memory) {
        return Helper.scoinToCoin(scoin, swapRouter, scoinAddress);    
    }     

    event VotingWasSet(address initiator, uint _votingId, uint8 _typo, uint startTime, uint endTime, uint8 _phase, uint256 time);
    function setVoting(uint8 typo, uint startTime, uint endTime) public payable onlyInvestor {
        votingId++;
        uint scoin = swapCoinToScoin(msg.value, 0);
        Helper.setVoting(votings[votingId], scoin, votingPriceScoin, startTime, endTime, typo, transactedIn, phase);                     
        emit VotingWasSet(msg.sender, votingId, typo, startTime, endTime, phase, block.timestamp);         
    }

    event Vote(address voter, uint _votingId, address addressProposition, uint uintProposition, uint256 time);
    function vote(uint _votingId, address addressProposition, uint uintProposition) public onlyInvestor {
        Helper.vote(votings[_votingId], _votingId, addressProposition, uintProposition, votingAdresses, votingAdressesCounts, votingUints, _balances, _balancesLockedTill, balancesLocked, phase);
        emit Vote(msg.sender, _votingId, addressProposition, uintProposition, block.timestamp);
    }   

    event VotingResultsApplied(address applier, uint _votingId, address _owner, uint8 _dividendsIncomePercentage, uint8 _phase, uint256 time);
    function applyVotingResults(uint _votingId) public {        
        (_owner, dividendsIncomePercentage) = Helper.applyVotingResults(votings[_votingId], _owner, dividendsIncomePercentage, _totalSupply, quorum);
        emit VotingResultsApplied(msg.sender, _votingId, _owner, dividendsIncomePercentage, phase, block.timestamp);   
    }

    event TransactedIn(address transactor, uint256 coin, uint scoin, uint256 time);
    function transactIn(uint scoin) public payable {
        if(scoin > 0) Scoin.transferFrom(msg.sender, address(this), scoin);
        else scoin = swapCoinToScoin(msg.value, 0);
        transactedIn[phase] += scoin;
        emit TransactedIn(msg.sender, msg.value, scoin, block.timestamp);
    }

    event TransactedOut(address transactor, address to, uint scoin, uint8 _phase, uint256 time);
    function transactOut(address to, uint scoin) public wasLongFinancePeriodPrepared ownerOrDelegated(1) needPeriod(1,true) {
        Helper.transactOut(scoin, available(block.timestamp),  delegatedTransactOutTotal, transactedOut, phase);
        Scoin.transfer(to, scoin);
        emit TransactedOut(msg.sender, to, scoin, phase, block.timestamp);
    }

    event DelegatedTransactOut(address to, uint scoinAmount, uint256 time);
    function delegateTransactOut(address to, uint amount) public ownerOrDelegated(1) {        
        Helper.delegateTransactOut(to, amount, delegatedTransactOutTotal, delegatedTransactOut, _owner);
        emit DelegatedTransactOut(to, amount, block.timestamp);
    }

    event UndelegatedTransactOut(address to, uint256 time);
    function undelegateTransactOut(address to) public ownerOrDelegated(1) {
        Helper.undelegateTransactOut(to, delegatedTransactOutTotal, delegatedTransactOut, _owner);
        emit UndelegatedTransactOut(to, block.timestamp);  
    }    

    function available(uint time) public view returns(uint) {
        uint it = investedTotal[phase];             
        uint igr = investmentGuideRewards[phase];
        uint riwt = rejectedInvestmentWithdrawals[phase];        
        uint igrr = it>0 ? igr * riwt / it : 0;
        it -= riwt;
        igr -= igrr;      
        uint av1 = availablize(it, time) - availablize(igr, time);
        uint av2 = riwt - igrr;
        uint swosfp = 0;
        uint nsfpn = nowShortFinancePeriodNum(time);
        uint _dividendingIncome = 0;
        if(time<dividendsPaymentPeriodEndTime) _dividendingIncome = dividendingIncome;        
        for(uint i=1; i<=nsfpn; i++)
            swosfp += splitWithdrawnOnShortFinancePeriods[phase][i];
        return av1 + av2 - swosfp + transactedIn[phase] - transactedOut[phase] - _dividendingIncome;
    }

    function availablize(uint val, uint time) public view returns(uint) {
        return shortFinancePeriodsCount > 0 ? (nowShortFinancePeriodNum(time)*val) / shortFinancePeriodsCount : 0;
    }

    function income(uint8 _phase, uint time) public view returns(int) {
        int _dividendingIncome = 0;
        if(time<dividendsPaymentPeriodEndTime) _dividendingIncome = int(dividendingIncome);
        return int(int(transactedIn[_phase]) - int(transactedOut[_phase]) - _dividendingIncome);
    }

    event DividendsPaymentAllowed(uint notDividendedIncome, uint _dividendsPaymentPeriodEndTime, uint8 _phase, uint256 time);
    function allowDividendsPayment(uint newDividendsPaymentPeriodEndTime) public onlyOwner needPeriod(1,true) {    
        require(block.timestamp > dividendsPaymentPeriodEndTime, 'Previous dividends payment period not passed yet');
        require(newDividendsPaymentPeriodEndTime > block.timestamp + 10 days);
        int _income = income(phase,block.timestamp);
        require(_income > 0, 'Income should be positive number');
        uint forDividendingIncome = uint(_income) * dividendsIncomePercentage / 100;                  
        dividendingIncome = uint(forDividendingIncome);
        totalDividendedIncome = uint(forDividendingIncome); 
        dividendsPaymentPeriodEndTime = newDividendsPaymentPeriodEndTime;        
        emit DividendsPaymentAllowed(uint(forDividendingIncome), dividendsPaymentPeriodEndTime, phase, block.timestamp);
    }

    function dividendsToReceive(address investor, uint time) public view returns(uint) {
        if(_totalSupply == 0 || _balances[investor] == 0 || time > dividendsPaymentPeriodEndTime) return 0;
        else {
            uint numerator = ((totalDividendedIncome * _balances[investor]) / _totalSupply);
            if(numerator < investorReceivedDividends[investor]) numerator = investorReceivedDividends[investor]; 
            return numerator - investorReceivedDividends[investor];
        }
    }

    event DividendsReceived(address investor, uint dividends, uint lockedBalanceTill, uint8 _phase, uint256 time);
    function receiveDividends() public onlyInvestor returns(uint dividends) {
        dividends = dividendsToReceive(msg.sender, block.timestamp);
        Helper.receiveDividends(investorReceivedDividends, msg.sender, dividends, dividendsPaymentPeriodEndTime, _balancesLockedTill, transactedOut, phase);       
        dividendingIncome -= dividends;
        Scoin.transfer(msg.sender, dividends);
        emit DividendsReceived(msg.sender, dividends, _balancesLockedTill[msg.sender], phase, block.timestamp);        
    }

    event SharesPaid(uint8 typo, address to, uint amount, uint8 _phase, uint256 time);
    function payShares(uint8 typo, address to, uint amount) public onlyOwner {
        require(platform.kycApprovedOf(to), 'ES1: recipient KYC not approved yet');
        if(typo==1) bountyCap -= amount;    
        if(typo==2) presaleCap -= amount;
        if(typo==3) airdropCap -= amount;
        _balances[to] += amount;
        _totalSupply += amount;
        suppliedTotal[phase] += amount;        
        emit Transfer(address(0), to, amount);
        emit SharesPaid(typo, to, amount, phase, block.timestamp);        
    }   

    function unlockShares(address to) internal returns(uint sharesAvailable) {
        uint bu = balancesUnlocked[phase][to];
        sharesAvailable = availablize(balancesLocked[phase][to]+bu, block.timestamp) - bu;
        if(sharesAvailable > 0) {        
            balancesUnlocked[phase][to] += sharesAvailable;
            balancesLocked[phase][to] -= sharesAvailable;
            _balances[to] += sharesAvailable;
            emit Transfer(address(0), to, sharesAvailable);
        }
    }

    function unlockTeamAndPlatformShares() public needPeriod(1,true) {
        require(platform.kycApprovedOf(_owner), 'ES1: owner KYC not approved yet');
        unlockShares(_owner);
        unlockShares(platformAddress);        
    }
    
    function investInStartup(address payable _Startup, uint amountScoin, bool rejectedWithdrawal) public onlyOwner {        
        require(available(block.timestamp) >= amountScoin, 'Not enough stable coin available');      
        Scoin.approve(swapRouterAddress, amountScoin);
        uint amountWei = Helper.swapScoinToCoin(amountScoin, 0, swapRouter, scoinAddress);
        Startup = Pool(_Startup);
        Startup.invest{value:amountWei}(platformAddress, rejectedWithdrawal);
        transactedOut[phase] += amountScoin;
    }

    function withdrawStartupInvestment(address payable _Startup) public onlyOwner {
        Startup = Pool(_Startup);
        uint amount = Startup.withdrawInvestment();
        transactedIn[phase] += amount;    
    }

    function receiveDividendsInStartup(address payable _Startup) public onlyOwner {
        Startup = Pool(_Startup);
        uint dividends = Startup.receiveDividends();
        transactedIn[phase] += dividends;    
    } 

    function voteInStartup(address payable _Startup, uint _votingId, address addressProposition, uint uintProposition) public onlyOwner {
        Startup = Pool(_Startup);
        Startup.vote(_votingId, addressProposition, uintProposition);
    }       
}
