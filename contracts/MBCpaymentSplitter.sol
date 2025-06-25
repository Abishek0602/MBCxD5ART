// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MBCPaymentSplitter {
    address public MBC_ADMIN;
    address public D5ART_ADMIN;
    address public JV_WALLET; 
    
    uint256 public constant JV_SPLIT_PERCENT = 20;
    uint256 public constant BONUS_PERCENT = 10;
    
    enum PlanType { BASIC, STANDARD, PREMIUM }
    
    mapping(PlanType => uint256) public originalPrices;
    mapping(PlanType => uint256) public concessionPrices;
    
    bool public mbcApproved;
    bool public d5artApproved;
    
    event PaymentReceived(address payer, uint256 amount, PlanType plan);
    event CommissionPaid(address to, uint256 amount);
    event FundsReleased(address to, uint256 amount);
    event MbcAdminUpdated(address newAdmin);
    event D5artAdminUpdated(address newAdmin);
    event JvWalletUpdated(address newWallet);
    event PriceUpdated(PlanType plan, uint256 newOriginalPrice, uint256 newConcessionPrice);

    modifier onlyMBCAdmin() {
        require(msg.sender == MBC_ADMIN, "Only MBC admin allowed");
        _;
    }

    modifier onlyD5ArtAdmin() {
        require(msg.sender == D5ART_ADMIN, "Only D5Art admin allowed");
        _;
    }

    modifier onlyParties() {
        require(msg.sender == MBC_ADMIN || msg.sender == D5ART_ADMIN, "Unauthorized");
        _; 
    }

    constructor(
        address _mbcAdmin,
        address _d5artAdmin,
        address _jvWallet,  
        uint256 _basicPrice,
        uint256 _standardPrice,
        uint256 _premiumPrice
    ) {
        require(_mbcAdmin != address(0) && _d5artAdmin != address(0) && _jvWallet != address(0), "Invalid addresses");
        MBC_ADMIN = _mbcAdmin;
        D5ART_ADMIN = _d5artAdmin;
        JV_WALLET = _jvWallet;

        _setPrice(PlanType.BASIC, _basicPrice);
        _setPrice(PlanType.STANDARD, _standardPrice);
        _setPrice(PlanType.PREMIUM, _premiumPrice);
    }

    function makePayment(PlanType plan) external payable {
        require(msg.value == concessionPrices[plan], "Incorrect payment amount");
        
        emit PaymentReceived(msg.sender, msg.value, plan);
        
        uint256 jvSplit = (originalPrices[plan] * JV_SPLIT_PERCENT) / 100;
        uint256 bonusSplit = (originalPrices[plan] * BONUS_PERCENT) / 100;

        (bool successJV, ) = JV_WALLET.call{value: jvSplit}("");
        require(successJV, "JV transfer failed");
        emit CommissionPaid(JV_WALLET, jvSplit);

        (bool successBonus, ) = MBC_ADMIN.call{value: bonusSplit}("");
        require(successBonus, "Bonus transfer failed");
        emit CommissionPaid(MBC_ADMIN, bonusSplit);
    }

    function approveRelease() external onlyParties {
        if (msg.sender == MBC_ADMIN) {
            mbcApproved = true;
        } else if (msg.sender == D5ART_ADMIN) {
            d5artApproved = true;
        }
        
        if (mbcApproved && d5artApproved) {
            _releaseFunds();
        }
    }

    function _releaseFunds() private {
        uint256 d5artFinalShare = address(this).balance;
        require(d5artFinalShare > 0, "No funds to release");

        (bool success2, ) = D5ART_ADMIN.call{value: d5artFinalShare}("");
        require(success2, "D5art transfer failed");

        emit FundsReleased(D5ART_ADMIN, d5artFinalShare);

        mbcApproved = false;
        d5artApproved = false;
    }

    // --- Admin Controls ---

    function updateMbcAdmin(address newAdmin) external onlyMBCAdmin {
        require(newAdmin != address(0), "Invalid address");
        MBC_ADMIN = newAdmin;
        emit MbcAdminUpdated(newAdmin);
    }

    function updateD5artAdmin(address newAdmin) external onlyD5ArtAdmin {
        require(newAdmin != address(0), "Invalid address");
        D5ART_ADMIN = newAdmin;
        emit D5artAdminUpdated(newAdmin);
    }

    function updateJvWallet(address newWallet) external onlyMBCAdmin {
        require(newWallet != address(0), "Invalid address");
        JV_WALLET = newWallet;
        emit JvWalletUpdated(newWallet);
    }

    function updatePrice(PlanType plan, uint256 newPrice) external onlyMBCAdmin {
        _setPrice(plan, newPrice);
    }

    function _setPrice(PlanType plan, uint256 price) internal {
        originalPrices[plan] = price;
        concessionPrices[plan] = (price * 90) / 100;
        emit PriceUpdated(plan, price, concessionPrices[plan]);
    }

    // --- Utilities ---
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function checkBalance(address _address) public view returns (uint256) {
        return _address.balance;
    }

    fallback() external payable {
        revert("Direct transfers not allowed");
    }

    receive() external payable {
        revert("Please use makePayment function");
    }
}
