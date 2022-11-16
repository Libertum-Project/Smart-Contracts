pragma solidity ^0.5.16;
import "./SafeMath.sol";
import "./IBEP20.sol";

contract LUSDVaultAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of VAI Vault
    */
    address public lusdVaultImplementation;

    /**
    * @notice Pending brains of VAI Vault
    */
    address public pendingLUSDVaultImplementation;
}

contract LUSDVaultStorage is LUSDVaultAdminStorage {
    /// @notice The LBM TOKEN!
    IBEP20 public lbm;

    /// @notice The LUSD TOKEN!
    IBEP20 public lusd;

    /// @notice Guard variable for re-entrancy checks
    bool internal _notEntered;

    /// @notice LBM balance of vault
    uint256 public lbmBalance;

    /// @notice Accumulated LBM per share
    uint256 public accLBMPerShare;

    //// pending rewards awaiting anyone to update
    uint256 public pendingRewards;

    /// @notice Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    // Info of each user that stakes tokens.
    mapping(address => UserInfo) public userInfo;
}
