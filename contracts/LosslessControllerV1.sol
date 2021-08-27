// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface ILosslessController {
    function beforeTransfer(address sender, address recipient, uint256 amount) external;

    function beforeTransferFrom(address msgSender, address sender, address recipient, uint256 amount) external;

    function beforeApprove(address sender, address spender, uint256 amount) external;

    function beforeIncreaseAllowance(address msgSender, address spender, uint256 addedValue) external;

    function beforeDecreaseAllowance(address msgSender, address spender, uint256 subtractedValue) external;

    function afterApprove(address sender, address spender, uint256 amount) external;

    function afterTransfer(address sender, address recipient, uint256 amount) external;

    function afterTransferFrom(address msgSender, address sender, address recipient, uint256 amount) external;

    function afterIncreaseAllowance(address sender, address spender, uint256 addedValue) external;

    function afterDecreaseAllowance(address sender, address spender, uint256 subtractedValue) external;

    function getVersion() external pure returns (uint256);
}

contract LosslessControllerV1 is Initializable, ContextUpgradeable, PausableUpgradeable, ILosslessController {
    address public pauseAdmin;
    address public admin;
    address public recoveryAdmin;
    address private recoveryAdminCanditate;
    bytes32 private recoveryAdminKeyHash;
    mapping (address => bool) public isBlackListed;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event RecoveryAdminChangeProposed(address indexed candidate);
    event RecoveryAdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event PauseAdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event RemovedBlackList(address _user);
    event AddedBlackList(address _user);


    function initialize(address _admin, address _recoveryAdmin, address _pauseAdmin) public initializer {
        admin = _admin;
        recoveryAdmin = _recoveryAdmin;
        pauseAdmin = _pauseAdmin;
    }

    // --- MODIFIERS ---

    modifier onlyLosslessRecoveryAdmin() {
        require(_msgSender() == recoveryAdmin, "LOSSLESS: Must be recoveryAdmin");
        _;
    }

    modifier onlyLosslessAdmin() {
        require(admin == _msgSender(), "LOSSLESS: Must be admin");
        _;
    }

    // --- SETTERS ---

    function pause() public {
        require(_msgSender() == pauseAdmin, "LOSSLESS: Must be pauseAdmin");
        _pause();
    }    
    
    function unpause() public {
        require(_msgSender() == pauseAdmin, "LOSSLESS: Must be pauseAdmin");
        _unpause();
    }

    function setAdmin(address newAdmin) public onlyLosslessRecoveryAdmin {
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function transferRecoveryAdminOwnership(address candidate, bytes32 keyHash) public onlyLosslessRecoveryAdmin {
        recoveryAdminCanditate = candidate;
        recoveryAdminKeyHash = keyHash;
        emit RecoveryAdminChangeProposed(candidate);
    }

    function acceptRecoveryAdminOwnership(bytes memory key) external {
        require(_msgSender() == recoveryAdminCanditate, "LOSSLESS: Must be canditate");
        require(keccak256(key) == recoveryAdminKeyHash, "LOSSLESS: Invalid key");
        emit RecoveryAdminChanged(recoveryAdmin, recoveryAdminCanditate);
        recoveryAdmin = recoveryAdminCanditate;
    }

    function setPauseAdmin(address newPauseAdmin) public onlyLosslessRecoveryAdmin {
        emit PauseAdminChanged(pauseAdmin, newPauseAdmin);
        pauseAdmin = newPauseAdmin;
    }

    // --- GETTERS ---

    function getVersion() override external pure returns (uint256) {
        return 1;
    }

    // Blacklisting check should use the already existing modifiers in LER20 and the check
    // itself should happen in LosslessController.
    function addBlackList (address _evilUser) public onlyLosslessRecoveryAdmin {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyLosslessRecoveryAdmin {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    // --- BEFORE HOOKS ---

    function beforeTransfer(address sender, address recipient, uint256 amount) override external {
        require(!isBlackListed[sender], "LosslessController: sender is blacklisted");
    }

    function beforeTransferFrom(address msgSender, address sender, address recipient, uint256 amount) override external {
        require(!isBlackListed[sender], "LosslessController: sender is blacklisted");
    }

    function beforeApprove(address sender, address spender, uint256 amount) override external {}

    function beforeIncreaseAllowance(address msgSender, address spender, uint256 addedValue) override external {}

    function beforeDecreaseAllowance(address msgSender, address spender, uint256 subtractedValue) override external {}

    // --- AFTER HOOKS ---

    function afterApprove(address sender, address spender, uint256 amount) override external {}

    function afterTransfer(address sender, address recipient, uint256 amount) override external {}

    function afterTransferFrom(address msgSender, address sender, address recipient, uint256 amount) override external {}

    function afterIncreaseAllowance(address sender, address spender, uint256 addedValue) override external {}

    function afterDecreaseAllowance(address sender, address spender, uint256 subtractedValue) override external {}
}