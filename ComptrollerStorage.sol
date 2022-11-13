pragma solidity ^0.5.16;

import "./VToken.sol";
import "./PriceOracle.sol";
import "./LUSDControllerInterface.sol";
import "./ComptrollerLensInterface.sol";

contract UnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of Unitroller
    */
    address public comptrollerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingComptrollerImplementation;
}

contract ComptrollerV1Storage is UnitrollerAdminStorage {

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    uint public maxAssets;

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => VToken[]) public accountAssets;

    struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;

        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint collateralFactorMantissa;

        /// @notice Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;

        /// @notice Whether or not this market receives LBM
        bool isLibertum;
    }

    /**
     * @notice Official mapping of vTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     */
    address public pauseGuardian;

    /// @notice Whether minting is paused (deprecated, superseded by actionPaused)
    bool private _mintGuardianPaused;
    /// @notice Whether borrowing is paused (deprecated, superseded by actionPaused)
    bool private _borrowGuardianPaused;
    /// @notice Whether borrowing is paused (deprecated, superseded by actionPaused)
    bool internal transferGuardianPaused;
    /// @notice Whether borrowing is paused (deprecated, superseded by actionPaused)
    bool internal seizeGuardianPaused;
    /// @notice Whether borrowing is paused (deprecated, superseded by actionPaused)
    mapping(address => bool) internal mintGuardianPaused;
    /// @notice Whether borrowing is paused (deprecated, superseded by actionPaused)
    mapping(address => bool) internal borrowGuardianPaused;

    struct LibertumMarketState {
        /// @notice The market's last updated libertumBorrowIndex or libertumSupplyIndex
        uint224 index;

        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice A list of all markets
    VToken[] public allMarkets;

    /// @notice The rate at which the flywheel distributes LBM, per block
    uint public libertumRate;

    /// @notice The portion of libertumRate that each market currently receives
    mapping(address => uint) public libertumSpeeds;

    /// @notice The Libertum market supply state for each market
    mapping(address => LibertumMarketState) public libertumSupplyState;

    /// @notice The Libertum market borrow state for each market
    mapping(address => LibertumMarketState) public libertumBorrowState;

    /// @notice The Libertum supply index for each market for each supplier as of the last time they accrued LBM
    mapping(address => mapping(address => uint)) public libertumSupplierIndex;

    /// @notice The Libertum borrow index for each market for each borrower as of the last time they accrued LBM
    mapping(address => mapping(address => uint)) public libertumBorrowerIndex;

    /// @notice The LBM accrued but not yet transferred to each user
    mapping(address => uint) public libertumAccrued;

    /// @notice The Address of LUSDController
    LUSDControllerInterface public lusdController;

    /// @notice The minted LUSD amount to each user
    mapping(address => uint) public mintedLUSDs;

    /// @notice LUSD Mint Rate as a percentage
    uint public lusdMintRate;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     */
    bool public mintLUSDGuardianPaused;
    bool public repayLUSDGuardianPaused;

    /**
     * @notice Pause/Unpause whole protocol actions
     */
    bool public protocolPaused;

    /// @notice The rate at which the flywheel distributes LBM to LUSD Minters, per block (deprecated)
    uint private libertumLUSDRate;
}

contract ComptrollerV2Storage is ComptrollerV1Storage {
    /// @notice The rate at which the flywheel distributes LBM to LUSD Vault, per block
    uint public libertumLUSDVaultRate;

    // address of LUSD Vault
    address public lusdVaultAddress;

    // start block of release to LUSD Vault
    uint256 public releaseStartBlock;

    // minimum release amount to LUSD Vault
    uint256 public minReleaseAmount;
}

contract ComptrollerV3Storage is ComptrollerV2Storage {
    /// @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    /// @notice Borrow caps enforced by borrowAllowed for each vToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint) public borrowCaps;
}

contract ComptrollerV4Storage is ComptrollerV3Storage {
    /// @notice Treasury Guardian address
    address public treasuryGuardian;

    /// @notice Treasury address
    address public treasuryAddress;

    /// @notice Fee percent of accrued interest with decimal 18
    uint256 public treasuryPercent;
}

contract ComptrollerV5Storage is ComptrollerV4Storage {
    /// @notice The portion of LBM that each contributor receives per block (deprecated)
    mapping(address => uint) private libertumContributorSpeeds;

    /// @notice Last block at which a contributor's LBM rewards have been allocated (deprecated)
    mapping(address => uint) private lastContributorBlock;
}

contract ComptrollerV6Storage is ComptrollerV5Storage {
    address public liquidatorContract;
}

contract ComptrollerV7Storage is ComptrollerV6Storage {
    ComptrollerLensInterface public comptrollerLens;
}

contract ComptrollerV8Storage is ComptrollerV7Storage {
    
    /// @notice Supply caps enforced by mintAllowed for each vToken address. Defaults to zero which corresponds to minting notAllowed
    mapping(address => uint256) public supplyCaps;
}
    
contract ComptrollerV9Storage is ComptrollerV8Storage {
    /// @notice AccessControlManager address
    address accessControl;

    enum Action {
        MINT,
        REDEEM,
        BORROW,
        REPAY,
        SEIZE,
        LIQUIDATE,
        TRANSFER,
        ENTER_MARKET,
        EXIT_MARKET
    }

    /// @notice True if a certain action is paused on a certain market
    mapping (address => mapping(uint => bool)) internal _actionPaused;
}
