// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MBCPaymentSplitter {
    uint256 public constant PRECISION = 1e6; // Precision factor for "floats"
    
    address public MBC_ADMIN;
    address public D5ART_ADMIN;
    address public D5ART_SUBADMIN;
    address public JV_WALLET;

    // Percentages expressed in fixed-point format (e.g., 20% = 0.2 * 1e6 = 200000)
    uint256 public constant JV_SPLIT_PERCENT = 200000; // 20% = 0.2
    uint256 public constant BONUS_PERCENT = 100000;    // 10% = 0.1

    enum PlanType { BASIC, STANDARD, PREMIUM }

    mapping(PlanType => uint256) public originalPrices;
    mapping(PlanType => uint256) public concessionPrices;

    bool public d5art_subAdminApproved;
    bool public d5ar_AdmintApproved;

    event PaymentReceived(address payer, uint256 amount, PlanType plan);
    event CommissionPaid(address to, uint256 amount);
    event FundsReleased(address to, uint256 amount);
    event MbcAdminUpdated(address newAdmin);
    event D5artAdminUpdated(address newAdmin);
    event D5art_subAdminUpdated(address new_subAdmin);
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
        require(msg.sender == D5ART_SUBADMIN || msg.sender == D5ART_ADMIN, "Unauthorized");
        _; 
    }

    constructor(
        address _mbcAdmin,
        address _d5artAdmin,
        address _d5artsubAdmin,
        address _jvWallet,  
        uint256 _basicPrice,
        uint256 _standardPrice,
        uint256 _premiumPrice
    ) {
        require(_mbcAdmin != address(0) && _d5artAdmin != address(0) && _jvWallet != address(0), "Invalid addresses");
        MBC_ADMIN = _mbcAdmin;
        D5ART_ADMIN = _d5artAdmin;
        D5ART_SUBADMIN = _d5artsubAdmin;
        JV_WALLET = _jvWallet;

        _setPrice(PlanType.BASIC, _basicPrice);
        _setPrice(PlanType.STANDARD, _standardPrice);
        _setPrice(PlanType.PREMIUM, _premiumPrice);
    }

    function makePayment(PlanType plan) external payable {
        require(msg.value == concessionPrices[plan], "Incorrect payment amount");
        
        emit PaymentReceived(msg.sender, msg.value, plan);
        
        uint256 jvSplit = (originalPrices[plan] * JV_SPLIT_PERCENT) / PRECISION;
        uint256 bonusSplit = (originalPrices[plan] * BONUS_PERCENT) / PRECISION;

        (bool successJV, ) = JV_WALLET.call{value: jvSplit}("");
        require(successJV, "JV transfer failed");
        emit CommissionPaid(JV_WALLET, jvSplit);

        (bool successBonus, ) = MBC_ADMIN.call{value: bonusSplit}("");
        require(successBonus, "Bonus transfer failed");
        emit CommissionPaid(MBC_ADMIN, bonusSplit);
    }

    function approveRelease() external onlyParties {
        if (msg.sender == D5ART_SUBADMIN) {
            d5art_subAdminApproved = true;
        } else if (msg.sender == D5ART_ADMIN) {
            d5ar_AdmintApproved = true;
        }
        
        if (d5art_subAdminApproved && d5ar_AdmintApproved) {
            _releaseFunds();
        }
    }

    function _releaseFunds() private {
        uint256 d5artFinalShare = address(this).balance;
        require(d5artFinalShare > 0, "No funds to release");

        (bool success2, ) = D5ART_ADMIN.call{value: d5artFinalShare}("");
        require(success2, "D5art transfer failed");

        emit FundsReleased(D5ART_ADMIN, d5artFinalShare);

        d5art_subAdminApproved = false;
        d5ar_AdmintApproved = false;
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

    function updateD5art_subAdmin( address new_subAdmin) external onlyD5ArtAdmin {
        require(new_subAdmin != address(0), "Invalid address");
        D5ART_SUBADMIN = new_subAdmin;
        emit D5art_subAdminUpdated(new_subAdmin);
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
        concessionPrices[plan] = (price * (PRECISION - BONUS_PERCENT)) / PRECISION;
        emit PriceUpdated(plan, price, concessionPrices[plan]);
    }

    // --- Utilities ---
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }


    fallback() external payable {
        revert("Direct transfers not allowed");
    }

    receive() external payable {
        revert("Please use makePayment function");
    }
}
