// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./extensions/IERC20Metadata.sol";
import "./interfaces/IERC20.sol";
import "./utils/Context.sol";

error LunchToken__OnlyTheContractOwnerCanInvokeThisMethod();
error LunchToken__ERC20decreasedAllowanceBelowZero();
error LunchToken__ERC20transferFromTheZeroAddress();
error LunchToken__ERC20transferToTheZeroAddress();
error LunchToken__ERC20transferAmountExceedsBalance();
error LunchToken__ERC20mintToTheZeroAddress();
error LunchToken__ERC20burnFromTheZeroAddress();
error LunchToken__ERC20burnAmountExceedsBalance();
error LunchToken__ERC20approveFromTheZeroAddress();
error LunchToken__ERC20approveToTheZeroAddress();
error LunchToken__ERC20insufficientAllowance();

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract LunchToken is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _owner;

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert LunchToken__OnlyTheContractOwnerCanInvokeThisMethod();
        }
        _;
    }

    address[] private participants;
    string[] private participantNames;

    modifier votingAllowed() {
        require(voteOpen, "Vote not open");
        _;
    }

    modifier votingClosed() {
        require(!voteOpen, "Vote closed");
        _;
    }

    modifier onlyParticipant() {
        (bool _isParticipant, uint256 i) = isParticipant(_msgSender());
        require(_isParticipant, "Only Participant allowed");
        _;
    }

    bool voteOpen = false;
    string[] optionNames;
    uint256[] optionVotes;
    mapping(uint256 => address[]) optionVoters;
    string lastWinner;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = _msgSender();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the address of the contract owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address sender = _msgSender();
        _transfer(sender, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner_, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner_][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address sender = _msgSender();
        _approve(sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address sender = _msgSender();
        _approve(sender, spender, allowance(sender, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address sender = _msgSender();
        uint256 currentAllowance = allowance(sender, spender);
        if (currentAllowance < subtractedValue) {
            revert LunchToken__ERC20decreasedAllowanceBelowZero();
        }
        unchecked {
            _approve(sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) {
            revert LunchToken__ERC20transferFromTheZeroAddress();
        }
        if (to == address(0)) {
            revert LunchToken__ERC20transferToTheZeroAddress();
        }

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        if (fromBalance < amount) {
            revert LunchToken__ERC20transferAmountExceedsBalance();
        }
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) {
            revert LunchToken__ERC20mintToTheZeroAddress();
        }

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */

    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) {
            revert LunchToken__ERC20burnFromTheZeroAddress();
        }

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        if (accountBalance < amount) {
            revert LunchToken__ERC20burnAmountExceedsBalance();
        }
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */

    function _approve(
        address owner_,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner_ == address(0)) {
            revert LunchToken__ERC20approveFromTheZeroAddress();
        }
        if (spender == address(0)) {
            revert LunchToken__ERC20approveToTheZeroAddress();
        }

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner_,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner_, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert LunchToken__ERC20insufficientAllowance();
            }
            unchecked {
                _approve(owner_, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function destroyContract(address payable adr) public onlyOwner {
        selfdestruct(adr);
    }

    function registerParticipant(address address_, string memory name_)
        public
        onlyOwner
    {
        participants.push(address_);
        participantNames.push(name_);
    }

    function isParticipant(address address_)
        public
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < participants.length; i += 1) {
            if (address_ == participants[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function getParticipantName(address address_)
        public
        view
        onlyOwner
        returns (string memory)
    {
        (bool _isParticipant, uint256 i) = isParticipant(address_);
        return
            _isParticipant
                ? participantNames[i]
                : "This address is not participating in the voting.";
    }

    function removeParticipant(address address_) public onlyOwner {
        (bool _isParticipant, uint256 i) = isParticipant(address_);
        if (_isParticipant) {
            participants[i] = participants[participants.length - 1];
            participants.pop();
            participantNames[i] = participantNames[participantNames.length - 1];
            participantNames.pop();
        }
    }

    function getAllParticipantNames() public view returns (string[] memory) {
        return participantNames;
    }

    function startVoting(uint256 allocation) public onlyOwner votingClosed {
        voteOpen = true;
        for (uint256 i = 0; i < participants.length; i += 1) {
            _mint(participants[i], allocation);
        }
    }

    function endVoting() public onlyOwner votingAllowed {
        voteOpen = false;
        (uint256 winnerPosition, uint256 reward) = findWinner();
        distributeRewardsToVoters(winnerPosition, reward);
        resetPassiveParticipantsBalance();
        lastWinner = optionNames[winnerPosition];
    }

    function getLastWinner() public view votingClosed returns (string memory) {
        return lastWinner;
    }

    function findWinner()
        internal
        view
        returns (uint256 winnerPosition, uint256 reward)
    {
        uint256 maxVotes = 0;
        winnerPosition = 0;
        reward = 0;
        for (uint256 i = 0; i < optionVotes.length; i += 1) {
            if (optionVotes[i] > maxVotes) {
                maxVotes = optionVotes[i];
                winnerPosition = i;
            }
            reward += optionVotes[i];
        }
    }

    function distributeRewardsToVoters(uint256 position, uint256 reward)
        internal
    {
        address[] memory winningVoters = optionVoters[position];
        uint256 individualReward = reward / winningVoters.length;
        for (uint256 i = 0; i < participants.length; i += 1) {
            if (hasVoted(participants[i])) {
                transferFrom(
                    participants[i],
                    _owner,
                    _allowances[participants[i]][_owner]
                );
            }
        }
        for (uint256 i = 0; i < winningVoters.length; i += 1) {
            transfer(winningVoters[i], individualReward);
        }
    }

    function resetPassiveParticipantsBalance() internal {
        for (uint256 i = 0; i < participants.length; i += 1) {
            if (!hasVoted(participants[i])) {
                _burn(participants[i], _balances[participants[i]]);
            }
        }
    }

    function hasVoted(address address_) internal view returns (bool) {
        for (uint256 i = 0; i < optionNames.length; i += 1) {
            for (uint256 j = 0; j < optionVoters[i].length; j += 1) {
                if (optionVoters[i][j] == address_) {
                    return true;
                }
            }
        }
        return false;
    }

    function addOption(string memory name_)
        public
        votingAllowed
        onlyParticipant
    {
        optionNames.push(name_);
        optionVotes.push(0);
    }

    function getOptions()
        public
        view
        onlyParticipant
        returns (string[] memory)
    {
        return optionNames;
    }

    function vote(uint256 position, uint256 votes)
        public
        votingAllowed
        onlyParticipant
    {
        approve(_owner, votes);
        optionVotes[position] += votes;
        optionVoters[position].push(_msgSender());
    }
}
