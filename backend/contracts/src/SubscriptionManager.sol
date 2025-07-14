// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ISubscriptionToken} from "./Interfaces/ISubscriptionToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AutomationCompatibleInterface} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {CrossChainManager} from "./CrossChainManager.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract SubscriptionManager is Ownable, AccessControl, AutomationCompatibleInterface {
    ISubscriptionToken private immutable i_subscriptionToken;
    CrossChainManager private crossChainManager;

    mapping(address => mapping(string => Subscription)) private subscriptionRecord;
    mapping(address => bool) private isKnownUser;

    mapping(string => CompanySubscription) private subscribingCompanies;
    address[] private companyAddresses;
    string[] private companyNames;
    address[] private userAddresses;

    bytes32 private constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 private constant CCIP_ROLE = keccak256("CCIP_ROLE");

    enum UpkeepAction {
        RENEW,
        CANCEL
    }

    struct CompanySubscription {
        string name;
        address subscriptionAddress;
        uint256 price;
        uint256 chainID;
    }

    struct Subscription {
        string name;
        address subscriptionAddress;
        uint256 price;
        uint256 interval;
        uint256 startTime;
        uint256 chainID;
        bool isActive;
    }

    struct DueSubscription {
        address user;
        string companyName;
        UpkeepAction action;
    }

    event SubscriptionPaid(string name, uint256 pricePaid, address subscriptionAddress, uint256 startTime);
    event SubscriptionUpdated(string name, address subscriptionAddress, uint256 price);
    event SubscriptionCancelled(string name, address user);

    error SubscriptionManager__InvalidInput();
    error SubscriptionManager__SubscriptionAlreadyExists();
    error SubscriptionManager__SubscriptionInactive();
    error SubscriptionManager__SubscriptionIsActive();

    address[] private receivers; // 0 -> sepolia, 1 -> avalanche

    constructor(ISubscriptionToken subscriptionTokenAddress) Ownable(msg.sender) {
        i_subscriptionToken = subscriptionTokenAddress;
    }

    function setReceivers(address[2] memory _receivers) external onlyOwner {
        receivers = _receivers;
    }

    function setCrossChainManager(CrossChainManager crossChainManagerAddress) external onlyOwner {
        crossChainManager = crossChainManagerAddress;
    }

    receive() external payable {
        // Handle incoming Ether deposits
    }

    function grantCCIPRole(address crossChainExecutor) external onlyOwner {
        _grantRole(CCIP_ROLE, crossChainExecutor);
    }

    function grantUserRole(address user) external onlyOwner {
        if (!isKnownUser[user]) {
            userAddresses.push(user);
            isKnownUser[user] = true;
        }

        _grantRole(USER_ROLE, user);
    }

    function createSubscription(string memory name, uint256 price) external {
        if (!_stringExists(companyNames, name)) {
            subscribingCompanies[name] =
                CompanySubscription({name: name, subscriptionAddress: msg.sender, price: price, chainID: block.chainid});
            companyNames.push(name);
        }
    }

    function enrollSubscription(
        string memory name,
        uint256 interval,
        address subscriptionAddress,
        uint256 price,
        uint256 chainID,
        address receiver
    ) external onlyRole(USER_ROLE) {
        _enrollSubscription(name, interval, subscriptionAddress, price, chainID, receiver);
    }

    function paySubscription(string memory name, address user, address receiver) public {
        _paySubscription(name, user, receiver);
    }

    function paySubscriptionWhenReceived(string memory name, address company, uint256 price)
        external
        onlyRole(CCIP_ROLE)
    {
        i_subscriptionToken.mint(company, price);
        emit SubscriptionPaid(name, price, company, block.timestamp);
    }

    function cancelSubscriptionWhenReceived(string memory name, address user) external onlyRole(CCIP_ROLE) {
        emit SubscriptionCancelled(name, user);
    }

    function cancelSubscription(string memory name, address user, address receiver) public {
        if (_checkIfSubscriptionIsOnDifferentChain(user, name)) {
            address[] memory users = new address[](1);
            users[0] = user;
            crossChainManager.sendMessage(
                CrossChainManager.Action.CANCEL,
                name,
                users,
                _getChainSelector(subscriptionRecord[user][name].chainID),
                receiver
            );
            subscriptionRecord[user][name].isActive = false;
            emit SubscriptionCancelled(name, user);
        } else {
            _cancelSubscription(name, user);
        }
    }

    // function updateCompanySubscription(string memory name, address _address, uint256 price)
    //     external
    //     onlyRole(COMPANY_ROLE)
    // {
    //     if (bytes(name).length == 0) {
    //         revert SubscriptionManager__InvalidInput();
    //     }
    //     CompanySubscription storage companySubscription = subscribingCompanies[name];

    //     companySubscription.subscriptionAddress = _address;
    //     companySubscription.price = price;
    //     emit SubscriptionUpdated(name, _address, price);
    // }

    function checkUpkeep(bytes calldata /* checkData */ )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (upkeepNeeded, performData) = _checkSubscriptionUpkeep();
    }

    function performUpkeep(bytes calldata performData) external override {
        _performSubscriptionUpkeep(performData);
    }

    function _checkSubscriptionUpkeep() internal view returns (bool upkeepNeeded, bytes memory performData) {
        DueSubscription[] memory dueList = new DueSubscription[](userAddresses.length * companyNames.length);
        uint256 count = 0;
        for (uint256 i = 0; i < userAddresses.length; i++) {
            address user = userAddresses[i];
            for (uint256 j = 0; j < companyNames.length; j++) {
                string memory companyName = companyNames[j];
                Subscription storage subscription = subscriptionRecord[user][companyName];
                if (subscription.isActive && block.timestamp >= subscription.startTime + subscription.interval) {
                    if (i_subscriptionToken.balanceOf(user) >= subscription.price) {
                        dueList[count] =
                            DueSubscription({user: user, companyName: companyName, action: UpkeepAction.RENEW});
                        count++;
                    } else {
                        dueList[count] =
                            DueSubscription({user: user, companyName: companyName, action: UpkeepAction.CANCEL});
                        count++;
                    }
                }
            }
        }

        if (count > 0) {
            upkeepNeeded = true;
            DueSubscription[] memory result = new DueSubscription[](count);
            for (uint256 k = 0; k < count; k++) {
                result[k] = dueList[k];
            }
            performData = abi.encode(result);
        } else {
            upkeepNeeded = false;
            performData = "";
        }
        return (upkeepNeeded, performData);
    }

    function _performSubscriptionUpkeep(bytes memory performData) internal {
        DueSubscription[] memory dueList = abi.decode(performData, (DueSubscription[]));
        for (uint256 i = 0; i < dueList.length; i++) {
            DueSubscription memory task = dueList[i];
            if (task.action == UpkeepAction.RENEW) {
                paySubscription(
                    task.companyName, task.user, _getReceiver(subscriptionRecord[task.user][task.companyName].chainID)
                );
            } else if (task.action == UpkeepAction.CANCEL) {
                cancelSubscription(
                    task.companyName, task.user, _getReceiver(subscriptionRecord[task.user][task.companyName].chainID)
                );
            }
        }
    }

    function _enrollSubscription(
        string memory name,
        uint256 interval,
        address subscriptionAddress,
        uint256 price,
        uint256 chainID,
        address receiver
    ) internal onlyRole(USER_ROLE) {
        if (bytes(name).length == 0) {
            revert SubscriptionManager__InvalidInput();
        }
        if (subscriptionAddress == address(0)) {
            revert SubscriptionManager__SubscriptionInactive();
        }

        subscriptionRecord[msg.sender][name] = Subscription({
            name: name,
            subscriptionAddress: subscriptionAddress,
            interval: interval,
            price: price,
            startTime: 0,
            chainID: chainID,
            isActive: true
        });
        if (!_stringExists(companyNames, name)) {
            subscribingCompanies[name] = CompanySubscription({
                name: name,
                subscriptionAddress: subscriptionAddress,
                price: price,
                chainID: chainID
            });
            companyNames.push(name);
        }
        _paySubscription(name, msg.sender, receiver);
    }

    function _getChainSelector(uint256 chainID) internal pure returns (uint64) {
        if (chainID == 11155111) {
            return 16015286601757825753; // Sepolia
        } else if (chainID == 43113) {
            return 14767482510784806043; // Avalanche
        } else {
            return 0; // Local Anvil or other networks
        }
    }

    function _getReceiver(uint256 chainID) internal view returns (address) {
        if (chainID == 11155111) {
            return receivers[0]; // Sepolia
        } else if (chainID == 43113) {
            return receivers[1]; // Avalanche
        } else {
            return address(0); // Local Anvil or other networks
        }
    }

    function _paySubscription(string memory name, address user, address receiver) internal {
        if (bytes(name).length == 0) {
            revert SubscriptionManager__InvalidInput();
        }
        Subscription storage subscription = subscriptionRecord[user][name];
        if (!subscription.isActive) {
            revert SubscriptionManager__SubscriptionInactive();
        }
        if (subscription.startTime == 0 || block.timestamp >= subscription.startTime + subscription.interval) {
            if (_checkIfSubscriptionIsOnDifferentChain(user, name)) {
                address[] memory users = new address[](1);
                users[0] = user;
                crossChainManager.sendMessage(
                    CrossChainManager.Action.PAY,
                    name,
                    users,
                    _getChainSelector(subscriptionRecord[user][name].chainID),
                    receiver
                );
                i_subscriptionToken.burn(user, subscriptionRecord[user][name].price);
                emit SubscriptionPaid(
                    name,
                    subscriptionRecord[user][name].price,
                    subscriptionRecord[user][name].subscriptionAddress,
                    block.timestamp
                );
                subscriptionRecord[user][name].startTime = block.timestamp;
                subscriptionRecord[user][name].isActive = true;
            } else {
                // i_subscriptionToken.transfer(subscription.subscriptionAddress, subscription.price);
                i_subscriptionToken.transferFrom(user, subscription.subscriptionAddress, subscription.price);

                subscription.startTime = block.timestamp;
                emit SubscriptionPaid(
                    name, subscription.price, subscription.subscriptionAddress, subscription.startTime
                );
            }
        } else {
            revert SubscriptionManager__SubscriptionIsActive();
        }
    }

    function _cancelSubscription(string memory name, address user) internal {
        Subscription storage subscription = subscriptionRecord[user][name];
        if (!subscription.isActive) return; // Already canceled, skip

        subscription.isActive = false;
        emit SubscriptionCancelled(name, user);
    }

    function getCompanySubscription(string memory name) public view returns (CompanySubscription memory) {
        return subscribingCompanies[name];
    }

    function _checkIfSubscriptionIsOnDifferentChain(address user, string memory name) internal view returns (bool) {
        Subscription storage subscription = subscriptionRecord[user][name];
        if (subscription.chainID != block.chainid) {
            return true;
        } else {
            return false;
        }
    }

    function _addressExists(address[] storage addresses, address addr) internal view returns (bool) {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function _stringExists(string[] storage list, string memory str) internal view returns (bool) {
        for (uint256 i = 0; i < list.length; i++) {
            if (keccak256(bytes(list[i])) == keccak256(bytes(str))) {
                return true;
            }
        }
        return false;
    }

    // function getCompanySubscription(string memory name) external view returns (CompanySubscription memory) {
    //     return subscribingCompanies[name];
    // }

    function getUserSubscription(string memory name, address user) external view returns (Subscription memory) {
        return subscriptionRecord[user][name];
    }

    function getSubscriptionTokenAddress() external view returns (address) {
        return address(i_subscriptionToken);
    }

    function getSubscriptionStatus(string memory name, address user) external view returns (bool) {
        return subscriptionRecord[user][name].isActive;
    }

    function getSubscriptionChainID(string memory name, address user) external view returns (uint256) {
        return subscriptionRecord[user][name].chainID;
    }

    function getSubscriptionCurrentPrice(string memory name, address user) external view returns (uint256) {
        return subscriptionRecord[user][name].price;
    }

    function getSubscriptionStartTime(string memory name, address user) external view returns (uint256) {
        return subscriptionRecord[user][name].startTime;
    }

    function getSubscriptionAddress(string memory name, address user) external view returns (address) {
        return subscriptionRecord[user][name].subscriptionAddress;
    }

    function getSubscriptionInterval(string memory name, address user) external view returns (uint256) {
        return subscriptionRecord[user][name].interval;
    }
}
