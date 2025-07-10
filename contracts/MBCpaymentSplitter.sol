// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MBCPaymentSplitter {
    uint256 public constant PRECISION = 1e6; // Precision factor for "floats"
    
    address public MBC_ADMIN;
    address public D5ART_ADMIN;
    address public D5ART_SUBADMIN;
    address public JV_WALLET;
    address public paymentToken;

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
        address _token, 
        uint256 _basicPrice,
        uint256 _standardPrice,
        uint256 _premiumPrice
    ) {
        require(_mbcAdmin != address(0) && _d5artAdmin != address(0) && _jvWallet != address(0), "Invalid addresses");
        MBC_ADMIN = _mbcAdmin;
        D5ART_ADMIN = _d5artAdmin;
        D5ART_SUBADMIN = _d5artsubAdmin;
        JV_WALLET = _jvWallet;
        paymentToken = _token;

        _setPrice(PlanType.BASIC, _basicPrice);
        _setPrice(PlanType.STANDARD, _standardPrice);
        _setPrice(PlanType.PREMIUM, _premiumPrice);
    }

    function makePayment(PlanType plan) external {
    uint256 price = concessionPrices[plan];
    require(price > 0, "Invalid price");

    // User must approve this contract to spend tokens before calling this
    require(IERC20(paymentToken).transferFrom(msg.sender, address(this), price), "Token transfer failed");

    emit PaymentReceived(msg.sender, price, plan);

    uint256 jvSplit = (originalPrices[plan] * JV_SPLIT_PERCENT) / PRECISION;
    uint256 bonusSplit = (originalPrices[plan] * BONUS_PERCENT) / PRECISION;

    require(IERC20(paymentToken).transfer(JV_WALLET, jvSplit), "JV transfer failed");
    emit CommissionPaid(JV_WALLET, jvSplit);

    require(IERC20(paymentToken).transfer(MBC_ADMIN, bonusSplit), "Bonus transfer failed");
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
    uint256 tokenBalance = IERC20(paymentToken).balanceOf(address(this));
    require(tokenBalance > 0, "No funds to release");

    require(IERC20(paymentToken).transfer(D5ART_ADMIN, tokenBalance), "Token transfer failed");

    emit FundsReleased(D5ART_ADMIN, tokenBalance);

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

    function updatePaymentToken(address newToken) external onlyMBCAdmin {
    require(newToken != address(0), "Invalid token address");
    paymentToken = newToken;
}


    function updatePrice(PlanType plan, uint256 newPrice) external onlyD5ArtAdmin {
        _setPrice(plan, newPrice);
    }

    function _setPrice(PlanType plan, uint256 price) internal {
        originalPrices[plan] = price;
        concessionPrices[plan] = (price * (PRECISION - BONUS_PERCENT)) / PRECISION;
        emit PriceUpdated(plan, price, concessionPrices[plan]);
    }

    // --- Utilities ---
    function getContractBalance() public view returns (uint256) {
    return IERC20(paymentToken).balanceOf(address(this));
}



    // fallback() external payable {
    //     revert("Direct transfers not allowed");
    // }

    // receive() external payable {
    //     revert("Please use makePayment function");
    // }
}
