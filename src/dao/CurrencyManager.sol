// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { AccessControl } from "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import { EnumerableSet } from "../../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import { ICurrencyManager } from "./interfaces/ICurrencyManager.sol";

/**
 * @title CurrencyManager
 * @notice It allows adding/removing currencies for usage on the OneWP.
 */
contract CurrencyManager is ICurrencyManager, AccessControl {
  error CurrencyManagerError(string message);
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private _whitelistedCurrencies;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

  event CurrencyRemoved(address indexed currency);
  event CurrencyWhitelisted(address indexed currency);

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);
  }

  /**
   * @notice Add a currency in the system
   * @param currency address of the currency to add
   */
  function addCurrency(
    address currency
  ) external override onlyRole(ADMIN_ROLE) {
    if (currency == address(0))
      revert CurrencyManagerError("Cannot be null address");
    if (_whitelistedCurrencies.contains(currency))
      revert CurrencyManagerError("Already whitelisted");
    _whitelistedCurrencies.add(currency);

    emit CurrencyWhitelisted(currency);
  }

  /**
   * @notice Remove a currency from the system
   * @param currency address of the currency to remove
   */
  function removeCurrency(
    address currency
  ) external override onlyRole(ADMIN_ROLE) {
    if (!_whitelistedCurrencies.contains(currency))
      revert CurrencyManagerError("Not whitelisted");
    _whitelistedCurrencies.remove(currency);

    emit CurrencyRemoved(currency);
  }

  /**
   * @notice Returns if a currency is in the system
   * @param currency address of the currency
   */
  function isCurrencyWhitelisted(
    address currency
  ) external view override returns (bool) {
    return _whitelistedCurrencies.contains(currency);
  }

  /**
   * @notice View number of whitelisted currencies
   */
  function viewCountWhitelistedCurrencies()
    external
    view
    override
    returns (uint256)
  {
    return _whitelistedCurrencies.length();
  }

  /**
   * @notice See whitelisted currencies in the system
   * @param cursor cursor (should start at 0 for first request)
   * @param size size of the response (e.g., 50)
   */
  function viewWhitelistedCurrencies(
    uint256 cursor,
    uint256 size
  ) external view override returns (address[] memory, uint256) {
    uint256 length = size;

    if (length > _whitelistedCurrencies.length() - cursor) {
      length = _whitelistedCurrencies.length() - cursor;
    }

    address[] memory whitelistedCurrencies = new address[](length);

    for (uint256 i = 0; i < length; i++) {
      whitelistedCurrencies[i] = _whitelistedCurrencies.at(cursor + i);
    }

    return (whitelistedCurrencies, cursor + length);
  }
}
